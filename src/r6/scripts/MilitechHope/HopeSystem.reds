// Militech "Hope" Sandevistan — gameplay system:
//   * heat model in degrees Celsius (overheat -> forced recharge)
//   * reactions to other installed implants (Axolotl, Cox-2, ...)
//   * Tier 5++ upgrade modules (two slots: AttachmentSlots.SandevistanSlot1/2)
//   * afterimage trail while the Sandevistan is active
//   * mastery: frequent use lowers the capacity cost and improves the implant
//   * burnout: too many activations in a short time can burn the core out
//   * Militech broker: hidden business card, shop and contracts
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

public class HopeFastTick extends DelayCallback {
    public let system: wref<MilitechHopeSystem>;
    public let token: Int32;

    public func Call() -> Void {
        if IsDefined(this.system) {
            this.system.FastTick(this.token);
        }
    }
}

public class MilitechHopeSystem extends ScriptableSystem {
    // ----- saved state ---------------------------------------------------
    // side job: 0 = not started, 1 = message received / go to the cemetery, 2 = done
    private persistent let m_stage: Int32;
    // broker: 1 = the number from the business card is known
    private persistent let m_contact: Int32;
    private persistent let m_cardMisses: Int32;
    // contracts: how many are done, current one (upgrade index + 1, 0 = none), kills so far
    private persistent let m_contractsDone: Int32;
    private persistent let m_contract: Int32;
    private persistent let m_contractKills: Int32;
    // mastery: how many times Hope has been activated (any tier)
    private persistent let m_masteryUses: Int32;

    // ----- session state ---------------------------------------------------
    private let m_loopToken: Int32;
    private let m_fastToken: Int32;
    private let m_sessionReady: Bool;
    private let m_levelHintShown: Bool;
    private let m_mappinID: NewMappinID;
    private let m_hasMappin: Bool;
    private let m_crateRequested: Bool;
    private let m_crateFilled: Bool;
    private let m_baselineCount: Int32;
    private let m_nearTicks: Int32;

    // ----- heat ------------------------------------------------------------
    private let m_heat: Float;
    private let m_warned: Bool;
    private let m_level: Int32;
    // installed module per upgrade slot (upgrade index, -1 = empty)
    private let m_slotUpgrades: array<Int32>;
    private let m_replaceSlot: Int32;
    private let m_clock: Float;

    // ----- active Sandevistan ----------------------------------------------
    private let m_active: Bool;
    private let m_activeTime: Float;
    private let m_realSpeedBullets: Bool;
    private let m_berserk: Bool;
    private let m_madness: Bool;
    private let m_phase: Bool;
    private let m_berserkMods: array<ref<gameStatModifierData>>;
    private let m_madnessMod: ref<gameStatModifierData>;
    private let m_breathMod: ref<gameStatModifierData>;
    private let m_killTimes: array<Float>;
    private let m_recentKills: array<EntityID>;

    // ----- mastery / warnings / burnout ------------------------------------------
    private let m_masteryApplied: Int32;
    private let m_masteryMods: array<ref<gameStatModifierData>>;
    private let m_activationTimes: array<Float>;
    private let m_pendingWarning: Int32;
    private let m_warnDelay: Float;
    private let m_burnoutPending: Bool;
    // 0 = none, 1 = error storm, 2 = discharge (time stopped)
    private let m_burnout: Int32;
    private let m_burnoutTimer: Float;
    private let m_burnoutErrorTimer: Float;
    private let m_burnoutHeatStart: Float;

    // ----- other implants ----------------------------------------------------
    private let m_implantIds: array<TweakDBID>;
    private let m_implantKinds: array<Int32>;
    private let m_implantTimer: Float;
    private let m_axolotl: Bool;
    private let m_cox2: Bool;
    private let m_bioconductor: Bool;
    private let m_adrenaline: Bool;
    private let m_secondHeart: Bool;
    private let m_reflexTuner: Bool;

    // ----- trail -------------------------------------------------------------
    private let m_trail: array<ref<FxInstance>>;
    private let m_trailLast: Vector4;
    private let m_trailHasLast: Bool;
    private let m_trailFade: Float;

    // ----- broker ------------------------------------------------------------
    private let m_hud: ref<HopeHud>;
    private let m_keyHandler: ref<CallbackSystemHandler>;
    private let m_menuOpen: Bool;
    private let m_menuIndex: Int32;
    private let m_menuStatus: String;
    private let m_installCursor: Int32;
    private let m_visited: array<EntityID>;
    private let m_cardPlanted: Bool;

    public static func Get(game: GameInstance) -> ref<MilitechHopeSystem> {
        return GameInstance.GetScriptableSystemsContainer(game).Get(n"MilitechHope.MilitechHopeSystem") as MilitechHopeSystem;
    }

    // =====================================================================
    //  Lifecycle
    // =====================================================================
    private func OnAttach() -> Void {
        this.BuildImplantTable();
        this.ResetSession();
        this.StartLoop(5.0);
    }

