const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const SOURCE_DIR = 'marketing/app-store/6.5-inch';
const OUTPUT_DIR = 'marketing/app-store/ipad-13-inch';
const TARGET_WIDTH = 2064;
const TARGET_HEIGHT = 2752;
const MAX_BYTES = 8 * 1024 * 1024;
const BG = { r: 3, g: 8, b: 6 };

async function main() {
  if (!fs.existsSync(SOURCE_DIR)) {
    throw new Error(`Kaynak klasör bulunamadı: ${SOURCE_DIR}`);
  }

  fs.mkdirSync(OUTPUT_DIR, { recursive: true });

  const files = fs.readdirSync(SOURCE_DIR).filter((f) => f.endsWith('.png'));

  for (const file of files.sort()) {
    const input = path.join(SOURCE_DIR, file);
    const output = path.join(OUTPUT_DIR, file);

    await sharp(input)
      .resize(TARGET_WIDTH, TARGET_HEIGHT, {
        fit: 'contain',
        background: BG,
        kernel: sharp.kernel.lanczos3,
      })
      .flatten({ background: BG })
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

  console.log(`\n${files.length} iPad görseli hazır → ${OUTPUT_DIR}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
