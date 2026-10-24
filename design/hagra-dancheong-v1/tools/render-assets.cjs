// Development tool only: npm install sharp, then node tools/render-assets.cjs.
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');
const root = path.resolve(__dirname, '..');
(async () => {
  await sharp(path.join(root, 'assets/wallpaper.svg')).png().toFile(path.join(root, 'assets/wallpaper.png'));
  const names = fs.readdirSync(path.join(root, 'assets')).filter(n => n.endsWith('.svg') && n !== 'wallpaper.svg').sort();
  const width = 1120, height = Math.ceil(names.length / 4) * 190 + 76;
  let svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}"><rect width="100%" height="100%" fill="#FAF6EA"/><text x="28" y="38" font-family="sans-serif" font-size="22" fill="#203F42">HAGRA / Ornament and icon assets / v1</text>`;
  names.forEach((name, i) => {
    const x = 28 + i % 4 * 275, y = 68 + Math.floor(i / 4) * 190;
    const data = fs.readFileSync(path.join(root, 'assets', name)).toString('base64');
    svg += `<rect x="${x}" y="${y}" width="245" height="142" rx="2" fill="#E3ECE6"/><image x="${x+12}" y="${y+12}" width="221" height="115" href="data:image/svg+xml;base64,${data}"/><text x="${x}" y="${y+167}" font-family="sans-serif" font-size="14" fill="#203F42">${name}</text>`;
  });
  await sharp(Buffer.from(svg + '</svg>')).png().toFile(path.join(root, 'asset-sheet.png'));
  console.log(`Rendered wallpaper and sheet with ${names.length} SVG assets.`);
})().catch(error => { console.error(error); process.exit(1); });
