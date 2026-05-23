const sharp = require('sharp');
const fs = require('fs');

const PROMO_WIDTH = 1080;
const PROMO_HEIGHT = 1920;
const HEADER_TOP = 90;
const TEXT_OFFSET_Y = 70;

const screens = [
  {
    id: '01_kesfet',
    title: 'Keşfet',
    subtitle: 'Ayet, hadis ve hikmetli sözler\nhuzurlu fon müziği eşliğinde',
    image: 'marketing/play-store/raw_screenshots/02_quote.png',
  },
  {
    id: '02_zikirmatik',
    title: 'Zikirmatik',
    subtitle: 'Ergonomik sayaç, zikir geçmişi\nve detaylı istatistikler',
    image: 'marketing/play-store/raw_screenshots/03_zikirmatik.png',
  },
  {
    id: '03_namaz',
    title: 'Namaz Vakitleri',
    subtitle: 'Diyanet uyumlu vakitler, namaz takibi\nve vakit bildirimleri',
    image: 'marketing/play-store/raw_screenshots/04_namaz.png',
  },
  {
    id: '04_pusula',
    title: 'Kıble Pusulası',
    subtitle: 'Nerede olursanız olun\nen doğru kıble yönü',
    image: 'marketing/play-store/raw_screenshots/05_pusula.png',
  },
  {
    id: '05_frekans',
    title: 'İyileştirici Frekanslar',
    subtitle: 'Huzur veren fon müzikleri\nve ayarlanabilir şifa frekansları',
    image: 'marketing/play-store/raw_screenshots/06_frekans.png',
  },
  {
    id: '06_kilit',
    title: 'Kilit Ekranı Widget',
    subtitle: 'Telefonu açmadan\nanlık ayet ve sözler',
    image: 'marketing/play-store/raw_screenshots/07_kilit.png',
  },
  {
    id: '07_saat_ayet',
    title: 'Saate Özel Ayet',
    subtitle: 'Saatiniz bir ayete dönüşür\nbu tesadüf değildir',
    image: 'marketing/play-store/raw_screenshots/08_saat_ayet.png',
  },
  {
    id: '08_gelisim_arinma',
    title: 'Gelişim & Arınma',
    subtitle: 'İyi alışkanlıkları takip et\nkötü alışkanlıklardan uzak kal',
    dual: true,
    images: [
      'marketing/play-store/raw_screenshots/10_gelisim.png',
      'marketing/play-store/raw_screenshots/09_arinma.png',
    ],
  },
];

