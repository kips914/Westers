// Militech "Hope" Sandevistan — tunables.
// Edit the numbers below; redscript recompiles scripts on the next game start.
module MilitechHope

public abstract class HopeConfig {
    // ----- Items --------------------------------------------------------
    public static func ItemBase() -> TweakDBID { return t"Items.MilitechHopeSandevistan"; }
    public static func ItemPlus() -> TweakDBID { return t"Items.MilitechHopeSandevistanPlus"; }
    public static func ItemPlusPlus() -> TweakDBID { return t"Items.MilitechHopeSandevistanPlusPlus"; }
    public static func OverheatEffect() -> TweakDBID { return t"MilitechHope.SandevistanOverheat"; }

    // ----- Overheat ------------------------------------------------------
    // Allowed activations in a row: 3 on Tier 5 / Tier 5+, 2 on Tier 5++.
    // The activation that goes over the limit triggers an overheat.
    public static func UsesInARow(level: Int32) -> Int32 {
        if level >= 2 {
            return 2;
        }
        return 3;
    }

    // Seconds of forced recharge after an overheat (also set in the .tweak).
    public static func OverheatSeconds() -> Float { return 12.0; }

    // Hope level (0 = T5, 1 = T5+, 2 = T5++) that unlocks real-speed bullets.
    public static func RealSpeedBulletsLevel() -> Int32 { return 2; }

    // The streak resets after this many seconds without activations
    // or when the charge is (almost) full.
    public static func StreakResetSeconds() -> Float { return 12.0; }
    public static func StreakResetChargePercent() -> Float { return 99.0; }

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
