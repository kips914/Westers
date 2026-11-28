// Militech "Hope" Sandevistan — tunables.
// Edit the numbers below; redscript recompiles scripts on the next game start.
module MilitechHope

public abstract class HopeConfig {
    // ----- Items --------------------------------------------------------
    public static func ItemBase() -> TweakDBID { return t"Items.MilitechHopeSandevistan"; }
    public static func ItemPlus() -> TweakDBID { return t"Items.MilitechHopeSandevistanPlus"; }
    public static func ItemPlusPlus() -> TweakDBID { return t"Items.MilitechHopeSandevistanPlusPlus"; }
    public static func OverheatEffect() -> TweakDBID { return t"MilitechHope.SandevistanOverheat"; }
    public static func OverheatEffectShort() -> TweakDBID { return t"MilitechHope.SandevistanOverheatShort"; }
    public static func DealerCard() -> TweakDBID { return t"Items.MilitechHopeDealerCard"; }
    public static func BurnoutSurgeEffect() -> TweakDBID { return t"MilitechHope.BurnoutSurge"; }
    public static func BurnoutEffect() -> TweakDBID { return t"MilitechHope.Burnout"; }
    public static func WarningEffect() -> TweakDBID { return t"MilitechHope.HeatWarning"; }

    // Two upgrade slots on Tier 5++ (vanilla attachment slots, see the .tweak blueprint).
    // They show up as module slots when you inspect the implant in the cyberware screen.
    public static func UpgradeSlotCount() -> Int32 { return 2; }
    public static func UpgradeSlot(i: Int32) -> TweakDBID {
        if i == 1 {
            return t"AttachmentSlots.SandevistanSlot2";
        }
        return t"AttachmentSlots.SandevistanSlot1";
    }

    // Hope level (0 = T5, 1 = T5+, 2 = T5++) that unlocks real-speed bullets.
    public static func RealSpeedBulletsLevel() -> Int32 { return 2; }

    // ----- Heat model (degrees Celsius) -------------------------------------
    // Idle temperature. A fully charged implant always cools down to it.
    public static func AmbientHeat() -> Float { return 40.0; }
    // Gauge turns yellow from this temperature on.
    public static func WarmHeat() -> Float { return 80.0; }
    // Gauge turns red and pulses from this temperature on.
    // (The overheat warning itself appears whenever the NEXT activation would
    // overheat the implant, and a softer one from WarmHeat on.)
    public static func WarningHeat() -> Float { return 100.0; }
    // Reaching this temperature = overheat (shutdown + lockout).
    public static func CriticalHeat() -> Float { return 120.0; }

    // Heat added by one activation.
    // T5 / T5+: 22 C -> 3 activations in a row are safe, the 4th overheats.
    // T5++    : 30 C -> 2 activations in a row are safe, the 3rd overheats.
    public static func ActivationHeat(level: Int32) -> Float {
        if level >= 2 {
            return 30.0;
        }
        return 22.0;
    }

    // Activation from a full charge heats this much less ("cold start").
    public static func ColdStartFactor() -> Float { return 0.5; }
    // Charge percent that counts as "full".
    public static func FullChargePercent() -> Float { return 99.0; }
    // Passive cooling while the Sandevistan is off (C per real second).
    public static func CoolingPerSecond() -> Float { return 1.5; }
    // Cooling once the charge is full again (resets the "uses in a row").
    public static func FullChargeCoolingPerSecond() -> Float { return 25.0; }

    // Seconds of forced recharge after an overheat (also set in the .tweak).
    public static func OverheatSeconds() -> Float { return 12.0; }

    // ----- Reactions to other implants ---------------------------------------
    // Axolotl: faster cooling, and every kill under Sandevistan cools Hope down.
    public static func AxolotlCoolingMult() -> Float { return 1.5; }
    public static func AxolotlKillCooling() -> Float { return 8.0; }
    // Cox-2 Cybersomatic Optimizer: faster cooling, less heat per activation.
    public static func Cox2CoolingMult() -> Float { return 1.5; }
    public static func Cox2HeatMult() -> Float { return 0.9; }
    // Bioconductor: less heat per activation.
    public static func BioconductorHeatMult() -> Float { return 0.9; }
    // Adrenaline Booster: weaker stamina drain (Berserk / True Madness).
    public static func AdrenalineDrainMult() -> Float { return 0.65; }
    // Second Heart: overheat lockout 8 s instead of 12 s.
    // Reflex Tuner: New Breath works below 50 % health instead of 40 %.
    public static func NewBreathThreshold() -> Float { return 40.0; }
    public static func NewBreathThresholdReflexTuner() -> Float { return 50.0; }