    private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
        this.ResetSession();
        this.StartLoop(5.0);
    }

    private func OnPlayerAttach(request: ref<PlayerAttachRequest>) -> Void {
        this.ResetSession();
        this.RegisterInput();
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

        this.m_heat = HopeConfig.AmbientHeat();
        this.m_warned = false;
        this.m_level = -1;
        ArrayClear(this.m_slotUpgrades);
        this.m_clock = 0.0;
        this.m_active = false;
        this.m_activeTime = 0.0;
        this.m_realSpeedBullets = false;
        this.m_berserk = false;
        this.m_madness = false;
        this.m_phase = false;
        ArrayClear(this.m_berserkMods);
        this.m_madnessMod = null;
        this.m_breathMod = null;
        ArrayClear(this.m_killTimes);
        ArrayClear(this.m_recentKills);
        this.m_implantTimer = 0.0;

        // Runtime stat modifiers are not saved: the new player object has none.
        this.m_masteryApplied = -1;
        ArrayClear(this.m_masteryMods);
        ArrayClear(this.m_activationTimes);
        this.m_pendingWarning = 0;
        this.m_warnDelay = 0.0;
        this.m_burnoutPending = false;
        if this.m_burnout > 0 {
            this.ClearBurnoutTime();
        }
        this.m_burnout = 0;
        this.m_burnoutTimer = 0.0;

        ArrayClear(this.m_trail);
        this.m_trailHasLast = false;
        this.m_trailFade = 0.0;

        if !IsDefined(this.m_hud) {
            this.m_hud = new HopeHud();
        }
        this.m_hud.HideMenu();
        this.m_hud.HideGauge();
        this.m_hud.HideBanner();
        this.m_hud.Reset();
        this.m_menuOpen = false;
        this.m_menuIndex = 0;
        this.m_menuStatus = "";
        ArrayClear(this.m_visited);
        this.m_cardPlanted = false;
    }

    private func StartLoop(delay: Float) -> Void {
        this.m_loopToken += 1;
        this.Schedule(delay);
        this.m_fastToken += 1;
        this.ScheduleFast(delay);
    }

    private func Schedule(delay: Float) -> Void {
        let cb = new HopeTick();
        cb.system = this;
        cb.token = this.m_loopToken;
        GameInstance.GetDelaySystem(this.GetGameInstance()).DelayCallback(cb, delay, false);
    }

    private func ScheduleFast(delay: Float) -> Void {
        let cb = new HopeFastTick();
        cb.system = this;
        cb.token = this.m_fastToken;
        GameInstance.GetDelaySystem(this.GetGameInstance()).DelayCallback(cb, delay, false);
    }

    // =====================================================================
    //  Helpers
    // =====================================================================
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

    private func Banner(text: String, sub: String, level: Int32, seconds: Float, glitch: Bool) -> Void {
        if HopeConfig.BannerEnabled() {
            this.m_hud.ShowBanner(text, sub, level, seconds, glitch);
        }
    }

    public func PlaySound(sound: CName) -> Void {
        let player = GetPlayer(this.GetGameInstance());
        if IsDefined(player) {
            GameObject.PlaySoundEvent(player, sound);
        }
    }

    private func StatsID(obj: ref<GameObject>) -> StatsObjectID {
        return Cast<StatsObjectID>(obj.GetEntityID());
    }

    private func PoolPercent(obj: ref<GameObject>, pool: gamedataStatPoolType) -> Float {
        return GameInstance.GetStatPoolsSystem(this.GetGameInstance()).GetStatPoolValue(this.StatsID(obj), pool, true);
    }

    private func SetPoolPercent(obj: ref<GameObject>, pool: gamedataStatPoolType, value: Float) -> Void {
        GameInstance.GetStatPoolsSystem(this.GetGameInstance()).RequestSettingStatPoolValue(this.StatsID(obj), pool, value, obj, true);
    }

    private func ChangePoolPercent(obj: ref<GameObject>, pool: gamedataStatPoolType, diff: Float) -> Void {
        GameInstance.GetStatPoolsSystem(this.GetGameInstance()).RequestChangingStatPoolValue(this.StatsID(obj), pool, diff, obj, false, true);
    }

    private func AddMod(obj: ref<GameObject>, stat: gamedataStatType, kind: gameStatModifierType, value: Float) -> ref<gameStatModifierData> {
        let mod = RPGManager.CreateStatModifier(stat, kind, value);
        GameInstance.GetStatsSystem(this.GetGameInstance()).AddModifier(this.StatsID(obj), mod);
        return mod;
    }

    private func RemoveMod(obj: ref<GameObject>, mod: ref<gameStatModifierData>) -> Void {
        if IsDefined(mod) {
            GameInstance.GetStatsSystem(this.GetGameInstance()).RemoveModifier(this.StatsID(obj), mod);
        }
    }

    // "1 234 567"
    public static func FormatMoney(value: Int32) -> String {
        let digits = IntToString(value);
        let result = "";
        let len = StrLen(digits);
        let i = 0;
        while i < len {
            if i > 0 && (len - i) % 3 == 0 {
                result = result + " ";
            }
            result = result + StrMid(digits, i, 1);
            i += 1;
        }
        return result;
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

    public func GetEquippedHopeItem(owner: ref<GameObject>) -> ItemID {
        let none: ItemID;
        let data = EquipmentSystem.GetData(owner);
        if !IsDefined(data) {
            return none;
        }
        let area = gamedataEquipmentArea.SystemReplacementCW;
        let count = data.GetNumberOfSlots(area);
        let i = 0;
        while i < count {
            let item = data.GetItemInEquipSlot(area, i);
            if ItemID.IsValid(item) && MilitechHopeSystem.LevelOf(ItemID.GetTDBID(item)) >= 0 {
                return item;
            }
            i += 1;
        }
        return none;
    }

    public func GetEquippedHopeLevel(owner: ref<GameObject>) -> Int32 {
        let item = this.GetEquippedHopeItem(owner);
        if !ItemID.IsValid(item) {
            return -1;
        }
        return MilitechHopeSystem.LevelOf(ItemID.GetTDBID(item));
    }

    // Upgrade modules installed in the equipped Tier 5++: one entry per slot
    // (upgrade index, -1 = empty slot). Empty array without a Tier 5++.
    public func GetInstalledUpgrades(owner: ref<GameObject>) -> array<Int32> {
        let result: array<Int32>;
        let item = this.GetEquippedHopeItem(owner);
        if !ItemID.IsValid(item) || MilitechHopeSystem.LevelOf(ItemID.GetTDBID(item)) < 2 {
            return result;
        }
        let data = GameInstance.GetTransactionSystem(this.GetGameInstance()).GetItemData(owner, item);
        let i = 0;
        while i < HopeConfig.UpgradeSlotCount() {
            let index = -1;
            let slot = HopeConfig.UpgradeSlot(i);
            if IsDefined(data) && data.HasPartInSlot(slot) {
                let part: InnerItemData;
                data.GetItemPart(part, slot);
                index = HopeUpgrades.IndexOf(ItemID.GetTDBID(InnerItemData.GetItemID(part)));
            }
            ArrayPush(result, index);
            i += 1;
        }
        return result;
    }

    private func RefreshUpgrades(owner: ref<GameObject>) -> Void {
        this.m_slotUpgrades = this.GetInstalledUpgrades(owner);
    }

    public func HasUpgrade(index: Int32) -> Bool {
        for installed in this.m_slotUpgrades {
            if installed == index {
                return true;
            }
        }
        return false;
    }

    // "Discharge, Berserk" (installed modules, slot order)
    private func UpgradeNames() -> String {
        let names = "";
        for installed in this.m_slotUpgrades {
            if installed >= 0 {
                names = this.Join(names, this.T(HopeUpgrades.NameKey(installed)));
            }
        }
        return names;
    }

    public func CountItems(owner: ref<GameObject>, record: TweakDBID) -> Int32 {
        let items: array<wref<gameItemData>>;
        let total = 0;
        if !IsDefined(owner) {
            return 0;
        }
        GameInstance.GetTransactionSystem(this.GetGameInstance()).GetItemList(owner, items);
        for item in items {
            if IsDefined(item) && ItemID.GetTDBID(item.GetID()) == record {
                total += item.GetQuantity();
            }
        }
        return total;
    }

    private func FindItem(owner: ref<GameObject>, record: TweakDBID) -> ItemID {
        let none: ItemID;
        let items: array<wref<gameItemData>>;
        GameInstance.GetTransactionSystem(this.GetGameInstance()).GetItemList(owner, items);
        for item in items {
            if IsDefined(item) && ItemID.GetTDBID(item.GetID()) == record {
                return item.GetID();
            }
        }
        return none;
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
    //  Other implants
    // =====================================================================
    // kinds: 0 Axolotl, 1 Cox-2, 2 Bioconductor, 3 Adrenaline Booster, 4 Second Heart, 5 Reflex Tuner
    private func AddImplant(base: String, kind: Int32) -> Void {
        let suffixes: array<String> = ["", "Common", "CommonPlus", "Uncommon", "UncommonPlus", "Rare", "RarePlus",
            "Epic", "EpicPlus", "Legendary", "LegendaryPlus", "LegendaryPlusPlus"];
        for suffix in suffixes {
            ArrayPush(this.m_implantIds, TDBID.Create(base + suffix));
            ArrayPush(this.m_implantKinds, kind);
        }
    }

    private func BuildImplantTable() -> Void {
        ArrayClear(this.m_implantIds);
        ArrayClear(this.m_implantKinds);
        this.AddImplant("Items.IconicAdvancedSubdermalCoProcessor", 0);
        this.AddImplant("Items.IconicBioConductors", 1);
        this.AddImplant("Items.AdvancedBioConductors", 2);
        this.AddImplant("Items.AdvancedStaminaRegenBooster", 3);
        this.AddImplant("Items.AdvancedSecondHeart", 4);
        this.AddImplant("Items.AdvancedReflexRecorder", 5);
    }

    private func MarkImplant(record: TweakDBID) -> Void {
        let i = 0;
        let count = ArraySize(this.m_implantIds);
        while i < count {
            if this.m_implantIds[i] == record {
                switch this.m_implantKinds[i] {
                    case 0:
                        this.m_axolotl = true;
                        break;
                    case 1:
                        this.m_cox2 = true;
                        break;
                    case 2:
                        this.m_bioconductor = true;
                        break;
                    case 3:
                        this.m_adrenaline = true;
                        break;
                    case 4:
                        this.m_secondHeart = true;
                        break;
                    case 5:
                        this.m_reflexTuner = true;
                        break;
                    default:
                        break;
                }
                return;
            }
            i += 1;
        }
    }

    private func RefreshImplants(player: ref<PlayerPuppet>) -> Void {
        this.m_axolotl = false;
        this.m_cox2 = false;
        this.m_bioconductor = false;
        this.m_adrenaline = false;
        this.m_secondHeart = false;
        this.m_reflexTuner = false;
        if ArraySize(this.m_implantIds) == 0 {
            this.BuildImplantTable();
        }
        let data = EquipmentSystem.GetData(player);
        if !IsDefined(data) {
            return;
        }
        let areas: array<gamedataEquipmentArea> = [
            gamedataEquipmentArea.FrontalCortexCW, gamedataEquipmentArea.CardiovascularSystemCW,
            gamedataEquipmentArea.NervousSystemCW, gamedataEquipmentArea.IntegumentarySystemCW,
            gamedataEquipmentArea.MusculoskeletalSystemCW, gamedataEquipmentArea.ImmuneSystemCW,
            gamedataEquipmentArea.SystemReplacementCW
        ];
        for area in areas {
            let count = data.GetNumberOfSlots(area);
            let i = 0;
            while i < count {
                let item = data.GetItemInEquipSlot(area, i);
                if ItemID.IsValid(item) {
                    this.MarkImplant(ItemID.GetTDBID(item));
                }
                i += 1;
            }
        }
    }

    private func SyncText() -> String {
        let names = "";
        if this.m_axolotl {
            names = this.Join(names, this.T(n"MilitechHope-Implant-Axolotl"));
        }
        if this.m_cox2 {
            names = this.Join(names, this.T(n"MilitechHope-Implant-Cox2"));
        }
        if this.m_bioconductor {
            names = this.Join(names, this.T(n"MilitechHope-Implant-Bioconductor"));
        }
        if this.m_adrenaline {
            names = this.Join(names, this.T(n"MilitechHope-Implant-Adrenaline"));
        }
        if this.m_secondHeart {
            names = this.Join(names, this.T(n"MilitechHope-Implant-SecondHeart"));
        }
        if this.m_reflexTuner {
            names = this.Join(names, this.T(n"MilitechHope-Implant-ReflexTuner"));
        }
        return names;
    }

    private func Join(a: String, b: String) -> String {
        if StrLen(a) == 0 {
            return b;
        }
        return a + ", " + b;
    }

    private func HeatMultiplier() -> Float {
        let mult = 1.0 - HopeConfig.MasteryHeatPerLevel() * Cast<Float>(this.MasteryLevel());
        if this.m_cox2 {
            mult *= HopeConfig.Cox2HeatMult();
        }
        if this.m_bioconductor {
            mult *= HopeConfig.BioconductorHeatMult();
        }
        return mult;
    }

    private func CoolingMultiplier() -> Float {
        let mult = 1.0 + HopeConfig.MasteryCoolingPerLevel() * Cast<Float>(this.MasteryLevel());
        if this.m_axolotl {
            mult *= HopeConfig.AxolotlCoolingMult();
        }
        if this.m_cox2 {
            mult *= HopeConfig.Cox2CoolingMult();
        }
        return mult;
    }

    private func DrainMultiplier() -> Float {
        if this.m_adrenaline {
            return HopeConfig.AdrenalineDrainMult();
        }
        return 1.0;
    }

    // =====================================================================
    //  Sandevistan enter / exit (called from SandevistanHooks.reds)
    // =====================================================================

    // Called right before the vanilla SandevistanEvents.OnEnter.
    // Returns true when this activation overheats the implant.
    public func OnSandevistanEnter(owner: ref<GameObject>) -> Bool {
        let player = owner as PlayerPuppet;
        let level = this.GetEquippedHopeLevel(owner);
        this.m_level = level;
        this.m_realSpeedBullets = level >= HopeConfig.RealSpeedBulletsLevel();
        if level < 0 || !IsDefined(player) {
            return false;
        }

        this.RefreshImplants(player);
        this.RefreshUpgrades(owner);
        let charge = this.PoolPercent(owner, gamedataStatPoolType.SandevistanCharge);

        let heat = HopeConfig.ActivationHeat(level) * this.HeatMultiplier();
        if charge >= HopeConfig.FullChargePercent() {
            heat *= HopeConfig.ColdStartFactor();
        }

        let madness = this.HasUpgrade(5) && RandF() < HopeConfig.MadnessChance();
        if madness {
            heat += HopeConfig.MadnessHeat();
        }

        if this.m_burnout > 0 {
            this.m_realSpeedBullets = false;
            return true;
        }

        // Burnout: the 10th (or later) activation within 5 minutes may burn the core out.
        let recent = this.CountRecentActivations() + 1;
        if HopeConfig.BurnoutEnabled() && recent >= HopeConfig.BurnoutActivations() && RandF() < HopeConfig.BurnoutChance() {
            this.m_burnoutPending = true;
            this.m_realSpeedBullets = false;
            return true;
        }

        if this.m_heat + heat >= HopeConfig.CriticalHeat() {
            this.m_heat = HopeConfig.CriticalHeat();
            this.m_realSpeedBullets = false;
            return true;
        }
        this.m_heat += heat;
        ArrayPush(this.m_activationTimes, this.m_clock);
        this.AddMasteryUse(player);

        this.m_active = true;
        this.m_activeTime = 0.0;
        this.m_berserk = this.HasUpgrade(4);
        this.m_madness = madness;

        if this.m_berserk {
            ArrayPush(this.m_berserkMods, this.AddMod(owner, gamedataStatType.MaxSpeed, gameStatModifierType.AdditiveMultiplier, HopeConfig.BerserkSpeed()));
            ArrayPush(this.m_berserkMods, this.AddMod(owner, gamedataStatType.AllDamageDonePercentBonus, gameStatModifierType.Additive, HopeConfig.BerserkDamage()));
            ArrayPush(this.m_berserkMods, this.AddMod(owner, gamedataStatType.CritChance, gameStatModifierType.Additive, HopeConfig.BerserkCritChance()));
            this.ShowMessage(this.T(n"MilitechHope-Msg-Berserk"), SimpleMessageType.Negative, 3.0);
        }
        if this.m_madness {
            // The vanilla OnEnter reads the time scale stat right after this call.
            this.m_madnessMod = this.AddMod(owner, gamedataStatType.TimeDilationSandevistanTimeScale, gameStatModifierType.Multiplier, HopeConfig.MadnessTimeScaleMult());
            this.ShowMessage(this.T(n"MilitechHope-Msg-Madness"), SimpleMessageType.Negative, 3.0);
        }
        if this.HasUpgrade(3) {
            this.m_phase = GameInstance.GetGodModeSystem(this.GetGameInstance()).AddGodMode(owner.GetEntityID(), gameGodModeType.Invulnerable, n"MilitechHopePhaseShield");
        }
        if IsDefined(this.m_breathMod) {
            this.ShowMessage(this.T(n"MilitechHope-Msg-NewBreath"), SimpleMessageType.Neutral, 3.0);
        }

        // Overheat warning: shown a moment later from the fast loop, so the
        // Sandevistan's own activation UI does not swallow it.
        let next = HopeConfig.ActivationHeat(level) * this.HeatMultiplier();
        if this.m_heat + next >= HopeConfig.CriticalHeat() {
            this.m_pendingWarning = 2;
        } else {
            if this.m_heat >= HopeConfig.WarmHeat() || recent >= HopeConfig.BurnoutActivations() - 2 {
                this.m_pendingWarning = 1;
            }
        }
        this.m_warnDelay = 0.4;

        this.StartTrail(player);
        return false;
    }

    public func OnSandevistanExit(owner: ref<GameObject>) -> Void {
        this.m_realSpeedBullets = false;
        if !this.m_active {
            return;
        }
        this.m_active = false;
        let player = owner as PlayerPuppet;

        this.EndPhaseShield(owner);
        this.EndMadness(owner);
        for mod in this.m_berserkMods {
            this.RemoveMod(owner, mod);
        }
        ArrayClear(this.m_berserkMods);

        if IsDefined(player) && this.HasUpgrade(0) && player.IsInCombat() {
            this.Discharge(player);
        }

        this.m_trailFade = HopeConfig.TrailFadeSeconds();

        if this.m_berserk {
            this.m_berserk = false;
            this.m_heat = HopeConfig.CriticalHeat();
            this.ApplyLockout(owner, false);
        }
    }

    private func EndPhaseShield(owner: ref<GameObject>) -> Void {
        if this.m_phase {
            this.m_phase = false;
            GameInstance.GetGodModeSystem(this.GetGameInstance()).RemoveGodMode(owner.GetEntityID(), gameGodModeType.Invulnerable, n"MilitechHopePhaseShield");
        }
    }

    private func EndMadness(owner: ref<GameObject>) -> Void {
        this.m_madness = false;
        if IsDefined(this.m_madnessMod) {
            this.RemoveMod(owner, this.m_madnessMod);
            this.m_madnessMod = null;
        }
    }

    // True while a Tier 5++ Hope Sandevistan is running: the player's
    // bullets keep their normal (hitscan) behaviour instead of turning
    // into slow time-dilated projectiles.
    public func HasRealSpeedBullets() -> Bool {
        return this.m_realSpeedBullets;
    }

    public func TriggerOverheat(owner: ref<GameObject>) -> Void {
        if this.m_burnoutPending {
            this.m_burnoutPending = false;
            this.StartBurnout(owner);
            return;
        }
        if this.m_burnout > 0 {
            this.RequestDeactivation(owner as PlayerPuppet);
            return;
        }
        this.ApplyLockout(owner, true);
    }

    private func RequestDeactivation(player: ref<PlayerPuppet>) -> Void {
        if !IsDefined(player) {
            return;
        }
        let request = new PSMPostponedParameterBool();
        request.id = n"requestSandevistanDeactivation";
        request.value = true;
        player.QueueEvent(request);
    }

    // Overheat: optional shutdown, empty charge, lockout status effect.
    private func ApplyLockout(owner: ref<GameObject>, deactivate: Bool) -> Void {
        let game = this.GetGameInstance();
        let player = owner as PlayerPuppet;
        if !IsDefined(player) {
            return;
        }

        if deactivate {
            this.RequestDeactivation(player);
        }

        GameInstance.GetStatPoolsSystem(game).RequestSettingStatPoolMinValue(this.StatsID(player), gamedataStatPoolType.SandevistanCharge, player);

        if this.m_secondHeart {
            StatusEffectHelper.ApplyStatusEffect(player, HopeConfig.OverheatEffectShort());
        } else {
            StatusEffectHelper.ApplyStatusEffect(player, HopeConfig.OverheatEffect());
        }

        GameObject.PlaySoundEvent(player, n"ui_jingle_chip_malfunction");
        this.ShowMessage(this.T(n"MilitechHope-Msg-Overheat"), SimpleMessageType.Negative, 5.0);
        this.Banner(this.T(n"MilitechHope-Banner-Overheat"), this.T(n"MilitechHope-Banner-OverheatSub"), 2, 4.0, false);
        this.m_pendingWarning = 0;
    }

    // =====================================================================
    //  Overheat warnings
    // =====================================================================
    private func UpdateWarning(player: ref<PlayerPuppet>, dt: Float) -> Void {
        if this.m_pendingWarning == 0 {
            return;
        }
        this.m_warnDelay -= dt;
        if this.m_warnDelay > 0.0 {
            return;
        }
        let kind = this.m_pendingWarning;
        this.m_pendingWarning = 0;
        if this.m_burnout > 0 || this.IsOverheated(player) {
            return;
        }

        let temp = IntToString(RoundF(this.m_heat)) + " °C";
        let risk = "";
        if HopeConfig.BurnoutEnabled() && this.CountRecentActivations() >= HopeConfig.BurnoutActivations() - 2 {
            risk = this.T(n"MilitechHope-Banner-BurnoutRisk");
        }
        if kind >= 2 {
            this.ShowMessage(this.T(n"MilitechHope-Msg-OverheatWarning") + " " + temp + ". " + this.T(n"MilitechHope-Msg-NextOverheats"), SimpleMessageType.Negative, 4.0);
            let sub = this.T(n"MilitechHope-Msg-NextOverheats");
            if StrLen(risk) > 0 {
                sub = sub + "  ·  " + risk;
            }
            this.Banner(this.T(n"MilitechHope-Banner-Critical") + "  " + temp, sub, 2, 4.0, false);
            StatusEffectHelper.ApplyStatusEffect(player, HopeConfig.WarningEffect());
            GameObject.PlaySoundEvent(player, n"ui_jingle_chip_malfunction");
        } else {
            this.ShowMessage(this.T(n"MilitechHope-Msg-HeatWarm") + " " + temp, SimpleMessageType.Neutral, 3.0);
            let sub = this.T(n"MilitechHope-Banner-WarmSub");
            if StrLen(risk) > 0 {
                sub = risk;
            }
            this.Banner(this.T(n"MilitechHope-Banner-Warm") + "  " + temp, sub, 1, 3.0, false);
        }
    }

    // =====================================================================
    //  Mastery
    // =====================================================================
    public func MasteryLevel() -> Int32 {
        let step = Max(1, HopeConfig.MasteryStep());
        return Min(HopeConfig.MasteryMaxLevel(), this.m_masteryUses / step);
    }

    public func MasteryCapacity() -> Int32 {
        return RoundF(HopeConfig.CapacityCost() - HopeConfig.MasteryCapacityPerLevel() * Cast<Float>(this.MasteryLevel()));
    }

    private func MasteryRoman(level: Int32) -> String {
        if level == 1 {
            return "I";
        }
        if level == 2 {
            return "II";
        }
        if level == 3 {
            return "III";
        }
        if level == 4 {
            return "IV";
        }
        if level == 5 {
            return "V";
        }
        return IntToString(level);
    }

    private func AddMasteryUse(player: ref<PlayerPuppet>) -> Void {
        let before = this.MasteryLevel();
        this.m_masteryUses += 1;
        let after = this.MasteryLevel();
        if after > before {
            this.ApplyMastery(player);
            let title = this.T(n"MilitechHope-Banner-Mastery") + " " + this.MasteryRoman(after);
            let sub = this.T(n"MilitechHope-Banner-MasterySub") + " " + IntToString(this.MasteryCapacity());
            this.Banner(title, sub, 0, 4.0, false);
            this.ShowMessage(title + ". " + sub, SimpleMessageType.Neutral, 4.0);
        }
    }

    // Keeps the mastery modifiers on the player in sync with the level
    // (removed while Hope is not equipped).
    private func ApplyMastery(player: ref<PlayerPuppet>) -> Void {
        let wanted = this.MasteryLevel();
        if wanted == this.m_masteryApplied {
            return;
        }
        this.RemoveMastery(player);
        this.m_masteryApplied = wanted;
        if wanted <= 0 {
            return;
        }
        let k = Cast<Float>(wanted);
        // Lower capacity use: same approach as the ripperdoc tutorial (player stat).
        ArrayPush(this.m_masteryMods, this.AddMod(player, gamedataStatType.HumanityAllocated, gameStatModifierType.Additive, -HopeConfig.MasteryCapacityPerLevel() * k));
        ArrayPush(this.m_masteryMods, this.AddMod(player, gamedataStatType.AllDamageDonePercentBonus, gameStatModifierType.Additive, HopeConfig.MasteryDamagePerLevel() * k));
        ArrayPush(this.m_masteryMods, this.AddMod(player, gamedataStatType.CritDamage, gameStatModifierType.Additive, HopeConfig.MasteryCritDamagePerLevel() * k));
        ArrayPush(this.m_masteryMods, this.AddMod(player, gamedataStatType.TimeDilationSandevistanDuration, gameStatModifierType.Additive, HopeConfig.MasteryDurationPerLevel() * k));
    }

    private func RemoveMastery(player: ref<PlayerPuppet>) -> Void {
        for mod in this.m_masteryMods {
            this.RemoveMod(player, mod);
        }
        ArrayClear(this.m_masteryMods);
        this.m_masteryApplied = -1;
    }

    private func MasteryText() -> String {
        let level = this.MasteryLevel();
        let text = this.T(n"MilitechHope-Hud-Mastery") + " " + this.MasteryRoman(level);
        if level == 0 {
            text = this.T(n"MilitechHope-Hud-Mastery") + " 0";
        }
        text = text + " (" + this.T(n"MilitechHope-Hud-Capacity") + " " + IntToString(this.MasteryCapacity()) + ")";
        if level < HopeConfig.MasteryMaxLevel() {
            let step = Max(1, HopeConfig.MasteryStep());
            text = text + " " + IntToString(this.m_masteryUses % step) + "/" + IntToString(step);
        }
        return text;
    }

    // =====================================================================
    //  Burnout
    // =====================================================================
    private func CountRecentActivations() -> Int32 {
        let window = HopeConfig.BurnoutWindow();
        while ArraySize(this.m_activationTimes) > 0 && this.m_clock - this.m_activationTimes[0] > window {
            ArrayErase(this.m_activationTimes, 0);
        }
        return ArraySize(this.m_activationTimes);
    }

    public func IsBurningOut() -> Bool {
        return this.m_burnout > 0;
    }

    private func StartBurnout(owner: ref<GameObject>) -> Void {
        let player = owner as PlayerPuppet;
        if !IsDefined(player) {
            return;
        }
        this.RequestDeactivation(player);
        GameInstance.GetStatPoolsSystem(this.GetGameInstance()).RequestSettingStatPoolMinValue(this.StatsID(player), gamedataStatPoolType.SandevistanCharge, player);

        this.m_burnout = 1;
        this.m_burnoutTimer = HopeConfig.BurnoutErrorSeconds();
        this.m_burnoutErrorTimer = 0.0;
        this.m_heat = HopeConfig.CriticalHeat();
        this.m_pendingWarning = 0;
        ArrayClear(this.m_activationTimes);

        StatusEffectHelper.ApplyStatusEffect(player, HopeConfig.BurnoutSurgeEffect());
        GameObject.PlaySoundEvent(player, n"ui_jingle_chip_malfunction");
        this.Banner(this.T(n"MilitechHope-Banner-Burnout"), this.BurnoutErrorLine(), 2, HopeConfig.BurnoutErrorSeconds() + 1.0, true);
    }

    private func BurnoutErrorLine() -> String {
        let code = "0x" + IntToString(RandRange(1000, 9999)) + "  ";
        let pick = RandRange(0, 6);
        let key = n"MilitechHope-Err-6";
        if pick == 0 {
            key = n"MilitechHope-Err-1";
        } else {
            if pick == 1 {
                key = n"MilitechHope-Err-2";
            } else {
                if pick == 2 {
                    key = n"MilitechHope-Err-3";
                } else {
                    if pick == 3 {
                        key = n"MilitechHope-Err-4";
                    } else {
                        if pick == 4 {
                            key = n"MilitechHope-Err-5";
                        }
                    }
                }
            }
        }
        return code + this.T(key);
    }

    private func UpdateBurnout(player: ref<PlayerPuppet>, dt: Float) -> Void {
        this.m_burnoutTimer -= dt;
        if this.m_burnout == 1 {
            this.m_burnoutErrorTimer -= dt;
            if this.m_burnoutErrorTimer <= 0.0 {
                this.m_burnoutErrorTimer = 0.4;
                let line = this.BurnoutErrorLine();
                this.ShowMessage(this.T(n"MilitechHope-Msg-SystemError") + " " + line, SimpleMessageType.Negative, 1.0);
                this.m_hud.UpdateBanner(this.T(n"MilitechHope-Banner-Burnout"), line);
            }
            if this.m_burnoutTimer <= 0.0 {
                this.StartDischarge(player);
            }
            return;
        }

        let total = MaxF(1.0, HopeConfig.BurnoutSeconds());
        let left = MaxF(0.0, this.m_burnoutTimer);
        let ambient = HopeConfig.AmbientHeat();
        this.m_heat = ambient + (this.m_burnoutHeatStart - ambient) * left / total;
        this.m_hud.UpdateBanner(this.T(n"MilitechHope-Banner-Discharge"), this.T(n"MilitechHope-Banner-DischargeSub") + " " + IntToString(CeilF(left)) + " " + this.T(n"MilitechHope-Hud-Seconds"));
        if this.m_burnoutTimer <= 0.0 {
            this.EndBurnout(player, true);
        }
    }

    // The discharge: the world stops, V is disarmed and can only walk.
    private func StartDischarge(player: ref<PlayerPuppet>) -> Void {
        this.m_burnout = 2;
        this.m_burnoutTimer = HopeConfig.BurnoutSeconds();
        this.m_burnoutHeatStart = this.m_heat;

        let time = GameInstance.GetTimeSystem(this.GetGameInstance());
        time.SetIgnoreTimeDilationOnLocalPlayerZero(true);
        time.SetTimeDilation(n"MilitechHopeBurnout", HopeConfig.BurnoutTimeScale());

        StatusEffectHelper.RemoveStatusEffect(player, HopeConfig.BurnoutSurgeEffect());
        StatusEffectHelper.ApplyStatusEffect(player, HopeConfig.BurnoutEffect());
        GameObject.PlaySoundEvent(player, n"ui_jingle_chip_malfunction");
        this.ShowMessage(this.T(n"MilitechHope-Msg-Burnout"), SimpleMessageType.Negative, 5.0);
        this.Banner(this.T(n"MilitechHope-Banner-Discharge"), this.T(n"MilitechHope-Banner-DischargeSub") + " " + IntToString(CeilF(HopeConfig.BurnoutSeconds())) + " " + this.T(n"MilitechHope-Hud-Seconds"), 2, HopeConfig.BurnoutSeconds() + 1.0, false);
    }

    private func ClearBurnoutTime() -> Void {
        let time = GameInstance.GetTimeSystem(this.GetGameInstance());
        time.UnsetTimeDilation(n"MilitechHopeBurnout");
        time.SetIgnoreTimeDilationOnLocalPlayerZero(false);
    }

    private func EndBurnout(player: ref<PlayerPuppet>, notify: Bool) -> Void {
        if this.m_burnout == 0 {
            return;
        }
        let wasDischarge = this.m_burnout == 2;
        this.m_burnout = 0;
        this.m_burnoutTimer = 0.0;
        if wasDischarge {
            this.ClearBurnoutTime();
        }
        this.m_heat = HopeConfig.AmbientHeat();
        if IsDefined(player) {
            StatusEffectHelper.RemoveStatusEffect(player, HopeConfig.BurnoutEffect());
            StatusEffectHelper.RemoveStatusEffect(player, HopeConfig.BurnoutSurgeEffect());
        }
        if notify {
            this.ShowMessage(this.T(n"MilitechHope-Msg-BurnoutOver"), SimpleMessageType.Neutral, 4.0);
            this.Banner(this.T(n"MilitechHope-Banner-Cooled"), this.T(n"MilitechHope-Banner-CooledSub"), 0, 3.0, false);
        }
    }

    public func IsOverheated(owner: ref<GameObject>) -> Bool {
        return StatusEffectSystem.ObjectHasStatusEffect(owner, HopeConfig.OverheatEffect())
            || StatusEffectSystem.ObjectHasStatusEffect(owner, HopeConfig.OverheatEffectShort());
    }

    // =====================================================================
    //  Upgrade 1: discharge
    // =====================================================================
    private func Discharge(player: ref<PlayerPuppet>) -> Void {
        let radius = HopeConfig.DischargeRadius();
        let query: TargetSearchQuery;
        query.testedSet = TargetingSet.Complete;
        query.searchFilter = TSF_EnemyNPC();
        query.includeSecondaryTargets = false;
        query.ignoreInstigator = true;
        query.maxDistance = radius;
        query.filterObjectByDistance = true;

        let parts: array<TS_TargetPartInfo>;
        GameInstance.GetTargetingSystem(this.GetGameInstance()).GetTargetParts(player, query, parts);

        let hit: array<EntityID>;
        let origin = player.GetWorldPosition();
        for part in parts {
            let component = TS_TargetPartInfo.GetComponent(part);
            let target: ref<GameObject>;
            if IsDefined(component) {
                target = component.GetEntity() as GameObject;
            }
            if IsDefined(target) && !target.IsPlayer()
                && Vector4.Distance(origin, target.GetWorldPosition()) <= radius + 0.5 {
                let id = target.GetEntityID();
                let seen = false;
                for other in hit {
                    if other == id {
                        seen = true;
                    }
                }
                if !seen {
                    ArrayPush(hit, id);
                    StatusEffectHelper.ApplyStatusEffect(target, HopeConfig.DischargeStatus(), player.GetEntityID());
                }
            }
        }
        if ArraySize(hit) > 0 {
            this.ShowMessage(this.T(n"MilitechHope-Msg-Discharge") + " " + IntToString(ArraySize(hit)), SimpleMessageType.Neutral, 2.0);
        }
    }

    // =====================================================================
    //  Kills (called from WorldHooks.reds)
    // =====================================================================
    public func OnPlayerKill(player: ref<PlayerPuppet>, target: EntityID) -> Void {
        if this.m_level < 0 {
            return;
        }
        // "defeated" and "killed" can both fire for the same NPC
        for recent in this.m_recentKills {
            if recent == target {
                return;
            }
        }
        ArrayPush(this.m_recentKills, target);
        if ArraySize(this.m_recentKills) > 16 {
            ArrayErase(this.m_recentKills, 0);
        }

        // Upgrade 2: quick recharge
        if this.HasUpgrade(1) {
            ArrayPush(this.m_killTimes, this.m_clock);
            let i = ArraySize(this.m_killTimes) - 1;
            while i >= 0 {
                if this.m_clock - this.m_killTimes[i] > HopeConfig.QuickChargeWindow() {
                    ArrayErase(this.m_killTimes, i);
                }
                i -= 1;
            }
            if ArraySize(this.m_killTimes) >= HopeConfig.QuickChargeKills() {
                ArrayClear(this.m_killTimes);
                this.SetPoolPercent(player, gamedataStatPoolType.SandevistanCharge, 100.0);
                this.ShowMessage(this.T(n"MilitechHope-Msg-QuickCharge"), SimpleMessageType.Neutral, 3.0);
            }
        }

        if !this.m_active {
            return;
        }

        // Axolotl: every kill under Sandevistan cools the core down
        if this.m_axolotl {
            this.m_heat = MaxF(HopeConfig.AmbientHeat(), this.m_heat - HopeConfig.AxolotlKillCooling());
        }

        // Broker contract
        if this.m_contract > 0 {
            let index = this.m_contract - 1;
            let need = HopeUpgrades.ContractKills(index);
            if this.m_contractKills < need {
                this.m_contractKills += 1;
                if this.m_contractKills >= need {
                    this.PlaySound(n"ui_phone_sms");
                    this.ShowMessage(this.T(n"MilitechHope-Msg-ContractDone"), SimpleMessageType.Neutral, 6.0);
                }
            }
        }
    }

    // =====================================================================
    //  Fast loop: heat, timers, upgrades, trail, HUD (5 times per second)
    // =====================================================================
    public func FastTick(token: Int32) -> Void {
        if token != this.m_fastToken {
            return;
        }
        let dt = 0.2;
        this.ScheduleFast(dt);

        let game = this.GetGameInstance();
        let player = GetPlayer(game);
        if !IsDefined(player) || !player.IsAttached() || player.IsDead() {
            if this.m_burnout > 0 {
                this.EndBurnout(player, false);
            }
            this.m_hud.HideGauge();
            this.m_hud.HideBanner();
            return;
        }
        if GameInstance.GetTimeSystem(game).IsPausedState() {
            return;
        }
        this.m_clock += dt;
        this.m_hud.Tick(dt);
        if this.m_burnout > 0 {
            this.UpdateBurnout(player, dt);
        }

        this.m_implantTimer -= dt;
        if this.m_implantTimer <= 0.0 {
            this.m_implantTimer = 2.0;
            this.RefreshImplants(player);
        }

        this.m_level = this.GetEquippedHopeLevel(player);
        if this.m_level < 0 {
            ArrayClear(this.m_slotUpgrades);
            this.RemoveMastery(player);
            this.UpdateNewBreath(player);
            this.KillTrail();
            this.m_hud.HideGauge();
            this.RenderMenuIfOpen();
            return;
        }
        if !this.m_active {
            this.RefreshUpgrades(player);
        }
        this.ApplyMastery(player);
        this.UpdateWarning(player, dt);

        let charge = this.PoolPercent(player, gamedataStatPoolType.SandevistanCharge);
        let ambient = HopeConfig.AmbientHeat();

        if this.m_active {
            this.m_activeTime += dt;
            this.UpdateTrail(player);

            if this.m_phase && this.m_activeTime >= HopeConfig.PhaseShieldSeconds() {
                this.EndPhaseShield(player);
            }
            if this.m_madness && this.m_activeTime >= HopeConfig.MadnessSeconds() {
                this.EndMadness(player);
            }
            if this.m_berserk {
                this.ChangePoolPercent(player, gamedataStatPoolType.Stamina, -HopeConfig.BerserkStaminaDrain() * this.DrainMultiplier() * dt);
            }
            if this.m_madness {
                this.ChangePoolPercent(player, gamedataStatPoolType.Stamina, -HopeConfig.MadnessStaminaDrain() * this.DrainMultiplier() * dt);
            }
        } else {
            // A full charge means the core had time to cool down.
            let cooling = HopeConfig.CoolingPerSecond() * this.CoolingMultiplier();
            if charge >= HopeConfig.FullChargePercent() && !this.IsOverheated(player) {
                cooling = MaxF(cooling, HopeConfig.FullChargeCoolingPerSecond());
            }
            if this.m_burnout == 0 {
                this.m_heat = MaxF(ambient, this.m_heat - cooling * dt);
            }

            if this.m_trailFade > 0.0 {
                this.m_trailFade -= dt;
                if this.m_trailFade <= 0.0 {
                    this.KillTrail();
                }
            }
        }

        this.UpdateNewBreath(player);
        this.UpdateGauge(player, charge);
        this.RenderMenuIfOpen();
    }

    // Upgrade 3: "New Breath" — below the health threshold the next activation lasts 15 s.
    private func UpdateNewBreath(player: ref<PlayerPuppet>) -> Void {
        let want = false;
        if this.m_level >= 2 && this.HasUpgrade(2) {
            let threshold = HopeConfig.NewBreathThreshold();
            if this.m_reflexTuner {
                threshold = HopeConfig.NewBreathThresholdReflexTuner();
            }
            want = this.PoolPercent(player, gamedataStatPoolType.Health) < threshold;
        }
        if want && !IsDefined(this.m_breathMod) {
            let current = GameInstance.GetStatsSystem(this.GetGameInstance()).GetStatValue(this.StatsID(player), gamedataStatType.TimeDilationSandevistanDuration);
            let extra = HopeConfig.NewBreathSeconds() - current;
            if extra > 0.0 {
                this.m_breathMod = this.AddMod(player, gamedataStatType.TimeDilationSandevistanDuration, gameStatModifierType.Additive, extra);
            }
        }
        // never shorten an activation that is already running
        if !want && IsDefined(this.m_breathMod) && !this.m_active {
            this.RemoveMod(player, this.m_breathMod);
            this.m_breathMod = null;
        }
    }

    private func UpdateGauge(player: ref<PlayerPuppet>, charge: Float) -> Void {
        if !HopeConfig.HudEnabled() {
            this.m_hud.HideGauge();
            return;
        }
        let ambient = HopeConfig.AmbientHeat();
        let critical = HopeConfig.CriticalHeat();
        let overheated = this.IsOverheated(player) || this.m_burnout > 0;
        let busy = this.m_active || overheated || this.m_menuOpen || this.m_heat > ambient + 0.5
            || (HopeConfig.HudShowInCombat() && player.IsInCombat());
        if !busy && !HopeConfig.HudAlwaysVisible() {
            this.m_hud.HideGauge();
            return;
        }

        let level = 0;
        if this.m_heat >= HopeConfig.WarningHeat() || overheated {
            level = 2;
        } else {
            if this.m_heat >= HopeConfig.WarmHeat() {
                level = 1;
            }
        }

        let state: String;
        if this.m_burnout > 0 {
            state = this.T(n"MilitechHope-Hud-Burnout");
        } else {
          if overheated {
            state = this.T(n"MilitechHope-Hud-Overheat");
        } else {
            if this.m_active {
                state = this.T(n"MilitechHope-Hud-Active");
                if this.m_madness {
                    state = state + " · " + this.T(n"MilitechHope-Hud-Madness");
                }
                if this.m_phase {
                    state = state + " · " + this.T(n"MilitechHope-Hud-Phase");
                }
                if this.m_berserk {
                    state = state + " · " + this.T(n"MilitechHope-Hud-Berserk");
                }
            } else {
                if this.m_heat >= HopeConfig.WarningHeat() {
                    state = this.T(n"MilitechHope-Hud-Critical");
                } else {
                    if charge >= HopeConfig.FullChargePercent() {
                        state = this.T(n"MilitechHope-Hud-Ready");
                    } else {
                        state = this.T(n"MilitechHope-Hud-Cooling");
                    }
                }
            }
        }
        }
        state = state + "   " + this.T(n"MilitechHope-Hud-Charge") + " " + IntToString(RoundF(charge)) + "%";

        let info = this.MasteryText();
        let modules = this.UpgradeNames();
        if StrLen(modules) > 0 {
            info = info + "   " + this.T(n"MilitechHope-Hud-Module") + " " + modules;
        }
        let sync = this.SyncText();
        if StrLen(sync) > 0 {
            if StrLen(info) > 0 {
                info = info + "   ";
            }
            info = info + this.T(n"MilitechHope-Hud-Sync") + " " + sync;
        }

        let fill = (this.m_heat - ambient) / (critical - ambient);
        let temp = IntToString(RoundF(this.m_heat)) + " °C";
        this.m_hud.ShowGauge(this.T(n"MilitechHope-Hud-Title"), temp, fill, level, state, info, !busy);
    }

    // =====================================================================
    //  Afterimage trail
    // =====================================================================
    private func StartTrail(player: ref<PlayerPuppet>) -> Void {
        this.KillTrail();
        this.m_trailFade = 0.0;
        this.m_trailHasLast = false;
        this.UpdateTrail(player);
    }

    private func UpdateTrail(player: ref<PlayerPuppet>) -> Void {
        if !HopeConfig.TrailEnabled() || ArraySize(this.m_trail) >= HopeConfig.TrailMaxPoints() {
            return;
        }
        let pos = player.GetWorldPosition();
        if this.m_trailHasLast && Vector4.Distance(pos, this.m_trailLast) < HopeConfig.TrailStep() {
            return;
        }
        this.m_trailLast = pos;
        this.m_trailHasLast = true;

        let path: ResourceAsyncRef;
        path *= HopeConfig.TrailEffect();
        let resource: FxResource;
        resource.effect = path;
        let transform: WorldTransform;
        WorldTransform.SetPosition(transform, pos);
        // Not ignoring time dilation: the effect stays almost frozen in the
        // slowed world, which leaves a trail of afterimages behind the player.
        let fx = GameInstance.GetFxSystem(this.GetGameInstance()).SpawnEffect(resource, transform, false);
        if IsDefined(fx) {
            ArrayPush(this.m_trail, fx);
        }
    }

    private func KillTrail() -> Void {
        for fx in this.m_trail {
            if IsDefined(fx) {
                fx.Kill();
            }
        }
        ArrayClear(this.m_trail);
        this.m_trailHasLast = false;
        this.m_trailFade = 0.0;
    }

    // =====================================================================
    //  Broker: business card in a random loot container
    // =====================================================================
    public func HasBrokerContact() -> Bool {
        return this.m_contact > 0;
    }

    // Called when the player walks up to a loot container (WorldHooks.reds).
    public func OnContainerApproached(container: ref<gameLootContainerBase>) -> Void {
        if this.m_contact > 0 || this.m_cardPlanted || !IsDefined(container) {
            return;
        }
        if container.IsQuest() || container.IsDisabled() {
            return;
        }
        let player = GetPlayer(this.GetGameInstance());
        if !IsDefined(player) {
            return;
        }
        let level = GameInstance.GetStatsSystem(this.GetGameInstance()).GetStatValue(this.StatsID(player), gamedataStatType.Level);
        if level < HopeConfig.ContactLevel() || this.CountItems(player, HopeConfig.DealerCard()) > 0 {
            return;
        }
        let id = container.GetEntityID();
        for seen in this.m_visited {
            if seen == id {
                return;
            }
        }
        ArrayPush(this.m_visited, id);
        if ArraySize(this.m_visited) > 300 {
            ArrayErase(this.m_visited, 0);
        }

        let chance = HopeConfig.ContactChance() + HopeConfig.ContactChanceBonus() * Cast<Float>(this.m_cardMisses);
        if RandF() >= chance {
            this.m_cardMisses += 1;
            return;
        }
        if GameInstance.GetTransactionSystem(this.GetGameInstance()).GiveItemByTDBID(container, HopeConfig.DealerCard(), 1) {
            this.m_cardPlanted = true;
            this.m_cardMisses = 0;
            this.ShowMessage(this.T(n"MilitechHope-Msg-CardNearby"), SimpleMessageType.Neutral, 5.0);
        }
    }

    // Slow loop: the card was picked up -> the number is known for good.
    private func CheckBrokerCard(player: ref<PlayerPuppet>) -> Void {
        if this.m_contact > 0 {
            return;
        }
        if this.CountItems(player, HopeConfig.DealerCard()) > 0 {
            this.UnlockBroker();
        }
    }

    private func UnlockBroker() -> Void {
        this.m_contact = 1;
        this.m_cardPlanted = false;
        this.PlaySound(n"ui_phone_sms");
        this.ShowMessage(this.T(n"MilitechHope-Msg-CardSms"), SimpleMessageType.Neutral, 12.0);
    }

    // =====================================================================
    //  Broker: hotkeys and menu
    // =====================================================================
    private func RegisterInput() -> Void {
        if IsDefined(this.m_keyHandler) {
            this.m_keyHandler.Unregister();
            this.m_keyHandler = null;
        }
        this.m_keyHandler = GameInstance.GetCallbackSystem().RegisterCallback(n"Input/Key", this, n"OnHopeKey");
        this.m_keyHandler.AddTarget(InputTarget.Key(HopeConfig.CallKey()));
        this.m_keyHandler.AddTarget(InputTarget.Key(HopeConfig.MenuUpKey()));
        this.m_keyHandler.AddTarget(InputTarget.Key(HopeConfig.MenuDownKey()));
        this.m_keyHandler.AddTarget(InputTarget.Key(HopeConfig.MenuConfirmKey()));
        this.m_keyHandler.AddTarget(InputTarget.Key(HopeConfig.MenuCloseKey()));
    }

    private cb func OnHopeKey(evt: ref<KeyInputEvent>) {
        if NotEquals(evt.GetAction(), EInputAction.IACT_Press) {
            return;
        }
        let game = this.GetGameInstance();
        let player = GetPlayer(game);
        if !IsDefined(player) || !player.IsAttached() || player.IsDead() || GameInstance.GetTimeSystem(game).IsPausedState() {
            return;
        }
        let key = evt.GetKey();
        if Equals(key, HopeConfig.CallKey()) {
            if this.m_menuOpen {
                this.CloseMenu();
            } else {
                this.OpenMenu(player);
            }
            return;
        }
        if !this.m_menuOpen {
            return;
        }
        let rows = this.MenuRowCount();
        if Equals(key, HopeConfig.MenuUpKey()) {
            this.m_menuIndex = (this.m_menuIndex + rows - 1) % rows;
        } else {
            if Equals(key, HopeConfig.MenuDownKey()) {
                this.m_menuIndex = (this.m_menuIndex + 1) % rows;
            } else {
                if Equals(key, HopeConfig.MenuConfirmKey()) {
                    this.ActivateMenuRow(player, this.m_menuIndex);
                } else {
                    if Equals(key, HopeConfig.MenuCloseKey()) {
                        this.CloseMenu();
                        return;
                    }
                }
            }
        }
        this.RenderMenu(player);
    }

    private func OpenMenu(player: ref<PlayerPuppet>) -> Void {
        if this.m_contact == 0 {
            if this.CountItems(player, HopeConfig.DealerCard()) == 0 {
                return;
            }
            this.UnlockBroker();
        }
        this.m_menuOpen = true;
        this.m_menuStatus = this.T(n"MilitechHope-Broker-Greeting");
        GameObject.PlaySoundEvent(player, n"ui_phone_incoming_call");
        this.RenderMenu(player);
    }

    private func CloseMenu() -> Void {
        if this.m_menuOpen {
            this.m_menuOpen = false;
            this.m_hud.HideMenu();
            this.PlaySound(n"ui_phone_hang_up");
        }
    }

    // rows: 0 Sandevistan, 1..6 upgrades, 7 contract, 8 install, 9 hang up
    private func MenuRowCount() -> Int32 {
        return HopeUpgrades.Count() + 4;
    }

    private func RenderMenuIfOpen() -> Void {
        if this.m_menuOpen {
            let player = GetPlayer(this.GetGameInstance());
            if IsDefined(player) {
                this.RenderMenu(player);
            }
        }
    }

    private func Money(player: ref<PlayerPuppet>) -> Int32 {
        return GameInstance.GetTransactionSystem(this.GetGameInstance()).GetItemQuantity(player, MarketSystem.Money());
    }

    private func RenderMenu(player: ref<PlayerPuppet>) -> Void {
        let rows: array<String>;
        let count = HopeUpgrades.Count();

        ArrayPush(rows, this.T(n"MilitechHope-Broker-Sandevistan") + "  —  " + MilitechHopeSystem.FormatMoney(HopeConfig.SandevistanPrice()) + " €$");

        let i = 0;
        while i < count {
            let line = this.T(HopeUpgrades.NameKey(i)) + "  —  " + MilitechHopeSystem.FormatMoney(HopeUpgrades.Price(i)) + " €$";
            let owned = this.CountItems(player, HopeUpgrades.Id(i));
            if owned > 0 {
                line = line + "   [" + this.T(n"MilitechHope-Broker-Owned") + " " + IntToString(owned) + "]";
            }
            if this.HasUpgrade(i) {
                line = line + "   [" + this.T(n"MilitechHope-Broker-Installed") + "]";
            }
            ArrayPush(rows, line);
            i += 1;
        }

        ArrayPush(rows, this.ContractRowText());
        ArrayPush(rows, this.T(n"MilitechHope-Broker-Install"));
        ArrayPush(rows, this.T(n"MilitechHope-Broker-HangUp"));

        let footer = this.T(n"MilitechHope-Broker-Balance") + " " + MilitechHopeSystem.FormatMoney(this.Money(player)) + " €$";
        if StrLen(this.m_menuStatus) > 0 {
            footer = footer + "   ·   " + this.m_menuStatus;
        }
        this.m_hud.ShowMenu(this.T(n"MilitechHope-Broker-Title"), rows, this.m_menuIndex, footer, this.T(n"MilitechHope-Broker-Hint"));
    }

    private func ContractRowText() -> String {
        if this.m_contract > 0 {
            let index = this.m_contract - 1;
            let need = HopeUpgrades.ContractKills(index);
            if this.m_contractKills >= need {
                return this.T(n"MilitechHope-Broker-ContractReady") + " " + this.T(HopeUpgrades.NameKey(index));
            }
            return this.T(n"MilitechHope-Broker-ContractActive") + " " + IntToString(this.m_contractKills) + "/" + IntToString(need)
                + "  —  " + this.T(HopeUpgrades.NameKey(index));
        }
        if this.m_contractsDone >= HopeUpgrades.Count() {
            return this.T(n"MilitechHope-Broker-ContractNone");
        }
        return this.T(n"MilitechHope-Broker-ContractNew") + " " + this.T(HopeUpgrades.NameKey(this.m_contractsDone))
            + " (" + IntToString(HopeUpgrades.ContractKills(this.m_contractsDone)) + ")";
    }

    private func ActivateMenuRow(player: ref<PlayerPuppet>, row: Int32) -> Void {
        let count = HopeUpgrades.Count();
        if row == 0 {
            this.Buy(player, HopeConfig.ItemBase(), HopeConfig.SandevistanPrice(), this.T(n"MilitechHope-Broker-Sandevistan"));
            return;
        }
        if row >= 1 && row <= count {
            let index = row - 1;
            this.Buy(player, HopeUpgrades.Id(index), HopeUpgrades.Price(index), this.T(HopeUpgrades.NameKey(index)));
            return;
        }
        if row == count + 1 {
            this.ContractAction(player);
            return;
        }
        if row == count + 2 {
            this.InstallNextUpgrade(player);
            return;
        }
        this.CloseMenu();
    }

    private func Buy(player: ref<PlayerPuppet>, record: TweakDBID, price: Int32, name: String) -> Void {
        let ts = GameInstance.GetTransactionSystem(this.GetGameInstance());
        if this.Money(player) < price {
            this.m_menuStatus = this.T(n"MilitechHope-Broker-NoMoney");
            GameObject.PlaySoundEvent(player, n"ui_menu_error");
            return;
        }
        if !ts.RemoveMoney(player, price, n"money") {
            this.m_menuStatus = this.T(n"MilitechHope-Broker-NoMoney");
            return;
        }
        ts.GiveItemByTDBID(player, record, 1);
        GameObject.PlaySoundEvent(player, n"ui_menu_item_bought");
        this.m_menuStatus = this.T(n"MilitechHope-Broker-Bought") + " " + name;
    }

    private func ContractAction(player: ref<PlayerPuppet>) -> Void {
        if this.m_contract == 0 {
            if this.m_contractsDone >= HopeUpgrades.Count() {
                this.m_menuStatus = this.T(n"MilitechHope-Broker-ContractNone");
                return;
            }
            this.m_contract = this.m_contractsDone + 1;
            this.m_contractKills = 0;
            this.m_menuStatus = this.T(n"MilitechHope-Broker-ContractTaken") + " " + IntToString(HopeUpgrades.ContractKills(this.m_contractsDone));
            return;
        }
        let index = this.m_contract - 1;
        if this.m_contractKills < HopeUpgrades.ContractKills(index) {
            this.m_menuStatus = this.T(n"MilitechHope-Broker-ContractActive") + " " + IntToString(this.m_contractKills) + "/" + IntToString(HopeUpgrades.ContractKills(index));
            return;
        }
        GameInstance.GetTransactionSystem(this.GetGameInstance()).GiveItemByTDBID(player, HopeUpgrades.Id(index), 1);
        this.m_contract = 0;
        this.m_contractKills = 0;
        this.m_contractsDone += 1;
        GameObject.PlaySoundEvent(player, n"ui_loot_rarity_legendary");
        this.m_menuStatus = this.T(n"MilitechHope-Broker-ContractReward") + " " + this.T(HopeUpgrades.NameKey(index));
    }

    // Puts the next owned upgrade module into the equipped Tier 5++ (cycles through them).
    private func InstallNextUpgrade(player: ref<PlayerPuppet>) -> Void {
        let count = HopeUpgrades.Count();
        let step = 1;
        while step <= count {
            let index = (this.m_installCursor + step) % count;
            if !this.HasUpgrade(index) && this.CountItems(player, HopeUpgrades.Id(index)) > 0 {
                let result = this.InstallUpgrade(player, index);
                if result == 0 {
                    this.m_installCursor = index;
                    this.m_menuStatus = this.T(n"MilitechHope-Broker-InstalledOk") + " " + this.T(HopeUpgrades.NameKey(index));
                    GameObject.PlaySoundEvent(player, n"ui_menu_item_crafting_done");
                } else {
                    if result == 1 {
                        this.m_menuStatus = this.T(n"MilitechHope-Broker-NeedT5PP");
                    } else {
                        this.m_menuStatus = this.T(n"MilitechHope-Broker-InstallFailed");
                    }
                }
                return;
            }
            step += 1;
        }
        this.m_menuStatus = this.T(n"MilitechHope-Broker-NoUpgrades");
    }

    // Puts a module into the equipped Tier 5++: the first empty slot, otherwise
    // the slots are replaced in turn (the replaced module goes back to the backpack).
    // 0 = ok, 1 = no Tier 5++ equipped, 2 = module missing / failed
    public func InstallUpgrade(player: ref<PlayerPuppet>, index: Int32) -> Int32 {
        let hope = this.GetEquippedHopeItem(player);
        if !ItemID.IsValid(hope) || MilitechHopeSystem.LevelOf(ItemID.GetTDBID(hope)) < 2 {
            return 1;
        }
        this.RefreshUpgrades(player);
        if this.HasUpgrade(index) {
            return 0;
        }
        let part = this.FindItem(player, HopeUpgrades.Id(index));
        if !ItemID.IsValid(part) {
            return 2;
        }
        let ts = GameInstance.GetTransactionSystem(this.GetGameInstance());
        let count = HopeConfig.UpgradeSlotCount();
        let target = -1;
        let i = 0;
        while i < count && target < 0 {
            if i < ArraySize(this.m_slotUpgrades) && this.m_slotUpgrades[i] < 0 {
                let data = ts.GetItemData(player, hope);
                if !IsDefined(data) || !data.HasPartInSlot(HopeConfig.UpgradeSlot(i)) {
                    target = i;
                }
            }
            i += 1;
        }
        if target < 0 {
            target = this.m_replaceSlot % count;
            this.m_replaceSlot = (this.m_replaceSlot + 1) % count;
            ts.RemovePart(player, hope, HopeConfig.UpgradeSlot(target));
        }
        if !ts.AddPart(player, hope, part, HopeConfig.UpgradeSlot(target)) {
            this.RefreshUpgrades(player);
            return 2;
        }
        this.RefreshUpgrades(player);
        return 0;
    }

    // Takes every module out of the equipped Tier 5++ (back into the backpack).
    public func RemoveUpgrades(player: ref<PlayerPuppet>) -> Int32 {
        let hope = this.GetEquippedHopeItem(player);
        if !ItemID.IsValid(hope) || MilitechHopeSystem.LevelOf(ItemID.GetTDBID(hope)) < 2 {
            return 0;
        }
        let ts = GameInstance.GetTransactionSystem(this.GetGameInstance());
        let removed = 0;
        let i = 0;
        while i < HopeConfig.UpgradeSlotCount() {
            let data = ts.GetItemData(player, hope);
            if IsDefined(data) && data.HasPartInSlot(HopeConfig.UpgradeSlot(i)) {
                ts.RemovePart(player, hope, HopeConfig.UpgradeSlot(i));
                removed += 1;
            }
            i += 1;
        }
        this.m_replaceSlot = 0;
        this.RefreshUpgrades(player);
        return removed;
    }

    // ----- console helpers (CET) -----------------------------------------------
    public func DebugInstallUpgrade(index: Int32) -> Int32 {
        let player = GetPlayer(this.GetGameInstance());
        if !IsDefined(player) || index < 0 || index >= HopeUpgrades.Count() {
            return 2;
        }
        if this.CountItems(player, HopeUpgrades.Id(index)) == 0 {
            GameInstance.GetTransactionSystem(this.GetGameInstance()).GiveItemByTDBID(player, HopeUpgrades.Id(index), 1);
        }
        return this.InstallUpgrade(player, index);
    }

    public func DebugRemoveUpgrades() -> Int32 {
        let player = GetPlayer(this.GetGameInstance());
        if !IsDefined(player) {
            return 0;
        }
        return this.RemoveUpgrades(player);
    }

    // Installed modules per slot as text, e.g. "1, 5" or "3, -" (1-based like the CET commands).
    public func DebugGetUpgrades() -> String {
        let player = GetPlayer(this.GetGameInstance());
        if !IsDefined(player) {
            return "";
        }
        this.RefreshUpgrades(player);
        let text = "";
        for installed in this.m_slotUpgrades {
            if installed >= 0 {
                text = this.Join(text, IntToString(installed + 1));
            } else {
                text = this.Join(text, "-");
            }
        }
        return text;
    }

    // Lets the CET helper check that the scripts compiled and run.
    public func DebugVersion() -> String {
        return "1.4.0";
    }

    public func DebugGetMastery() -> Int32 {
        return this.m_masteryUses;
    }

    public func DebugSetMastery(uses: Int32) -> Void {
        this.m_masteryUses = Max(0, uses);
        let player = GetPlayer(this.GetGameInstance());
        if IsDefined(player) && this.GetEquippedHopeLevel(player) >= 0 {
            this.ApplyMastery(player);
        }
    }

    public func DebugBurnout() -> Void {
        let player = GetPlayer(this.GetGameInstance());
        if IsDefined(player) && this.m_burnout == 0 {
            this.StartBurnout(player);
        }
    }

    public func DebugWarning(kind: Int32) -> Void {
        this.m_pendingWarning = Max(1, Min(2, kind));
        this.m_warnDelay = 0.0;
    }

    public func DebugUnlockBroker() -> Void {
        if this.m_contact == 0 {
            this.UnlockBroker();
        }
    }

    public func DebugGetHeat() -> Float {
        return this.m_heat;
    }

    public func DebugSetHeat(value: Float) -> Void {
        this.m_heat = ClampF(value, HopeConfig.AmbientHeat(), HopeConfig.CriticalHeat());
    }

    public func DebugCompleteContract() -> Void {
        if this.m_contract > 0 {
            this.m_contractKills = HopeUpgrades.ContractKills(this.m_contract - 1);
        }
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

        this.CheckBrokerCard(player);

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
