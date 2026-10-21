#!/usr/bin/env node
// Shared instrument preparation and registration. This never calls an image model
// or modifies game/. Sharp performs only deterministic transforms/compositing.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const sharp = require(process.env.CLICKER_SHARP_PATH || path.join(__dirname, 'node_modules/sharp'));
const ROOT = path.resolve(process.env.CLICKER_ART_ROOT || path.join(__dirname, '../..'));
const BASE = path.join(ROOT, 'art/instruments/standing-v1');
const read = file => JSON.parse(fs.readFileSync(file, 'utf8'));
const write = (file, value) => fs.writeFileSync(file, JSON.stringify(value, null, 2) + '\n');
const hash = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const relative = file => path.relative(ROOT, file).split(path.sep).join('/');
const xml = text => String(text).replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('"', '&quot;');
function inside(root, value) {
  const file = path.resolve(root, value);
  if (file !== root && !file.startsWith(root + path.sep)) throw Error('Path leaves its workspace: ' + value);
  return file;
}
function context(kind) {
  const system = read(path.join(BASE, 'system.json'));
  if (!Object.hasOwn(system.profiles, kind)) throw Error('Unknown instrument profile: ' + kind);
  const file = inside(BASE, system.profiles[kind]);
  return {system, profile: read(file), file};
}
function audit() {
  const errors = [];
  for (const item of read(path.join(BASE, 'sources.json')).files) {
    const file = inside(ROOT, item.path);
    if (!fs.existsSync(file) || hash(file) !== item.sha256) errors.push('Source changed or missing: ' + item.path);
  }
  return {source_integrity_pass: !errors.length, errors};
}
function assertSources() {
  const result = audit();
  if (result.errors.length) throw Error(result.errors.join('\n'));
}
async function pixels(input) {
  return sharp(input).ensureAlpha().raw().toBuffer({resolveWithObject: true});
}
function alphaAt(image, x, y) {
  x = Math.round(x); y = Math.round(y);
  if (x < 0 || y < 0 || x >= image.info.width || y >= image.info.height) return 0;
  return image.data[(y * image.info.width + x) * 4 + 3];
}
function bounds(image, threshold) {
  let x0 = image.info.width, y0 = image.info.height, x1 = -1, y1 = -1;
  for (let y = 0; y < image.info.height; y++) for (let x = 0; x < image.info.width; x++) {
    if (alphaAt(image, x, y) > threshold) {x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y);}
  }
  return x1 < 0 ? null : [x0, y0, x1 + 1, y1 + 1];
}
function neckSection(image, centre, nx, ny) {
  let low = 0, high = 0;
  const visible = alphaAt(image, ...centre) >= 128;
  if (visible) {
    while (low > -64 && alphaAt(image, centre[0] + (low - 1) * nx, centre[1] + (low - 1) * ny) >= 128) low--;
    while (high < 64 && alphaAt(image, centre[0] + (high + 1) * nx, centre[1] + (high + 1) * ny) >= 128) high++;
  }
  return {width: visible ? high - low + 1 : 0, offset: (high + low) / 2, visible};
}
async function check(kind, input) {
  const {system: s, profile: p} = context(kind);
  const meta = await sharp(input).metadata();
  const image = await pixels(input);
  const errors = [];
  if (meta.format !== 'png' || !meta.hasAlpha) errors.push('Expected PNG with alpha');
  if (meta.width !== s.canvas[0] || meta.height !== s.canvas[1]) errors.push('Expected a 900x900 canvas with unchanged origin');
  let minAlpha = 255, maxAlpha = 0;
  for (let i = 3; i < image.data.length; i += 4) {minAlpha = Math.min(minAlpha, image.data[i]); maxAlpha = Math.max(maxAlpha, image.data[i]);}
  if (minAlpha !== 0 || maxAlpha < 128) errors.push('Expected nonempty painted content and genuinely transparent exterior');
  const box = bounds(image, s.alpha_visible_threshold);
  if (!box) errors.push('Empty instrument');
  else {
    const width = box[2] - box[0], height = box[3] - box[1];
    for (const [name, value] of [['width', width], ['height', height]]) {
      const [low, high] = p.visible_size_range[name];
      if (value < low || value > high) errors.push(`Painted ${name} ${value} outside ${low}..${high} for ${kind}`);
    }
    if (box[0] < 2 || box[1] < 2 || box[2] > s.canvas[0] - 2 || box[3] > s.canvas[1] - 2) errors.push('Instrument touches a canvas edge');
  }
  const grips = s.grip_centers.map((point, grip) => {
    const alpha = alphaAt(image, ...point);
    if (alpha < s.grip_min_instrument_alpha) errors.push(`Grip ${grip}: instrument misses the hand contact at ${point}`);
    return {grip, point, alpha};
  });
  const wrists = s.grip_deltas_from_neutral.flatMap((delta, grip) => s.wrist_probes_neutral.map(point => {
    const xy = [point[0] + delta[0], point[1] + delta[1]];
    const alpha = alphaAt(image, ...xy);
    if (alpha > s.wrist_max_instrument_alpha) errors.push(`Grip ${grip}: instrument hides the wrist at ${xy}`);
    return {grip, point: xy, alpha};
  }));
  if (alphaAt(image, ...s.picking_contact) < 128) errors.push('Instrument misses the picking-hand area');
  const [a, b] = [p.anchors.bridge, p.anchors.nut];
  const dx = b[0] - a[0], dy = b[1] - a[1], length = Math.hypot(dx, dy);
  const nx = -dy / length, ny = dx / length;
  const widths = s.grip_centers.map((point, grip) => {
    const t = ((point[0] - a[0]) * dx + (point[1] - a[1]) * dy) / (length * length);
    const centre = [a[0] + t * dx, a[1] + t * dy];
    if (Math.hypot(point[0] - centre[0], point[1] - centre[1]) > p.neck_axis_tolerance_px) errors.push(`Profile axis misses grip ${grip}; this geometry needs a different profile`);
    const width = neckSection(image, centre, nx, ny).width;
    const [minimum, maximum] = p.neck_width_range_px;
    if (width < minimum || width > maximum) errors.push(`Grip ${grip}: neck width ${width} outside ${minimum}..${maximum}`);
    return {grip, center: centre, normal_width_px: width};
  });
  const axisSamples = s.neck_axis_probe_fractions.map(fraction => {
    const centre = [a[0] + fraction * dx, a[1] + fraction * dy];
    const section = neckSection(image, centre, nx, ny);
    if (!section.visible || Math.abs(section.offset) > s.neck_center_max_offset_px) errors.push(`Neck axis: centre offset ${section.offset}px at fraction ${fraction}; bridge and fretboard are misaligned`);
    return {fraction, center: centre, normal_width_px: section.width, center_offset_px: section.offset};
  });
  return {profile: p.id, technical_pass: !errors.length, errors, canvas: [meta.width, meta.height],
    alpha_range: [minAlpha, maxAlpha], visible_bounds_xyxy: box, hand_contacts: grips,
    uncovered_wrist_probes: wrists, neck_widths: widths, neck_axis_samples: axisSamples,
    visual_review: 'Required: hardware, actual measured anchors, sleeve/strap joins, all six rendered poses. Alpha probes do not certify the drawing.'};
}
async function assemble(kind) {
  const {system: s, profile: p} = context(kind);
  const layers = [];
  for (const layer of s.musician_layers) {
    let input = layer.file === '$instrument' ? inside(BASE, p.reference) : path.join(BASE, 'musician', layer.file);
    let [left, top] = layer.offset;
    const meta = await sharp(input).metadata();
    if (left < 0 || top < 0 || top + meta.height > s.canvas[1]) {
      input = await sharp(input).extract({left: Math.max(0, -left), top: Math.max(0, -top),
        width: Math.min(meta.width + Math.min(0, left), s.canvas[0] - Math.max(0, left)),
        height: Math.min(meta.height + Math.min(0, top), s.canvas[1] - Math.max(0, top))}).png().toBuffer();
      left = Math.max(0, left); top = Math.max(0, top);
    }
    layers.push({input, left, top});
  }
  return sharp({create: {width: 900, height: 900, channels: 4, background: {r: 0, g: 0, b: 0, alpha: 0}}}).composite(layers).png().toBuffer();
}
async function guides() {
  const system = read(path.join(BASE, 'system.json'));
  for (const kind of Object.keys(system.profiles)) {
    const {profile: p, file} = context(kind);
    const folder = path.dirname(file);
    const assembly = await assemble(kind);
    fs.writeFileSync(path.join(folder, 'assembly.png'), assembly);
    const box = p.reference_visible_bounds_xyxy;
    let svg = `<svg xmlns="http://www.w3.org/2000/svg" width="900" height="900"><rect width="900" height="900" fill="#526371"/><image width="900" height="900" opacity="0.7" href="data:image/png;base64,${assembly.toString('base64')}"/><g font-family="sans-serif" fill="#ffffff"><text x="22" y="35" font-size="23">${xml(p.id)}</text><text x="22" y="62" font-size="16">Painted ${box[2] - box[0]} x ${box[3] - box[1]} · canvas 900 x 900 · origin unchanged</text><text x="22" y="90" font-size="15">Orange: grip · Green: wrist must stay visible · Pink: picking area</text></g>`;
    svg += `<rect x="${box[0]}" y="${box[1]}" width="${box[2] - box[0]}" height="${box[3] - box[1]}" fill="none" stroke="#9ed8ed" stroke-dasharray="5 5"/>`;
    const body = p.reference_body_region_xyxy;
    svg += `<rect x="${body[0]}" y="${body[1]}" width="${body[2] - body[0]}" height="${body[3] - body[1]}" fill="none" stroke="#ffffff" stroke-opacity="0.5" stroke-dasharray="3 7"/><circle cx="355" cy="560" r="5" fill="#fb9edf"/>`;
    svg += `<path d="M${p.anchors.bridge.join(' ')}L${p.anchors.nut.join(' ')}" stroke="#9ed8ed" stroke-width="2"/>`;
    for (const [name, xy] of Object.entries(p.anchors)) svg += `<circle cx="${xy[0]}" cy="${xy[1]}" r="6" fill="#9ed8ed"/><text x="${xy[0] + 10}" y="${xy[1] - 12}" font-family="sans-serif" font-size="15" fill="white">${name} (${xy.map(Math.round)})</text>`;
    for (const xy of system.grip_centers) svg += `<circle cx="${xy[0]}" cy="${xy[1]}" r="5" fill="#ffb95d"/>`;
    for (const delta of system.grip_deltas_from_neutral) for (const xy of system.wrist_probes_neutral) svg += `<circle cx="${xy[0] + delta[0]}" cy="${xy[1] + delta[1]}" r="3" fill="#86f2ae"/>`;
    svg += `<ellipse cx="352" cy="480" rx="23" ry="20" fill="none" stroke="#fb9edf" stroke-width="2"/><rect x="425" y="380" width="27" height="35" fill="none" stroke="#ffffff" stroke-dasharray="3 4"/><text x="22" y="875" font-family="sans-serif" font-size="16" fill="white">Feet origin (350,900) · torso pivot (355,560) · instrument (0,0), centered=false</text></svg>`;
    fs.writeFileSync(path.join(folder, 'guide.svg'), svg + '\n');
    await sharp(Buffer.from(svg)).png().toFile(path.join(folder, 'guide.png'));
  }
}
async function prepare(briefName, jobId) {
  assertSources();
  if (!/^[a-z0-9][a-z0-9-]{0,79}$/.test(jobId || '')) throw Error('Invalid job ID');
  const briefFile = inside(ROOT, briefName), brief = read(briefFile);
  if (!brief.id || typeof brief.subject !== 'string' || !Array.isArray(brief.must_keep) || !brief.must_keep.every(v => typeof v === 'string')) throw Error('Brief requires id, profile, subject and must_keep strings');
  const {system: s, profile: p, file} = context(brief.profile);
  const styleFile = path.join(ROOT, 'art/style-v0.json'), style = read(styleFile);
  const references = brief.references || [];
  if (!Array.isArray(references) || !references.every(v => typeof v.path === 'string' && typeof v.role === 'string')) throw Error('References require path and role');
  const inputs = [
    [briefFile, 'brief.json', 'requested identity'], [file, 'profile.json', 'instrument geometry'],
    [path.join(BASE, 'system.json'), 'system.json', 'shared contacts'], [styleFile, 'style.json', 'illustration finish'],
    [inside(BASE, p.reference), 'registered-reference.png', 'registered instrument construction, not new generated art'],
    [inside(BASE, p.source_reference), 'native-source.png', 'editable source construction; points in profile.json apply only while its geometry is unchanged'],
    [path.join(path.dirname(file), 'guide.png'), 'guide.png', 'shared scale and hand placement'],
    [path.join(path.dirname(file), 'guide.svg'), 'guide.svg', 'editable construction guide'],
    [path.join(path.dirname(file), 'assembly.png'), 'assembly.png', 'reference musician with this instrument']
  ];
  references.forEach((ref, i) => inputs.push([inside(ROOT, ref.path), `identity-${i + 1}${path.extname(ref.path)}`, ref.role]));
  for (const [source] of inputs) if (!fs.statSync(source).isFile()) throw Error('Missing input: ' + source);
  const job = inside(path.join(ROOT, 'workspace/art-jobs'), jobId);
  fs.mkdirSync(path.dirname(job), {recursive: true});
  fs.mkdirSync(job); fs.mkdirSync(path.join(job, 'inputs')); fs.mkdirSync(path.join(job, 'source'));
  const records = inputs.map(([source, name, role]) => {
    const dest = path.join(job, 'inputs', name); fs.copyFileSync(source, dest);
    return {file: 'inputs/' + name, source: relative(source), role, sha256: hash(dest)};
  });
  const prompt = `Use case: stylized-concept.\nAsset: one complete isolated ${brief.profile} instrument, true transparent background.\nIdentity: ${brief.subject}\nPreserve: ${brief.must_keep.join('; ')}\nFinish: ${style.world_style}\nAvoid: ${style.avoid}\nGeometry: ${p.prompt_note}\nThe construction reference sets scale and hand contacts; the identity references set the requested instrument design. Do not copy unrelated hardware from the construction reference.\nCreate a complete instrument alone, without musician, hands, strap, background or UI. An upright source is suitable for symmetric instruments; it will be registered uniformly using measured bridge and nut centers. Keep every string straight from bridge to nut. Preserve the actual reference's hardware order and silhouette.\nRegistration targets: bridge ${JSON.stringify(p.anchors.bridge)}, nut ${JSON.stringify(p.anchors.nut)}, on a 900x900 canvas extending only to the right of the character's original canvas. Do not shrink a bass to fit 700px. Keep all three hand contacts and the green wrist zones in the guide.\nInputs:\n${records.map(r => `- ${r.file}: ${r.role}`).join('\n')}\n`;
  fs.writeFileSync(path.join(job, 'prompt.txt'), prompt);
  write(path.join(job, 'measurements.json'), {profile: brief.profile, status: 'unmeasured', source: 'source/instrument.png', points: {bridge: null, nut: null}, axis_samples: {neck_base: null, neck_mid: null}});
  write(path.join(job, 'manifest.json'), {id: jobId, status: 'prepared-not-generated', profile: p.id,
    recipe_sha256: hash(__filename),
    input_files: records, prompt_sha256: hash(path.join(job, 'prompt.txt')),
    generation: {provider: null, model: null, seed: null, attempts: []}, editable: null,
    note: 'No final PNG or generated artwork exists yet. Edit or generate the instrument, measure anchors, then register and review.'});
  return {job: relative(job), status: 'prepared-not-generated', canvas: s.canvas};
}
async function register(jobName, force = false) {
  assertSources();
  const job = inside(ROOT, jobName);
  if (!job.startsWith(path.join(ROOT, 'workspace/art-jobs') + path.sep)) throw Error('Registration output must be inside workspace/art-jobs/');
  const measurements = read(path.join(job, 'measurements.json'));
  if (measurements.status !== 'measured') throw Error('Measure bridge and nut in the actual source and set status=measured');
  const {system: s, profile: p} = context(measurements.profile);
  const source = inside(job, measurements.source), meta = await sharp(source).metadata();
  const points = ['bridge', 'nut'].map(name => {
    const xy = measurements.points[name];
    if (!Array.isArray(xy) || xy.length !== 2 || !xy.every(Number.isFinite) || xy[0] < 0 || xy[1] < 0 || xy[0] >= meta.width || xy[1] >= meta.height) throw Error('Invalid measured ' + name);
    return xy;
  });
  const [a, b] = points, [c, d] = [p.anchors.bridge, p.anchors.nut];
  const distance = Math.hypot(b[0] - a[0], b[1] - a[1]);
  if (distance < 8) throw Error('Measured anchors are too close');
  const scale = Math.hypot(d[0] - c[0], d[1] - c[1]) / distance;
  const sourceAxis = [];
  if (measurements.axis_samples) {
    for (const name of ['neck_base', 'neck_mid']) {
      const xy = measurements.axis_samples[name];
      if (!Array.isArray(xy) || xy.length !== 2 || !xy.every(Number.isFinite) || xy[0] < 0 || xy[1] < 0 || xy[0] >= meta.width || xy[1] >= meta.height) throw Error('Measure the source axis point: ' + name);
      const error = Math.abs((xy[0] - a[0]) * (b[1] - a[1]) - (xy[1] - a[1]) * (b[0] - a[0])) / distance * scale;
      if (error > s.neck_center_max_offset_px) throw Error(`Source neck axis ${name} deviates by ${error.toFixed(2)} registered pixels; correct the drawing`);
      sourceAxis.push({name, source_point: xy, registered_axis_error_px: error});
    }
  }
  const angle = (Math.atan2(d[1] - c[1], d[0] - c[0]) - Math.atan2(b[1] - a[1], b[0] - a[0])) * 180 / Math.PI;
  const width = Math.max(1, Math.round(meta.width * scale)), height = Math.max(1, Math.round(meta.height * scale));
  if (width * height > 36000000 || Math.max(width, height) > 12000) throw Error('Measured anchors imply an excessive scale; recheck bridge and nut');
  const rotated = await sharp(source).resize(width, height).rotate(angle, {background: {r: 0, g: 0, b: 0, alpha: 0}}).png().toBuffer();
  const rotatedImage = await pixels(rotated), rm = rotatedImage.info, theta = angle * Math.PI / 180;
  const x = a[0] * width / meta.width - width / 2, y = a[1] * height / meta.height - height / 2;
  const left = Math.round(c[0] - (Math.cos(theta) * x - Math.sin(theta) * y + rm.width / 2));
  const top = Math.round(c[1] - (Math.sin(theta) * x + Math.cos(theta) * y + rm.height / 2));
  const anchorErrors = points.map((point, index) => {
    const px = point[0] * width / meta.width - width / 2, py = point[1] * height / meta.height - height / 2;
    const actual = [Math.cos(theta) * px - Math.sin(theta) * py + rm.width / 2 + left,
      Math.sin(theta) * px + Math.cos(theta) * py + rm.height / 2 + top];
    const target = index ? d : c;
    return {anchor: index ? 'nut' : 'bridge', registered: actual, error_px: Math.hypot(actual[0] - target[0], actual[1] - target[1])};
  });
  if (anchorErrors.some(item => item.error_px > p.anchor_tolerance_px)) throw Error('Rounded export cannot meet the anchor tolerance');
  const box = bounds(rotatedImage, s.alpha_visible_threshold);
  if (!box || box[0] + left < 2 || box[1] + top < 2 || box[2] + left > 898 || box[3] + top > 898) throw Error('Painted instrument would be clipped; correct the source proportions or select a different profile');
  const x0 = Math.max(0, -left), y0 = Math.max(0, -top);
  const cropped = await sharp(rotated).extract({left: x0, top: y0,
    width: Math.min(rm.width - x0, 900 - Math.max(0, left)), height: Math.min(rm.height - y0, 900 - Math.max(0, top))}).png().toBuffer();
  const result = await sharp({create: {width: 900, height: 900, channels: 4, background: {r: 0, g: 0, b: 0, alpha: 0}}})
    .composite([{input: cropped, left: Math.max(0, left), top: Math.max(0, top)}]).png().toBuffer();
  const report = await check(measurements.profile, result);
  const destination = path.join(job, 'exports/instrument.png');
  if (fs.existsSync(destination) && !force) throw Error('Export exists; use --force only to rebuild this job intentionally');
  fs.mkdirSync(path.dirname(destination), {recursive: true}); fs.mkdirSync(path.join(job, 'qa'), {recursive: true});
  fs.writeFileSync(destination, result);
  write(path.join(job, 'registration.json'), {profile: p.id, source: measurements.source,
    recipe_sha256: hash(__filename),
    source_sha256: hash(source), source_size: [meta.width, meta.height], source_points: measurements.points,
    target_points: p.anchors, scale, clockwise_rotation_degrees: angle,
    anchor_errors: anchorErrors,
    source_axis_samples: sourceAxis,
    resized_size: [width, height], rotated_size: [rm.width, rm.height], translation_after_rotation: [left, top],
    canvas: s.canvas, policy: 'One uniform similarity transform; output retains the shared origin.'});
  write(path.join(job, 'qa/instrument-check.json'), report);
  const manifestFile = path.join(job, 'manifest.json');
  if (fs.existsSync(manifestFile)) {
    const manifest = read(manifestFile);
    manifest.status = report.technical_pass ? 'registered-awaiting-visual-review' : 'registered-needs-correction';
    manifest.export = {file: 'exports/instrument.png', sha256: hash(destination)};
    manifest.review = {technical: report.technical_pass, visual: null};
    manifest.registration = 'registration.json';
    write(manifestFile, manifest);
  }
  return {job: relative(job), export: relative(destination), ...report};
}
async function main() {
  const [command, ...args] = process.argv.slice(2);
  let result;
  if (command === 'audit' && !args.length) result = audit();
  else if (command === 'guides' && !args.length) {await guides(); result = {guides: 'rebuilt from frozen reference PNGs'};}
  else if (command === 'check' && args.length === 2) result = await check(args[0], inside(ROOT, args[1]));
  else if (command === 'prepare' && args.length === 3 && args[1] === '--job') result = await prepare(args[0], args[2]);
  else if (command === 'register' && (args.length === 1 || args.length === 2 && args[1] === '--force')) result = await register(args[0], args[1] === '--force');
  else throw Error('Usage: instruments.cjs prepare BRIEF --job ID | register JOB [--force] | check guitar|bass PNG | guides | audit');
  process.stdout.write(JSON.stringify(result, null, 2) + '\n');
  if (result.errors?.length) process.exitCode = 1;
}
module.exports = {ROOT, BASE, context, check, audit, prepare, register, guides, assemble, hash};
if (require.main === module) main().catch(error => {process.stderr.write('Instruments: ' + error.message + '\n'); process.exitCode = 1;});
