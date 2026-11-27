using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Windows.Forms;

namespace MilitechHopeInstaller
{
    internal static class Program
    {
        /// <summary>
        /// GUI:     MilitechHopeInstaller.exe [--game "C:\Games\Cyberpunk 2077"]
        /// Silent:  MilitechHopeInstaller.exe --silent --game "..." [--only red4ext,redscript,...] [--log install.log]
        ///          MilitechHopeInstaller.exe --silent --game "..." --uninstall
        /// Exit code 0 = success.
        /// </summary>
        [STAThread]
        private static int Main(string[] args)
        {
            var opts = ParseArgs(args);
            opts.TryGetValue("game", out var game);

            if (opts.ContainsKey("silent"))
                return RunSilent(opts, game);

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm(game));
            return 0;
        }

        private static int RunSilent(Dictionary<string, string> opts, string game)
        {
            opts.TryGetValue("log", out var logPath);
            if (string.IsNullOrEmpty(logPath))
                logPath = Path.Combine(Path.GetTempPath(), "MilitechHopeInstaller.log");
            var log = new StringBuilder();
            void Write(string s) { log.AppendLine(s); try { Console.WriteLine(s); } catch { } }

            var code = 1;
            try
            {
                if (string.IsNullOrEmpty(game)) game = GameLocator.Find();
                if (!GameLocator.IsGameDir(game))
                {
                    Write("Game folder not found. Use --game \"<Cyberpunk 2077 folder>\".");
                    return 2;
                }
                Write("Game: " + game);

                var engine = new InstallerEngine();
                engine.Log += Write;

                if (opts.ContainsKey("uninstall"))
                {
                    code = engine.RemoveMainMod(game) ? 0 : 1;
                }
                else
                {
                    IList<ModComponent> list = Catalog.All.Where(c => c.Required || c.Id == "cet").ToList();
                    if (opts.TryGetValue("only", out var only) && !string.IsNullOrEmpty(only))
                    {
                        var ids = only.Split(',').Select(s => s.Trim()).ToList();
                        list = Catalog.All.Where(c => ids.Contains(c.Id, StringComparer.OrdinalIgnoreCase)).ToList();
                    }
                    else if (opts.ContainsKey("all"))
                    {
                        list = Catalog.All.ToList();
                    }
                    code = engine.Install(game, list, opts.ContainsKey("download-mod")) ? 0 : 1;
                }
                Write(code == 0 ? "RESULT: OK" : "RESULT: FAILED");
            }
            catch (Exception ex)
            {
                Write("FATAL: " + ex);
                code = 1;
            }
            finally
            {
                try { File.WriteAllText(logPath, log.ToString(), Encoding.UTF8); } catch { }
            }
            return code;
        }

        private static Dictionary<string, string> ParseArgs(string[] args)
        {
            var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            for (var i = 0; i < args.Length; i++)
            {
                var a = args[i];
                if (!a.StartsWith("--")) continue;
                var key = a.Substring(2);
                string value = null;
                if (i + 1 < args.Length && !args[i + 1].StartsWith("--")) value = args[++i];
                result[key] = value ?? "";
            }
            return result;
        }
    }
}
