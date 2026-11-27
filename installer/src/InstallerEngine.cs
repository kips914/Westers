using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Net;
using System.Reflection;
using System.Text.RegularExpressions;

namespace MilitechHopeInstaller
{
    /// <summary>Downloads and unpacks components into the game folder. UI-agnostic, reports via events.</summary>
    public sealed class InstallerEngine
    {
        private static readonly string[] KnownRoots = { "bin", "r6", "red4ext", "archive", "engine", "mods" };

        public event Action<string> Log;
        /// <summary>Overall progress 0..100.</summary>
        public event Action<int> Progress;

        private readonly string _tempDir = Path.Combine(Path.GetTempPath(), "MilitechHopeInstaller");

        static InstallerEngine()
        {
            ServicePointManager.SecurityProtocol |= SecurityProtocolType.Tls12;
        }

        private void Write(string message) => Log?.Invoke(message);

        public static bool HasEmbeddedMod() =>
            Assembly.GetExecutingAssembly().GetManifestResourceNames().Contains("MilitechHope.zip");

        public static bool IsGameRunning()
        {
            try { return Process.GetProcessesByName("Cyberpunk2077").Length > 0; }
            catch { return false; }
        }

        public static bool CanWrite(string dir)
        {
            try
            {
                var probe = Path.Combine(dir, ".militechhope_write_test");
                File.WriteAllText(probe, "ok");
                File.Delete(probe);
                return true;
            }
            catch (UnauthorizedAccessException) { return false; }
            catch (IOException) { return false; }
        }

        /// <summary>Installs the components in order. Returns true when everything succeeded.</summary>
        public bool Install(string gameDir, IList<ModComponent> components, bool preferDownloadForMainMod = false)
        {
            Directory.CreateDirectory(_tempDir);
            var ok = true;
            for (var i = 0; i < components.Count; i++)
            {
                var c = components[i];
                var start = i * 100 / components.Count;
                var span = 100 / components.Count;
                Progress?.Invoke(start);
                try
                {
                    Write($"── {c.Name}");
                    string zip;
                    if (c.IsMainMod && HasEmbeddedMod() && !preferDownloadForMainMod)
                    {
                        zip = ExtractEmbeddedMod();
                        Write("   встроенный пакет мода");
                    }
                    else
                    {
                        zip = DownloadLatest(c, p => Progress?.Invoke(start + p * span * 8 / 1000));
                    }

                    var count = ExtractToGame(zip, gameDir, c.SkipRootFiles);
                    Write($"   ✓ установлено файлов: {count}");
                }
                catch (Exception ex)
                {
                    ok = false;
                    Write($"   ✗ ошибка: {ex.Message}");
                }
                Progress?.Invoke(start + span);
            }
            Progress?.Invoke(100);
            return ok;
        }

        public bool RemoveMainMod(string gameDir)
        {
            var ok = true;
            foreach (var rel in Catalog.MainModPaths)
            {
                var full = Path.Combine(gameDir, rel);
                try
                {
                    if (File.Exists(full)) { File.Delete(full); Write($"   удалён {rel}"); }
                    else if (Directory.Exists(full)) { Directory.Delete(full, true); Write($"   удалена папка {rel}"); }
                }
                catch (Exception ex)
                {
                    ok = false;
                    Write($"   ✗ {rel}: {ex.Message}");
                }
            }
            return ok;
        }

        // ------------------------------------------------------------------ download

        private string ExtractEmbeddedMod()
        {
            var path = Path.Combine(_tempDir, "MilitechHope.zip");
            using (var res = Assembly.GetExecutingAssembly().GetManifestResourceStream("MilitechHope.zip"))
            using (var file = File.Create(path))
            {
                res.CopyTo(file);
            }
            return path;
        }