function escapeXml(value) {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function buildHeaderSvg(title, subtitle) {
  const lines = subtitle.split('\n');
  const line1 = escapeXml(lines[0] ?? '');
  const line2 = escapeXml(lines[1] ?? '');
  const titleY = 96 + TEXT_OFFSET_Y;
  const lineY = 118 + TEXT_OFFSET_Y;
  const sub1Y = 168 + TEXT_OFFSET_Y;
  const sub2Y = 210 + TEXT_OFFSET_Y;

  return `
  <svg width="${PROMO_WIDTH}" height="480" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="titleGrad" x1="0%" y1="0%" x2="100%" y2="0%">
        <stop offset="0%" stop-color="#ffffff"/>
        <stop offset="100%" stop-color="#d1fae5"/>
      </linearGradient>
      <filter id="titleShadow" x="-20%" y="-20%" width="140%" height="140%">
        <feDropShadow dx="0" dy="4" stdDeviation="8" flood-color="#000000" flood-opacity="0.35"/>
      </filter>
    </defs>

    <rect x="490" y="${lineY}" width="100" height="4" rx="2" fill="#4ade80" opacity="0.9"/>
    <text x="540" y="${titleY}" font-family="Segoe UI, Arial, sans-serif" font-weight="800" font-size="68"
          fill="url(#titleGrad)" text-anchor="middle" letter-spacing="-1.5" filter="url(#titleShadow)">
      ${escapeXml(title)}
    </text>
    <text x="540" y="${sub1Y}" font-family="Segoe UI, Arial, sans-serif" font-weight="500" font-size="30"
          fill="rgba(255,255,255,0.82)" text-anchor="middle">${line1}</text>
    <text x="540" y="${sub2Y}" font-family="Segoe UI, Arial, sans-serif" font-weight="400" font-size="28"
          fill="rgba(255,255,255,0.58)" text-anchor="middle">${line2}</text>
  </svg>`;
}

function buildBackgroundSvg() {
  return `
  <svg width="${PROMO_WIDTH}" height="${PROMO_HEIGHT}" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <radialGradient id="bg" cx="50%" cy="35%" r="75%">
        <stop offset="0%" stop-color="#123628"/>
        <stop offset="45%" stop-color="#081912"/>
        <stop offset="100%" stop-color="#030806"/>
      </radialGradient>
      <filter id="glow">
        <feGaussianBlur stdDeviation="55" result="blur"/>
        <feMerge>
          <feMergeNode in="blur"/>
          <feMergeNode in="SourceGraphic"/>
        </feMerge>
      </filter>
    </defs>
    <rect width="100%" height="100%" fill="url(#bg)"/>
    <circle cx="540" cy="980" r="420" fill="#4ade80" opacity="0.07" filter="url(#glow)"/>
    <circle cx="180" cy="300" r="120" fill="#4ade80" opacity="0.04"/>
    <circle cx="900" cy="1700" r="160" fill="#4ade80" opacity="0.05"/>
  </svg>`;
}

async function cropPhoneScreen(inputPath) {
  const img = sharp(inputPath);
  const meta = await img.metadata();
  const w = meta.width;
  const h = meta.height;
  const topCrop = Math.round(h * 0.035);
  const bottomCrop = Math.round(h * 0.055);
  return img
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

  const radius = Math.round(screenW * 0.11);
  const mask = Buffer.from(
    `<svg width="${screenW}" height="${screenH}"><rect x="0" y="0" width="${screenW}" height="${screenH}" rx="${radius}" ry="${radius}" fill="#fff"/></svg>`
  );
  const roundedScreen = await sharp(resizedScreen)
    .composite([{ input: mask, blend: 'dest-in' }])
    .png()
    .toBuffer();

  const bezel = 10;
  const frameW = screenW + bezel * 2;
  const frameH = screenH + bezel * 2;
  const frameRadius = radius + bezel;

  const frameSvg = Buffer.from(`
    <svg width="${frameW}" height="${frameH}" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="frame" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#3a3a3a"/>
          <stop offset="50%" stop-color="#111111"/>
          <stop offset="100%" stop-color="#252525"/>
        </linearGradient>
        <filter id="phoneShadow" x="-20%" y="-10%" width="140%" height="130%">
          <feDropShadow dx="0" dy="18" stdDeviation="24" flood-color="#000000" flood-opacity="0.45"/>
        </filter>
      </defs>
      <rect x="0" y="0" width="${frameW}" height="${frameH}" rx="${frameRadius}" ry="${frameRadius}"
            fill="url(#frame)" filter="url(#phoneShadow)"/>
      <rect x="${bezel + 1}" y="${bezel + 1}" width="${screenW - 2}" height="${screenH - 2}"
            rx="${radius - 1}" ry="${radius - 1}" fill="none" stroke="rgba(74,222,128,0.22)" stroke-width="2"/>
    </svg>
  `);

  return sharp(frameSvg)
    .composite([{ input: roundedScreen, left: bezel, top: bezel }])
    .png()
    .toBuffer();
}

async function createPromoScreenshots() {
  if (!fs.existsSync('marketing/play-store/promo')) {
    fs.mkdirSync('marketing/play-store/promo', { recursive: true });
  }

  const bgBuffer = Buffer.from(buildBackgroundSvg());
  const singlePhoneHeight = 1280;
  const dualPhoneHeight = 980;
  const singlePhoneTop = 480;
  const dualPhoneTop = 500;

  for (const screen of screens) {
    console.log(`Generating promo for ${screen.id}...`);

    const headerBuffer = Buffer.from(buildHeaderSvg(screen.title, screen.subtitle));
    const composites = [{ input: headerBuffer, left: 0, top: HEADER_TOP }];

    if (screen.dual) {
      const leftPhone = await makePhoneMockup(screen.images[0], dualPhoneHeight);
      const rightPhone = await makePhoneMockup(screen.images[1], dualPhoneHeight);
      const leftMeta = await sharp(leftPhone).metadata();
      const rightMeta = await sharp(rightPhone).metadata();
      const gap = 24;
      const totalWidth = leftMeta.width + gap + rightMeta.width;
      const leftX = Math.round((PROMO_WIDTH - totalWidth) / 2);
      const rightX = leftX + leftMeta.width + gap;

      composites.push(
        { input: leftPhone, left: leftX, top: dualPhoneTop },
        { input: rightPhone, left: rightX, top: dualPhoneTop },
      );
    } else {
      const phone = await makePhoneMockup(screen.image, singlePhoneHeight);
      const phoneMeta = await sharp(phone).metadata();
      const phoneLeft = Math.round((PROMO_WIDTH - phoneMeta.width) / 2);
      composites.push({ input: phone, left: phoneLeft, top: singlePhoneTop });
    }

    await sharp(bgBuffer)
      .composite(composites)
      .png()
      .toFile(`marketing/play-store/promo/${screen.id}_promo.png`);
  }

  const stale = [
    'marketing/play-store/promo/08_arinma_promo.png',
    'marketing/play-store/promo/09_gelisim_promo.png',
  ];
  for (const file of stale) {
    if (fs.existsSync(file)) fs.unlinkSync(file);
  }

  console.log('All promo screenshots generated successfully!');
}

createPromoScreenshots().catch(console.error);
