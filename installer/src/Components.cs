using System.IO;
using System.Linq;

namespace MilitechHopeInstaller
{
    /// <summary>One installable package: a framework mod from GitHub releases or the embedded Militech Hope mod.</summary>
    public sealed class ModComponent
    {
        public string Id;
        public string Name;
        public string Description;
        /// <summary>GitHub "owner/repo" of the latest release to download (null for the embedded mod).</summary>
        public string Repo;
        /// <summary>Regex for the release asset file name.</summary>
        public string AssetPattern;
        /// <summary>Paths relative to the game folder; any of them existing means "installed".</summary>
        public string[] DetectPaths;
        public bool Required;
        public bool IsMainMod;
        /// <summary>Skip files that sit in the root of the zip (readme, license...).</summary>
        public bool SkipRootFiles;

        public bool IsInstalled(string gameDir)
        {
            if (string.IsNullOrEmpty(gameDir)) return false;
            return DetectPaths.Any(p =>
            {
                var full = Path.Combine(gameDir, p);
                return File.Exists(full) || Directory.Exists(full);
            });
        }

        public override string ToString() => Name;
    }

    public static class Catalog
    {
        public const string ModRepo = "kips914/Westers";

        public static readonly ModComponent[] All =
        {
            new ModComponent
            {
                Id = "red4ext", Name = "RED4ext", Required = true,
                Description = "Загрузчик нативных плагинов (нужен TweakXL, Codeware, redscript).",
                Repo = "wopss/RED4ext", AssetPattern = @"^red4ext-[\d.]+\.zip$",
                DetectPaths = new[] { @"red4ext\RED4ext.dll" },
            },
            new ModComponent
            {
                Id = "redscript", Name = "redscript", Required = true,
                Description = "Компилятор скриптов .reds (логика перегрева и задания).",
                Repo = "jac3km4/redscript", AssetPattern = @"windows\.zip$",
                DetectPaths = new[] { @"engine\tools\scc.exe", @"red4ext\plugins\redscript" },
            },
            new ModComponent
            {
                Id = "tweakxl", Name = "TweakXL", Required = true,
                Description = "Загружает .tweak — сам имплант и его уровни.",
                Repo = "psiberx/cp2077-tweak-xl", AssetPattern = @"^TweakXL-[\d.]+\.zip$",
                DetectPaths = new[] { @"red4ext\plugins\TweakXL" },
            },
            new ModComponent
            {
                Id = "codeware", Name = "Codeware", Required = true,
                Description = "Библиотека для скриптов: тексты RU/EN, ящик и метка задания.",
                Repo = "psiberx/cp2077-codeware", AssetPattern = @"^Codeware-[\d.]+\.zip$",
                DetectPaths = new[] { @"red4ext\plugins\Codeware" },
            },
            new ModComponent
            {
                Id = "cet", Name = "Cyber Engine Tweaks", Required = false,
                Description = "Консоль и оверлей (выдача импланта командой). Рекомендуется.",
                Repo = "maximegmd/CyberEngineTweaks", AssetPattern = @"^cet_[\d_]+\.zip$",
                DetectPaths = new[] { @"bin\x64\plugins\cyber_engine_tweaks.asi" },
            },
            new ModComponent
            {
                Id = "archivexl", Name = "ArchiveXL", Required = false,
                Description = "Не обязателен для «Надежды», но нужен многим другим модам.",
                Repo = "psiberx/cp2077-archive-xl", AssetPattern = @"^ArchiveXL-[\d.]+\.zip$",
                DetectPaths = new[] { @"red4ext\plugins\ArchiveXL" },
            },
            new ModComponent
            {
                Id = "militechhope", Name = "Сандевистан Militech «Надежда»", Required = true, IsMainMod = true,
                Description = "Сам мод: имплант, перегрев, задание, иконка.",
                Repo = ModRepo, AssetPattern = @"^MilitechHope_Sandevistan_.*\.zip$",
                DetectPaths = new[] { @"r6\tweaks\MilitechHope\militech_hope.tweak" },
                SkipRootFiles = true,
            },
        };

        /// <summary>Written by the CI into the mod package: the installed mod version ("v1.4.0").</summary>
        public const string VersionFile = @"r6\scripts\MilitechHope\VERSION.txt";

        public static ModComponent MainMod => All.First(c => c.IsMainMod);

        /// <summary>Files and folders that belong to the Militech Hope mod (used by "Remove mod").</summary>
        public static readonly string[] MainModPaths =
        {
            @"archive\pc\mod\MilitechHope.archive",
            @"r6\tweaks\MilitechHope",
            @"r6\scripts\MilitechHope",
            @"bin\x64\plugins\cyber_engine_tweaks\mods\MilitechHope",
        };
    }
}
