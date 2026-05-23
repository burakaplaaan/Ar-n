const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const SOURCE_DIR = 'marketing/play-store/promo';
const OUTPUT_ROOT = 'marketing/play-store';

const PROMO_FILES = [
  '01_kesfet_promo.png',
  '02_zikirmatik_promo.png',
  '03_namaz_promo.png',
  '04_pusula_promo.png',
  '05_frekans_promo.png',
  '06_kilit_promo.png',
  '07_saat_ayet_promo.png',
  '08_gelisim_arinma_promo.png',
];

const TARGETS = [
  {
    id: 'tablet-7-inch',
    label: '7 inç tablet',
    width: 1080,
    height: 1920,
    minSide: 320,
    maxSide: 3840,
    maxBytes: 8 * 1024 * 1024,
  },
  {
    id: 'tablet-10-inch',
    label: '10 inç tablet',
    width: 1620,
    height: 2880,
    minSide: 1080,
    maxSide: 7680,
    maxBytes: 8 * 1024 * 1024,
  },
  {
    id: 'chromebook',
    label: 'Chromebook',
    width: 1620,
    height: 2880,
    minSide: 1080,
    maxSide: 7680,
    maxBytes: 8 * 1024 * 1024,
  },
  {
    id: 'android-xr',
    label: 'Android XR',
    width: 1440,
    height: 2560,
    minSide: 720,
    maxSide: 7680,
    maxBytes: 15 * 1024 * 1024,
  },
];

function assertTarget(target) {
  const shortSide = Math.min(target.width, target.height);
  const longSide = Math.max(target.width, target.height);
  if (shortSide < target.minSide || longSide > target.maxSide) {
    throw new Error(`${target.id} boyutları Play Console sınırları dışında: ${target.width}x${target.height}`);
  }
}

async function exportForTarget(target) {
  assertTarget(target);
  const outDir = path.join(OUTPUT_ROOT, target.id);
  fs.mkdirSync(outDir, { recursive: true });

  for (const file of PROMO_FILES) {
    const sourcePath = path.join(SOURCE_DIR, file);
    if (!fs.existsSync(sourcePath)) {
      throw new Error(`Kaynak bulunamadı: ${sourcePath}`);
    }

    const outPath = path.join(outDir, file);
    await sharp(sourcePath)
      .resize(target.width, target.height, {
        fit: 'contain',
        background: { r: 3, g: 8, b: 6, alpha: 1 },
      })
      .png({ compressionLevel: 9 })
      .toFile(outPath);

    const size = fs.statSync(outPath).size;
    if (size > target.maxBytes) {
      throw new Error(`${outPath} dosya boyutu limiti aşıyor: ${(size / 1024 / 1024).toFixed(2)} MB`);
    }
  }

  console.log(`✓ ${target.label}: ${PROMO_FILES.length} görsel → ${outDir} (${target.width}x${target.height})`);
}

async function main() {
  for (const target of TARGETS) {
    await exportForTarget(target);
  }
  console.log('\nTüm cihaz klasörleri hazır.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
