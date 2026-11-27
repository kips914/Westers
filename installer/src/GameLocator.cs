using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using Microsoft.Win32;

namespace MilitechHopeInstaller
{
    /// <summary>Finds the Cyberpunk 2077 folder for Steam, GOG and Epic installs.</summary>
    public static class GameLocator
    {
        public const string GameExe = @"bin\x64\Cyberpunk2077.exe";

        public static bool IsGameDir(string dir)
        {
            try { return !string.IsNullOrWhiteSpace(dir) && File.Exists(Path.Combine(dir, GameExe)); }
            catch { return false; }
        }

        public static string GetGameVersion(string dir)
        {
            try
            {
                var info = FileVersionInfo.GetVersionInfo(Path.Combine(dir, GameExe));
                return string.IsNullOrEmpty(info.ProductVersion) ? info.FileVersion : info.ProductVersion;
            }
            catch { return null; }
        }

        public static string Find() => Candidates().FirstOrDefault(IsGameDir);

        public static IEnumerable<string> Candidates()
        {
            var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach (var c in RawCandidates())
            {
                string full;
                try { full = Path.GetFullPath(c.Trim().Trim('"')); }
                catch { continue; }
                if (seen.Add(full)) yield return full;
            }
        }

        private static IEnumerable<string> RawCandidates()
        {
            // ---- Steam ----
            var steamRoots = new List<string>();
            AddIfNotNull(steamRoots, ReadReg(RegistryHive.CurrentUser, RegistryView.Default, @"Software\Valve\Steam", "SteamPath"));
            AddIfNotNull(steamRoots, ReadReg(RegistryHive.LocalMachine, RegistryView.Registry32, @"SOFTWARE\Valve\Steam", "InstallPath"));
            AddIfNotNull(steamRoots, ReadReg(RegistryHive.LocalMachine, RegistryView.Registry64, @"SOFTWARE\Valve\Steam", "InstallPath"));
            steamRoots.Add(@"C:\Program Files (x86)\Steam");

            foreach (var root in steamRoots.ToList())
            {
                foreach (var lib in SteamLibraries(root))
                    yield return Path.Combine(lib, "steamapps", "common", "Cyberpunk 2077");
            }

            foreach (var view in new[] { RegistryView.Registry64, RegistryView.Registry32 })
            {
                var steamApp = ReadReg(RegistryHive.LocalMachine, view,
                    @"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 1091500", "InstallLocation");
                if (steamApp != null) yield return steamApp;
            }

            // ---- GOG ----
            foreach (var view in new[] { RegistryView.Registry32, RegistryView.Registry64 })
            {
                var gog = ReadReg(RegistryHive.LocalMachine, view, @"SOFTWARE\GOG.com\Games\1423049311", "path");
                if (gog != null) yield return gog;
                var gogUninstall = ReadReg(RegistryHive.LocalMachine, view,
                    @"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\1423049311_is1", "InstallLocation");
                if (gogUninstall != null) yield return gogUninstall;
            }
            yield return @"C:\GOG Games\Cyberpunk 2077";
            yield return @"C:\Program Files (x86)\GOG Galaxy\Games\Cyberpunk 2077";

            // ---- Epic ----
            foreach (var epic in EpicLocations()) yield return epic;
            yield return @"C:\Program Files\Epic Games\Cyberpunk2077";

            // ---- Other drives, default folder names ----
            foreach (var drive in SafeDrives())
            {
                yield return Path.Combine(drive, @"SteamLibrary\steamapps\common\Cyberpunk 2077");
                yield return Path.Combine(drive, @"Steam\steamapps\common\Cyberpunk 2077");
                yield return Path.Combine(drive, @"Games\Cyberpunk 2077");
                yield return Path.Combine(drive, @"GOG Games\Cyberpunk 2077");
                yield return Path.Combine(drive, @"Epic Games\Cyberpunk2077");
            }
        }

        private static IEnumerable<string> SteamLibraries(string steamRoot)
        {
            var result = new List<string>();
            if (string.IsNullOrEmpty(steamRoot)) return result;
            result.Add(steamRoot.Replace('/', '\\'));
            try
            {
                var vdf = Path.Combine(steamRoot, "steamapps", "libraryfolders.vdf");
                if (File.Exists(vdf))
                {
                    var text = File.ReadAllText(vdf);
                    foreach (Match m in Regex.Matches(text, "\"path\"\\s+\"([^\"]+)\""))
                        result.Add(m.Groups[1].Value.Replace(@"\\", @"\"));
                }
            }
            catch { /* ignore broken vdf */ }
            return result;
        }

        private static IEnumerable<string> EpicLocations()
        {
            var result = new List<string>();
            try
            {
                var dir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData),
                    @"Epic\EpicGamesLauncher\Data\Manifests");
                if (!Directory.Exists(dir)) return result;
                foreach (var item in Directory.GetFiles(dir, "*.item"))
                {
                    var text = File.ReadAllText(item);
                    if (text.IndexOf("Cyberpunk", StringComparison.OrdinalIgnoreCase) < 0) continue;
                    var m = Regex.Match(text, "\"InstallLocation\"\\s*:\\s*\"([^\"]+)\"");
                    if (m.Success) result.Add(m.Groups[1].Value.Replace(@"\\", @"\").Replace('/', '\\'));
                }
            }
            catch { /* ignore */ }
            return result;
        }

        private static IEnumerable<string> SafeDrives()
        {
            try
            {
                return DriveInfo.GetDrives()
                    .Where(d => d.DriveType == DriveType.Fixed && d.IsReady)
                    .Select(d => d.RootDirectory.FullName)
                    .ToList();
            }
            catch { return Enumerable.Empty<string>(); }
        }

        private static string ReadReg(RegistryHive hive, RegistryView view, string key, string value)
        {
            try
            {
                using (var root = RegistryKey.OpenBaseKey(hive, view))
                using (var k = root.OpenSubKey(key))
                {
                    var v = k?.GetValue(value) as string;
                    return string.IsNullOrWhiteSpace(v) ? null : v.Replace('/', '\\');
                }
            }
            catch { return null; }
        }

        private static void AddIfNotNull(List<string> list, string value)
        {
            if (!string.IsNullOrWhiteSpace(value)) list.Add(value);
        }
    }
}
