const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const OUT_DIR = 'C:/Users/burak/Desktop/iosiphonnarin/appstore_ready';
const SRC_ROOT = 'C:/Users/burak/Desktop/' + fs.readdirSync('C:/Users/burak/Desktop').find((d) => d.startsWith('Yeni klas'));
const TARGET_W = 1242;
const TARGET_H = 2688;
const BG = { r: 0, g: 8, b: 6 };

// Orijinal appstore_ready dosya adları -> Yeni klasör kaynakları
const MAP = {
  '1.er.png': '1..ü.png',
  '243731db-69a9-440d-8ac3-9d8e2aa704b4.png': '7abd712b-0a18-44e1-ad4b-bc2ab63f86da.png',
  '26b35684-334f-4748-9619-d06c01b7d100.png': '553db60d-cee1-43d1-877f-0e12bfacb5f7.png',
  '350124a5-c183-4db1-a456-afc747bf5289.png': '1.png',
  '5cb718d5-4407-47a0-95ab-dff251b7925f.png': '2b0b129a-c5e4-4bcb-8d14-f52ddd957435.png',
  '667d52ba-68e6-496a-9190-e5b48073e9ca.png': 'arın1.png',
  'a1459d20-609f-4d7b-b87d-02735809a61b.png': 'b1d035e0-bf4e-4a09-b6a9-e9d576f40767.png',
  'c21b64b0-b734-4c9f-8855-24bd2259f37f.png': '68185621-6ec7-49a3-b98b-7063cd594f8c.png',
  'e60efab8-fe92-499a-b884-8b981fb8cb42.png': '2489bbc2-aed8-468b-af9e-db14fc494000.png',
  'koma.png': '20715661-85cd-428f-9fb5-5afec0c1d3bb.png',
};

async function fitWithBlur(inputPath) {
  const meta = await sharp(inputPath).metadata();
  const fitScale = Math.min(TARGET_W / meta.width, TARGET_H / meta.height);
  const fitW = Math.round(meta.width * fitScale);
  const fitH = Math.round(meta.height * fitScale);
  const offsetX = Math.floor((TARGET_W - fitW) / 2);
  const offsetY = Math.floor((TARGET_H - fitH) / 2);

  const blurred = await sharp(inputPath)
    .resize(TARGET_W, TARGET_H, { fit: 'cover', position: 'centre' })
    .blur(24)
    .removeAlpha()
    .toBuffer();

  const fitted = await sharp(inputPath)
    .resize(fitW, fitH, { kernel: sharp.kernel.lanczos3 })
    .toBuffer();

  let pipeline = sharp(blurred).composite([{ input: fitted, left: offsetX, top: offsetY }]);

  return pipeline.png({ compressionLevel: 9, force: true }).toBuffer();
}

async function main() {
  fs.mkdirSync(OUT_DIR, { recursive: true });

  for (const [outName, srcName] of Object.entries(MAP)) {
    const srcPath = path.join(SRC_ROOT, srcName);
    if (!fs.existsSync(srcPath)) {
      const alt = fs.readdirSync(SRC_ROOT).find((f) => f.normalize('NFC') === srcName.normalize('NFC') || f.includes(srcName.slice(0, 8)));
      if (!alt) throw new Error(`Kaynak yok: ${srcName}`);
      Object.assign(MAP, { [outName]: alt });
    }
  }

  for (const [outName, srcName] of Object.entries(MAP)) {
    let srcFile = path.join(SRC_ROOT, srcName);
    if (!fs.existsSync(srcFile)) {
      srcFile = path.join(SRC_ROOT, fs.readdirSync(SRC_ROOT).find((f) => f.startsWith(srcName.slice(0, 6))));
    }

    let buf = await fitWithBlur(srcFile);

    if (outName === '1.er.png') {
      buf = await sharp(buf).flatten({ background: BG }).png({ compressionLevel: 9, force: true }).toBuffer();
    }

    fs.writeFileSync(path.join(OUT_DIR, outName), buf);
    const meta = await sharp(buf).metadata();
    console.log(`✓ ${outName} <- ${path.basename(srcFile)} (${meta.width}x${meta.height}, alpha=${meta.hasAlpha})`);
  }

  console.log(`\n${Object.keys(MAP).length} dosya eski haline getirildi → ${OUT_DIR}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
