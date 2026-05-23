const sharp = require('sharp');
const fs = require('fs');

async function createFeatureGraphic() {
    console.log("Starting feature graphic creation...");
    const bgWidth = 1024;
    const bgHeight = 500;
    
    // Create background
    const bgSvg = `
    <svg width="${bgWidth}" height="${bgHeight}" xmlns="http://www.w3.org/2000/svg">
        <defs>
            <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stop-color="#05100B" />
                <stop offset="100%" stop-color="#0C261B" />
            </linearGradient>
            <filter id="glow">
                <feGaussianBlur stdDeviation="15" result="coloredBlur"/>
                <feMerge>
                    <feMergeNode in="coloredBlur"/>
                    <feMergeNode in="SourceGraphic"/>
                </feMerge>
            </filter>
        </defs>
        <rect width="100%" height="100%" fill="url(#grad)" />
        
        <!-- Subtle decorative circles -->
        <circle cx="800" cy="250" r="300" fill="#4ade80" opacity="0.05" filter="url(#glow)" />
        <circle cx="200" cy="400" r="200" fill="#4ade80" opacity="0.03" filter="url(#glow)" />

        <!-- Text -->
        <g transform="translate(60, 200)">
            <text x="0" y="0" font-family="sans-serif" font-weight="900" font-size="54" fill="#ffffff" letter-spacing="-1">Arın</text>
            <text x="0" y="45" font-family="sans-serif" font-weight="600" font-size="28" fill="#4ade80" letter-spacing="1">İSLAMİ YAŞAM ASİSTANI</text>
            
            <text x="0" y="110" font-family="sans-serif" font-weight="400" font-size="20" fill="rgba(255,255,255,0.8)">Namaz vakitleri, zikirmatik, kıble pusulası</text>
            <text x="0" y="140" font-family="sans-serif" font-weight="400" font-size="20" fill="rgba(255,255,255,0.8)">ve saate özel ayet eşleşmeleri.</text>
        </g>
    </svg>`;

    // Process screenshots
    // We will resize them to fit the graphic
    const scHeight = 380;
    
    // Left screenshot (Namaz)
    const scLeft = await sharp('marketing/play-store/raw_screenshots/04_namaz.png')
        .resize({ height: scHeight })
        .toBuffer();
        
    // Right screenshot (Zikirmatik)
    const scRight = await sharp('marketing/play-store/raw_screenshots/03_zikirmatik.png')
        .resize({ height: scHeight })
        .toBuffer();
        
    // Center screenshot (Saat Ayet)
    const scCenter = await sharp('marketing/play-store/raw_screenshots/08_saat_ayet.png')
        .resize({ height: scHeight + 40 }) // slightly larger
        .toBuffer();

    // Add rounded corners and borders to screenshots
    async function formatScreenshot(buffer, height) {
        const meta = await sharp(buffer).metadata();
        const width = meta.width;
        const radius = 20;
        
        const mask = Buffer.from(`
            <svg><rect x="0" y="0" width="${width}" height="${height}" rx="${radius}" ry="${radius}" fill="#fff" /></svg>
        `);
        
        const rounded = await sharp(buffer)
            .composite([{ input: mask, blend: 'dest-in' }])
            .png()
            .toBuffer();
            
        // Add border
        const border = Buffer.from(`
            <svg width="${width}" height="${height}">
                <rect x="1" y="1" width="${width-2}" height="${height-2}" rx="${radius}" ry="${radius}" fill="none" stroke="rgba(255,255,255,0.15)" stroke-width="2" />
            </svg>
        `);
        
        return sharp(rounded)
            .composite([{ input: border }])
            .png()
            .toBuffer();
    }

    const formattedLeft = await formatScreenshot(scLeft, scHeight);
    const formattedRight = await formatScreenshot(scRight, scHeight);
    const formattedCenter = await formatScreenshot(scCenter, scHeight + 40);

    // App Icon
    const icon = await sharp('assets/branding/app_icon_512_no_alpha.png')
        .resize(100, 100)
        .png()
        .toBuffer();
        
    // Add rounded corners to icon
    const iconMask = Buffer.from(`<svg><rect x="0" y="0" width="100" height="100" rx="22" ry="22" fill="#fff" /></svg>`);
    const formattedIcon = await sharp(icon)
        .composite([{ input: iconMask, blend: 'dest-in' }])
        .png()
        .toBuffer();

    // Composite everything
    await sharp(Buffer.from(bgSvg))
        .composite([
            { input: formattedLeft, left: 520, top: 60 },
            { input: formattedRight, left: 780, top: 60 },
            { input: formattedCenter, left: 630, top: 40 }, // Center is on top
            { input: formattedIcon, left: 60, top: 60 }
        ])
        .toFile('marketing/play-store/feature_graphic_final.png');
        
    console.log("Feature graphic created successfully!");
}

createFeatureGraphic().catch(console.error);
