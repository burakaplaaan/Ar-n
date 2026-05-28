const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const SOURCE_DIR = 'marketing/app-store/source';
const OUTPUT_DIR = 'marketing/app-store';

const LEFT = 72;
const TEXT_TOP = 196;
const COVER_HEIGHT = 680;

const SCREENS = [
  {
    file: 'arin-appstore-67-01.png',
    out: '01_gununu_sakinlestir.png',
    eyebrow: 'ARINAPP',
    title: 'Gününü sakinleştir.',
    lines: ['Namaz vakitleri, hatırlatmalar ve ilham —', 'hepsi tek, sade bir akışta.'],
    accent: '#4ade80',
  },
  {
    file: 'arin-appstore-67-02.png',
    out: '02_namaz_vakitleri.png',
    eyebrow: 'NAMAZ',
    title: 'Namaz vakitlerini takip et.',
    lines: ['Sıradaki vakti gör, bildirim al,', 'hatırlatma sürelerini kendine göre ayarla.'],
    accent: '#4ade80',
  },
  {
    file: 'arin-appstore-67-03.png',
    out: '03_kesfet_ilham.png',
    eyebrow: 'KEŞFET',
    title: 'Keşfet ile kısa ilhamlar.',
    lines: ['Ayet, hadis ve hikmetli sözleri huzurlu', 'görsellerle oku; kaydet, paylaş.'],
    accent: '#4ade80',
  },
  {
    file: 'arin-appstore-67-04.png',
    out: '04_kesfet_arama.png',
    eyebrow: 'KEŞFET',
    title: 'Görsel akışta hızlı arama.',
    lines: ['Keşfet ızgarasında içeriği anında bul,', 'dilediğin kartı aç.'],
    accent: '#4ade80',
  },
  {
    file: 'arin-appstore-67-05.png',
    out: '05_namaza_hazirlik.png',
    eyebrow: 'NAMAZ',
    title: 'Namaza hazırlık.',
    lines: ['Nefesini yavaşlat, niyetini kalbine indir,', 'huşû ile namaza geç.'],
    accent: '#4ade80',
  },
  {
    file: 'arin-appstore-67-06.png',
    out: '06_zikirmatik.png',
    eyebrow: 'ZİKİRMATİK',
    title: 'Zikirmatik, sade ve odaklı.',
    lines: ['Tur sayacı, titreşim ve zikir bilgisi —', 'kalabalıksız, derin bir pratik.'],
    accent: '#4ade80',
  },
  {
    file: 'arin-appstore-67-07.png',
    out: '07_frekanslar.png',
    eyebrow: 'FREKANSLAR',
    title: 'Sükûnet için ses alanı.',
    lines: ['Şifa frekansları, ambiyans sesleri ve', 'manevi metinlerle sakinleş.'],
    accent: '#2dd4bf',
  },
  {
    file: 'arin-appstore-67-08.png',
    out: '08_gelisim_arinma.png',
    eyebrow: 'ARINMA',
    title: 'Gelişim ve arınma.',
    lines: ['Bırakmak istediklerini takip et,', 'manevi niyetlerle adım adım ilerle.'],
    accent: '#fb7185',
  },
  {
    file: 'arin-appstore-67-09.png',
    out: '09_kilit_ekrani.png',
    eyebrow: 'WİDGET',
    title: 'Kilit ekranında söz ve vakit.',
    lines: ['Günlük ayet, hadis ve sıradaki vakit —', 'arka planını kapatmadan.'],
    accent: '#fbbf24',
  },
];