    // ----- Upgrades ----------------------------------------------------------
    // 1. Discharge: electric shock around the player when Sandevistan ends (in combat).
    public static func DischargeRadius() -> Float { return 2.0; }
    public static func DischargeStatus() -> TweakDBID { return t"BaseStatusEffect.Electrocuted"; }
    // 2. Phase shield: no damage during the first seconds of Sandevistan.
    public static func PhaseShieldSeconds() -> Float { return 1.5; }
    // 3. New breath: activation length below the health threshold.
    public static func NewBreathSeconds() -> Float { return 15.0; }
    // 4. Quick recharge: this many kills within the window refill the charge to 100 %.
    public static func QuickChargeKills() -> Int32 { return 5; }
    public static func QuickChargeWindow() -> Float { return 15.0; }
    // 5. Berserk: stamina drain per second while Sandevistan is active.
    public static func BerserkStaminaDrain() -> Float { return 12.0; }
    // Berserk bonuses while active: +30 % move speed, +15 % damage, +5 % crit chance.
    public static func BerserkSpeed() -> Float { return 0.3; }
    public static func BerserkDamage() -> Float { return 0.15; }
    public static func BerserkCritChance() -> Float { return 5.0; }
    // 6. True madness: chance per activation, freeze length, extra heat, stamina drain.
    public static func MadnessChance() -> Float { return 0.25; }
    public static func MadnessSeconds() -> Float { return 5.0; }
    public static func MadnessHeat() -> Float { return 45.0; }
    public static func MadnessStaminaDrain() -> Float { return 15.0; }
    // World time scale during the freeze (0.005 = 200x slower: looks frozen,
    // but stays in the range the engine handles well).
    public static func MadnessTimeScale() -> Float { return 0.005; }

    // ----- Mastery ---------------------------------------------------------------
    // Every MasteryStep() activations of Hope raise the mastery level (max MasteryMaxLevel()).
    // Each level lowers the implant's capacity (humanity) cost and improves it.
    // Example: 50 -> 47 after 20 activations, 44 after 40, ... 35 after 100.
    // Capacity cost of every Hope tier without mastery (Humanity50Cost in the .tweak).
    public static func CapacityCost() -> Float { return 50.0; }
    public static func MasteryStep() -> Int32 { return 20; }
    public static func MasteryMaxLevel() -> Int32 { return 5; }
    public static func MasteryCapacityPerLevel() -> Float { return 3.0; }
    // per level: +2 % damage, +3 % crit damage, +0.3 s duration, 6 % faster cooling, 3 % less heat
    public static func MasteryDamagePerLevel() -> Float { return 0.02; }
    public static func MasteryCritDamagePerLevel() -> Float { return 3.0; }
    public static func MasteryDurationPerLevel() -> Float { return 0.3; }
    public static func MasteryCoolingPerLevel() -> Float { return 0.06; }
    public static func MasteryHeatPerLevel() -> Float { return 0.03; }

    // ----- Burnout ---------------------------------------------------------------
    // BurnoutActivations() activations within BurnoutWindow() real seconds put the
    // implant at risk: every further activation burns it out with BurnoutChance().
    // Burnout: a storm of system errors for BurnoutErrorSeconds(), then a discharge
    // that stops time almost completely for BurnoutSeconds(): V is disarmed and can
    // only walk until the core cools down.
    public static func BurnoutEnabled() -> Bool { return true; }
    public static func BurnoutActivations() -> Int32 { return 10; }
    public static func BurnoutWindow() -> Float { return 300.0; }
    public static func BurnoutChance() -> Float { return 0.15; }
    public static func BurnoutErrorSeconds() -> Float { return 3.0; }
    public static func BurnoutSeconds() -> Float { return 20.0; }
    // World time scale during the discharge (0.005 = time looks stopped;
    // smaller values can make physics and animation unstable).
    public static func BurnoutTimeScale() -> Float { return 0.005; }

    // ----- Trail ---------------------------------------------------------------
    // A short effect is spawned along the path while Sandevistan is active.
    // Spawned effects play in slowed world time, so they stay almost frozen
    // until the slowdown ends and are removed one second after it.
    public static func TrailEnabled() -> Bool { return true; }
    public static func TrailEffect() -> ResRef { return r"base\\fx\\characters\\common\\charged_jump\\charged_jump.effect"; }
    // Fewer, sparser effects: each one is a live particle system.
    public static func TrailStep() -> Float { return 1.6; }
    public static func TrailMaxPoints() -> Int32 { return 24; }
    public static func TrailFadeSeconds() -> Float { return 1.0; }

    // ----- Broker (contact, shop, contracts) -----------------------------------
    // Hotkeys (Codeware raw input). F7 = call / hang up.
    public static func CallKey() -> EInputKey { return EInputKey.IK_F7; }
    public static func MenuUpKey() -> EInputKey { return EInputKey.IK_Up; }
    public static func MenuDownKey() -> EInputKey { return EInputKey.IK_Down; }
    public static func MenuConfirmKey() -> EInputKey { return EInputKey.IK_Enter; }
    public static func MenuCloseKey() -> EInputKey { return EInputKey.IK_Backspace; }

