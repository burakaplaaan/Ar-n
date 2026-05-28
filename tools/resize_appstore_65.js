const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const SOURCE_DIR = 'marketing/app-store';
const OUTPUT_DIR = 'marketing/app-store/6.5-inch';
const TARGET_WIDTH = 1284;
const TARGET_HEIGHT = 2778;
const MAX_BYTES = 8 * 1024 * 1024;

async function main() {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });

  const files = fs
    .readdirSync(SOURCE_DIR)
    .filter((f) => f.endsWith('.png') && !f.includes('source'));

  for (const file of files.sort()) {
    const input = path.join(SOURCE_DIR, file);
    const output = path.join(OUTPUT_DIR, file);

    await sharp(input)
      .resize(TARGET_WIDTH, TARGET_HEIGHT, {
        fit: 'fill',
        kernel: sharp.kernel.lanczos3,
      })
      .flatten({ background: { r: 3, g: 8, b: 6 } })
      .png({ compressionLevel: 9 })
      .toFile(output);

    const meta = await sharp(output).metadata();
    const size = fs.statSync(output).size;
    if (size > MAX_BYTES) {
      throw new Error(`${file} dosya boyutu limiti aşıyor: ${(size / 1024 / 1024).toFixed(2)} MB`);
    }

    console.log(
      `✓ ${file} → ${meta.width}x${meta.height} (${(size / 1024 / 1024).toFixed(2)} MB)`,
    );
  }

  console.log(`\n${files.length} görsel hazır → ${OUTPUT_DIR}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
