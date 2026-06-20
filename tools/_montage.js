const sharp = require('sharp');
const fs = require('fs'); const path = require('path');
const dir = process.argv[2], outFile = process.argv[3];
(async () => {
  const files = fs.readdirSync(dir).filter(f => /\.png$/i.test(f)).sort();
  const cellW = 240, perRow = 5;
  const tiles = [];
  for (const f of files) tiles.push(await sharp(path.join(dir, f)).resize(cellW).png().toBuffer());
  const cellH = (await sharp(tiles[0]).metadata()).height;
  const rows = Math.ceil(tiles.length / perRow);
  const comps = tiles.map((t, i) => ({ input: t, left: (i % perRow) * cellW, top: Math.floor(i / perRow) * cellH }));
  await sharp({ create: { width: perRow * cellW, height: rows * cellH, channels: 3, background: { r: 20, g: 20, b: 20 } } })
    .composite(comps).png().toFile(outFile);
  console.log('montage done');
})();
