//! Type-checks the mod's redscript sources against the game's REDmod script
//! sources (CDPR-Modding-Documentation/Cyberpunk-Scripts), Codeware's scripts
//! and small stubs for Codeware's native classes, without a game bundle.
//!
//! Built in CI as an example of the redscript-redmod-adapter crate
//! (redscript v1.0.2). It reuses the adapter's corpus pipeline:
//! game `.script` files are parsed with the REDmod parser, the mod and its
//! dependencies with the community parser, and everything is checked together.
//! Only diagnostics located in the mod's files are reported.
//!
//! Usage: mh_check <game-scripts-dir> <mod-dir> [dependency-dir ...]
use std::collections::HashSet;
use std::path::{Path, PathBuf};
use std::process::ExitCode;
use std::{env, fs, io};

use redscript_community_ast::{FileId, SourceMap};
use redscript_compiler_api::SourceMapExt;
use redscript_compiler_frontend::{
    CompileErrorReporter, DiagnosticLevel, Symbols, TypeInterner, parse_file,
};
use redscript_redmod_adapter::{parse_file_with_metadata, process_sources};

fn discover(root: &Path, ext: &str, out: &mut Vec<PathBuf>) -> io::Result<()> {
    for entry in fs::read_dir(root)? {
        let entry = entry?;
        let kind = entry.file_type()?;
        let path = entry.path();
        if kind.is_dir() {
            discover(&path, ext, out)?;
        } else if path
            .extension()
            .and_then(|e| e.to_str())
            .is_some_and(|e| e.eq_ignore_ascii_case(ext))
        {
            out.push(path);
        }
    }
    Ok(())
}

fn load(sources: &SourceMap, root: &Path, ext: &str) -> io::Result<Vec<FileId>> {
    let mut paths = Vec::new();
    discover(root, ext, &mut paths)?;
    paths.sort();
    let mut ids = Vec::new();
    for path in paths {
        let source = fs::read_to_string(&path)
            .map_err(|err| io::Error::other(format!("{}: {err}", path.display())))?;
        ids.push(sources.push_back(path, source));
    }
    Ok(ids)
}

