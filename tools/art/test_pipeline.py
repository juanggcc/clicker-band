#!/usr/bin/env python3
"""Offline pipeline checks in a temporary copy; run with the art Python environment."""
from pathlib import Path
from types import SimpleNamespace
import importlib.util, tempfile, shutil, json, hashlib, zipfile, contextlib, io
from PIL import Image, ImageDraw
repo=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('art_pipeline',repo/'tools/art/pipeline.py')
p=importlib.util.module_from_spec(spec);spec.loader.exec_module(p)
checks=0

def check(value,label):
 global checks
 assert value,label
 checks+=1
 print('PASS',label)

with tempfile.TemporaryDirectory(prefix='clicker-art-tests-') as temp:
 root=Path(temp).resolve()
 shutil.copytree(repo/'art',root/'art')
 for file in ['protagonist.gd','protagonist.tscn','deformable_limb.gd']:
  dest=root/'game/characters/protagonist'/file;dest.parent.mkdir(parents=True,exist_ok=True)
  shutil.copyfile(repo/'game/characters/protagonist'/file,dest)
 p.ROOT=root;p.ART=root/'art';p.JOBS=root/'workspace/art-jobs';p.STYLE=p.ART/'style-v0.json';p.GUITAR=p.ART/'templates/guitar-standing-v1/template.json'
 check(p.verify_sources()==[],'frozen reference/rig hashes verify from a fresh copied workspace')
 for job in ['first','second']:
  with contextlib.redirect_stdout(io.StringIO()):
   p.prepare(SimpleNamespace(brief='art/briefs/protagonist-pilot.json',job=job))
 first=root/'workspace/art-jobs/first'; second=root/'workspace/art-jobs/second'
 check((first/'prompt.txt').read_bytes()==(second/'prompt.txt').read_bytes(),'two teammates get byte-identical compiled prompts')
 first_manifest=p.read(first/'manifest.json')
 check(all(p.sha(first/r['file'])==r['sha256'] for r in first_manifest['source_inputs']+first_manifest['references']),'every input copy matches its recorded hash')
 check(first_manifest['generation']['status']=='not-run' and first_manifest['review']['visual'] is None,'prepared starter is not reported as generated/approved art')
 try:p.prepare(SimpleNamespace(brief='art/briefs/protagonist-pilot.json',job='first'))
 except FileExistsError: pass
 else:raise AssertionError('existing job was overwritten')
 check(True,'existing job cannot be overwritten')
 with contextlib.redirect_stdout(io.StringIO()):
  p.prepare(SimpleNamespace(brief='art/briefs/garage-pilot.json',job='garage'))
 check((root/'workspace/art-jobs/garage/prompt.txt').is_file(),'background recipe prepares independently')
 check(p.pixel_check('character',first/'exports')['technical_pass'],'registered starter passes canvas/alpha checks')
 body=first/'exports/body_core.png'; original=body.read_bytes()
 with Image.open(body) as im:im.resize((350,450)).save(body)
 check(not p.pixel_check('character',first/'exports')['technical_pass'],'wrong-sized piece is rejected')
 body.write_bytes(original)
 with Image.open(body) as im: im.convert('RGB').save(body)
 check(not p.pixel_check('character',first/'exports')['technical_pass'],'missing character alpha is rejected')
 body.write_bytes(original)
 blank=root/'transparent-background.png';Image.new('RGBA',(2400,1080)).save(blank)
 check(not p.pixel_check('background',blank)['technical_pass'],'transparent background is rejected')
 landmarks=first/'landmarks.json'
 check(bool(p.check_landmarks(landmarks)['errors']),'unmeasured copied landmarks cannot pass as measured')
 data=p.read(landmarks);data['status']='measured';p.write(landmarks,data)
 check(p.check_landmarks(landmarks)['declared_geometry_pass'],'measured matching attachment geometry passes')
 data['points']['strum_elbow'][0]+=30;p.write(landmarks,data)
 check(bool(p.check_landmarks(landmarks)['errors']),'shifted attachment is rejected')
 template=p.GUITAR.parent
 before={name:p.sha(template/name) for name in ['assembly.png','guide.svg','registered-parts.ora']}
 with contextlib.redirect_stdout(io.StringIO()):p.compose_template()
 check(before=={name:p.sha(template/name) for name in before},'derived template and OpenRaster rebuild byte-identically')
 with zipfile.ZipFile(template/'registered-parts.ora') as archive:
  files=[name for name in archive.namelist() if name.startswith('data/')]
  check(len(files)==7 and all(archive.read(name)==(template/'layers'/Path(name).name).read_bytes() for name in files),'editable packages seven unchanged full-canvas layer PNGs')
 anchor=root/'art/anchors/v0/protagonist.png';anchor.write_bytes(anchor.read_bytes()+b'changed')
 check(bool(p.verify_sources()),'unreviewed anchor drift is detected')
 print(f'{checks} art pipeline checks passed')
