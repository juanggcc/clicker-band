#!/usr/bin/env python3
"""Generate flat placeholder sprites on the exact canvases the real art must use.

Every character part is drawn on the same 700x900 canvas, so the artist delivers
layers of a single master drawing and the scene needs no offsets. Replace any PNG
with real art of the same name and size; nothing else changes.
Pure standard library; run from anywhere:  python3 tools/gen_placeholders.py
"""
from __future__ import annotations

import math
import struct
import zlib
from pathlib import Path

ASSETS = Path(__file__).resolve().parent.parent / "game" / "assets"
Color = tuple[int, int, int, int]

CHARACTER_CANVAS = (700, 900)
BACKGROUND_CANVAS = (2400, 1080)

# Joint positions on the character canvas. The Godot scene pivots on these same numbers.
JOINTS = {
    "hips": (355, 560),
    "neck": (358, 266),
    "shoulder_fret": (462, 300),
    "elbow_strum": (258, 404),
}

OUTLINE: Color = (30, 26, 28, 255)
SKIN: Color = (232, 190, 160, 255)
CAP: Color = (28, 28, 32, 255)
HAIR: Color = (22, 20, 24, 255)
TEE: Color = (58, 58, 64, 255)
JEANS: Color = (86, 118, 160, 255)
SHOE: Color = (236, 230, 214, 255)
GUITAR: Color = (240, 232, 210, 255)
PICKGUARD: Color = (120, 30, 36, 255)
WOOD: Color = (70, 48, 36, 255)
WALL: Color = (96, 116, 140, 255)
FLOOR: Color = (150, 112, 78, 255)
WINDOW: Color = (230, 200, 120, 255)
BED: Color = (190, 140, 70, 255)
AMP: Color = (40, 36, 34, 255)
NOTE: Color = (255, 190, 73, 255)
TRANSPARENT: Color = (0, 0, 0, 0)


class Canvas:
    def __init__(self, size: tuple[int, int], background: Color = TRANSPARENT) -> None:
        self.w, self.h = size
        self.px = bytearray(bytes(background) * (self.w * self.h))

    def _row_fill(self, y: int, x0: int, x1: int, c: Color) -> None:
        x0, x1 = max(0, x0), min(self.w, x1)
        if y < 0 or y >= self.h or x1 <= x0:
            return
        start = (y * self.w + x0) * 4
        self.px[start : start + (x1 - x0) * 4] = bytes(c) * (x1 - x0)

    def rect(self, x0: int, y0: int, x1: int, y1: int, c: Color, outline: int = 0) -> None:
        if outline:
            self.rect(x0 - outline, y0 - outline, x1 + outline, y1 + outline, OUTLINE)
        for y in range(y0, y1):
            self._row_fill(y, x0, x1, c)

    def ellipse(self, cx: float, cy: float, rx: float, ry: float, c: Color, outline: int = 0) -> None:
        if outline:
            self.ellipse(cx, cy, rx + outline, ry + outline, OUTLINE)
        for y in range(int(cy - ry), int(cy + ry) + 1):
            dy = (y - cy) / ry
            if abs(dy) > 1:
                continue
            half = rx * math.sqrt(1 - dy * dy)
            self._row_fill(y, int(cx - half), int(cx + half) + 1, c)

    def segment(self, a: tuple[float, float], b: tuple[float, float], width: float, c: Color, outline: int = 0) -> None:
        if outline:
            self.segment(a, b, width + 2 * outline, OUTLINE)
        (ax, ay), (bx, by) = a, b
        r = width / 2
        length_sq = (bx - ax) ** 2 + (by - ay) ** 2 or 1.0
        for y in range(int(min(ay, by) - r), int(max(ay, by) + r) + 1):
            for x in range(int(min(ax, bx) - r), int(max(ax, bx) + r) + 1):
                t = max(0.0, min(1.0, ((x - ax) * (bx - ax) + (y - ay) * (by - ay)) / length_sq))
                px, py = ax + t * (bx - ax), ay + t * (by - ay)
                if (x - px) ** 2 + (y - py) ** 2 <= r * r:
                    self._row_fill(y, x, x + 1, c)

    def save(self, path: Path) -> None:
        stride = self.w * 4
        raw = b"".join(b"\x00" + bytes(self.px[y * stride : (y + 1) * stride]) for y in range(self.h))
        ihdr = struct.pack(">IIBBBBB", self.w, self.h, 8, 6, 0, 0, 0)
        png = b"\x89PNG\r\n\x1a\n" + _chunk(b"IHDR", ihdr) + _chunk(b"IDAT", zlib.compress(raw, 9)) + _chunk(b"IEND", b"")
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(png)
        print(f"wrote {path} ({self.w}x{self.h})")


