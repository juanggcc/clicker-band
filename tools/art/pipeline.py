#!/usr/bin/env python3
"""Shared art recipes, registered guitarist starters, and technical PNG checks.

Preparation is offline and never invokes an image model or modifies runtime art.
Pixel checks/composition use Pillow; all other commands use the standard library.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import html
import json
import math
import re
import shutil
import sys
import io
import zipfile
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path
from string import Template

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "art"
# Art jobs are local work, kept out of Git with the rest of workspace/.
JOBS = ROOT / "workspace/art-jobs"
STYLE = ART / "style-v0.json"
GUITAR = ART / "templates/guitar-standing-v1/template.json"


def read(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def write(path: Path, value: dict) -> None:
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def repo_path(value: str) -> Path:
    path = (ROOT / value).resolve()
    if not path.is_relative_to(ROOT):
        raise ValueError(f"Input must be inside the repository: {value}")
    return path


def art_path(value: str) -> Path:
    path = (ART / value).resolve()
    if not path.is_relative_to(ART):
        raise ValueError(f"Style resource must be inside art/: {value}")
    return path


def pil():
    try:
        from PIL import Image
        return Image
    except ImportError as exc:
        raise ValueError("Pixel operations require Pillow. Install tools/art/requirements.txt in your art environment.") from exc


def verify_sources() -> list[str]:
    errors = []
    manifests = [ART / "anchors/v0/manifest.json"]
    manifests += [art_path(value).parent / "sources.json" for value in read(STYLE)["templates"].values()]
    for manifest in manifests:
        for item in read(manifest)["files"]:
            path = repo_path(item["path"])
            if not path.is_file() or sha(path) != item["sha256"]:
                errors.append(f"Source changed or missing: {item['path']}")
    return errors


def prepare(args) -> None:
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]{0,79}", args.job):
        raise ValueError("Job id must use lowercase letters, numbers and hyphens, up to 80 characters.")
    brief_path = repo_path(args.brief)
    brief = read(brief_path)
    required = {"id", "kind", "subject", "composition", "lighting", "must_keep"}
    if not required.issubset(brief):
        raise ValueError(f"Brief missing: {sorted(required - brief.keys())}")
    unknown = brief.keys() - required - {"family", "references"}
    if unknown:
        raise ValueError(f"Unknown brief fields: {sorted(unknown)}")
    if brief["kind"] not in {"character", "background"}:
        raise ValueError("kind must be character or background")
    for field in ["id", "subject", "composition", "lighting"]:
        if not isinstance(brief[field], str) or not brief[field].strip():
            raise ValueError(f"{field} must be a nonempty string")
    if not isinstance(brief["must_keep"], list) or not all(isinstance(v, str) for v in brief["must_keep"]):
        raise ValueError("must_keep must be a list of strings")
    extra = brief.get("references", [])
    if not isinstance(extra, list) or not all(isinstance(v, dict) and set(v) == {"path", "role"} and all(isinstance(t, str) for t in v.values()) for v in extra):
        raise ValueError("references must be a list of objects with path and role strings")
    style = read(STYLE)
    contract_path = art_path(style["contracts"][brief["kind"]])
    contract = read(contract_path)
    sources = [STYLE, ART / "backend-lock.json", ART / "bible.md", contract_path, brief_path,
               ART / "prompts/shared.txt", ART / f"prompts/{brief['kind']}.txt"]
    refs = [(art_path(p), f"{brief['kind']} finish reference") for p in style["references"][brief["kind"]]]
    construction = "No construction family selected. Establish geometry in a master and document a new contract before preparing a rig."
    family = brief.get("family")
    template = None
    if family:
        if brief["kind"] != "character" or family not in style["templates"]:
            raise ValueError("Unsupported family for this kind of asset")
        template_path = art_path(style["templates"][family])
        template = read(template_path)
        construction = template["construction_prompt"]
        sources += [template_path, template_path.parent / "procedure.md", template_path.parent / "sources.json", art_path(template["editable"])]
        sources += [repo_path(item["path"]) for item in read(template_path.parent / "sources.json")["files"]
                    if Path(item["path"]).suffix in {".gd", ".tscn"}]
        refs += [(art_path(template["reference"]), "construction: neutral assembly; preserve pose and contacts"),
                 (art_path(template["guide"]), "construction: rig landmarks and mesh area; SVG for the editor")]
        sources += [template_path.parent / "layers" / item["file"] for item in template["layers"]]
    refs += [(repo_path(item["path"]), item["role"]) for item in extra]
    errors = verify_sources()
    if errors:
        raise ValueError("\n".join(errors) + "\nReview and version changed references or rig before preparing another job.")
    # Resolve and validate every input before making an output directory.
    for path in sources + [path for path, _ in refs]:
        if not path.is_file():
            raise ValueError(f"Missing input: {path}")
    if len(set(sources)) != len(sources):
        raise ValueError("Duplicate source inputs")
    reference_records = [
        {"file": f"inputs/ref-{i:02d}-{p.name}", "role": role, "source": p.relative_to(ROOT).as_posix(), "sha256": sha(p)}
        for i, (p, role) in enumerate(refs, 1)
    ]
    values = {
        "style_id": style["id"], "style_status": style["status"], "world_style": style["world_style"],
        "avoid": style["avoid"], "palette": ", ".join(f"{k} {v}" for k, v in style["palettes"]["world"]["colors"].items()),
        "references": "\n".join(f"- {r['file']}: {r['role']}" for r in reference_records),
        "asset_id": brief["id"], "subject": brief["subject"], "composition": brief["composition"],
        "lighting": brief["lighting"], "must_keep": "; ".join(brief["must_keep"]),
        "construction": construction, "width": contract["canvas"][0], "height": contract["canvas"][1],
    }
    prompt = "\n".join(Template(p.read_text(encoding="utf-8")).substitute(values) for p in sources[5:7])
    job = JOBS / args.job
    job.mkdir(parents=True, exist_ok=False)
    (job / "inputs").mkdir()
    records = []
    for i, path in enumerate(sources, 1):
        target = job / "inputs" / f"source-{i:02d}-{path.name}"
        shutil.copyfile(path, target)
        records.append({"file": target.relative_to(job).as_posix(), "source": path.relative_to(ROOT).as_posix(), "sha256": sha(target)})
    for (path, _), record in zip(refs, reference_records):
        shutil.copyfile(path, job / record["file"])
    (job / "prompt.txt").write_text(prompt, encoding="utf-8")
    if template:
        exports = job / "exports"
        exports.mkdir()
        for layer in template["layers"]:
            shutil.copyfile(template_path.parent / "layers" / layer["file"], exports / layer["file"])
        shutil.copyfile(art_path(template["reference"]), exports / "master.png")
        shutil.copyfile(art_path(template["editable"]), job / "source.ora")
        write(job / "landmarks.json", {"family": family, "status": "copied-from-template-not-measured", "points": template["landmarks"]})
    write(job / "manifest.json", {
        "id": args.job, "asset_id": brief["id"], "kind": brief["kind"], "family": family,
        "status": "prepared", "created_at_utc": datetime.now(timezone.utc).isoformat(),
        "style_id": style["id"], "style_status": style["status"], "contract_id": contract["id"],
        "backend_profile": read(ART / "backend-lock.json")["id"],
        "prompt_sha256": sha(job / "prompt.txt"), "source_inputs": records, "references": reference_records,
        "generation": {"status": "not-run", "provider": None, "model_reported": None, "model_version": None,
                       "seed": None, "settings": {}, "attempts": [], "edits": []},
        "time_minutes": {"generation_selection": None, "preparation": None, "animation": None, "integration_fixes": None},
        "review": {"technical": None, "visual": None, "reviewer": None, "notes": []},
        "deliverables": [], "starter_note": "Copied template exports are unchanged prototype artwork, not a completed new musician." if template else None,
    })
    print(f"Prepared {job.relative_to(ROOT)}; no generation performed. Prompt SHA256: {sha(job / 'prompt.txt')}")


def pixel_check(kind: str, path: Path) -> dict:
    Image = pil()
    contract = read(art_path(read(STYLE)["contracts"][kind]))
    files = [path / name for name in contract["required_files"]] if kind == "character" else [path]
    errors, results = [], []
    for file in files:
        try:
            with Image.open(file) as im:
                im.load()
                if im.format != "PNG":
                    errors.append(f"{file.name}: expected PNG")
                if list(im.size) != contract["canvas"]:
                    errors.append(f"{file.name}: {im.size}, expected {contract['canvas']}")
                alpha = im.convert("RGBA").getchannel("A")
                minimum, maximum = alpha.getextrema()
                if kind == "character" and (im.mode != "RGBA" or minimum != 0 or maximum == 0):
                    errors.append(f"{file.name}: expected nonempty RGBA with genuinely transparent pixels")
                if kind == "background" and minimum != 255:
                    errors.append(f"{file.name}: background must be fully opaque")
                if kind == "background" and im.mode not in {"RGB", "RGBA"}:
                    errors.append(f"{file.name}: background must be RGB or RGBA")
                results.append({"file": file.name, "size": list(im.size), "mode": im.mode,
                                "alpha_range": [minimum, maximum], "visible_bbox": alpha.getbbox(), "sha256": sha(file)})
        except (OSError, ValueError) as exc:
            errors.append(f"{file.name}: {exc}")
    return {"kind": kind, "technical_pass": not errors, "visual_review": "still-required", "errors": errors, "files": results}


def palette() -> None:
    style = read(STYLE)
    folder = ART / "palettes"
    folder.mkdir(exist_ok=True)
    for name, group in style["palettes"].items():
        lines = ["GIMP Palette", f"Name: {style['id']} / {name}", "Columns: 6", "# Generated from art/style-v0.json"]
        for key, value in group["colors"].items():
            rgb = bytes.fromhex(value.removeprefix("#"))
            lines.append(f"{rgb[0]:3} {rgb[1]:3} {rgb[2]:3}\t{key}")
        (folder / f"{name}-v0.gpl").write_text("\n".join(lines) + "\n", encoding="utf-8")
    items = [(group, key, value) for group, palette in style["palettes"].items() for key, value in palette["colors"].items()]
    rows = math.ceil(len(items) / 6)
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="{100 + rows * 110}" viewBox="0 0 1200 {100 + rows * 110}">',
             '<rect width="100%" height="100%" fill="#F4F1EA"/>',
             '<text x="24" y="34" font-family="sans-serif" font-size="22">Clicker Band · paleta provisional v0</text>',
             '<text x="24" y="62" font-family="sans-serif" font-size="14">Mundo: familias orientativas. UI: colores existentes. Fuente: art/style-v0.json</text>']
    for i, (group, key, value) in enumerate(items):
        x, y = 24 + i % 6 * 196, 85 + i // 6 * 110
        parts += [f'<rect x="{x}" y="{y}" width="170" height="54" fill="{value}"/>',
                  f'<text x="{x}" y="{y + 73}" font-family="sans-serif" font-size="12">{html.escape(group + ": " + key)}</text>',
                  f'<text x="{x}" y="{y + 92}" font-family="monospace" font-size="13">{value}</text>']
    (folder / "swatches-v0.svg").write_text("\n".join(parts + ["</svg>"]) + "\n", encoding="utf-8")
    print("Generated GPL palettes and SVG swatches from style-v0.json")


def compose_template() -> None:
    Image = pil()
    template = read(GUITAR)
    result = Image.new("RGBA", tuple(template["canvas"]))
    for layer in template["layers"]:
        with Image.open(GUITAR.parent / "layers" / layer["file"]) as im:
            result.alpha_composite(im.convert("RGBA"), dest=tuple(layer["rest_offset"]))
    result.save(art_path(template["reference"]))
    encoded = base64.b64encode(art_path(template["reference"]).read_bytes()).decode()
    parts = ['<svg xmlns="http://www.w3.org/2000/svg" width="700" height="900" viewBox="0 0 700 900">',
             '<rect width="700" height="900" fill="#CCD3D7"/>',
             f'<image width="700" height="900" href="data:image/png;base64,{encoded}"/>',
             '<rect x="210" y="345" width="195" height="190" fill="none" stroke="#C82963" stroke-width="2"/>',
             '<path d="M210 389H405 M210 431H405" stroke="#C82963" stroke-dasharray="6 4"/>']
    for label, (x, y) in template["landmarks"].items():
        parts += [f'<circle cx="{x}" cy="{min(y, 895)}" r="6" fill="#00D6BA" stroke="#102B36" stroke-width="2"/>',
                  f'<text x="{min(x + 10, 480)}" y="{min(y - 10, 880)}" font-family="sans-serif" font-size="13" fill="#073D40" stroke="#FFFFFF" stroke-width="3" paint-order="stroke">{label} ({x},{y})</text>']
    (GUITAR.parent / "guide.svg").write_text("\n".join(parts + ["</svg>"]) + "\n", encoding="utf-8")
    # OpenRaster keeps every original PNG at (0,0). Runtime offsets are deliberately
    # not baked into the editable source layers; the rig applies them when previewing.
    raw_composite = Image.new("RGBA", tuple(template["canvas"]))
    for layer in template["layers"]:
        with Image.open(GUITAR.parent / "layers" / layer["file"]) as im:
            raw_composite.alpha_composite(im.convert("RGBA"))
    document = ET.Element("image", {"w": "700", "h": "900", "name": "Registered source parts (runtime applies fret offsets)", "version": "0.0.3"})
    stack = ET.SubElement(document, "stack")
    with zipfile.ZipFile(art_path(template["editable"]), "w") as archive:
        archive.writestr(zipfile.ZipInfo("mimetype"), "image/openraster", compress_type=zipfile.ZIP_STORED)
        for layer in reversed(template["layers"]):
            src = "data/" + layer["file"]
            ET.SubElement(stack, "layer", {"name": Path(layer["file"]).stem, "src": src, "x": "0", "y": "0", "opacity": "1.0", "visibility": "visible", "composite-op": "svg:src-over"})
            # Fixed timestamps keep this derived archive byte-identical on rebuild.
            archive.writestr(zipfile.ZipInfo(src), (GUITAR.parent / "layers" / layer["file"]).read_bytes())
        archive.writestr(zipfile.ZipInfo("stack.xml"), ET.tostring(document, encoding="utf-8", xml_declaration=True))
        data = io.BytesIO()
        raw_composite.save(data, format="PNG")
        archive.writestr(zipfile.ZipInfo("mergedimage.png"), data.getvalue())
    print("Composed neutral template from unchanged source layers; no AI generation")


def check_landmarks(path: Path) -> dict:
    data = read(path)
    family = data.get("family")
    templates = read(STYLE)["templates"]
    if family not in templates:
        return {"declared_geometry_pass": False, "errors": ["Unknown construction family"], "distances_px": {}}
    template = read(art_path(templates[family]))
    errors, distances = [], {}
    if data.get("family") != template["id"] or data.get("status") != "measured":
        errors.append("Measure the exported attachment points and set family and status=measured; a template copy is not a measurement.")
    points = data.get("points", {})
    for name, expected in template["landmarks"].items():
        point = points.get(name)
        if not isinstance(point, list) or len(point) != 2 or not all(isinstance(v, (int, float)) and not isinstance(v, bool) and math.isfinite(v) for v in point):
            errors.append(f"Missing or invalid landmark: {name}")
            continue
        distances[name] = round(math.dist(expected, point), 3)
        if distances[name] > template["landmark_tolerance_px"]:
            errors.append(f"{name}: attachment deviates by {distances[name]} px; adapt drawing or version the family")
    return {"declared_geometry_pass": not errors, "errors": errors, "distances_px": distances,
            "limitation": "Checks supplied measurements, not anatomical detection; pose renders still required."}


def guitar_scene(args) -> None:
    errors = verify_sources()
    if errors:
        raise ValueError("\n".join(errors) + "\nReview/version the construction family before creating a derived scene.")
    assets = repo_path(args.assets)
    if not assets.is_relative_to(ROOT / "game/assets/characters"):
        raise ValueError("Scene assets must be under game/assets/characters/")
    report = pixel_check("character", assets)
    if report["errors"]:
        raise ValueError("\n".join(report["errors"]))
    target = repo_path(args.out)
    if not target.is_relative_to(ROOT / "game/characters") or target.suffix != ".tscn":
        raise ValueError("Scene output must be a .tscn under game/characters/")
    if target.exists():
        raise ValueError("Refusing to overwrite an existing scene")
    template = read(GUITAR)
    layers = template["layers"]
    lines = [f'[gd_scene load_steps={len(layers) + 2} format=3]', '',
             '[ext_resource type="PackedScene" path="res://characters/protagonist/protagonist.tscn" id="1_base"]']
    for i, layer in enumerate(layers, 2):
        path = (assets / layer["file"]).relative_to(ROOT / "game").as_posix()
        lines.append(f'[ext_resource type="Texture2D" path="res://{path}" id="{i}_texture"]')
    strum_id = next(i for i, layer in enumerate(layers, 2) if layer["file"] == "arm_strum.png")
    lines += ['', '[node name="Guitarist" instance=ExtResource("1_base")]', f'strum_texture = ExtResource("{strum_id}_texture")']
    for i, layer in enumerate(layers, 2):
        if layer["file"] == "arm_strum.png":
            continue  # Its texture belongs to the mesh configured by the base script.
        parent, _, name = layer["node"].rpartition("/")
        lines += ['', f'[node name="{name}" parent="{parent}" index={layer["index"]}]', f'texture = ExtResource("{i}_texture")']
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Created inherited scene {target.relative_to(ROOT)}; not instantiated in the game. Visual review remains required.")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    job = commands.add_parser("prepare")
    job.add_argument("brief")
    job.add_argument("--job", required=True)
    check = commands.add_parser("check")
    check.add_argument("kind", choices=["character", "background"])
    check.add_argument("path")
    landmarks = commands.add_parser("check-landmarks")
    landmarks.add_argument("path")
    scene = commands.add_parser("guitar-scene")
    scene.add_argument("--assets", required=True)
    scene.add_argument("--out", required=True)
    commands.add_parser("palette")
    commands.add_parser("compose-template", help="Rebuild derived neutral assembly/guide from frozen template layers")
    commands.add_parser("audit", help="Verify frozen reference and construction source hashes")
    args = parser.parse_args()
    try:
        if args.command == "prepare":
            prepare(args)
        elif args.command == "palette":
            palette()
        elif args.command == "compose-template":
            compose_template()
        elif args.command == "guitar-scene":
            guitar_scene(args)
        else:
            if args.command == "audit":
                errors = verify_sources()
                result = {"source_integrity_pass": not errors, "errors": errors, "visual_review": "not-assessed"}
            elif args.command == "check-landmarks":
                result = check_landmarks(repo_path(args.path))
            else:
                result = pixel_check(args.kind, repo_path(args.path))
            print(json.dumps(result, ensure_ascii=False, indent=2))
            return 1 if result["errors"] else 0
    except (ValueError, OSError, KeyError) as exc:
        print(f"Art pipeline: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
