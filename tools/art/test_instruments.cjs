#!/usr/bin/env node
// Exercise the real hand-occlusion regression and the reusable production workflow.
const fs = require('fs'), path = require('path'), os = require('os'), assert = require('assert/strict');
const sharp = require(process.env.CLICKER_SHARP_PATH || path.join(__dirname, 'node_modules/sharp'));
const repo = path.resolve(__dirname, '../..');
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'clicker-instrument-tests-'));
process.env.CLICKER_ART_ROOT = temporary;
const api = require('./instruments.cjs');
let passed = 0;
function pass(value, text) {assert.ok(value, text); passed++; process.stdout.write('PASS ' + text + '\n');}
const save = (file, data) => fs.writeFileSync(file, JSON.stringify(data, null, 2));

(async () => {
  try {
    fs.mkdirSync(path.join(temporary, 'workspace/art-jobs'), {recursive: true});
    fs.cpSync(path.join(repo, 'art/instruments'), path.join(temporary, 'art/instruments'), {recursive: true});
    const snapshot = JSON.parse(fs.readFileSync(path.join(api.BASE, 'sources.json')));
    for (const item of snapshot.files) {
      const target = path.join(temporary, item.path);
      if (fs.existsSync(target)) continue;
      fs.mkdirSync(path.dirname(target), {recursive: true}); fs.copyFileSync(path.join(repo, item.path), target);
    }
    pass(api.audit().source_integrity_pass, 'frozen construction inputs verify in a fresh workspace');
    const guitar = path.join(api.BASE, 'guitar/reference.png'), bass = path.join(api.BASE, 'bass/reference.png');
    pass((await api.check('guitar', guitar)).technical_pass && (await api.check('bass', bass)).technical_pass, 'both accepted references fit size, grips and visible wrists');
    const crookedGuitar = await api.check('guitar', path.join(repo, 'tools/art/fixtures/guitar-axis-before.png'));
    pass(!crookedGuitar.technical_pass && crookedGuitar.errors.some(error => error.includes('Neck axis')),
      'the previous Jaguar bridge/neck misalignment is detected even though its hands fit');
    const low = await sharp(bass).extract({left: 0, top: 0, width: 900, height: 888}).png().toBuffer();
    const down12 = await sharp({create: {width: 900, height: 900, channels: 4, background: {r: 0, g: 0, b: 0, alpha: 0}}}).composite([{input: low, left: 0, top: 12}]).png().toBuffer();
    const regression = await api.check('bass', down12);
    pass(!regression.technical_pass && regression.errors.filter(error => error.includes('hides the wrist')).length === 9,
      'lowering the bass 12px recreates and detects the actual hand cut in all three grips');
    const wrongCanvas = await sharp(bass).extract({left: 0, top: 0, width: 700, height: 900}).png().toBuffer();
    pass((await api.check('bass', wrongCanvas)).errors.some(error => error.includes('900x900')), 'cropping away the long neck is rejected');
    const opaque = await sharp(bass).removeAlpha().png().toBuffer();
    pass(!(await api.check('bass', opaque)).technical_pass, 'a missing transparent background is rejected');
    const tiny = await sharp(bass).resize(450, 450).extend({right: 450, bottom: 450, background: {r: 0, g: 0, b: 0, alpha: 0}}).png().toBuffer();
    pass((await api.check('bass', tiny)).errors.some(error => error.includes('Painted width')), 'a bass reduced to fit the musician like a small guitar is rejected');
    const brief = path.join(temporary, 'art/brief.json');
    save(brief, {id: 'bass-test', profile: 'bass', subject: 'A new bass from a user reference', must_keep: ['Four strings'], references: []});
    await api.prepare('art/brief.json', 'first'); await api.prepare('art/brief.json', 'second');
    const first = path.join(temporary, 'workspace/art-jobs/first'), second = path.join(temporary, 'workspace/art-jobs/second');
    pass(fs.readFileSync(path.join(first, 'prompt.txt')).equals(fs.readFileSync(path.join(second, 'prompt.txt'))), 'two teammates prepare identical prompts');
    const manifest = JSON.parse(fs.readFileSync(path.join(first, 'manifest.json')));
    pass(manifest.status === 'prepared-not-generated' && !fs.existsSync(path.join(first, 'exports')) && manifest.input_files.every(item => api.hash(path.join(first, item.file)) === item.sha256),
      'preparation preserves every input hash and produces no fake final artwork');
    await assert.rejects(() => api.prepare('art/brief.json', 'first'));
    await assert.rejects(() => api.register('workspace/art-jobs/first'), /Measure bridge and nut/);
    pass(true, 'existing jobs and unmeasured sources cannot be overwritten or registered silently');
    fs.copyFileSync(path.join(api.BASE, 'bass/source.png'), path.join(first, 'source/instrument.png'));
    const measurements = {profile: 'bass', source: 'source/instrument.png', status: 'measured', points: {bridge: [512, 1410], nut: [512, 214]}, axis_samples: {neck_base: [512, 980], neck_mid: [512, 600]}};
    save(path.join(first, 'measurements.json'), measurements);
    const result = await api.register('workspace/art-jobs/first');
    const output = path.join(first, 'exports/instrument.png');
    pass(result.technical_pass && fs.readFileSync(output).equals(fs.readFileSync(bass)), 'measured upright source reconstructs the accepted registered bass byte-for-byte');
    const registeredManifest = JSON.parse(fs.readFileSync(path.join(first, 'manifest.json')));
    pass(registeredManifest.status === 'registered-awaiting-visual-review' && registeredManifest.review.visual === null,
      'a technical pass does not masquerade as visual approval');
    await assert.rejects(() => api.register('workspace/art-jobs/first'), /Export exists/);
    const before = api.hash(output); await api.register('workspace/art-jobs/first', true);
    pass(api.hash(output) === before, 'explicit rebuild is deterministic and implicit replacement is rejected');
    measurements.axis_samples.neck_base = [600, 980]; save(path.join(first, 'measurements.json'), measurements);
    await assert.rejects(() => api.register('workspace/art-jobs/first', true), /Source neck axis/);
    pass(api.hash(output) === before, 'a crooked measured source is rejected without overwriting accepted artwork');
    measurements.axis_samples.neck_base = [512, 980];
    measurements.points.nut = [9000, 9000]; save(path.join(first, 'measurements.json'), measurements);
    await assert.rejects(() => api.register('workspace/art-jobs/first', true), /Invalid measured nut/);
    pass(api.hash(output) === before, 'bad source measurements fail before changing the accepted export');
    fs.appendFileSync(path.join(api.BASE, 'bass/profile.json'), ' ');
    pass(!api.audit().source_integrity_pass, 'unreviewed instrument geometry drift is detected');
    process.stdout.write(`${passed} instrument workflow checks passed\n`);
  } finally {fs.rmSync(temporary, {recursive: true, force: true});}
})().catch(error => {process.stderr.write(error.stack + '\n'); process.exitCode = 1;});
