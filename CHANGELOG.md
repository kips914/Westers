# Changelog

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
