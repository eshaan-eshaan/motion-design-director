// scripts/qa-frames.cjs  (needs: npm i -D pngjs)   run: node scripts/qa-frames.cjs out/qa
// Light-mode and blank-frame gate for rendered PNG frames.
const fs = require('fs');
const path = require('path');
const {PNG} = require('pngjs');

const dir = process.argv[2] || 'out/qa';
const names = fs.readdirSync(dir).filter((n) => n.endsWith('.png')).sort();
let bad = 0;

for (const name of names) {
  const {width, height, data} = PNG.sync.read(fs.readFileSync(path.join(dir, name)));
  const total = width * height;
  const bg = [data[0], data[1], data[2]]; // top-left pixel approximates the canvas background
  let lumaSum = 0;
  let dark = 0;
  let content = 0;
  for (let i = 0; i < data.length; i += 4) {
    const luma = 0.2126 * data[i] + 0.7152 * data[i + 1] + 0.0722 * data[i + 2];
    lumaSum += luma;
    if (luma < 51) dark++; // below 20% luminance
    if (Math.abs(data[i] - bg[0]) > 6 || Math.abs(data[i + 1] - bg[1]) > 6 || Math.abs(data[i + 2] - bg[2]) > 6) content++;
  }
  const mean = lumaSum / total;
  const darkPct = (100 * dark) / total;
  const contentPct = (100 * content) / total;
  const flags = [];
  if (mean < 200) flags.push('DARK (mean luma < 200)');
  if (darkPct > 15) flags.push('DARK-AREA (> 15% of pixels)');
  if (contentPct < 0.5) flags.push('BLANK? (< 0.5% differs from background)');
  if (flags.length) bad++;
  console.log(`${name}  mean=${mean.toFixed(0)}  dark=${darkPct.toFixed(1)}%  content=${contentPct.toFixed(1)}%  ${flags.join(', ') || 'ok'}`);
}
process.exitCode = bad ? 1 : 0;
