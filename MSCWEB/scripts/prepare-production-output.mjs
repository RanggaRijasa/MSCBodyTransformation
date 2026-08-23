import { createHash } from 'node:crypto';
import { copyFileSync, existsSync, mkdirSync, readFileSync } from 'node:fs';

if (!existsSync('dist/index.html') || !existsSync('dist/landing.html')) {
  throw new Error('Output Expo atau landing statis belum tersedia.');
}

copyFileSync('dist/index.html', 'dist/app.html');
copyFileSync('dist/landing.html', 'dist/index.html');
const wasmSource = 'node_modules/zxing-wasm/dist/reader/zxing_reader.wasm';
const wasmTarget = 'dist/wasm/zxing-reader-3.1.1-6a858c01.wasm';
const expectedWasmSha256 = '6a858c01e076bab3a1bd413e4f2cf5e5e45f819a0d9441d83c66993bc48ed38f';
const wasmSha256 = createHash('sha256').update(readFileSync(wasmSource)).digest('hex');
if (wasmSha256 !== expectedWasmSha256) {
  throw new Error('ZXing reader WASM tidak cocok dengan versi yang direview.');
}
mkdirSync('dist/wasm', { recursive: true });
copyFileSync(wasmSource, wasmTarget);
process.stdout.write('Output production siap: index.html statis + app.html SPA.\n');
