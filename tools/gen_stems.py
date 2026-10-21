#!/usr/bin/env python3
"""Synthesise three placeholder music stems at one tempo and one length.

slow / mid / fast are the same four bars at 120 BPM with growing intensity, so
the game can keep all three playing in sample lock and crossfade between them.
Replace them with real stems of the SAME length and tempo (8.0 s at 120 BPM).
Pure standard library; run from anywhere:  python3 tools/gen_stems.py
"""
from __future__ import annotations

import math
import random
import struct
from collections.abc import Callable
from pathlib import Path

SAMPLE_RATE = 44100
BPM = 120
BARS = 4
BEATS = BARS * 4
BEAT_SEC = 60.0 / BPM
TOTAL_SAMPLES = int(SAMPLE_RATE * BEATS * BEAT_SEC)
OUT_DIR = Path(__file__).resolve().parent.parent / "game" / "audio" / "stems"

ROOTS_HZ = [55.0, 55.0, 73.42, 82.41]  # A1 A1 D2 E2, one root per bar

Voice = Callable[[float], float]


def kick(t: float) -> float:
    phase = 2 * math.pi * (50 * t + (100 / 30) * (1 - math.exp(-30 * t)))
    return math.sin(phase) * math.exp(-8 * t)


def make_snare(rng: random.Random) -> Voice:
    def snare(t: float) -> float:
        return (rng.uniform(-1, 1) * 0.7 + math.sin(2 * math.pi * 185 * t) * 0.5) * math.exp(-18 * t)

    return snare


def make_hat(rng: random.Random, gain: float) -> Voice:
    def hat(t: float) -> float:
        return rng.uniform(-1, 1) * gain * math.exp(-60 * t)

    return hat


def make_bass(freq: float) -> Voice:
    def bass(t: float) -> float:
        attack = min(1.0, t * 200)
        tone = math.sin(2 * math.pi * freq * t) * 0.8 + math.sin(2 * math.pi * 2 * freq * t) * 0.2
        return tone * math.exp(-3 * t) * attack

    return bass


def make_lead(freq: float) -> Voice:
    def lead(t: float) -> float:
        tone = sum(math.sin(2 * math.pi * freq * n * t) / n for n in (1, 3, 5))
        return tone * 0.35 * math.exp(-12 * t)

    return lead


class Track:
    def __init__(self) -> None:
        self.buf: list[float] = [0.0] * TOTAL_SAMPLES

    def add(self, start_beat: float, duration_sec: float, voice: Voice, gain: float = 1.0) -> None:
        start = int(start_beat * BEAT_SEC * SAMPLE_RATE)
        for i in range(int(duration_sec * SAMPLE_RATE)):
            idx = (start + i) % TOTAL_SAMPLES  # tails wrap so the loop point is seamless
            self.buf[idx] += voice(i / SAMPLE_RATE) * gain

    def write(self, path: Path) -> None:
        peak = max(abs(s) for s in self.buf) or 1.0
        scale = 0.85 / peak
        pcm = struct.pack("<%dh" % TOTAL_SAMPLES, *(int(s * scale * 32767) for s in self.buf))
        fmt = struct.pack("<HHIIHH", 1, 1, SAMPLE_RATE, SAMPLE_RATE * 2, 2, 16)
        loop = struct.pack("<IIIIII", 0, 0, 0, TOTAL_SAMPLES - 1, 0, 0)
        smpl = struct.pack("<IIIIIIIII", 0, 0, int(1e9 / SAMPLE_RATE), 60, 0, 0, 0, 1, 0) + loop
        body = (
            b"WAVE"
            + chunk(b"fmt ", fmt)
            + chunk(b"data", pcm)
            + chunk(b"smpl", smpl)  # loop points so Godot imports the WAV as a seamless loop
        )
        path.write_bytes(b"RIFF" + struct.pack("<I", len(body)) + body)


def chunk(tag: bytes, data: bytes) -> bytes:
    return tag + struct.pack("<I", len(data)) + data


def build_slow(rng: random.Random) -> Track:
    track = Track()
    hat = make_hat(rng, 0.25)
    for beat in range(BEATS):
        root = ROOTS_HZ[beat // 4]
        if beat % 4 in (0, 2):
            track.add(beat, 0.35, kick, 0.9)
            track.add(beat, 0.6, make_bass(root), 0.7)
        else:
            track.add(beat, 0.08, hat)
    return track


def build_mid(rng: random.Random) -> Track:
    track = Track()
    hat = make_hat(rng, 0.4)
    snare = make_snare(rng)
    for beat in range(BEATS):
        root = ROOTS_HZ[beat // 4]
        track.add(beat, 0.35, kick, 0.9)
        track.add(beat, 0.45, make_bass(root), 0.7)
        if beat % 4 in (1, 3):
            track.add(beat, 0.25, snare, 0.8)
        for eighth in (0.0, 0.5):
            track.add(beat + eighth, 0.08, hat)
    return track


def build_fast(rng: random.Random) -> Track:
    track = Track()
    hat = make_hat(rng, 0.45)
    snare = make_snare(rng)
    riff = [0, 0, 7, 0, 0, 0, 7, 5]  # semitones above the root, one per eighth
    for beat in range(BEATS):
        root = ROOTS_HZ[beat // 4]
        track.add(beat, 0.35, kick, 0.9)
        if beat % 4 == 3:
            track.add(beat + 0.5, 0.35, kick, 0.7)
        if beat % 4 in (1, 3):
            track.add(beat, 0.25, snare, 0.8)
        for sixteenth in (0.0, 0.25, 0.5, 0.75):
            track.add(beat + sixteenth, 0.06, hat)
        for eighth_index, eighth in enumerate((0.0, 0.5)):
            octave = 1 if eighth_index == 0 else 2
            track.add(beat + eighth, 0.3, make_bass(root * octave), 0.6)
            step = riff[(beat * 2 + eighth_index) % len(riff)]
            track.add(beat + eighth, 0.2, make_lead(root * 4 * 2 ** (step / 12)), 0.5)
    return track


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    builders = {"slow": build_slow, "mid": build_mid, "fast": build_fast}
    for name, build in builders.items():
        track = build(random.Random(42))
        path = OUT_DIR / f"{name}.wav"
        track.write(path)
        print(f"wrote {path} ({TOTAL_SAMPLES} samples, {BEATS * BEAT_SEC:.1f}s)")


if __name__ == "__main__":
    main()
