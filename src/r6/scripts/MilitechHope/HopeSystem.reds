// Militech "Hope" Sandevistan — gameplay system:
//   * overheat logic (uses in a row -> forced 12 s recharge)
//   * side job "Hope" (Arasaka Waterfront -> Columbarium crate)
module MilitechHope

public class HopeMappinData extends MappinScriptData {}

public class HopeTick extends DelayCallback {
    public let system: wref<MilitechHopeSystem>;
    public let token: Int32;

    public func Call() -> Void {
        if IsDefined(this.system) {
            this.system.Tick(this.token);
        }
    }
}

public class MilitechHopeSystem extends ScriptableSystem {
    // ----- quest state (saved) -------------------------------------------
    // 0 = not started, 1 = message received / go to the cemetery, 2 = done
    private persistent let m_stage: Int32;

    // ----- session state ---------------------------------------------------
    private let m_loopToken: Int32;
    private let m_sessionReady: Bool;
    private let m_levelHintShown: Bool;
    private let m_mappinID: NewMappinID;
    private let m_hasMappin: Bool;
    private let m_crateRequested: Bool;
    private let m_crateFilled: Bool;
    private let m_baselineCount: Int32;
    private let m_nearTicks: Int32;

    // ----- overheat state --------------------------------------------------
    private let m_streak: Int32;
    private let m_lastExit: Float;

    // ----- max level perk: real-speed bullets ------------------------------
    private let m_realSpeedBullets: Bool;

    public static func Get(game: GameInstance) -> ref<MilitechHopeSystem> {
        return GameInstance.GetScriptableSystemsContainer(game).Get(n"MilitechHope.MilitechHopeSystem") as MilitechHopeSystem;
    }

    // =====================================================================
    //  Lifecycle
    // =====================================================================
    private func OnAttach() -> Void {
        this.ResetSession();
        this.StartLoop(5.0);
    }