        private static HttpWebRequest Request(string url)
        {
            var req = (HttpWebRequest)WebRequest.Create(url);
            req.UserAgent = "MilitechHopeInstaller/1.1";
            req.Accept = url.Contains("api.github.com") ? "application/vnd.github+json" : "application/octet-stream";
            req.AllowAutoRedirect = true;
            req.Timeout = 60000;
            req.ReadWriteTimeout = 60000;
            return req;
        }

        private string DownloadLatest(ModComponent c, Action<int> progressPermille)
        {
            string json;
            using (var resp = Request($"https://api.github.com/repos/{c.Repo}/releases/latest").GetResponse())
            using (var reader = new StreamReader(resp.GetResponseStream()))
            {
                json = reader.ReadToEnd();
            }

            var tag = Regex.Match(json, "\"tag_name\"\\s*:\\s*\"([^\"]+)\"").Groups[1].Value;
            var pattern = new Regex(c.AssetPattern, RegexOptions.IgnoreCase);
            var url = Regex.Matches(json, "\"browser_download_url\"\\s*:\\s*\"([^\"]+)\"")
                .Cast<Match>()
                .Select(m => m.Groups[1].Value)
                .FirstOrDefault(u => pattern.IsMatch(Uri.UnescapeDataString(u.Substring(u.LastIndexOf('/') + 1))));
            if (url == null)
                throw new InvalidOperationException($"в релизе {c.Repo} {tag} нет файла по шаблону {c.AssetPattern}");

            var fileName = url.Substring(url.LastIndexOf('/') + 1);
            var target = Path.Combine(_tempDir, fileName);
            Write($"   скачивание {fileName} ({tag})");

            using (var resp = (HttpWebResponse)Request(url).GetResponse())
            using (var input = resp.GetResponseStream())
            using (var output = File.Create(target))
            {
                var total = resp.ContentLength;
                var buffer = new byte[81920];
                long done = 0;
                int read;
                var lastReported = -1;
                while ((read = input.Read(buffer, 0, buffer.Length)) > 0)
                {
                    output.Write(buffer, 0, read);
                    done += read;
                    if (total > 0)
                    {
                        var p = (int)(done * 1000 / total);
                        if (p != lastReported) { lastReported = p; progressPermille(p); }
                    }
                }
            }
            return target;
        }

        // ------------------------------------------------------------------ unpack

        /// <summary>Extracts a game-rooted zip. Strips a single wrapper folder if the zip has one.</summary>
        public static int ExtractToGame(string zipPath, string gameDir, bool skipRootFiles)
        {
            var root = Path.GetFullPath(gameDir).TrimEnd('\\') + "\\";
            var count = 0;
            using (var zip = ZipFile.OpenRead(zipPath))
            {
                var files = zip.Entries
                    .Select(e => new { Entry = e, Path = e.FullName.Replace('\\', '/').TrimStart('/') })
                    .Where(x => x.Path.Length > 0 && !x.Path.EndsWith("/"))
                    .ToList();

                // Strip a wrapper folder like "ModName-1.0/bin/..." when present.
                var prefix = "";
                var firstSegments = files.Select(x => x.Path.Contains("/") ? x.Path.Substring(0, x.Path.IndexOf('/')) : null)
                    .Distinct(StringComparer.OrdinalIgnoreCase).ToList();
                if (firstSegments.Count == 1 && firstSegments[0] != null &&
                    !KnownRoots.Contains(firstSegments[0], StringComparer.OrdinalIgnoreCase))
                {
                    prefix = firstSegments[0] + "/";
                }

                foreach (var x in files)
                {
                    var rel = x.Path.Substring(prefix.Length);
                    if (skipRootFiles && !rel.Contains("/")) continue;

                    var dest = Path.GetFullPath(Path.Combine(root, rel.Replace('/', '\\')));
                    if (!dest.StartsWith(root, StringComparison.OrdinalIgnoreCase))
                        continue; // zip-slip protection

                    Directory.CreateDirectory(Path.GetDirectoryName(dest));
                    x.Entry.ExtractToFile(dest, true);
                    count++;
                }
            }
            return count;
        }
    }
}
