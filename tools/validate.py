#!/usr/bin/env python3
"""Static sanity checks for the mod sources (runs in CI before packing).

* brace / bracket balance in .tweak, .reds and .lua files
* every LocKey#MilitechHope-* used in tweaks is defined for every language
* inkatlas JSON is valid and points at the texture we import
* the raw icon exists and is a 512x512 RGBA PNG
"""
from __future__ import annotations

import json
import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []


def strip_comments(text: str, line_comment: str) -> str:
    text = re.sub(r'"(?:\\.|[^"\\])*"', '""', text)  # drop string contents
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return "\n".join(line.split(line_comment, 1)[0] for line in text.splitlines())


def check_balance(path: Path, line_comment: str) -> None:
    text = strip_comments(path.read_text(encoding="utf-8"), line_comment)
    pairs = {")": "(", "]": "[", "}": "{"}
    stack: list[tuple[str, int]] = []
    for lineno, line in enumerate(text.splitlines(), 1):
        for ch in line:
            if ch in "([{":
                stack.append((ch, lineno))
            elif ch in pairs:
                if not stack or stack[-1][0] != pairs[ch]:
                    errors.append(f"{path.relative_to(ROOT)}:{lineno}: unbalanced '{ch}'")
                    return
                stack.pop()
    if stack:
        errors.append(f"{path.relative_to(ROOT)}:{stack[-1][1]}: unclosed '{stack[-1][0]}'")


def main() -> int:
    src = ROOT / "src"
    for p in src.rglob("*.tweak"):
        check_balance(p, "//")
    for p in src.rglob("*.reds"):
        check_balance(p, "//")
    for p in src.rglob("*.lua"):
        check_balance(p, "--")

    # localization keys
    tweak_text = "\n".join(p.read_text(encoding="utf-8") for p in src.rglob("*.tweak"))
    reds_text = "\n".join(p.read_text(encoding="utf-8") for p in src.rglob("*.reds"))
    used = set(re.findall(r"LocKey#(MilitechHope-[\w-]+)", tweak_text))
    used |= set(re.findall(r'n"(MilitechHope-[\w-]+)"', reds_text))
    loc = (src / "r6/scripts/MilitechHope/Localization.reds").read_text(encoding="utf-8")
    packages = re.split(r"public class \w+ extends ModLocalizationPackage", loc)[1:]
    if not packages:
        errors.append("Localization.reds: no localization packages found")
    for i, body in enumerate(packages):
        defined = set(re.findall(r'this\.Text\("([^"]+)"', body))
        for key in sorted(used - defined):
            errors.append(f"Localization package #{i + 1}: missing text for {key}")

    # inkatlas
    atlas = ROOT / "source/archive/militech_hope/icons/militech_hope_sandevistan.inkatlas.json"
    data = json.loads(atlas.read_text(encoding="utf-8"))
    slot = data["Data"]["RootChunk"]["slots"]["Elements"][0]
    depot = slot["texture"]["DepotPath"]["$value"]
    if depot != "militech_hope\\icons\\militech_hope_sandevistan.xbm":
        errors.append(f"inkatlas points to unexpected texture {depot}")
    if slot["parts"][0]["partName"]["$value"] != "custom_icon":
        errors.append("inkatlas part must be named custom_icon")
    if 'atlasResourcePath = "militech_hope\\\\icons\\\\militech_hope_sandevistan.inkatlas"' not in tweak_text:
        errors.append("UIIcon record does not point at the packed inkatlas")

    # icon
    png = ROOT / "source/raw/militech_hope/icons/militech_hope_sandevistan.png"
    head = png.read_bytes()[:33]
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        errors.append("icon is not a PNG")
    else:
        w, h, depth, color = struct.unpack(">IIBB", head[16:26])
        if (w, h) != (512, 512) or color != 6:
            errors.append(f"icon must be 512x512 RGBA, got {w}x{h} color type {color}")

    if errors:
        print("Validation failed:")
        for e in errors:
            print("  -", e)
        return 1
    print(f"OK: {len(used)} localization keys, sources balanced, icon and atlas valid")
    return 0


if __name__ == "__main__":
    sys.exit(main())
