#!/usr/bin/env python3
"""Generates src/r6/tweaks/MilitechHope/militech_hope.tweak from the per-tier table below.
Usage: python tools/gen_tweak.py"""
TIERS = [
    # id suffix, quality, duration, timescale, critchance passive, headshot mult, mitigation, armor, stamina on kill, hp on kill, desc key suffix
    dict(rec="Items.MilitechHopeSandevistan", base="Items.SandevistanBase", quality="Quality.Legendary", key="T5",
         dur=5.0, ts=0.05, cc=5, hs=1.15, mit=10, armor=50, kst=20, khp=0, next="Items.MilitechHopeSandevistanPlus"),
    dict(rec="Items.MilitechHopeSandevistanPlus", base="Items.MilitechHopeSandevistan", quality="Quality.LegendaryPlus", key="T5P",
         dur=7.5, ts=0.03, cc=7, hs=1.20, mit=15, armor=70, kst=20, khp=5, next="Items.MilitechHopeSandevistanPlusPlus"),
    dict(rec="Items.MilitechHopeSandevistanPlusPlus", base="Items.MilitechHopeSandevistan", quality="Quality.LegendaryPlusPlus", key="T5PP",
         dur=10.0, ts=0.01, cc=10, hs=1.25, mit=20, armor=90, kst=25, khp=8, next=""),
]

def const(stat, mtype, value, ind):
    t = "\t" * ind
    return (f"{t}{{\n{t}\tstatType = \"BaseStats.{stat}\";\n{t}\tmodifierType = \"{mtype}\";\n"
            f"{t}\tvalue = {value}f;\n{t}}} : ConstantStatModifier")

def ui(key, ind=2):
    t = "\t" * ind
    return (f"{t}{{\n{t}\tUIData =\n{t}\t{{\n{t}\t\tlocalizedDescription = \"LocKey#{key}\";\n{t}\t}};\n{t}}} : GameplayLogicPackage")

