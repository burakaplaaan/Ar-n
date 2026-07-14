/**
 * Proje kökünden: cd tool/audio_trim && npm install && node trim_notification_assets.mjs
 * CC0 kaynakları kırpar; Android/iOS için uyumlu WAV, Flutter önizlemesi için MP3 yazar.
 */
import { execFileSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import ffmpeg from 'ffmpeg-static';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, '..', '..');

const jobs = [
  [
    'sound_candidates/01_adhan_turkish_sonically_sound_CC0_preview.mp3',
    10,
    'prayer_ntf_adhan_turkish.wav',
  ],
  [
    'sound_candidates/02_adhan_ramadan_dubai_wshintani_CC0_preview.mp3',
    9,
    'prayer_ntf_adhan_dubai.wav',
  ],
  [
    'sound_candidates/05_ambient_flute_texture_bassimat_CC0_preview.mp3',
    6,
    'prayer_ntf_ambient_flute.wav',
  ],
  [
    'sound_candidates/06_ambient_piano_guitar_deadrobot_CC0_preview.mp3',
    7,
    'prayer_ntf_ambient_piano_guitar.wav',
  ],
  [
    'sound_candidates/09_ambient_ethereal_voices_CC0_preview.mp3',
    10,
    'prayer_ntf_ambient_ethereal.wav',
  ],
];

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

if (!ffmpeg) {
  console.error('ffmpeg-static binary not found.');
  process.exit(1);
}

const rawDir = path.join(root, 'android/app/src/main/res/raw');
const iosDir = path.join(root, 'ios/Runner');
const assetDir = path.join(root, 'assets/sounds/prayer');
ensureDir(rawDir);
ensureDir(iosDir);
ensureDir(assetDir);

for (const [rel, seconds, outName] of jobs) {
  const inp = path.join(root, rel);
  if (!fs.existsSync(inp)) {
    console.error('Missing input:', inp);
    process.exit(1);
  }
  const outRaw = path.join(rawDir, outName);
  const fadeStart = Math.max(0, seconds - 0.32);
  const args = [
    '-y',
    '-ss',
    '0',
    '-t',
    String(seconds),
    '-i',
    inp,
    '-af',
    `afade=t=out:st=${fadeStart}:d=0.28`,
    '-acodec',
    'pcm_s16le',
    '-ar',
    '32000',
    '-ac',
    '1',
    outRaw,
  ];
  console.log('ffmpeg', outName, seconds + 's');
  execFileSync(ffmpeg, args, { stdio: 'inherit' });
  fs.copyFileSync(outRaw, path.join(iosDir, outName));
  const previewName = outName.replace(/\.wav$/i, '.mp3');
  const previewOut = path.join(assetDir, previewName);
  execFileSync(
    ffmpeg,
    [
      '-y',
      '-i',
      outRaw,
      '-acodec',
      'libmp3lame',
      '-b:a',
      '96k',
      '-ar',
      '32000',
      '-ac',
      '1',
      previewOut,
    ],
    { stdio: 'inherit' },
  );
  const legacyAssetWav = path.join(assetDir, outName);
  if (fs.existsSync(legacyAssetWav)) fs.unlinkSync(legacyAssetWav);
  console.log('OK', outName);
}
