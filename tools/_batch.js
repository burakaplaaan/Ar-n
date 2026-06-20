const sharp = require('sharp');
const fs = require('fs');
const path = require('path');
const { getBoxes } = require('./_boxes');

const TEXT_TOP_FRAC = 0.043;
const PHONE_TOP_FRAC = 0.293;
const PHONE_W_FRAC = 0.748;

const clamp = (v, a, b) => (v < a ? a : v > b ? b : v);
const smooth = (x, a, b) => { let t = (x - a) / (b - a); t = clamp(t, 0, 1); return t * t * (3 - 2 * t); };

function avgColor(data, W, C, x0, x1, y0, y1) {
  let r = 0, g = 0, b = 0, n = 0;
  for (let y = y0; y < y1; y++) for (let x = x0; x < x1; x++) { const i = (y * W + x) * C; r += data[i]; g += data[i + 1]; b += data[i + 2]; n++; }
  return n ? [r / n, g / n, b / n] : [0, 0, 0];
}

async function processImage(file, outFile) {
  const d = await getBoxes(file, path.basename(file));
  const { W, H, data, C, phone, text, dbg } = d;

  // ---- phone crop bounds, extended to include the rounded top/bottom bezel ----
  const cropW = phone.x1 - phone.x0 + 1;
  const cornerExt = Math.round(0.05 * cropW);
  const cropTop = Math.max(0, phone.y0 - cornerExt);
  const cropBot = Math.min(H, phone.y1 + cornerExt);
  const cropH = cropBot - cropTop;

  const newTextTop = Math.round(TEXT_TOP_FRAC * H);
  const newPhoneTop = Math.min(Math.round(PHONE_TOP_FRAC * H), cropTop);

  // ---------- clean base: erase old text, ghost title AND any old-phone-top sliver ----------
  const base = Buffer.from(data);
  const pad = Math.round(0.012 * H);
  const bandTop = 0;
  const bandBot = Math.min(H, Math.max(text.y1 + pad, newPhoneTop + Math.round(0.012 * H)));
  const bandH = bandBot - bandTop;
  const textRowStart = Math.max(0, text.y0 - pad);
  const tbg = dbg.tbg;
  const tlo = tbg + 5, thi = tbg + 22;
  const mL0 = Math.round(0.006 * W), mL1 = Math.round(0.05 * W);
  const mR0 = W - Math.round(0.05 * W), mR1 = W - Math.round(0.006 * W);

  const alpha = new Float32Array(bandH * W);
  const interpR = new Float32Array(bandH * W), interpG = new Float32Array(bandH * W), interpB = new Float32Array(bandH * W);
  for (let yy = 0; yy < bandH; yy++) {
    const y = bandTop + yy;
    const lref = avgColor(data, W, C, mL0, mL1, y, y + 1);
    const rref = avgColor(data, W, C, mR0, mR1, y, y + 1);
    for (let x = 0; x < W; x++) {
      const i = (y * W + x) * C;
      const b = (data[i] + data[i + 1] + data[i + 2]) / 3;
      alpha[yy * W + x] = smooth(b, tlo, thi);
      const t = x / (W - 1);
      interpR[yy * W + x] = lref[0] + (rref[0] - lref[0]) * t;
      interpG[yy * W + x] = lref[1] + (rref[1] - lref[1]) * t;
      interpB[yy * W + x] = lref[2] + (rref[2] - lref[2]) * t;
    }
  }
  // separable max-dilation to fully cover text + its soft outer glow/halo
  const r = Math.max(6, Math.round(0.011 * W));
  const tmp = new Float32Array(bandH * W);
  for (let yy = 0; yy < bandH; yy++) {
    const row = yy * W;
    for (let x = 0; x < W; x++) {
      let m = 0; const x0 = Math.max(0, x - r), x1 = Math.min(W - 1, x + r);
      for (let nx = x0; nx <= x1; nx++) { const v = alpha[row + nx]; if (v > m) m = v; }
      tmp[row + x] = m;
    }
  }
  const dil = new Float32Array(bandH * W);
  for (let x = 0; x < W; x++) {
    for (let yy = 0; yy < bandH; yy++) {
      let m = 0; const y0 = Math.max(0, yy - r), y1 = Math.min(bandH - 1, yy + r);
      for (let ny = y0; ny <= y1; ny++) { const v = tmp[ny * W + x]; if (v > m) m = v; }
      dil[yy * W + x] = m;
    }
  }
  for (let yy = 0; yy < bandH; yy++) {
    const y = bandTop + yy;
    for (let x = 0; x < W; x++) {
      const k = yy * W + x;
      const e = Math.min(1, dil[k] * 1.15); if (e <= 0) continue;
      const i = (y * W + x) * C;
      base[i] = Math.round(data[i] * (1 - e) + interpR[k] * e);
      base[i + 1] = Math.round(data[i + 1] * (1 - e) + interpG[k] * e);
      base[i + 2] = Math.round(data[i + 2] * (1 - e) + interpB[k] * e);
    }
  }
  // smooth the erased patches so they blend with the surrounding glow gradient
  const blurredRaw = await sharp(Buffer.from(base), { raw: { width: W, height: H, channels: C } })
    .blur(Math.max(8, 0.014 * W)).raw().toBuffer();
  for (let yy = 0; yy < bandH; yy++) {
    const y = bandTop + yy;
    for (let x = 0; x < W; x++) {
      const e = Math.min(1, dil[yy * W + x] * 1.15); if (e <= 0) continue;
      const i = (y * W + x) * C;
      base[i] = Math.round(base[i] * (1 - e) + blurredRaw[i] * e);
      base[i + 1] = Math.round(base[i + 1] * (1 - e) + blurredRaw[i + 1] * e);
      base[i + 2] = Math.round(base[i + 2] * (1 - e) + blurredRaw[i + 2] * e);
    }
  }

  const basePng = await sharp(base, { raw: { width: W, height: H, channels: C } }).png().toBuffer();
  if (process.env.DBG) { await sharp(basePng).toFile(outFile.replace(/\.png$/i, '_base.png')); console.log('  band', JSON.stringify({ textY0: text.y0, textY1: text.y1, bandBot, newPhoneTop })); }

  // ---------- crisp keyed text layer (real text only, never reaching into the phone) ----------
  const textLayerBot = Math.min(bandBot, text.y1 + pad, cropTop - Math.round(0.004 * H));
  const layerH = textLayerBot - textRowStart;
  const textBuf = Buffer.alloc(W * layerH * 4);
  for (let yy = 0; yy < layerH; yy++) {
    const y = textRowStart + yy;
    for (let x = 0; x < W; x++) {
      const i = (y * W + x) * C; const o = (yy * W + x) * 4;
      textBuf[o] = data[i]; textBuf[o + 1] = data[i + 1]; textBuf[o + 2] = data[i + 2];
      textBuf[o + 3] = Math.round(alpha[y * W + x] * 255);
    }
  }

  // ---------- text placement ----------
  const textH = text.y1 - text.y0;
  const gap = Math.round(0.022 * H);
  let placeTextTop = newTextTop - pad;
  let scale = 1;
  if (newTextTop + textH + gap > newPhoneTop) {
    const lifted = newPhoneTop - gap - textH;
    if (lifted >= Math.round(0.012 * H)) placeTextTop = lifted - pad;
    else { scale = (newPhoneTop - gap - Math.round(0.012 * H)) / textH; placeTextTop = Math.round(0.012 * H) - Math.round(pad * scale); }
  }
  let textPng, textLeft = 0;
  if (scale < 0.999) {
    const sW = Math.round(W * scale), sH = Math.round(layerH * scale);
    textPng = await sharp(textBuf, { raw: { width: W, height: layerH, channels: 4 } }).resize(sW, sH).png().toBuffer();
    textLeft = Math.round((W - sW) / 2);
  } else {
    textPng = await sharp(textBuf, { raw: { width: W, height: layerH, channels: 4 } }).png().toBuffer();
  }

  // ---------- enlarged phone ----------
  const aspect = cropH / cropW;
  let newW = Math.round(PHONE_W_FRAC * W);
  let newH = Math.round(newW * aspect);
  const maxH = H - newPhoneTop - Math.round(0.006 * H);
  if (newH > maxH) { newH = maxH; newW = Math.round(newH / aspect); }
  const newX = Math.round((W - newW) / 2);
  const phoneCrop = await sharp(data, { raw: { width: W, height: H, channels: C } })
    .extract({ left: phone.x0, top: cropTop, width: cropW, height: cropH })
    .resize(newW, newH).png().toBuffer();
  const rad = Math.round(newW * 0.115);
  const maskSvg = `<svg width="${newW}" height="${newH}"><rect x="1" y="1" width="${newW - 2}" height="${newH - 2}" rx="${rad}" ry="${rad}" fill="#fff"/></svg>`;
  const mask = await sharp(Buffer.from(maskSvg)).blur(Math.max(0.6, newW / 320)).png().toBuffer();
  const phonePng = await sharp(phoneCrop).composite([{ input: mask, blend: 'dest-in' }]).png().toBuffer();

  // glow color sampled around old phone
  const gl = avgColor(data, W, C, Math.max(0, phone.x0 - Math.round(0.05 * W)), phone.x0, phone.y0, phone.y1);
  const gr = avgColor(data, W, C, phone.x1, Math.min(W, phone.x1 + Math.round(0.05 * W)), phone.y0, phone.y1);
  const gcol = [(gl[0] + gr[0]) / 2, (gl[1] + gr[1]) / 2, (gl[2] + gr[2]) / 2];
  const mx = Math.max(...gcol) || 1; const boost = clamp(120 / mx, 1, 6);
  const gR = clamp(Math.round(gcol[0] * boost), 0, 255), gG = clamp(Math.round(gcol[1] * boost), 0, 255), gB = clamp(Math.round(gcol[2] * boost), 0, 255);
  const GP = Math.round(newW * 0.16);
  const glowW = Math.min(W, newW + GP * 2), glowH = newH + GP * 2;
  const glowRectX = Math.round((glowW - newW) / 2);
  const glowSvg = `<svg width="${glowW}" height="${glowH}"><rect x="${glowRectX}" y="${GP}" width="${newW}" height="${newH}" rx="${rad + 20}" ry="${rad + 20}" fill="rgb(${gR},${gG},${gB})"/></svg>`;
  const glowPng = await sharp(Buffer.from(glowSvg)).blur(Math.max(8, newW / 12)).png().toBuffer();

  await sharp(basePng).composite([
    { input: glowPng, left: Math.round(newX - (glowW - newW) / 2), top: newPhoneTop - GP },
    { input: phonePng, left: newX, top: newPhoneTop },
    { input: textPng, left: textLeft, top: Math.max(0, placeTextTop) },
  ]).png().toFile(outFile);
  console.log(path.basename(file), '-> phone', JSON.stringify({ cropTop, cropBot, newPhoneTop, newW, newH }), 'scale', +scale.toFixed(3));
}

(async () => {
  const dir = process.argv[2], outDir = process.argv[3], only = process.argv[4];
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
  for (const f of fs.readdirSync(dir)) {
    if (!/\.png$/i.test(f)) continue;
    if (only && !f.includes(only)) continue;
    await processImage(path.join(dir, f), path.join(outDir, f));
  }
})();