    // The broker's card can turn up in any loot container once you reach this level.
    public static func ContactLevel() -> Float { return 25.0; }
    // Chance per new container, +bonus for every container without the card.
    public static func ContactChance() -> Float { return 0.04; }
    public static func ContactChanceBonus() -> Float { return 0.01; }

    public static func SandevistanPrice() -> Int32 { return 500000; }

    // ----- HUD (heat gauge and broker menu) -----------------------------------
    public static func HudEnabled() -> Bool { return true; }
    // Heat gauge position, relative to the left edge / vertical centre of the HUD.
    public static func HudX() -> Float { return 40.0; }
    public static func HudY() -> Float { return 170.0; }
    // Compact gauge: temperature font size and the small state line.
    public static func HudFontSize() -> Int32 { return 26; }
    public static func HudSmallFontSize() -> Int32 { return 16; }
    // Opacity while something happens (active / hot / combat) and when idle.
    public static func HudOpacity() -> Float { return 0.7; }
    // Extra line (mastery, modules, synced implants) while active; false = only temperature and state.
    public static func HudShowDetails() -> Bool { return false; }
    // Always show the gauge while in combat (otherwise only when hot / active).
    public static func HudShowInCombat() -> Bool { return true; }
    // Show the gauge (dimmed) whenever Hope is equipped, even when idle.
    public static func HudAlwaysVisible() -> Bool { return true; }
    public static func HudIdleOpacity() -> Float { return 0.3; }
    // Big warning banner at the top of the screen (overheat, burnout, mastery).
    public static func BannerEnabled() -> Bool { return true; }

    // ----- Quest -----------------------------------------------------------
    public static func RequiredLevel() -> Float { return 40.0; }

    // Watson, Arasaka Waterfront (Konpeki Plaza / waterfront promenade)
    public static func TriggerX() -> Float { return -2235.0; }
    public static func TriggerY() -> Float { return 1785.0; }
    public static func TriggerRadius() -> Float { return 130.0; }

    // Night City Columbarium (cemetery). The crate stands next to the entrance.
    public static func CrateX() -> Float { return 231.0; }
    public static func CrateY() -> Float { return 548.5; }
    public static func CrateZ() -> Float { return 114.8; }

    // Distances (metres)
    public static func CrateSpawnDistance() -> Float { return 80.0; }
    public static func CrateFallbackDistance() -> Float { return 3.0; }
    // If the crate cannot be opened for some reason, standing next to it
    // for this many seconds hands the implant over directly.
    public static func CrateFallbackSeconds() -> Int32 { return 25; }

    public static func CrateTemplate() -> ResRef { return r"base\\gameplay\\loot\\containers\\weapon_cases\\appearances\\weapon_case_medium_neomilitary_a.ent"; }
    public static func CrateTag() -> CName { return n"MilitechHopeCrate"; }
}

// The six upgrades, in shop order. Index is used by the shop and contracts.
public abstract class HopeUpgrades {
    public static func Count() -> Int32 { return 6; }

    public static func Id(i: Int32) -> TweakDBID {
        switch i {
            case 0: return t"Items.MilitechHopeMod_Discharge";
            case 1: return t"Items.MilitechHopeMod_QuickCharge";
            case 2: return t"Items.MilitechHopeMod_NewBreath";
            case 3: return t"Items.MilitechHopeMod_PhaseShield";
            case 4: return t"Items.MilitechHopeMod_Berserk";
            case 5: return t"Items.MilitechHopeMod_TrueMadness";
        }
        return TDBID.None();
    }

    // Prices in eddies, from 150 000 to 300 000 depending on power.
    public static func Price(i: Int32) -> Int32 {
        switch i {
            case 0: return 150000;
            case 1: return 175000;
            case 2: return 200000;
            case 3: return 250000;
            case 4: return 275000;
            case 5: return 300000;
        }
        return 300000;
    }

    // Contract: kills under Sandevistan needed to earn the upgrade for free.
    public static func ContractKills(i: Int32) -> Int32 {
        switch i {
            case 0: return 15;
            case 1: return 20;
            case 2: return 25;
            case 3: return 30;
            case 4: return 40;
            case 5: return 50;
        }
        return 50;
    }

    public static func NameKey(i: Int32) -> CName {
        switch i {
            case 0: return n"MilitechHope-Mod-Discharge-Name";
            case 1: return n"MilitechHope-Mod-QuickCharge-Name";
            case 2: return n"MilitechHope-Mod-NewBreath-Name";
            case 3: return n"MilitechHope-Mod-PhaseShield-Name";
            case 4: return n"MilitechHope-Mod-Berserk-Name";
            case 5: return n"MilitechHope-Mod-TrueMadness-Name";
        }
        return n"MilitechHope-Mod-Discharge-Name";
    }

    public static func IndexOf(id: TweakDBID) -> Int32 {
        let i = 0;
        while i < HopeUpgrades.Count() {
            if HopeUpgrades.Id(i) == id {
                return i;
            }
            i += 1;
        }
        return -1;
    }
}
