const sharp = require('sharp');

const OVERRIDE = {};
function keyFor(fname) { for (const k of Object.keys(OVERRIDE)) if (fname.includes(k)) return k; return null; }

function smoothArr(a, w) {
  const n = a.length, out = new Array(n).fill(0);
  let sum = 0; const half = Math.floor(w / 2);
  for (let i = 0; i < n + half; i++) {
    if (i < n) sum += a[i];
    if (i - w >= 0) sum -= a[i - w];
    const idx = i - half; if (idx >= 0 && idx < n) out[idx] = sum / Math.min(w, i + 1);
  }
  return out;
}

async function detect(file) {
  const { data, info } = await sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const W = info.width, H = info.height, C = info.channels;
  const br = (x, y) => { const i = (y * W + x) * C; return (data[i] + data[i + 1] + data[i + 2]) / 3; };
  const G = (x, y) => Math.abs(br(x + 1, y) - br(x - 1, y)) + Math.abs(br(x, y + 1) - br(x, y - 1));

  // phone columns via gradient energy over a lower band
  const yb0 = Math.round(0.46 * H), yb1 = Math.round(0.88 * H);
  const colE = new Array(W).fill(0);
  for (let x = 1; x < W - 1; x++) { let s = 0; for (let y = yb0; y < yb1; y += 2) s += G(x, y); colE[x] = s; }
  const cmax = Math.max(...colE); const ct = cmax * 0.16;
  let px0 = 0, px1 = W - 1;
  for (let x = 0; x < W; x++) { if (colE[x] > ct) { px0 = x; break; } }
  for (let x = W - 1; x >= 0; x--) { if (colE[x] > ct) { px1 = x; break; } }

  // phone vertical via frame-edge energy (independent of dark screen content)
  const sw = Math.round(0.022 * W);
  const frameE = new Array(H).fill(0);
  for (let y = 1; y < H - 1; y++) {
    let e = 0;
    for (let x = Math.max(1, px0 - 4); x <= Math.min(W - 2, px0 + sw); x++) e += G(x, y);
    for (let x = Math.max(1, px1 - sw); x <= Math.min(W - 2, px1 + 4); x++) e += G(x, y);
    frameE[y] = e;
  }
  const fS = smoothArr(frameE, 15);
  let fmax = 0; for (let y = Math.round(0.3 * H); y < Math.round(0.95 * H); y++) fmax = Math.max(fmax, fS[y]);
  const ft = fmax * 0.13;
  const cy = Math.round(0.60 * H);
  const gapY = Math.round(0.03 * H);
  let py0 = cy, py1 = cy, miss = 0;
  for (let y = cy; y >= 0; y--) { if (fS[y] > ft) { py0 = y; miss = 0; } else if (++miss > gapY) break; }
  miss = 0;
  for (let y = cy; y < H; y++) { if (fS[y] > ft) { py1 = y; miss = 0; } else if (++miss > gapY) break; }

  // text band (above the phone)
  const tTop = Math.round(0.03 * H), tBot = py0 - Math.round(0.015 * H);
  const lx = Math.round(0.05 * W), rx = Math.round(0.95 * W);
  const sideArr = [];
  for (let y = tTop; y < tBot; y += 3) for (let x = 0; x < Math.round(0.035 * W); x++) sideArr.push(br(x, y));
  sideArr.sort((a, b) => a - b); const tbg = sideArr.length ? sideArr[Math.floor(sideArr.length / 2)] : 8;
  const strongThr = Math.max(150, tbg + 90);
  const softThr = tbg + 22;
  const rowCntSoft = new Array(H).fill(0), rowCntStrong = new Array(H).fill(0);
  for (let y = tTop; y < tBot; y++) {
    let cs = 0, cg = 0;
    for (let x = lx; x < rx; x++) { const b = br(x, y); if (b > softThr) cs++; if (b > strongThr) cg++; }
    rowCntSoft[y] = cs; rowCntStrong[y] = cg;
  }
  let s0 = -1, s1 = -1;
  for (let y = tTop; y < tBot; y++) if (rowCntStrong[y] > 0.02 * W) { if (s0 < 0) s0 = y; s1 = y; }
  let ty0, ty1;
  if (s0 < 0) {
    for (let y = tTop; y < tBot; y++) if (rowCntSoft[y] > 0.02 * W) { if (ty0 === undefined) ty0 = y; ty1 = y; }
    ty0 = ty0 ?? Math.round(0.12 * H); ty1 = ty1 ?? Math.round(0.30 * H);
  } else {
    const gapT = Math.round(0.025 * H);
    const upLimit = Math.max(tTop, s0 - Math.round(0.075 * H));
    const downLimit = Math.min(tBot, s1 + Math.round(0.11 * H));
    ty0 = s0; ty1 = s1; let m = 0;
    for (let y = s0; y >= upLimit; y--) { if (rowCntSoft[y] > 0.012 * W) { ty0 = y; m = 0; } else if (++m > gapT) break; }
    m = 0;
    for (let y = s1; y < downLimit; y++) { if (rowCntSoft[y] > 0.012 * W) { ty1 = y; m = 0; } else if (++m > gapT) break; }
  }

  return { W, H, data, C, phone: { x0: px0, x1: px1, y0: py0, y1: py1 }, text: { y0: ty0, y1: ty1 }, dbg: { tbg, fmax, cmax } };
}

async function getBoxes(file, fname) {
  const d = await detect(file);
  const k = keyFor(fname);
  if (k) {
    const o = OVERRIDE[k];
    if (o.tt != null) d.text.y0 = Math.round(o.tt * d.H);
    if (o.tb != null) d.text.y1 = Math.round(o.tb * d.H);
    if (o.pt != null) d.phone.y0 = Math.round(o.pt * d.H);
    if (o.pb != null) d.phone.y1 = Math.round(o.pb * d.H);
  }
  return d;
}

module.exports = { getBoxes, detect, OVERRIDE };
