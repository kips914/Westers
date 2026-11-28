# Changelog

## v1.4.1 — 2026-11-28

* Fixed the in-game redscript compile errors reported by `redscript_rCURRENT.log`:
  * `BulletHooks.reds`: `EnumInt()` already returns `Int32`, so `Cast<Int32>(EnumInt(...))` had no matching overload. This bug dates back to v1.2.0 and kept every mod script from running.
  * `HopeHud.reds`: `Bool == Bool` has no `OperatorEqual` overload.
* `tools/validate.py` now flags both patterns. The CI type checker misses them because it builds the game types from REDmod sources instead of the real game bundle.

## v1.4.0 — 2026-11-27

* Module icons: chip-style 3D renders for the six upgrade modules (`tools/make_module_icons.py`). Each module has its own xbm and inkatlas, plus a `UIIcon.militech_hope_mod_*` record.
* HUD (`HopeHud.reds`):
  * widgets are re-created whenever they are no longer attached to the current `inkHUDLayer` window (after loading a save or leaving a menu);
  * the gauge is always visible while Hope is equipped, dimmed when idle (`HudAlwaysVisible`, `HudIdleOpacity`);
  * the temperature pulses (inkAnimTransparency, PingPong) from 100 °C;
  * new top banner with slide-in and pulse animations and a glitch jitter mode.
* Overheat warnings are back:
  * a critical warning when the next activation would overheat, with a banner, a screen glitch (`MilitechHope.HeatWarning`), a sound and a message;
  * a soft warning from 80 °C;
  * warnings are shown 0.4 s after activation from the fast loop.
* Mastery: a persistent activation counter, with a level every 20 activations (max 5). Each level gives:
  * −3 `HumanityAllocated` on the player;
  * +2 % `AllDamageDonePercentBonus`;
  * +3 `CritDamage`;
  * +0.3 s Sandevistan duration;
  * −3 % heat and +6 % cooling.

  The banner announces level-ups.
* Burnout: from the 10th activation within 5 minutes, each activation has a 15 % chance to burn out.
  * Phase 1 lasts 3 s: an error storm (`MilitechHope.BurnoutSurge`, heavy glitch, Sandevistan offline).
  * Phase 2 lasts 20 s: a discharge. Global time dilation is set to 0.0001 while the player ignores dilation. `MilitechHope.Burnout`, based on `GameplayRestriction.NoCombat`, adds NoWeapons, NoJump, NoRadialMenus and NoScanning tags and sets CanJump/CanSprint ×0.
* CET: `mastery([n])`, `burnout()`, `warn(kind)` and matching overlay buttons. `DebugVersion` is now 1.4.0.
* Installer:
  * updates the mod from the latest GitHub release (button, startup check, `--update [--force]`);
  * the package now includes `r6/scripts/MilitechHope/VERSION.txt`;
  * version 1.4.0; the User-Agent follows the assembly version.
* CI: new `check-scripts.yml` type-checks the mod scripts with the redscript 1.0.2 frontend against the game sources and Codeware. Known checker artifacts are classified separately.

## v1.3.1 — 2026-11-27

* Tier 5++ now has two upgrade slots: the blueprint gets `AttachmentSlots.SandevistanSlot2`, the modules accept both slots, and the two installed modules work at the same time.
  * `InstallUpgrade` uses the first free slot, then replaces the slots in turn. New `RemoveUpgrades`.
  * The HUD and the broker menu list every installed module.
  * A Tier 5++ created by v1.3.0 keeps its single slot; a new one has two.
* Troubleshooting for raw `LocKey#…` texts, which mean the mod scripts did not compile:
  * new CET `diag()` checks TweakXL, the mod scripts (`DebugVersion`), Codeware and the texts;
  * the CET helper runs the check once per session and shows an on-screen warning when something is broken.
* New CET commands: `modules()`, `uninstall()`, `diag()`.

## v1.3.0 — 2026-11-27

* Heat model in degrees Celsius replaces the plain "uses in a row" counter:
  * 40 °C at rest, overheat at 120 °C, warning from 100 °C;
  * every activation heats the core by 22 °C (30 °C on Tier 5++), only half as much when it starts from a full charge;
  * the core cools 1.5 °C/s while off and drops back to 40 °C once the charge is full again.
