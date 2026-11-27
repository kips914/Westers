# Changelog

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
