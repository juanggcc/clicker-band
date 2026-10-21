#!/usr/bin/env node
/* Register the two generated pedal sprites on transparent canvases with one uniform
 * transform per image. Usage: node tools/art/export_pedal.cjs WORLD_SOURCE SHOP_SOURCE
 * Requires sharp, as declared in tools/art/package.json. */
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const sharp = require('sharp');

const ROOT = path.resolve(__dirname, '../..');
const JOB = path.join(ROOT, 'workspace/art-jobs/pedal-perro-v01');
const relative = file => path.relative(ROOT, file).split(path.sep).join('/');
const sha = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');

async function alphaBounds(file) {
  const {data, info} = await sharp(file).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  let left=info.width, top=info.height, right=-1, bottom=-1, transparent=0, intermediate=0;
  for(let y=0; y<info.height; y++) for(let x=0; x<info.width; x++) {
    const alpha=data[(y*info.width+x)*4+3];
    if(alpha===0) transparent++;
    if(alpha>0 && alpha<255) intermediate++;
    // The generated transparent padding contains isolated 1/255-alpha specks.
    // Ignore those only when finding the crop rectangle; never threshold the art.
    if(alpha>=8) { left=Math.min(left,x); top=Math.min(top,y); right=Math.max(right,x); bottom=Math.max(bottom,y); }
  }
  if(!transparent || right<left) throw new Error('Expected nonempty artwork with true transparency: '+file);
  left=Math.max(0,left-2); top=Math.max(0,top-2);
  right=Math.min(info.width-1,right+2); bottom=Math.min(info.height-1,bottom+2);
  return {bbox:{left,top,width:right-left+1,height:bottom-top+1},bbox_selection_alpha_min:8,crop_guard_px:2,
    source_size:[info.width,info.height],transparent_pixels:transparent,antialiased_pixels:intermediate};
}

async function register(input, name, size, fitBox, anchor, kernel, target) {
  const original=path.join(JOB,'source',name+'-generated.png');
  if(path.resolve(input)!==original) fs.copyFileSync(input,original);
  const alpha=await alphaBounds(original);
  const {data,info}=await sharp(original).extract(alpha.bbox)
    .resize(fitBox[0],fitBox[1],{fit:'inside',kernel}).toBuffer({resolveWithObject:true});
  const left=Math.round(anchor[0]-info.width/2);
  const top=Math.round(anchor[1]-(name==='world'?info.height:info.height/2));
  if(left<0 || top<0 || left+info.width>size[0] || top+info.height>size[1]) throw new Error('Artwork does not fit canvas');
  const final=path.join(JOB,'exports',name==='world'?'pedal.png':'pedal_upgrade_v2.png');
  await sharp({create:{width:size[0],height:size[1],channels:4,background:{r:0,g:0,b:0,alpha:0}}})
    .composite([{input:data,left,top}]).toColourspace('srgb').png().toFile(final);
  fs.mkdirSync(path.dirname(target),{recursive:true});
  fs.copyFileSync(final,target);
  return {original:relative(original),...alpha,canvas:size,fit_box:fitBox,
    registered_art_xywh:[left,top,info.width,info.height],anchor,
    operation:'Alpha-bound crop, uniform resize and transparent padding; original alpha preserved',
    kernel,export:relative(final),installed:relative(target),sha256:sha(final)};
}

async function main() {
  const [world,shop]=process.argv.slice(2);
  if(!world || !shop) throw new Error('Supply WORLD_SOURCE and SHOP_SOURCE PNG paths');
  const records={
    world:await register(world,'world',[512,384],[432,288],[256,336],'lanczos3',path.join(ROOT,'game/assets/props/pedal.png')),
    shop:await register(shop,'shop',[512,512],[400,448],[256,256],'nearest',path.join(ROOT,'game/assets/ui/shop/v1/pedal_upgrade_v2.png')),
  };
  fs.writeFileSync(path.join(JOB,'registration.json'),JSON.stringify(records,null,2)+'\n');
  console.log(JSON.stringify(records,null,2));
}
main().catch(error=>{console.error(error);process.exitCode=1;});