* On-screen heat gauge (Codeware ink widgets on `inkHUDLayer`, `HopeHud.reds`): temperature, heat bar, state, charge, installed module, synced implants.
* Reactions to other implants: Axolotl, Cox-2, Bioconductor, Adrenaline Booster, Second Heart (8 s lockout, `MilitechHope.SandevistanOverheatShort`), Reflex Tuner.
* Tier 5++ gets an upgrade slot (`Items.MilitechHopeSandevistanBlueprint` → `AttachmentSlots.SandevistanSlot1`) and six Fragment-based modules `Items.MilitechHopeMod_*`:
  * Discharge;
  * Quick Recharge;
  * New Breath;
  * Phase Shield;
  * Berserk;
  * True Madness.
* Militech broker:
  * a business card (`Items.MilitechHopeDealerCard`) is planted in a random loot container from level 25 (`WorldHooks.reds`);
  * F7 opens a shop menu (Codeware `Input/Key` callback): the Sandevistan for 500 000 €$, modules for 150 000–300 000 €$;
  * kill contracts give the modules for free;
  * the menu can also install modules into the equipped Tier 5++.
* Afterimage trail: effects are spawned along the path while the Sandevistan is active and removed 1 s after it ends.
* New CET commands: `upgrade`, `upgrades`, `install`, `broker`, `card`, `heat`, `cool`, `contract`, plus buttons in the overlay window.

## v1.2.0 — 2026-11-27

* Inventory icon is now 160×160 (vanilla cyberware size), so it no longer overflows its slot.
* Capacity (humanity) cost raised from 40 to 50.
* New buffs:
  * Combat firmware (always on): +5 / 7 / 10 % Crit Chance on top of +10 % Crit Damage and +12 Stamina.
  * Hunter protocol (while Sandevistan is active): +15 / 20 / 25 % Headshot Damage, +10 / 15 / 20 % Mitigation Chance, +50 / 70 / 90 Armor.
  * Adrenaline loop: each kill under Sandevistan restores 20 / 20 / 25 % Stamina (+5 / 8 % Health on Tier 5+ / 5++).
  * Tier 5++ "Last Hope protocol": the player's bullets are not slowed during Sandevistan; guns keep their regular hitscan attack instead of switching to time-dilated projectiles (`BulletHooks.reds`).
* Rewritten RU/EN item descriptions, one titled line per effect.
* `tools/gen_tweak.py` generates the tweak file from a per-tier table.

## v1.1.0 — 2026-11-27

* New `MilitechHope_Installer.exe` (Windows, .NET Framework 4.8, ~200 KB).
  * Finds the game automatically (Steam / GOG / Epic) or lets you browse to it.
  * Downloads the latest RED4ext, redscript, TweakXL, Codeware, Cyber Engine Tweaks and ArchiveXL from their GitHub releases.
  * Installs the embedded Militech Hope mod and shows which components are already installed.
  * "Remove mod" button.
  * Asks to restart as administrator when the game folder is write-protected.
  * Silent mode: `--silent --game <dir> [--all|--only ...] [--uninstall]`.
* CI builds the installer and tests it on a fake game folder (install and uninstall).

## v1.0.0 — 2026-11-27

First release of the Militech "Hope" (Надежда) Sandevistan for Cyberpunk 2077 2.5.

* New iconic implant `Items.MilitechHopeSandevistan` (Tier 5, upgradable to 5+ and 5++).
  * Time slowdown: 95 / 97 / 99 %.
  * Duration: 5 / 7.5 / 10 s.
  * Full recharge: 10 s, charge-based (can be reactivated before it is fully recharged).
  * +10 % Crit Damage, +12 Stamina while installed.
* Overheat flaw: 3 activations in a row (2 on Tier 5++). The next one forces a shutdown and a 12 s full recharge.
* Side job "Hope" (level 40+): Arasaka Waterfront → SMS + map marker → Militech case at the Columbarium.
* CET console helper: `GetMod("MilitechHope").give()`.
* Custom inventory icon, RU/EN texts.
* Repository cleaned of the old Minecraft "Warhead" project.