def tier(t):
    out = []
    if t["base"] != "Items.SandevistanBase":
        out.append("[ notQueryable ]")
    out.append(f"{t['rec']} : {t['base']}\n{{")
    if t["key"] == "T5PP":
        out.append('\tblueprint = "Items.MilitechHopeSandevistanBlueprint";')
    if t["base"] == "Items.SandevistanBase":
        out.append("""\tdisplayName = "LocKey#MilitechHope-Name";
\tlocalizedDescription = "LocKey#MilitechHope-Lore";
\tupgradeCostMult = 2.5f;
\ticonPath = "militech_hope_sandevistan";
\ttags += [ "MilitechHope" ];
\tobjectActions +=
\t[
\t\t"CyberwareAction.UseCooldownedSandevistan", "CyberwareAction.UseCooldownedCorruptedSandevistan"
\t];
\tvariants = [ "Variants.Humanity50Cost" ];
\tusesVariants = true;
\tOnLooted = [];""")
    out.append(f"\tquality = \"{t['quality']}\";")
    mods = [
        const("IsItemIconic", "Additive", 1, 2),
        const("HasSandevistan", "Additive", 1, 2),
        const("TimeDilationSandevistanDuration", "Additive", t["dur"], 2),
        const("TimeDilationSandevistanTimeScale", "Additive", t["ts"], 2),
        const("TimeDilationSandevistanRechargeDuration", "Additive", 10.0, 2),
        const("TimeDilationSandevistanCooldownBase", "Additive", 1, 2),
        const("SandevistanKillRechargeValue", "Additive", 10, 2),
        const("TimeDilationSandevistanEnterCost", "Additive", -10, 2),
        """\t\t{
\t\t\tstatType = "BaseStats.AttunementHelper";
\t\t\tmodifierType = "Additive";
\t\t\trefStat = "BaseStats.Reflexes";
\t\t\trefObject = "Player";
\t\t\topSymbol = "*";
\t\t\tvalue = 0.1f;
\t\t} : CombinedStatModifier""",
    ]
    out.append("\tstatModifiers =\n\t[\n" + ",\n".join(mods) + "\n\t];")

    k = t["key"]
    pk = []
    # 1. core description
    pk.append(ui(f"MilitechHope-Core-{k}"))
    # 2. passive stats
    pk.append("\t\t{\n\t\t\tstats =\n\t\t\t[\n" + ",\n".join([
        const("CritDamage", "Additive", 10, 4),
        const("CritChance", "Additive", t["cc"], 4),
        const("Stamina", "Additive", 12, 4),
    ]) + f"\n\t\t\t];\n\t\t\tUIData =\n\t\t\t{{\n\t\t\t\tlocalizedDescription = \"LocKey#MilitechHope-Passive-{k}\";\n\t\t\t}};\n\t\t}} : GameplayLogicPackage")
    # 3. buffs while Sandevistan is active
    group = ",\n".join([
        const("HeadshotDamageMultiplier", "Multiplier", t["hs"], 7),
        const("MitigationChance", "Additive", t["mit"], 7),
        const("Armor", "Additive", t["armor"], 7),
    ])
    pk.append(f"""\t\t{{
\t\t\teffectors =
\t\t\t[
\t\t\t\t{{
\t\t\t\t\tprereqRecord =
\t\t\t\t\t{{
\t\t\t\t\t\tstring stateName = "Sandevistan";
\t\t\t\t\t\tbool isInState = true;
\t\t\t\t\t}} : Prereqs.TimeDilationPSMPrereq;
\t\t\t\t\tstatGroup =
\t\t\t\t\t{{
\t\t\t\t\t\tstatModifiers =
\t\t\t\t\t\t[
{group}
\t\t\t\t\t\t];
\t\t\t\t\t}};
\t\t\t\t}} : ApplyStatGroupEffector
\t\t\t];
\t\t\tUIData =
\t\t\t{{
\t\t\t\tlocalizedDescription = "LocKey#MilitechHope-Active-{k}";
\t\t\t}};
\t\t}} : GameplayLogicPackage""")
    # 4. restore on kill while Sandevistan is active
    pools = [("Stamina", t["kst"])] + ([("Health", t["khp"])] if t["khp"] else [])
    upd = ",\n".join(
        f"\t\t\t\t\t\t\t{{\n\t\t\t\t\t\t\t\tstatPoolType = \"BaseStatPools.{p}\";\n\t\t\t\t\t\t\t\tstatPoolValue = {v}f;\n\t\t\t\t\t\t\t}} : StatPoolUpdate"
        for p, v in pools)
    pk.append(f"""\t\t{{
\t\t\teffectors =
\t\t\t[
\t\t\t\t{{
\t\t\t\t\tprereqRecord =
\t\t\t\t\t{{
\t\t\t\t\t\tstring stateName = "Sandevistan";
\t\t\t\t\t\tbool isInState = true;
\t\t\t\t\t}} : Prereqs.TimeDilationPSMPrereq;
\t\t\t\t\teffectorToApply =
\t\t\t\t\t{{
\t\t\t\t\t\tstatPoolUpdates =
\t\t\t\t\t\t[
{upd}
\t\t\t\t\t\t];
\t\t\t\t\t}} : Items.RestoreStatPoolOnKillEffector;
\t\t\t\t}} : Perks.ApplyEffectorOnPlayer
\t\t\t];
\t\t\tUIData =
\t\t\t{{
\t\t\t\tlocalizedDescription = "LocKey#MilitechHope-Kill-{k}";
\t\t\t}};
\t\t}} : GameplayLogicPackage""")
    # 5. real-speed bullets (script) on max level
    if k == "T5PP":
        pk.append(ui("MilitechHope-Bullets"))
        pk.append(ui("MilitechHope-UpgradeSlot"))
    # 6. flaw
    pk.append(ui(f"MilitechHope-Overheat-{'T5PP' if k == 'T5PP' else 'T5'}"))
    out.append("\tOnEquip =\n\t[\n" + ",\n".join(pk) + "\n\t];")
    out.append(f"\tnextUpgradeItem = \"{t['next']}\";\n}}")
    return "\n".join(out)

HEADER = """// =====================================================================
//  Militech "Hope" (Надежда) Sandevistan — TweakXL definitions
//  Game: Cyberpunk 2077 2.5   Requires: TweakXL, Codeware (texts)
//  Generated from a per-tier table; keep the three tiers in sync.
//
//  Level    | Slow | Time  | Crit% | Headshot | Mitig. | Armor | On kill
//  Tier 5   | 95 % | 5.0 s |  +5   |  x1.15   |  +10   |  +50  | 20% stamina
//  Tier 5+  | 97 % | 7.5 s |  +7   |  x1.20   |  +15   |  +70  | 20% stamina, 5% HP
//  Tier 5++ | 99 % | 10  s |  +10  |  x1.25   |  +20   |  +90  | 25% stamina, 8% HP
//  All tiers: +10 % crit damage, +12 stamina, 10 s full recharge, humanity 50.
//  Tier 5++ only: bullets keep their real speed during Sandevistan (redscript).
//  Overheat (redscript, heat in degrees C): 40 C idle, 120 C = shutdown + 12 s lockout.
//    Each activation heats 22 C (30 C on Tier 5++), half as much from a full charge;
//    a fully recharged implant cools back to 40 C.
//  Tier 5++ has an upgrade slot (AttachmentSlots.SandevistanSlot1) for six
//  Militech upgrade modules (logic in redscript), sold by the broker or given by console.
//  Headshot / mitigation / armor apply only while the Sandevistan is active.
// =====================================================================

// ---------------------------------------------------------------------
//  Inventory icon (texture is packed into archive/pc/mod/MilitechHope.archive)
// ---------------------------------------------------------------------
UIIcon.militech_hope_sandevistan : UIIcon
{
	atlasResourcePath = "militech_hope\\\\icons\\\\militech_hope_sandevistan.inkatlas";
	atlasPartName = "custom_icon";
}

// ---------------------------------------------------------------------
//  Overheat lockout: blocks Sandevistan activation for 12 seconds
// ---------------------------------------------------------------------
MilitechHope.SandevistanOverheat : BaseStatusEffect.PlayerCyberwareCooldown
{
	gameplayTags += [ "MilitechHopeOverheat" ];
	duration =
	{
		statModifiers =
		[
			{
				statType = "BaseStats.MaxDuration";
				modifierType = "Additive";
				value = 12f;
			} : ConstantStatModifier
		];
	} : StatModifierGroup;
	packages =
	[
		{
			stats =
			[
				{
					statType = "BaseStats.HasSandevistan";
					modifierType = "Multiplier";
					value = 0f;
				} : ConstantStatModifier
			];
		} : GameplayLogicPackage
	];
}
"""