def _chunk(tag: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def protagonist() -> dict[str, Canvas]:
    parts: dict[str, Canvas] = {}
    neck_x, neck_y = JOINTS["neck"]
    shoulder = JOINTS["shoulder_fret"]
    elbow = JOINTS["elbow_strum"]

    head = Canvas(CHARACTER_CANVAS)
    head.rect(neck_x - 22, neck_y - 10, neck_x + 22, neck_y + 40, SKIN, outline=3)
    head.ellipse(neck_x, 165, 92, 100, HAIR, outline=3)
    head.ellipse(neck_x, 180, 78, 88, SKIN, outline=3)
    head.ellipse(neck_x, 118, 92, 48, CAP, outline=3)
    head.rect(neck_x - 10, 124, neck_x + 130, 146, CAP, outline=3)
    head.ellipse(neck_x + 30, 190, 7, 9, OUTLINE)
    parts["head"] = head

    torso = Canvas(CHARACTER_CANVAS)
    torso.rect(272, 236, 428, 545, TEE, outline=3)
    torso.ellipse(292, 262, 32, 30, TEE, outline=3)
    torso.ellipse(408, 262, 32, 30, TEE, outline=3)
    torso.rect(272, 236, 428, 545, TEE)
    parts["torso"] = torso

    legs = Canvas(CHARACTER_CANVAS)
    legs.rect(282, 500, 342, 872, JEANS, outline=3)
    legs.rect(358, 500, 418, 872, JEANS, outline=3)
    legs.ellipse(312, 878, 44, 20, SHOE, outline=3)
    legs.ellipse(392, 878, 44, 20, SHOE, outline=3)
    parts["legs"] = legs

    arm_fret = Canvas(CHARACTER_CANVAS)
    arm_fret.segment(shoulder, (640, 390), 42, SKIN, outline=3)
    arm_fret.segment(shoulder, (472, 312), 52, TEE, outline=3)
    arm_fret.ellipse(642, 392, 26, 22, SKIN, outline=3)
    parts["arm_fret"] = arm_fret

    arm_strum = Canvas(CHARACTER_CANVAS)
    arm_strum.segment(elbow, (345, 482), 40, SKIN, outline=3)
    arm_strum.ellipse(348, 486, 24, 20, SKIN, outline=3)
    arm_strum.ellipse(364, 498, 8, 10, NOTE, outline=2)
    parts["arm_strum"] = arm_strum

    guitar = Canvas(CHARACTER_CANVAS)
    guitar.segment((430, 455), (690, 398), 34, WOOD, outline=3)
    guitar.ellipse(694, 396, 22, 30, WOOD, outline=3)
    guitar.ellipse(340, 468, 125, 92, GUITAR, outline=3)
    guitar.ellipse(300, 420, 70, 60, GUITAR, outline=3)
    guitar.ellipse(340, 468, 125, 92, GUITAR)
    guitar.ellipse(355, 478, 70, 48, PICKGUARD, outline=3)
    parts["guitar"] = guitar
    return parts


def bedroom() -> Canvas:
    bg = Canvas(BACKGROUND_CANVAS, WALL)
    bg.rect(0, 760, 2400, 1080, FLOOR)
    bg.rect(0, 750, 2400, 768, OUTLINE)
    bg.rect(1500, 160, 1900, 520, WINDOW, outline=6)
    bg.rect(1696, 160, 1704, 520, OUTLINE)
    bg.rect(1500, 336, 1900, 344, OUTLINE)
    bg.rect(400, 170, 560, 390, PICKGUARD, outline=5)
    bg.rect(1200, 600, 1850, 820, BED, outline=6)
    bg.rect(1200, 560, 1230, 820, WOOD, outline=4)
    bg.rect(1000, 640, 1180, 820, AMP, outline=5)
    bg.rect(1020, 690, 1160, 800, WOOD)
    return bg


def note() -> Canvas:
    n = Canvas((96, 96))
    n.ellipse(36, 66, 24, 18, NOTE, outline=3)
    n.rect(54, 12, 64, 66, NOTE, outline=3)
    n.segment((59, 14), (84, 32), 12, NOTE, outline=3)
    return n


def main() -> None:
    for name, canvas in protagonist().items():
        canvas.save(ASSETS / "characters" / "protagonist" / f"{name}.png")
    bedroom().save(ASSETS / "backgrounds" / "bedroom.png")
    note().save(ASSETS / "ui" / "note.png")


if __name__ == "__main__":
    main()