    private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
        this.ResetSession();
        this.StartLoop(5.0);
    }

    private func OnPlayerAttach(request: ref<PlayerAttachRequest>) -> Void {
        this.ResetSession();
        this.StartLoop(5.0);
    }

    private func ResetSession() -> Void {
        this.m_sessionReady = false;
        this.m_levelHintShown = false;
        this.m_hasMappin = false;
        this.m_crateRequested = false;
        this.m_crateFilled = false;
        this.m_baselineCount = 0;
        this.m_nearTicks = 0;
        this.m_streak = 0;
        this.m_lastExit = 0.0;
        this.m_realSpeedBullets = false;
    }

    private func StartLoop(delay: Float) -> Void {
        this.m_loopToken += 1;
        this.Schedule(delay);
    }

    private func Schedule(delay: Float) -> Void {
        let cb = new HopeTick();
        cb.system = this;
        cb.token = this.m_loopToken;
        GameInstance.GetDelaySystem(this.GetGameInstance()).DelayCallback(cb, delay, false);
    }

    // =====================================================================
    //  Helpers
    // =====================================================================
    private func Now() -> Float {
        return EngineTime.ToFloat(GameInstance.GetSimTime(this.GetGameInstance()));
    }

    public func T(key: CName) -> String {
        return GetLocalizedTextByKey(key);
    }

    public func ShowMessage(text: String, kind: SimpleMessageType, duration: Float) -> Void {
        let message: SimpleScreenMessage;
        message.isShown = true;
        message.duration = duration;
        message.message = text;
        message.isInstant = true;
        message.type = kind;
        GameInstance.GetBlackboardSystem(this.GetGameInstance()).Get(GetAllBlackboardDefs().UI_Notifications)
            .SetVariant(GetAllBlackboardDefs().UI_Notifications.WarningMessage, ToVariant(message), true);
    }

    public func PlaySound(sound: CName) -> Void {
        let player = GetPlayer(this.GetGameInstance());
        if IsDefined(player) {
            GameObject.PlaySoundEvent(player, sound);
        }
    }

    // -1 = not a Hope item, 0 = Tier 5, 1 = Tier 5+, 2 = Tier 5++
    public static func LevelOf(record: TweakDBID) -> Int32 {
        if record == HopeConfig.ItemPlusPlus() {
            return 2;
        }
        if record == HopeConfig.ItemPlus() {
            return 1;
        }
        if record == HopeConfig.ItemBase() {
            return 0;
        }
        return -1;
    }

    public func GetEquippedHopeLevel(owner: ref<GameObject>) -> Int32 {
        let data = EquipmentSystem.GetData(owner);
        if !IsDefined(data) {
            return -1;
        }
        let area = gamedataEquipmentArea.SystemReplacementCW;
        let count = data.GetNumberOfSlots(area);
        let i = 0;
        while i < count {
            let item = data.GetItemInEquipSlot(area, i);
            if ItemID.IsValid(item) {
                let level = MilitechHopeSystem.LevelOf(ItemID.GetTDBID(item));
                if level >= 0 {
                    return level;
                }
            }
            i += 1;
        }
        return -1;
    }

    public func CountHopeItems(owner: ref<GameObject>) -> Int32 {
        let items: array<wref<gameItemData>>;
        let total = 0;
        if !IsDefined(owner) {
            return 0;
        }
        GameInstance.GetTransactionSystem(this.GetGameInstance()).GetItemList(owner, items);
        for item in items {
            if IsDefined(item) && MilitechHopeSystem.LevelOf(ItemID.GetTDBID(item.GetID())) >= 0 {
                total += item.GetQuantity();
            }
        }
        return total;
    }

    public func GiveToPlayer() -> Bool {
        let player = GetPlayer(this.GetGameInstance());
        if !IsDefined(player) {
            return false;
        }
        return GameInstance.GetTransactionSystem(this.GetGameInstance()).GiveItemByTDBID(player, HopeConfig.ItemBase(), 1);
    }

    // =====================================================================
    //  Overheat
    // =====================================================================

    // Called right before the vanilla SandevistanEvents.OnEnter.
    // Returns true when this activation overheats the implant.
    public func OnSandevistanEnter(owner: ref<GameObject>) -> Bool {
        let level = this.GetEquippedHopeLevel(owner);
        this.m_realSpeedBullets = level >= HopeConfig.RealSpeedBulletsLevel();
        if level < 0 {
            this.m_streak = 0;
            return false;
        }

        let game = this.GetGameInstance();
        let now = this.Now();
        let charge = GameInstance.GetStatPoolsSystem(game).GetStatPoolValue(Cast<StatsObjectID>(owner.GetEntityID()), gamedataStatPoolType.SandevistanCharge, true);

        if charge >= HopeConfig.StreakResetChargePercent()
            || (this.m_lastExit > 0.0 && now - this.m_lastExit > HopeConfig.StreakResetSeconds()) {
            this.m_streak = 0;
        }

        this.m_streak += 1;
        let limit = HopeConfig.UsesInARow(level);

        if this.m_streak > limit {
            this.m_streak = 0;
            this.m_realSpeedBullets = false;
            return true;
        }

        if this.m_streak == limit {
            this.ShowMessage(this.T(n"MilitechHope-Msg-OverheatWarning"), SimpleMessageType.Neutral, 3.0);
        }
        return false;
    }

    public func OnSandevistanExit(owner: ref<GameObject>) -> Void {
        this.m_lastExit = this.Now();
        this.m_realSpeedBullets = false;
    }

    // True while a Tier 5++ Hope Sandevistan is running: the player's
    // bullets keep their normal (hitscan) behaviour instead of turning
    // into slow time-dilated projectiles.
    public func HasRealSpeedBullets() -> Bool {
        return this.m_realSpeedBullets;
    }

    public func TriggerOverheat(owner: ref<GameObject>) -> Void {
        let game = this.GetGameInstance();
        let player = owner as PlayerPuppet;
        if !IsDefined(player) {
            return;
        }

        // 1) shut the Sandevistan down right away
        let deactivate = new PSMPostponedParameterBool();
        deactivate.id = n"requestSandevistanDeactivation";
        deactivate.value = true;
        player.QueueEvent(deactivate);

        // 2) dump the whole charge -> full recharge from zero
        GameInstance.GetStatPoolsSystem(game).RequestSettingStatPoolMinValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatPoolType.SandevistanCharge, player);

        // 3) lock activation for 12 s (status effect zeroes HasSandevistan)
        StatusEffectHelper.ApplyStatusEffect(player, HopeConfig.OverheatEffect());

        GameObject.PlaySoundEvent(player, n"ui_jingle_chip_malfunction");
        this.ShowMessage(this.T(n"MilitechHope-Msg-Overheat"), SimpleMessageType.Negative, 5.0);
    }

    public func IsOverheated(owner: ref<GameObject>) -> Bool {
        return StatusEffectSystem.ObjectHasStatusEffect(owner, HopeConfig.OverheatEffect());
    }

    // =====================================================================
    //  Side job "Hope"
    // =====================================================================
    public func GetStage() -> Int32 {
        return this.m_stage;
    }

    public func DebugSetStage(stage: Int32) -> Void {
        this.ClearMappins();
        this.DeleteCrate();
        this.m_stage = stage;
        this.ResetSession();
    }

    public func Tick(token: Int32) -> Void {
        if token != this.m_loopToken {
            return;
        }
        this.Schedule(1.0);

        let player = GetPlayer(this.GetGameInstance());
        if !IsDefined(player) || !player.IsAttached() || player.IsDead() {
            return;
        }

        if !this.m_sessionReady {
            this.m_sessionReady = true;
            this.ClearMappins();
            if this.m_stage >= 2 {
                this.DeleteCrate();
            }
            if this.m_stage == 1 {
                this.EnsureMappin();
            }
        }

        let pos = player.GetWorldPosition();
        switch this.m_stage {
            case 0:
                this.TickNotStarted(player, pos);
                break;
            case 1:
                this.TickGoToCemetery(player, pos);
                break;
            default:
                break;
        }
    }

    private func Distance2D(a: Vector4, x: Float, y: Float) -> Float {
        let dx = a.X - x;
        let dy = a.Y - y;
        return SqrtF(dx * dx + dy * dy);
    }

    private func CratePosition() -> Vector4 {
        let v: Vector4;
        v.X = HopeConfig.CrateX();
        v.Y = HopeConfig.CrateY();
        v.Z = HopeConfig.CrateZ();
        v.W = 1.0;
        return v;
    }

    private func TickNotStarted(player: ref<PlayerPuppet>, pos: Vector4) -> Void {
        if this.Distance2D(pos, HopeConfig.TriggerX(), HopeConfig.TriggerY()) > HopeConfig.TriggerRadius() {
            return;
        }

        let level = GameInstance.GetStatsSystem(this.GetGameInstance()).GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.Level);
        if level < HopeConfig.RequiredLevel() {
            if !this.m_levelHintShown {
                this.m_levelHintShown = true;
                this.ShowMessage(this.T(n"MilitechHope-Msg-LevelLocked"), SimpleMessageType.Neutral, 6.0);
            }
            return;
        }

        this.m_stage = 1;
        this.m_crateRequested = false;
        this.m_crateFilled = false;
        this.m_nearTicks = 0;
        GameObject.PlaySoundEvent(player, n"ui_phone_sms");
        this.ShowMessage(this.T(n"MilitechHope-Msg-Sms"), SimpleMessageType.Neutral, 12.0);
        this.EnsureMappin();
    }

    private func TickGoToCemetery(player: ref<PlayerPuppet>, pos: Vector4) -> Void {
        let cratePos = this.CratePosition();
        let dist = Vector4.Distance(pos, cratePos);

        if dist <= HopeConfig.CrateSpawnDistance() {
            this.EnsureCrate();
            this.FillCrate(player);
        }

        // Looted from the crate?
        if this.m_crateFilled && this.CountHopeItems(player) > this.m_baselineCount {
            this.CompleteQuest(false);
            return;
        }

        // Fallback: crate missing or not interactable -> hand it over directly
        if dist <= HopeConfig.CrateFallbackDistance() {
            this.m_nearTicks += 1;
            if (!this.m_crateFilled && this.m_nearTicks >= 3) || this.m_nearTicks >= HopeConfig.CrateFallbackSeconds() {
                this.CompleteQuest(true);
            }
        } else {
            this.m_nearTicks = 0;
        }
    }

    private func CompleteQuest(giveDirectly: Bool) -> Void {
        if giveDirectly {
            this.EmptyCrate();
            this.GiveToPlayer();
        }
        this.m_stage = 2;
        this.ClearMappins();
        this.PlaySound(n"ui_loot_rarity_legendary");
        this.ShowMessage(this.T(n"MilitechHope-Msg-Complete"), SimpleMessageType.Relic, 8.0);
    }

    // ----- mappin ------------------------------------------------------------
    private func EnsureMappin() -> Void {
        if this.m_hasMappin {
            return;
        }
        let system = GameInstance.GetMappinSystem(this.GetGameInstance());
        if !IsDefined(system) {
            return;
        }
        let data: MappinData;
        data.mappinType = t"Mappins.DefaultStaticMappin";
        data.variant = gamedataMappinVariant.CustomPositionVariant;
        data.active = true;
        data.visibleThroughWalls = true;
        data.debugCaption = "Militech Hope";
        data.scriptData = new HopeMappinData();
        this.m_mappinID = system.RegisterMappin(data, this.CratePosition());
        this.m_hasMappin = true;
    }

    private func ClearMappins() -> Void {
        let system = GameInstance.GetMappinSystem(this.GetGameInstance());
        if !IsDefined(system) {
            return;
        }
        let pins = system.GetAllMappins();
        for pin in pins {
            if IsDefined(pin) && IsDefined(pin.GetScriptData() as HopeMappinData) {
                system.UnregisterMappin(pin.GetNewMappinID());
            }
        }
        this.m_hasMappin = false;
    }

    // ----- crate (Codeware DynamicEntitySystem) ------------------------------
    private func EnsureCrate() -> Void {
        let des = GameInstance.GetDynamicEntitySystem();
        if !IsDefined(des) || !des.IsReady() {
            return;
        }
        if des.IsPopulated(HopeConfig.CrateTag()) {
            this.m_crateRequested = true;
            return;
        }
        if this.m_crateRequested {
            return;
        }
        let rot: Quaternion;
        rot.i = 0.0;
        rot.j = 0.0;
        rot.k = 0.0;
        rot.r = 1.0;
        let spec = new DynamicEntitySpec();
        spec.templatePath = HopeConfig.CrateTemplate();
        spec.position = this.CratePosition();
        spec.orientation = rot;
        spec.persistState = false;
        spec.persistSpawn = false;
        spec.alwaysSpawned = false;
        spec.spawnInView = true;
        spec.active = true;
        spec.tags = [HopeConfig.CrateTag()];
        des.CreateEntity(spec);
        this.m_crateRequested = true;
        this.m_crateFilled = false;
    }

    private func GetCrate() -> ref<GameObject> {
        let des = GameInstance.GetDynamicEntitySystem();
        if !IsDefined(des) {
            return null;
        }
        let entities = des.GetTagged(HopeConfig.CrateTag());
        for entity in entities {
            let obj = entity as GameObject;
            if IsDefined(obj) && obj.IsAttached() {
                return obj;
            }
        }
        return null;
    }

    private func FillCrate(player: ref<PlayerPuppet>) -> Void {
        if this.m_crateFilled {
            return;
        }
        let crate = this.GetCrate();
        if !IsDefined(crate) {
            return;
        }
        this.m_baselineCount = this.CountHopeItems(player);
        if GameInstance.GetTransactionSystem(this.GetGameInstance()).GiveItemByTDBID(crate, HopeConfig.ItemBase(), 1) {
            this.m_crateFilled = true;
        }
    }

    private func EmptyCrate() -> Void {
        let crate = this.GetCrate();
        if IsDefined(crate) && this.m_crateFilled {
            GameInstance.GetTransactionSystem(this.GetGameInstance()).RemoveItemByTDBID(crate, HopeConfig.ItemBase(), 1);
        }
    }

    private func DeleteCrate() -> Void {
        let des = GameInstance.GetDynamicEntitySystem();
        if IsDefined(des) && des.IsReady() {
            des.DeleteTagged(HopeConfig.CrateTag());
        }
        this.m_crateRequested = false;
        this.m_crateFilled = false;
    }
}