UPGRADES = [
    # record suffix, loc key part
    ("Discharge", "Discharge"),
    ("QuickCharge", "QuickCharge"),
    ("NewBreath", "NewBreath"),
    ("PhaseShield", "PhaseShield"),
    ("Berserk", "Berserk"),
    ("TrueMadness", "TrueMadness"),
]

def upgrade(rec, key):
    return f"""[ notQueryable ]
Items.MilitechHopeMod_{rec} : Items.Fragment
{{
\tdisplayName = "LocKey#MilitechHope-Mod-{key}-Name";
\tlocalizedDescription = "LocKey#MilitechHope-Mod-Lore";
\tquality = "Quality.Legendary";
\ticonPath = "cwf_sandevistan1";
\tplacementSlots = [ "AttachmentSlots.SandevistanSlot1" ];
\ttags += [ "itemPart", "MilitechHopeUpgrade" ];
\tOnAttach =
\t[
\t\t{{
\t\t\tUIData =
\t\t\t{{
\t\t\t\tlocalizedDescription = "LocKey#MilitechHope-Mod-{key}-Desc";
\t\t\t}};
\t\t}} : GameplayLogicPackage
\t];
}}
"""

EXTRA = """
// ---------------------------------------------------------------------
//  Shorter overheat lockout (8 s) used when a Second Heart is installed
// ---------------------------------------------------------------------
MilitechHope.SandevistanOverheatShort : MilitechHope.SandevistanOverheat
{
\tduration =
\t{
\t\tstatModifiers =
\t\t[
\t\t\t{
\t\t\t\tstatType = "BaseStats.MaxDuration";
\t\t\t\tmodifierType = "Additive";
\t\t\t\tvalue = 8f;
\t\t\t} : ConstantStatModifier
\t\t];
\t} : StatModifierGroup;
}

// ---------------------------------------------------------------------
//  Tier 5++ blueprint: one upgrade slot
// ---------------------------------------------------------------------
[ notQueryable ]
Items.MilitechHopeSandevistanBlueprint : ItemBlueprint
{
\trootElement =
\t{
\t\tslot = "AttachmentSlots.GenericItemRoot";
\t\tchildElements =
\t\t[
\t\t\t{
\t\t\t\tslot = "AttachmentSlots.SandevistanSlot1";
\t\t\t}
\t\t];
\t};
}

// ---------------------------------------------------------------------
//  Upgrade modules (Tier 5++ slot). Effects are scripted in redscript.
// ---------------------------------------------------------------------
""" + "\n".join(upgrade(r, k) for r, k in UPGRADES) + """
// ---------------------------------------------------------------------
//  Broker's business card: hidden in a random loot container (redscript)
// ---------------------------------------------------------------------
[ notQueryable ]
Items.MilitechHopeDealerCard : Items.SouvenirJunkItem1
{
\tdisplayName = "LocKey#MilitechHope-Card-Name";
\tlocalizedDescription = "LocKey#MilitechHope-Card-Desc";
\ttags += [ "MilitechHope" ];
}
"""

names = ["Tier 5 (base)", "Tier 5+", "Tier 5++ (max level)"]
body = HEADER
for n, t in zip(names, TIERS):
    body += f"\n// ---------------------------------------------------------------------\n//  {n}\n// ---------------------------------------------------------------------\n" + tier(t) + "\n"
body += EXTRA
open(__import__("pathlib").Path(__file__).resolve().parents[1] / "src/r6/tweaks/MilitechHope/militech_hope.tweak", "w", encoding="utf-8").write(body)
print(len(body.splitlines()))
