const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const OUT_DIR = 'C:/Users/burak/Desktop/iosiphonnarin/appstore_ready';
const IPAD_1ER = 'C:/Users/burak/Desktop/iosiphonnarin/ipad/1.er.png';
const TARGET_W = 1242;
const TARGET_H = 2688;
const BG = { r: 0, g: 8, b: 6 };

async function fitWithBlur(inputPath) {
  const meta = await sharp(inputPath).metadata();
  const fitScale = Math.min(TARGET_W / meta.width, TARGET_H / meta.height);
  const fitW = Math.round(meta.width * fitScale);
  const fitH = Math.round(meta.height * fitScale);
  const offsetX = Math.floor((TARGET_W - fitW) / 2);
  const offsetY = Math.floor((TARGET_H - fitH) / 2);

  const blurred = await sharp(inputPath)
    .resize(TARGET_W, TARGET_H, { fit: 'cover', position: 'centre' })
    .blur(28)
    .removeAlpha()
    .toBuffer();

  const fitted = await sharp(inputPath)
    .resize(fitW, fitH, { kernel: sharp.kernel.lanczos3 })
    .removeAlpha()
    .toBuffer();

  return sharp(blurred)
    .composite([{ input: fitted, left: offsetX, top: offsetY }])
    .flatten({ background: BG })
    .png({ compressionLevel: 9, force: true })
    .toBuffer();
}

async function flattenToOpaquePng(inputPath) {
  return sharp(inputPath)
    .resize(TARGET_W, TARGET_H, { fit: 'fill', kernel: sharp.kernel.lanczos3 })
    .flatten({ background: BG })
    .png({ compressionLevel: 9, force: true })
    .toBuffer();
}

async function main() {
  if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });

  const jpgFiles = fs
    .readdirSync(OUT_DIR)
    .filter((f) => /\.jpe?g$/i.test(f));

  if (!fs.existsSync(IPAD_1ER)) {
    throw new Error(`1.er kaynağı bulunamadı: ${IPAD_1ER}`);
  }

  const oneEr = await fitWithBlur(IPAD_1ER);
  fs.writeFileSync(path.join(OUT_DIR, '1.er.png'), oneEr);
  const m1 = await sharp(oneEr).metadata();
  console.log(`✓ 1.er.png ${m1.width}x${m1.height} alpha=${m1.hasAlpha}`);

  for (const jpg of jpgFiles) {
    if (jpg.toLowerCase() === '1.er.jpg') {
      fs.unlinkSync(path.join(OUT_DIR, jpg));
      continue;
    }
    const out = jpg.replace(/\.jpe?g$/i, '.png');
    const buf = await flattenToOpaquePng(path.join(OUT_DIR, jpg));
    fs.writeFileSync(path.join(OUT_DIR, out), buf);
    fs.unlinkSync(path.join(OUT_DIR, jpg));
    const meta = await sharp(buf).metadata();
    console.log(`✓ ${out} ${meta.width}x${meta.height} alpha=${meta.hasAlpha}`);
  }

  for (const file of fs.readdirSync(OUT_DIR)) {
    if (/\.png\.tmp.*$/i.test(file)) {
      fs.unlinkSync(path.join(OUT_DIR, file));
    }
  }

  const pngs = fs.readdirSync(OUT_DIR).filter((f) => f.endsWith('.png'));
  console.log(`\n${pngs.length} dosya hazır → ${OUT_DIR}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
