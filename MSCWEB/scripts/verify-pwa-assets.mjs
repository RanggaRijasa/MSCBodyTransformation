import { readFileSync } from 'node:fs';

const expectedDimensions = new Map([
  ['public/icons/icon-192.png', [192, 192]],
  ['public/icons/icon-512.png', [512, 512]],
  ['public/icons/icon-maskable-192.png', [192, 192]],
  ['public/icons/icon-maskable-512.png', [512, 512]],
  ['public/icons/apple-touch-icon.png', [180, 180]],
  ['public/icons/favicon-48.png', [48, 48]],
]);

function readPNGDimensions(filePath) {
  const bytes = readFileSync(filePath);
  const signature = bytes.subarray(0, 8).toString('hex');

  if (signature !== '89504e470d0a1a0a') {
    throw new Error(`${filePath} bukan PNG yang valid.`);
  }

  return [bytes.readUInt32BE(16), bytes.readUInt32BE(20)];
}

for (const [filePath, expected] of expectedDimensions) {
  const actual = readPNGDimensions(filePath);
  if (actual[0] !== expected[0] || actual[1] !== expected[1]) {
    throw new Error(`${filePath}: ukuran ${actual.join('x')}, expected ${expected.join('x')}.`);
  }
}

const manifest = JSON.parse(readFileSync('public/manifest.webmanifest', 'utf8'));
const purposes = new Set(manifest.icons.map((icon) => `${icon.sizes}:${icon.purpose}`));

for (const required of ['192x192:any', '512x512:any', '192x192:maskable', '512x512:maskable']) {
  if (!purposes.has(required)) {
    throw new Error(`Manifest kehilangan icon ${required}.`);
  }
}

process.stdout.write('PWA icons dan manifest valid.\n');
