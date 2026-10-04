// node tools/render-brand-icons.cjs; requires sharp (npm install --no-save sharp).
// Or set NODE_PATH to an existing sharp installation. No SF Symbols exports used.
const fs = require('node:fs');
const path = require('node:path');
const sharp = require('sharp');
const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'design/brand/motioncue-icon.svg'), 'utf8');
const catalog = path.join(root, 'mobile/ios/MotionCueSensor/MotionCueSensor/Resources/Assets.xcassets');
async function writePNG(svg, size, file) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  await sharp(Buffer.from(svg)).resize(size, size).png().toFile(file);
}
async function main() {
  await writePNG(source, 1024, path.join(catalog, 'AppIcon.appiconset/AppIcon.png'));
  await writePNG(source, 192, path.join(catalog, 'BrandMark.imageset/BrandMark.png'));
  const rounded = source.replace('rx="0"', 'rx="216"');
  await writePNG(rounded, 512, path.join(root, 'design/brand/motioncue-icon-preview.png'));
  const sizes = [16, 20, 24, 32, 40, 48, 64, 128, 256];
  const images = await Promise.all(sizes.map(size => sharp(Buffer.from(rounded)).resize(size, size).png().toBuffer()));
  const header = Buffer.alloc(6 + images.length * 16);
  header.writeUInt16LE(1, 2);
  header.writeUInt16LE(images.length, 4);
  let offset = header.length;
  sizes.forEach((size, i) => {
    const p = 6 + i * 16;
    header[p] = header[p + 1] = size === 256 ? 0 : size;
    header.writeUInt16LE(1, p + 4);
    header.writeUInt16LE(32, p + 6);
    header.writeUInt32LE(images[i].length, p + 8);
    header.writeUInt32LE(offset, p + 12);
    offset += images[i].length;
  });
  const destination = path.join(root, 'src/MotionCue.Windows/Assets/MotionCue.ico');
  fs.mkdirSync(path.dirname(destination), { recursive: true });
  fs.writeFileSync(destination, Buffer.concat([header, ...images]));
  console.log('iOS AppIcon, BrandMark, preview and 9-size Windows ICO generated.');
}
main().catch(error => { console.error(error); process.exitCode = 1; });