fn main() -> Result<ExitCode, Box<dyn std::error::Error>> {
    let args: Vec<PathBuf> = env::args_os().skip(1).map(PathBuf::from).collect();
    if args.len() < 2 {
        return Err("usage: mh_check <game-scripts-dir> <mod-dir> [dependency-dir ...]".into());
    }

    let sources = SourceMap::new();
    let boot = sources.populate_boot_lib();
    let game = load(&sources, &args[0], "script")?;
    let mod_files = load(&sources, &args[1], "reds")?;
    let mut deps = Vec::new();
    for dir in &args[2..] {
        deps.extend(load(&sources, dir, "reds")?);
    }
    let mod_set: HashSet<FileId> = mod_files.iter().copied().collect();
    println!(
        "loaded: {} game scripts, {} mod files, {} dependency files",
        game.len(),
        mod_files.len(),
        deps.len()
    );

    let interner = TypeInterner::default();
    let mut reporter = CompileErrorReporter::default();
    let mut community = Vec::new();
    for id in std::iter::once(boot).chain(deps.iter().copied()).chain(mod_files.iter().copied()) {
        let file = sources.get(id).expect("loaded file");
        if let Some(module) = parse_file(id, file, &mut reporter) {
            community.push(module);
        }
    }

    let mut modules = Vec::new();
    let mut excluded = Vec::new();
    for &id in &game {
        let file = sources.get(id).expect("loaded file");
        let (parsed, errors) = parse_file_with_metadata(file.source(), id);
        if errors.is_empty()
            && let Some(parsed) = parsed
        {
            modules.push(parsed);
        } else {
            let first = errors.first().map(ToString::to_string).unwrap_or_default();
            excluded.push(format!("{}: {first}", file.path().display()));
        }
    }
    println!(
        "game scripts: {} processed, {} excluded (unsupported syntax)",
        modules.len(),
        excluded.len()
    );
    for line in excluded.iter().take(40) {
        println!("  excluded {line}");
    }

    let (_unit, _symbols, _adapter_errors) = process_sources(
        modules,
        community,
        Symbols::with_default_types(),
        &mut reporter,
        &interner,
    );

    // Known checker artifacts (not errors for the real compiler with a game bundle):
    // * UNSUPPORTED_NATIVE_CONVERSION: the game's `cast` declarations come from REDmod
    //   sources here, so ordinary `Cast<Float>(i)` / `Cast<StatsObjectID>(id)` are
    //   rejected by the REDmod dialect policy.
    // * Codeware's `@addMethod`/`@addField` on game classes (GameInstance statics,
    //   MappinSystem.GetAllMappins, FxResource.effect) are not registered on
    //   source-defined game classes.
    // Locals declared on an artifact line produce follow-up UNRESOLVED_REF errors;
    // those are suppressed too.
    const CODEWARE_MEMBERS: &[&str] = &[
        "`FxResource` has no member named `effect`",
        "`MappinSystem` has no member named `GetAllMappins`",
    ];
    struct Item {
        file: FileId,
        line: usize,
        code: String,
        text: String,
        location: String,
        is_error: bool,
    }
    let mut items = Vec::new();
    let mut other_errors = 0;
    for diagnostic in reporter.reported() {
        let in_mod = mod_set.contains(&diagnostic.span().file);
        let is_error = matches!(
            diagnostic.level(),
            DiagnosticLevel::Error | DiagnosticLevel::ErrorAllowedAtRuntime
        );
        if !in_mod {
            if is_error {
                other_errors += 1;
            }
            continue;
        }
        if diagnostic.level() == DiagnosticLevel::Pedantic {
            continue;
        }
        // Game classes come from sources here (not from a bundle), so patching
        // them looks like "modifying a user-defined symbol". Not a real error.
        if diagnostic.code() == "INVALID_ANN_USE" {
            continue;
        }
        let span = diagnostic.span();
        let (location, line) = sources
            .get(span.file)
            .map(|file| {
                let loc = file.lookup(span.start);
                let name = file
                    .path()
                    .file_name()
                    .map(|n| n.to_string_lossy().into_owned())
                    .unwrap_or_default();
                (format!("{name}:{}:{}", loc.line + 1, loc.col + 1), loc.line)
            })
            .unwrap_or_default();
        items.push(Item {
            file: span.file,
            line,
            code: diagnostic.code().to_string(),
            text: diagnostic.to_string().replace('\n', " "),
            location,
            is_error,
        });
    }

    let is_artifact = |item: &Item| {
        item.code == "UNSUPPORTED_NATIVE_CONVERSION"
            || (item.code == "UNRESOLVED_REF" && item.text.contains("`GameInstance` is not defined"))
            || (item.code == "UNRESOLVED_MEMBER"
                && CODEWARE_MEMBERS.iter().any(|m| item.text.contains(m)))
    };
    // Locals declared on an artifact (or cascade) line; repeated until nothing changes
    // so chains like `let ink = ...; let layer = ink.GetLayer(...)` are covered.
    let declared = |item: &Item| -> Option<String> {
        let file = sources.get(item.file)?;
        let text = file.source().lines().nth(item.line)?;
        let rest = text.trim_start().strip_prefix("let ")?;
        let name: String = rest
            .chars()
            .take_while(|c| c.is_alphanumeric() || *c == '_')
            .collect();
        (!name.is_empty()).then_some(name)
    };
    let is_cascade = |item: &Item, poisoned: &HashSet<(FileId, String)>| {
        item.code == "UNRESOLVED_REF"
            && poisoned
                .iter()
                .any(|(f, n)| *f == item.file && item.text.contains(&format!("`{n}` is not defined")))
    };
    let mut poisoned: HashSet<(FileId, String)> = HashSet::new();
    loop {
        let before = poisoned.len();
        for item in &items {
            if (is_artifact(item) || is_cascade(item, &poisoned))
                && let Some(name) = declared(item)
            {
                poisoned.insert((item.file, name));
            }
        }
        if poisoned.len() == before {
            break;
        }
    }
    let mut artifacts = 0;
    let mut errors = 0;
    let mut warnings = 0;
    for item in &items {
        let cascade = is_cascade(item, &poisoned);
        let line = format!("{} {} {}", item.location, item.code, item.text);
        if is_artifact(item) || cascade {
            artifacts += 1;
            println!("[ARTIFACT] {line}");
        } else if item.is_error {
            errors += 1;
            println!("[ERROR] {line}");
        } else {
            warnings += 1;
            println!("[WARN] {line}");
        }
    }
    println!(
        "mod: {errors} errors, {warnings} warnings, {artifacts} known checker artifacts (outside the mod: {other_errors} errors, ignored)"
    );
    Ok(if errors > 0 { ExitCode::FAILURE } else { ExitCode::SUCCESS })
}
