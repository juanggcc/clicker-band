#!/usr/bin/env python3
"""Export the HUD's geometric pixel vocabulary as transparent shop UI sprites.

Uses the existing standard-library PNG writer. Does not alter gameplay or the HUD.
The illustrated pick is supplied separately by imagegen and is never overwritten.
Run: python3 tools/art/build_shop_ui.py
"""
from __future__ import annotations

import hashlib
import json
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.dont_write_bytecode = True
sys.path.insert(0, str(ROOT / "tools"))
from gen_placeholders import Canvas  # noqa: E402

OUT = ROOT / "game/assets/ui/shop/v1"
DESIGN = ROOT / "docs/art/2026-10-21-shop"
PALETTE = {
    "ink": "111923", "face": "202b35", "inset": "16212b",
    "rim": "52606b", "edge": "71808a", "muted": "a8b4b8",
    "cream": "f6efdb", "mint": "8ed8b1", "mint_light": "c5eed3",
    "mint_shadow": "548e75", "gold": "f4ca78", "coral": "f28f76",
    "disabled": "34434b",
}
ASSETS: dict[str, dict] = {}


def color(name: str) -> tuple[int, int, int, int]:
    value = PALETTE.get(name, name)
    return tuple(bytes.fromhex(value)) + (255,)


def export(name: str, source: Canvas, scale: int, role: str, margins: list[int] | None = None) -> None:
    result = Canvas((source.w * scale, source.h * scale))
    for y in range(source.h):
        for x in range(source.w):
            start = (y * source.w + x) * 4
            rgba = tuple(source.px[start:start + 4])
            result.rect(x * scale, y * scale, (x + 1) * scale, (y + 1) * scale, rgba)
    result.save(OUT / name)
    entry = {"size": [result.w, result.h], "logical_size": [source.w, source.h], "pixel_scale": scale,
             "role": role, "alpha": "binary", "filter": "nearest"}
    if margins:
        entry["nine_patch_margins_ltrb"] = [v * scale for v in margins]
    ASSETS[name] = entry


def cut_rect(c: Canvas, a: int, b: int, end_x: int, end_y: int, fill: str, cut: int = 2) -> None:
    tint = color(fill)
    c.rect(a + cut, b, end_x - cut, end_y, tint)
    c.rect(a, b + cut, end_x, end_y - cut, tint)


def frame(name: str, face: str, rim: str = "rim", highlight: str = "edge", accent: str | None = None) -> None:
    c = Canvas((24, 24))
    cut_rect(c, 0, 0, 24, 24, "ink", 2)
    cut_rect(c, 1, 1, 23, 23, rim, 2)
    cut_rect(c, 2, 2, 22, 22, face, 1)
    c.rect(4, 2, 20, 3, color(highlight))
    if accent:
        c.rect(5, 2, 10, 3, color(accent))
    export(name, c, 3, "Scalable pixel panel; tile/stretch the center, preserve 18 px corners.", [6, 6, 6, 6])


def button(state: str, face: str, rim: str, light: str, bottom: str) -> None:
    c = Canvas((24, 24))
    cut_rect(c, 0, 0, 24, 24, "ink", 2)
    cut_rect(c, 1, 1, 23, 23, rim, 2)
    cut_rect(c, 2, 2, 22, 21, face, 1)
    c.rect(3, 3, 21, 4, color(light))
    c.rect(3, 21, 21, 23, color(bottom))
    if state == "pressed":
        c.rect(3, 2, 21, 4, color(bottom))
        c.rect(3, 21, 21, 22, color(light))
    export(f"button_primary_{state}.png", c, 3, f"Purchase button: {state}; keep text as live UI.", [6, 6, 6, 8])


def shop_icon(tint: str) -> Canvas:
    c = Canvas((24, 24))
    ink = color(tint)
    # Broad roof and scalloped awning distinguish this from the room's house outline.
    c.rect(10, 3, 14, 4, ink)
    c.rect(8, 4, 16, 5, ink)
    c.rect(6, 5, 18, 6, ink)
    c.rect(4, 6, 20, 8, ink)
    c.rect(3, 8, 21, 10, ink)
    for x in (3, 7, 11, 15, 19):
        c.rect(x, 10, x + 2, 12, ink)
    c.rect(5, 12, 19, 21, ink)
    c.rect(9, 15, 14, 21, (0, 0, 0, 0))
    c.rect(6, 13, 8, 16, (0, 0, 0, 0))
    c.rect(16, 13, 18, 16, (0, 0, 0, 0))
    return c


