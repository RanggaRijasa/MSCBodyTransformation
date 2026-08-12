import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';

function walk(directory) {
  return readdirSync(directory).flatMap((entry) => {
    const path = join(directory, entry);
    return statSync(path).isDirectory() ? walk(path) : [path];
  });
}

const javascriptFiles = walk('dist').filter((file) => file.endsWith('.js'));
if (javascriptFiles.length < 2) {
  throw new Error('Route-based bundle splitting belum terbukti.');
}

const bundleText = javascriptFiles.map((file) => readFileSync(file, 'utf8')).join('\n');
for (const unusedIcon of ['airplane-tilt', 'horse', 'piggy-bank']) {
  if (bundleText.includes(unusedIcon)) {
    throw new Error(`Glyph Phosphor yang tidak dipakai ikut terbundle: ${unusedIcon}`);
  }
}

for (const forbiddenSecretMarker of ['service_role', 'SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_SECRET']) {
  if (bundleText.includes(forbiddenSecretMarker)) {
    throw new Error(`Marker rahasia ditemukan pada output: ${forbiddenSecretMarker}`);
  }
}

const sourceFiles = walk('src').filter((file) => file.endsWith('.ts') || file.endsWith('.tsx'));
for (const file of sourceFiles) {
  if (file.endsWith('src/shared/icons/MSCIcon.tsx')) continue;
  if (readFileSync(file, 'utf8').includes('phosphor-react-native')) {
    throw new Error(`Import Phosphor langsung di luar MSCIcon: ${file}`);
  }
}

process.stdout.write(`Bundle split valid: ${javascriptFiles.length} berkas JavaScript.\n`);
