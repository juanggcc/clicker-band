#!/usr/bin/env node
/* Export generated artwork without distortion, and make the optional safe-crop thumbnails.
 * NODE_PATH=<directory containing sharp> node tools/art/finalize_menu_map_art.cjs PARK_PNG LOCKED_PNG
 */
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const sharp = require('sharp');

const ROOT = path.resolve(__dirname, '../..');
const JOB = path.join(ROOT, 'workspace/art-jobs/parque-menu-v01');
const DESIGN = path.join(ROOT, 'docs/art/2026-10-21-menu-map');
const REVIEW = path.join(ROOT, 'workspace/reviews/2026-10-21-menu-map');
const GAME = path.join(ROOT, 'game');
const relative = p => path.relative(ROOT, p).split(path.sep).join('/');
const hash = p => crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');

async function main() {
  const [parkInput, lockedInput] = process.argv.slice(2);
  if (!parkInput || !lockedInput) throw new Error('Supply the original generated park and locked PNG paths.');
  for (const dir of [JOB + '/source', JOB + '/exports', JOB + '/qa', REVIEW + '/source', GAME + '/assets/backgrounds', GAME + '/assets/ui/map/v1']) {
    fs.mkdirSync(dir, {recursive: true});
  }
  const original = JOB + '/source/park-generated.png';
  const lockedOriginal = REVIEW + '/source/zone-locked-generated.png';
  if (path.resolve(parkInput) !== original) fs.copyFileSync(parkInput, original);
  if (path.resolve(lockedInput) !== lockedOriginal) fs.copyFileSync(lockedInput, lockedOriginal);
  const parkExport = JOB + '/exports/park.png';
  // One uniform scale plus centered crop, never stretching either axis independently.
  await sharp(original).rotate().resize(2400, 1080, {fit:'cover', position:'centre'})
    .flatten({background:'#344863'}).toColourspace('srgb').png().toFile(parkExport);
  const installed = GAME + '/assets/backgrounds/park.png';
  fs.copyFileSync(parkExport, installed);

  const assets = {};
  for (const [zone, background] of [['bedroom', GAME + '/assets/backgrounds/bedroom.png'], ['park', installed]]) {
    const file = GAME + '/assets/ui/map/v1/zone_' + zone + '.png';
    await sharp(background).extract({left:240, top:0, width:1920, height:1080})
      .resize(384,216).removeAlpha().png().toFile(file);
    assets[relative(file)] = {size:[384,216], role:'Central 16:9 safe crop of the actual background',
      source:relative(background), source_crop_xywh:[240,0,1920,1080], filter:'linear', opaque:true, sha256:hash(file)};
  }
  const locked = GAME + '/assets/ui/map/v1/zone_locked.png';
  await sharp(lockedOriginal).rotate().resize(384,216,{fit:'cover',position:'centre'})
    .flatten({background:'#16212b'}).toColourspace('srgb').png().toFile(locked);
  assets[relative(locked)] = {size:[384,216], role:'Undiscovered venue silhouette; overlay live ??? and reused lock in Godot',
    source:relative(lockedOriginal), filter:'linear', opaque:true, sha256:hash(locked)};
  assets[relative(installed)] = {size:[2400,1080], role:'Empty park background', source:relative(original),
    filter:'linear', opaque:true, sha256:hash(installed)};
  const metadata = await sharp(original).metadata();
  const exportRecord = {source_size:[metadata.width,metadata.height], target_size:[2400,1080],
    operation:'Uniform resize with centered cover crop, sRGB RGB export',
    world_to_image_offset:[240,0], central_crop_xywh:[240,0,1920,1080],
    protagonist_feet_image:[1000,1000], drummer_free_floor_image_x:[1390,1740]};
  fs.writeFileSync(JOB + '/source/export-transform.json', JSON.stringify(exportRecord,null,2)+'\n');
  fs.writeFileSync(DESIGN + '/art-manifest.json', JSON.stringify({version:1,assets},null,2)+'\n');
  console.log(JSON.stringify({export:exportRecord,assets:Object.keys(assets)},null,2));
}
main().catch(error => {console.error(error);process.exitCode=1;});
