#!/usr/bin/env python3
"""Build the inventory icons of the six Sandevistan upgrade modules.

Usage:  python tools/make_module_icons.py
Needs:  pip install pillow numpy scipy

Input : assets/modules/raw/<name>.png   (renders on a flat #00FF00 chroma background)
Output: source/raw/militech_hope/icons/militech_hope_mod_<name>.png          (160x160 RGBA)
        source/archive/militech_hope/icons/militech_hope_mod_<name>.inkatlas.json
        assets/modules/preview.png                                         (all icons on a dark background)

Every icon gets its own xbm + inkatlas (same layout as the Sandevistan icon),
part name "custom_icon". The CI imports/deserializes every militech_hope_*.png
and *.inkatlas.json found in those folders.
"""
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage as ndi

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "assets" / "modules" / "raw"
OUT_PNG = ROOT / "source" / "raw" / "militech_hope" / "icons"
OUT_ATLAS = ROOT / "source" / "archive" / "militech_hope" / "icons"
TEMPLATE = OUT_ATLAS / "militech_hope_sandevistan.inkatlas.json"
PREVIEW = ROOT / "assets" / "modules" / "preview.png"

NAMES = ["discharge", "quickcharge", "newbreath", "phaseshield", "berserk", "madness"]
ICON_SIZE = 160
ICON_MARGIN = 0.08


def key_out(path: Path) -> Image.Image:
    a = np.array(Image.open(path).convert("RGB")).astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    # how much greener than the other channels
    green = g - np.maximum(r, b)
    bg = (green > 60) & (g > 120)
    # background = green regions connected to the image border
    lab, _ = ndi.label(bg)
    border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    bg = np.isin(lab, list(border))
    obj = ndi.binary_opening(~bg, iterations=2)
    lab2, n2 = ndi.label(obj)
    if n2:
        sizes = ndi.sum(obj, lab2, range(1, n2 + 1))
        obj = lab2 == (int(np.argmax(sizes)) + 1)
        obj = ndi.binary_fill_holes(obj)
    alpha = Image.fromarray((obj * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2))
    alpha_np = np.array(alpha).astype(np.float32)
    alpha_np[alpha_np < 40] = 0
    # despill: clamp green to the max of red/blue near the edges
    spill = np.clip(g - np.maximum(r, b), 0, None)
    edge = ndi.distance_transform_edt(obj) < 12
    g2 = np.where(edge | (spill > 25), np.minimum(g, np.maximum(r, b) + 8), g)
    rgb = np.stack([r, g2, b], -1).clip(0, 255).astype(np.uint8)
    rgba = Image.fromarray(rgb).convert("RGBA")
    rgba.putalpha(Image.fromarray(alpha_np.astype(np.uint8)))
    return rgba.crop(rgba.getchannel("A").getbbox())


def fit(art: Image.Image) -> Image.Image:
    inner = round(ICON_SIZE * (1 - 2 * ICON_MARGIN))
    scale = inner / max(art.size)
    art = art.resize((max(1, round(art.width * scale)), max(1, round(art.height * scale))), Image.LANCZOS)
    icon = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
    icon.paste(art, ((ICON_SIZE - art.width) // 2, (ICON_SIZE - art.height) // 2))
    return icon


def write_atlas(name: str) -> None:
    text = TEMPLATE.read_text(encoding="utf-8")
    text = text.replace("militech_hope_sandevistan", f"militech_hope_mod_{name}")
    json.loads(text)  # still valid
    (OUT_ATLAS / f"militech_hope_mod_{name}.inkatlas.json").write_text(text, encoding="utf-8")


def main() -> None:
    OUT_PNG.mkdir(parents=True, exist_ok=True)
    preview = Image.new("RGBA", (ICON_SIZE * len(NAMES) + 20 * (len(NAMES) + 1), ICON_SIZE + 40), (20, 24, 32, 255))
    for i, name in enumerate(NAMES):
        icon = fit(key_out(RAW / f"{name}.png"))
        icon.save(OUT_PNG / f"militech_hope_mod_{name}.png")
        write_atlas(name)
        preview.alpha_composite(icon, (20 + i * (ICON_SIZE + 20), 20))
        print(f"icon -> militech_hope_mod_{name}")
    preview.convert("RGB").save(PREVIEW)


if __name__ == "__main__":
    main()
