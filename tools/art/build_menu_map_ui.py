#!/usr/bin/env python3
"""Pixel menu/map glyphs using the shop's exact palette and 3 px grid.

Run from the repository root: python3 tools/art/build_menu_map_ui.py
Only writes its five new glyphs and their source/manifest; leaves shop art alone.
"""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from gen_placeholders import Canvas
from build_shop_ui import PALETTE, color

DESIGN = ROOT / "docs/art/2026-10-21-menu-map"
ASSETS = ROOT / "game/assets/ui"
ENTRIES = {}


def polygon(canvas: Canvas, points: list[tuple[int, int]], tint: tuple) -> None:
    """Aliased fill at native resolution; all exports use integer nearest scaling."""
    for y in range(canvas.h):
        for x in range(canvas.w):
            inside = False
            a, b = points[-1]
            for c, d in points:
                if (b > y + 0.5) != (d > y + 0.5):
                    if x + 0.5 < (c - a) * (y + 0.5 - b) / (d - b) + a:
                        inside = not inside
                a, b = c, d
            if inside:
                canvas.rect(x, y, x + 1, y + 1, tint)


def export(path: str, canvas: Canvas, role: str, conditional: str | None = None) -> None:
    target = ASSETS / path
    scaled = Canvas((canvas.w * 3, canvas.h * 3))
    for y in range(canvas.h):
        for x in range(canvas.w):
            i = (y * canvas.w + x) * 4
            scaled.rect(x * 3, y * 3, (x + 1) * 3, (y + 1) * 3, tuple(canvas.px[i:i + 4]))
    scaled.save(target)
    source = DESIGN / "source" / (target.stem + "_native.png")
    canvas.save(source)
    ENTRIES[target.relative_to(ROOT).as_posix()] = {
        "size": [scaled.w, scaled.h], "native_size": [canvas.w, canvas.h],
        "pixel_scale": 3, "alpha": "binary", "filter": "nearest", "mipmaps": False,
        "role": role, "conditional_use": conditional,
        "source": source.relative_to(ROOT).as_posix(),
        "sha256": hashlib.sha256(target.read_bytes()).hexdigest(),
    }


def main() -> None:
    cream, clear = color("cream"), (0, 0, 0, 0)
    c = Canvas((24, 24))
    polygon(c, [(3, 6), (9, 3), (15, 6), (21, 3), (21, 18), (15, 21), (9, 18), (3, 21)], cream)
    polygon(c, [(5, 7), (8, 6), (8, 16), (5, 18)], clear)
    polygon(c, [(10, 6), (14, 8), (14, 18), (10, 16)], clear)
    polygon(c, [(16, 8), (19, 6), (19, 17), (16, 18)], clear)
    export("menu/v1/icon_map.png", c, "Folded three-panel map; MAPA menu tile.")

    c = Canvas((24, 24))
    for y in (5, 10, 15):
        c.rect(4, y, 20, y + 3, cream)
    export("menu/v1/icon_menu.png", c, "Three-bar general menu glyph; matches the existing HUD bars.",
           "Use if the shop/house glyph becomes TIENDA and the corner button opens the general menu.")

    c = Canvas((24, 24))
    # Eight separated teeth, with visible notches even at small HUD scale.
    polygon(c, [(10, 2), (14, 2), (14, 5), (16, 6), (18, 4), (20, 6),
                (18, 8), (19, 10), (22, 10), (22, 14), (19, 14), (18, 16),
                (20, 18), (18, 20), (16, 18), (14, 19), (14, 22), (10, 22),
                (10, 19), (8, 18), (6, 20), (4, 18), (6, 16), (5, 14),
                (2, 14), (2, 10), (5, 10), (6, 8), (4, 6), (6, 4),
                (8, 6), (10, 5)], cream)
    c.rect(9, 8, 15, 16, clear)
    c.rect(8, 9, 16, 15, clear)
    export("menu/v1/icon_settings.png", c, "Eight-tooth settings gear; AJUSTES menu tile.",
           "Use if the pause/options action is consolidated into the general menu.")

    c = Canvas((12, 12))
    rows = ["............", "....####....", "...######...", "..########..",
            "..###..###..", "..###..###..", "..########..", "...######...",
            "....####....", ".....##.....", ".....##.....", "............"]
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == "#":
                c.rect(x, y, x + 1, y + 1, color("mint"))
    export("map/v1/icon_pin.png", c, "Mint current-location pin; place beside live ESTÁS AQUÍ text.")

    c = Canvas((12, 12))
    rows = ["............", "....####....", "..########..", ".##########.",
            ".##########.", "..########..", "...######...", ".....##.....",
            ".....##.....", ".....##.....", "...######...", "............"]
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == "#":
                c.rect(x, y, x + 1, y + 1, color("mint"))
    export("map/v1/icon_place_park.png", c, "Mint broadleaf tree; 36 px place marker matching the bedroom house.")

    manifest = {
        "version": 1, "style": "Clicker Band / existing pixel amplifier HUD",
        "palette": {k: "#" + v for k, v in PALETTE.items()},
        "assets": ENTRIES,
        "reused": ["shop/v1/icon_shop.png", "shop/v1/icon_lock.png", "shop/v1/icon_coin.png",
                   "shop/v1/icon_arrow.png", "shop/v1/item_frame.png", "shop/v1/item_slot.png"],
        "text_is_live": True,
    }
    DESIGN.mkdir(parents=True, exist_ok=True)
    (DESIGN / "icon-manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")


if __name__ == "__main__":
    main()
