#!/usr/bin/env python3
"""Rebuild the inventory icon from the original screenshot.

Usage:  python tools/make_icon.py
Needs:  pip install pillow numpy scipy

Input : assets/icon_source.png                (screenshot with a baked checkerboard)
Output: source/raw/militech_hope/icons/militech_hope_sandevistan.png  (160x160 RGBA)
        assets/icon_preview.png               (preview on a dark background)
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage as ndi

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "icon_source.png"
OUT = ROOT / "source" / "raw" / "militech_hope" / "icons" / "militech_hope_sandevistan.png"
PREVIEW = ROOT / "assets" / "icon_preview.png"

# Inventory widgets draw the atlas part at its pixel size, so the icon must
# match vanilla cyberware icons (~160x156). A 512 px texture overflows the slot.
ICON_SIZE = 160
ICON_MARGIN = 0.07  # transparent border on every side, fraction of ICON_SIZE


def cut_background() -> Image.Image:
    a = np.array(Image.open(SRC).convert("RGB")).astype(int)[1:877, 1:887]  # drop screenshot frame
    mx, mn = a.max(2), a.min(2)
    sat, lum = mx - mn, a.mean(2)
    bg_like = (sat < 14) & (lum > 224)
    lab, _ = ndi.label(bg_like)
    border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    obj = ndi.binary_opening(~np.isin(lab, list(border)), iterations=1)
    lab2, n2 = ndi.label(obj)
    sizes = ndi.sum(obj, lab2, range(1, n2 + 1))
    keep = np.isin(lab2, [i + 1 for i, s in enumerate(sizes) if s > 400])
    alpha = Image.fromarray((keep * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8))
    rgba = Image.fromarray(a.astype(np.uint8)).convert("RGBA")
    rgba.putalpha(alpha)
    rgba = rgba.crop(alpha.getbbox())
    w, h = rgba.size
    s = max(w, h)
    pad = int(s * 0.04)
    canvas = Image.new("RGBA", (s + 2 * pad, s + 2 * pad), (0, 0, 0, 0))
    canvas.paste(rgba, ((s + 2 * pad - w) // 2, (s + 2 * pad - h) // 2))
    return canvas.resize((512, 512), Image.LANCZOS)


def remove_halo(img: Image.Image) -> Image.Image:
    im = np.array(img).astype(np.int32)
    rgb, a = im[..., :3], im[..., 3]
    mn, mx = rgb.min(-1), rgb.max(-1)
    light = (mn > 185) & ((mx - mn) < 45) & (a > 0)
    bg = a == 0
    lab, _ = ndi.label(light | bg)
    rem = np.isin(lab, np.unique(lab[bg])) & light
    rem &= ndi.distance_transform_edt(~bg) < 14
    im[..., 3][rem] = 0
    alpha = im[..., 3].astype(float)
    edge = (alpha > 0) & ~ndi.binary_erosion(alpha > 0, iterations=1)
    alpha[edge] *= 0.6
    im[..., 3] = alpha.astype(np.int32)
    return Image.fromarray(im.astype(np.uint8))


def fit_to_slot(big: Image.Image) -> Image.Image:
    art = big.crop(big.getchannel("A").getbbox())
    inner = round(ICON_SIZE * (1 - 2 * ICON_MARGIN))
    scale = inner / max(art.size)
    art = art.resize((max(1, round(art.width * scale)), max(1, round(art.height * scale))), Image.LANCZOS)
    icon = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
    icon.paste(art, ((ICON_SIZE - art.width) // 2, (ICON_SIZE - art.height) // 2))
    return icon


def main() -> None:
    big = remove_halo(cut_background())
    icon = fit_to_slot(big)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    icon.save(OUT)
    prev = Image.new("RGBA", big.size, (20, 24, 32, 255))
    prev.alpha_composite(big)
    prev.convert("RGB").save(PREVIEW)
    print(f"icon -> {OUT}")


if __name__ == "__main__":
    main()
