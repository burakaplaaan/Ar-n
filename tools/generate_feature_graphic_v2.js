const sharp = require('sharp');

const W = 1024;
const H = 500;

async function cropPhoneScreen(inputPath) {
  const meta = await sharp(inputPath).metadata();
  const w = meta.width;
  const h = meta.height;
  const topCrop = Math.round(h * 0.035);
  const bottomCrop = Math.round(h * 0.055);
  return sharp(inputPath)
    .extract({ left: 0, top: topCrop, width: w, height: h - topCrop - bottomCrop })
    .toBuffer();
}

async function makePhoneMockup(inputPath, targetHeight) {
  const cleanScreen = await cropPhoneScreen(inputPath);
  const meta = await sharp(cleanScreen).metadata();
  const ratio = targetHeight / meta.height;
  const screenW = Math.round(meta.width * ratio);
  const screenH = targetHeight;

  const resizedScreen = await sharp(cleanScreen)
    .resize(screenW, screenH)
    .toBuffer();

  const radius = Math.round(screenW * 0.12);
  const mask = Buffer.from(
    `<svg width="${screenW}" height="${screenH}"><rect x="0" y="0" width="${screenW}" height="${screenH}" rx="${radius}" ry="${radius}" fill="#fff"/></svg>`
  );
  const roundedScreen = await sharp(resizedScreen)
    .composite([{ input: mask, blend: 'dest-in' }])
    .png()
    .toBuffer();

  const bezel = 7;
  const frameW = screenW + bezel * 2;
  const frameH = screenH + bezel * 2;
  const frameRadius = radius + bezel;

  const frameSvg = Buffer.from(`
    <svg width="${frameW}" height="${frameH}" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="frame" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#2a2a2a"/>
          <stop offset="50%" stop-color="#0a0a0a"/>
          <stop offset="100%" stop-color="#1a1a1a"/>
        </linearGradient>
      </defs>
      <rect x="0" y="0" width="${frameW}" height="${frameH}" rx="${frameRadius}" ry="${frameRadius}" fill="url(#frame)"/>
    </svg>
  `);

  return sharp(frameSvg)
    .composite([{ input: roundedScreen, left: bezel, top: bezel }])
    .png()
    .toBuffer();
}

async function rotatePhone(buffer, angle) {
  const rotated = await sharp(buffer)
    .rotate(angle, { background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .toBuffer();
  const meta = await sharp(rotated).metadata();
  return { buffer: rotated, width: meta.width, height: meta.height };
}


async function build() {
  const bgSvg = `
  <svg width="${W}" height="${H}" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <radialGradient id="bg" cx="28%" cy="40%" r="90%">
        <stop offset="0%" stop-color="#0E2A1E"/>
        <stop offset="55%" stop-color="#06120C"/>
        <stop offset="100%" stop-color="#020604"/>
      </radialGradient>
      <filter id="blur"><feGaussianBlur stdDeviation="60"/></filter>
    </defs>
    <rect width="100%" height="100%" fill="url(#bg)"/>
    <circle cx="100" cy="${H - 50}" r="170" fill="#4ade80" opacity="0.10" filter="url(#blur)"/>
    <circle cx="${W - 60}" cy="50" r="150" fill="#4ade80" opacity="0.08" filter="url(#blur)"/>

    <g transform="translate(48, 100)">
      <text x="0" y="0" font-family="Segoe UI, sans-serif" font-weight="800" font-size="72" fill="#ffffff" letter-spacing="-2">Arın</text>
      <text x="0" y="42" font-family="Segoe UI, sans-serif" font-weight="600" font-size="20" fill="#4ade80" letter-spacing="2.5">İSLAMİ YAŞAM ASİSTANI</text>
    </g>

    <g transform="translate(48, 280)">
      <text x="0" y="0" font-family="Segoe UI, sans-serif" font-weight="500" font-size="19" fill="rgba(255,255,255,0.78)">Namaz vakitleri • Zikirmatik • Kıble</text>
      <text x="0" y="30" font-family="Segoe UI, sans-serif" font-weight="500" font-size="19" fill="rgba(255,255,255,0.78)">Keşfet • Kilit ekranı widget</text>
      <text x="0" y="60" font-family="Segoe UI, sans-serif" font-weight="500" font-size="19" fill="rgba(255,255,255,0.78)">Saate özel ayet eşleşmeleri</text>
    </g>
  </svg>`;

  const phones = [
    {
      image: 'marketing/play-store/raw_screenshots/04_namaz.png',
      height: 300,
      angle: -16,
      left: 390,
      top: 95,
    },
    {
      image: 'marketing/play-store/raw_screenshots/01_kesfet.png',
      height: 300,
      angle: -9,
      left: 470,
      top: 85,
    },
    {
      image: 'marketing/play-store/raw_screenshots/07_kilit.png',
      height: 370,
      angle: -3,
      left: 560,
      top: 55,
    },
    {
      image: 'marketing/play-store/raw_screenshots/08_saat_ayet.png',
      height: 300,
      angle: 8,
      left: 700,
      top: 85,
    },
    {
      image: 'marketing/play-store/raw_screenshots/03_zikirmatik.png',
      height: 300,
      angle: 14,
      left: 820,
      top: 95,
    },
  ];

  const composites = [];
  for (const phone of phones) {
    const mockup = await makePhoneMockup(phone.image, phone.height);
    const rotated = await rotatePhone(mockup, phone.angle);
    composites.push({
      input: rotated.buffer,
      left: phone.left,
      top: phone.top,
    });
  }

  await sharp(Buffer.from(bgSvg))
    .composite(composites)
    .png()
    .toFile('marketing/play-store/feature_graphic_final.png');

  console.log('Feature graphic v4 (5 phones + labels) created.');
}

build().catch(console.error);