function escapeXml(value) {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function buildTextOverlay(width, screen) {
  const eyebrowY = TEXT_TOP;
  const lineY = TEXT_TOP + 30;
  const titleY = TEXT_TOP + 96;
  const sub1Y = TEXT_TOP + 172;
  const sub2Y = TEXT_TOP + 218;
  const titleSize = screen.title.length > 28 ? 48 : 54;

  return Buffer.from(`
  <svg width="${width}" height="${COVER_HEIGHT}" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="titleGrad" x1="0%" y1="0%" x2="100%" y2="0%">
        <stop offset="0%" stop-color="#ffffff"/>
        <stop offset="100%" stop-color="#e7f7ef"/>
      </linearGradient>
      <filter id="titleShadow" x="-20%" y="-30%" width="140%" height="180%">
        <feDropShadow dx="0" dy="3" stdDeviation="6" flood-color="#000000" flood-opacity="0.45"/>
      </filter>
      <filter id="subShadow" x="-10%" y="-20%" width="120%" height="160%">
        <feDropShadow dx="0" dy="2" stdDeviation="4" flood-color="#000000" flood-opacity="0.35"/>
      </filter>
    </defs>

    <text x="${LEFT}" y="${eyebrowY}" font-family="Segoe UI, Arial, sans-serif" font-size="18"
          font-weight="700" fill="${screen.accent}" letter-spacing="5">${escapeXml(screen.eyebrow)}</text>
    <rect x="${LEFT}" y="${lineY}" width="56" height="3" rx="1.5" fill="${screen.accent}" opacity="0.95"/>
    <text x="${LEFT}" y="${titleY}" font-family="Segoe UI, Arial, sans-serif" font-size="${titleSize}"
          font-weight="800" fill="url(#titleGrad)" letter-spacing="-1.2" filter="url(#titleShadow)">
      ${escapeXml(screen.title)}
    </text>
    <text x="${LEFT}" y="${sub1Y}" font-family="Segoe UI, Arial, sans-serif" font-size="31"
          font-weight="400" fill="rgba(255,255,255,0.84)" filter="url(#subShadow)">
      ${escapeXml(screen.lines[0])}
    </text>
    <text x="${LEFT}" y="${sub2Y}" font-family="Segoe UI, Arial, sans-serif" font-size="31"
          font-weight="400" fill="rgba(255,255,255,0.68)" filter="url(#subShadow)">
      ${escapeXml(screen.lines[1])}
    </text>
  </svg>`);
}

function buildDarkenOverlay(width, height) {
  return Buffer.from(`
  <svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="fade" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0%" stop-color="#030806" stop-opacity="0.72"/>
        <stop offset="45%" stop-color="#030806" stop-opacity="0.42"/>
        <stop offset="100%" stop-color="#030806" stop-opacity="0"/>
      </linearGradient>
    </defs>
    <rect width="100%" height="100%" fill="url(#fade)"/>
  </svg>`);
}

function buildLeftPanelWipe(width, height) {
  return Buffer.from(`
  <svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="lp" x1="0" y1="0" x2="1" y2="0">
        <stop offset="0%" stop-color="#030806" stop-opacity="0.82"/>
        <stop offset="72%" stop-color="#030806" stop-opacity="0.38"/>
        <stop offset="100%" stop-color="#030806" stop-opacity="0"/>
      </linearGradient>
    </defs>
    <rect width="100%" height="100%" fill="url(#lp)"/>
  </svg>`);
}

async function eraseOldText(inputPath) {
  const meta = await sharp(inputPath).metadata();
  const width = meta.width;
  const height = meta.height;
  const coverH = Math.min(COVER_HEIGHT, height);

  const blurredPatch = await sharp(inputPath)
    .extract({ left: 0, top: 0, width, height: coverH })
    .blur(58)
    .modulate({ brightness: 0.68, saturation: 0.85 })
    .png()
    .toBuffer();

  const darken = buildDarkenOverlay(width, coverH);
  const leftWipe = buildLeftPanelWipe(width, coverH);
  const base = await sharp(inputPath).png().toBuffer();

  return sharp(base)
    .composite([
      { input: blurredPatch, left: 0, top: 0 },
      { input: darken, left: 0, top: 0, blend: 'over' },
      { input: leftWipe, left: 0, top: 0, blend: 'over' },
    ])
    .png()
    .toBuffer();
}

async function processScreen(screen) {
  const inputPath = path.join(SOURCE_DIR, screen.file);
  const outputPath = path.join(OUTPUT_DIR, screen.out);

  if (!fs.existsSync(inputPath)) {
    throw new Error(`Kaynak bulunamadı: ${inputPath}`);
  }

  const meta = await sharp(inputPath).metadata();
  const cleaned = await eraseOldText(inputPath);
  const textOverlay = buildTextOverlay(meta.width, screen);

  await sharp(cleaned)
    .composite([{ input: textOverlay, left: 0, top: 0 }])
    .png({ compressionLevel: 9 })
    .toFile(outputPath);

  const size = fs.statSync(outputPath).size;
  console.log(`✓ ${screen.out} (${meta.width}x${meta.height}, ${(size / 1024 / 1024).toFixed(2)} MB)`);
}

async function main() {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });

  for (const screen of SCREENS) {
    await processScreen(screen);
  }

  console.log(`\n${SCREENS.length} App Store görseli hazır → ${OUTPUT_DIR}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
