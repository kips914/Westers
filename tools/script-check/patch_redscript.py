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
path.write_text(src)
print(f"patched: {n1} field spans, {n2} param spans")
if n1 == 0 and n2 == 0:
    sys.exit(1)
