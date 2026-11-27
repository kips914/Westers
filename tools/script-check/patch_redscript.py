#!/usr/bin/env python3
"""Make the redscript frontend tolerate spanless declarations.

Fields/params bridged from the REDmod game sources or Codeware's generated
imports can lack a source span; the frontend expects user declarations to
have one and panics. For a diagnostics-only check we simply skip them.
Usage: patch_redscript.py <redscript-source-root>
"""
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
path = root / "crates/compiler/frontend/src/stages/resolution/validation.rs"
src = path.read_text()
src, n1 = re.subn(r'let span = field\.span\(\)\.expect\("user field should have a span"\);',
                  'let Some(span) = field.span() else { continue };', src)
src, n2 = re.subn(r'let span = param\s*\.span\(\)\s*\.expect\("user function param should have a span"\);',
                  'let Some(span) = param.span() else { continue };', src)
src, n3 = re.subn(r'for field in module\.fields\(\) \{\s*let field = &self\.symbols\[\*field\.id\(\)\];',
                  'for field in module.fields() {\n            let Some((_, field)) = self.symbols.get_field(*field.id()) else { continue };', src)
path.write_text(src)
print(f"patched: {n3} module field lookups")

infer = root / "crates/compiler/frontend/src/stages/infer.rs"
src = infer.read_text()
src, n4 = re.subn(r'(FuncItemKind::AddMethod\(func\) => \{\s*)if !symbols\[func\.id\]\.type_\(\)\.is_valid\(\) \{',
                  r'\1if symbols.get_method(func.id).is_none_or(|(_, m)| !m.type_().is_valid()) {', src)
infer.write_text(src)
print(f"patched: {n4} add-method lookups")

# REDmod authoring checks (overrides / persistent fields of the game files) are
# irrelevant here and index symbols that duplicate Codeware additions removed.
lib = root / "crates/compiler/redmod/adapter/src/lib.rs"
src = lib.read_text()
src, n5 = re.subn(r'\n(\s*)validate::overrides\(&unit, &symbols, &files, &overrides, &mut errors\);\n\s*persistent::validate\(&unit, &symbols, &files, &mut errors\);',
                  r'\n\1std::hint::black_box((&overrides, &files));', src, count=1)
lib.write_text(src)
print(f"patched: {n5} adapter validations skipped")
print(f"patched: {n1} field spans, {n2} param spans")
if n1 == 0 and n2 == 0:
    sys.exit(1)