def small_icon(name: str, rows: list[str], tint: str = "cream", scale: int = 3) -> None:
    c = Canvas((len(rows[0]), len(rows)))
    for y, row in enumerate(rows):
        for x, cell in enumerate(row):
            if cell != ".":
                c.rect(x, y, x + 1, y + 1, color(tint if cell == "#" else "ink"))
    export(name, c, scale, "Transparent geometric icon matching the existing HUD pixel vocabulary.")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    DESIGN.mkdir(parents=True, exist_ok=True)
    frame("panel_frame.png", "face")
    frame("item_frame.png", "inset", "disabled", "rim")
    frame("item_slot.png", "ink", "disabled", "rim")
    frame("button_secondary.png", "face", "rim", "edge")
    button("normal", "mint", "mint_shadow", "mint_light", "mint_shadow")
    button("hover", "mint_light", "mint", "cream", "mint_shadow")
    button("pressed", "mint_shadow", "mint_shadow", "mint", "disabled")
    button("disabled", "disabled", "rim", "rim", "ink")
    export("icon_shop.png", shop_icon("cream"), 3, "Shop access: filled roof/awning silhouette, 24 px source.")
    export("icon_shop_active.png", shop_icon("mint"), 3, "Shop access: mint selected/available variant.")
    export("icon_shop_disabled.png", shop_icon("edge"), 3, "Shop access: muted variant.")
    export("icon_shop_24.png", shop_icon("cream"), 1, "Native 24x24 source, for integer-scaled layouts.")
    small_icon("icon_close.png", [
        "............", "............", "..##....##..", "..###..###..", "...######...", "....####....",
        "....####....", "...######...", "..###..###..", "..##....##..", "............", "............",
    ])
    small_icon("icon_arrow.png", [
        "........", "...##...", "....##..", ".######.", ".######.", "....##..", "...##...", "........",
    ])
    small_icon("icon_check.png", [
        "............", "............", ".........##.", "........###.", ".......###..", "..##..###...",
        "..######....", "...####.....", "....##......", "............", "............", "............",
    ], "mint")
    small_icon("icon_lock.png", [
        "............", "....####....", "...######...", "...##..##...", "...##..##...", "..########..",
        "..########..", "..###..###..", "..###..###..", "..########..", "............", "............",
    ], "muted")
    small_icon("icon_coin.png", [
        "..#####..", ".#######.", "###222###", "##22#2###", "##2#2#2##", "##2#22###", "###222###", ".#######.", "..#####..",
    ], "gold", 4)
    # The base pick is a small monochrome interface glyph, not the illustrated upgrade sprite.
    small_icon("icon_pick_basic.png", [
        "................", "................", "....########....", "...##########...",
        "..############..", "..############..", "..############..", "...##########...",
        "...##########...", "....########....", ".....######.....", "......####......",
        ".......##.......", "................", "................", "................",
    ], "cream", 3)
    manifest = {
        "version": 1, "style": "Clicker Band / pixel amplifier HUD", "palette": {k: "#" + v for k, v in PALETTE.items()},
        "assets": ASSETS, "font": "res://assets/fonts/silkscreen/Silkscreen-Regular.ttf",
        "integration": {"filter": "nearest", "mipmaps": False, "ui_grid_px": 3,
                        "reference_viewport": [1920, 1080], "text_is_live": True,
                        "scope": "Design assets only. Prices and upgrade effects in the mockup are examples."},
    }
    pick = OUT / "pick_upgrade.png"
    if pick.exists():
        width, height = struct.unpack_from(">II", pick.read_bytes(), 16)
        manifest["assets"][pick.name] = {
            "size": [width, height], "role": "Amber guitar pick with embossed musical note; illustrated upgrade item.",
            "alpha": "RGBA; true transparency", "filter": "nearest", "display_box_reference_px": [216, 219],
            "source": "Built-in image_gen.imagegen; prompt in source/imagegen-pick-prompt.txt",
            "note": "Illustrated pixel-style sprite; not constrained to the geometric UI sprites' exact palette or native grid.",
        }
    for filename, entry in manifest["assets"].items():
        data = (OUT / filename).read_bytes()
        entry["bytes"] = len(data)
        entry["sha256"] = hashlib.sha256(data).hexdigest()
    manifest["total_png_bytes"] = sum(entry["bytes"] for entry in manifest["assets"].values())
    manifest["theme_resource"] = "res://assets/ui/shop/v1/shop_theme.tres"
    (DESIGN / "sprite-manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    print(f"Available {len(ASSETS)} sprites; total {sum((OUT / p).stat().st_size for p in ASSETS):,} bytes")


if __name__ == "__main__":
    main()
