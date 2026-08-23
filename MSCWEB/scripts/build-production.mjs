import { readFileSync, statSync } from 'node:fs';
import { spawnSync } from 'node:child_process';

const environmentPath = '.env.production.local';
const expectedKeys = new Set([
  'EXPO_PUBLIC_SUPABASE_URL',
  'EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY',
  'EXPO_PUBLIC_AUTH_REDIRECT_URL',
]);

const mode = statSync(environmentPath).mode & 0o777;
if (process.platform !== 'win32' && mode !== 0o600) {
  throw new Error(`${environmentPath} wajib memiliki permission 0600.`);
}

const productionEnvironment = parseEnvironment(readFileSync(environmentPath, 'utf8'));
for (const key of expectedKeys) {
  if (!productionEnvironment[key]) throw new Error(`${key} belum diisi.`);
}
for (const key of Object.keys(productionEnvironment)) {
  if (!expectedKeys.has(key)) throw new Error(`Variabel production web tidak diizinkan: ${key}`);
}

const environment = { ...process.env };
for (const key of Object.keys(environment)) {
  if (key.startsWith('EXPO_PUBLIC_')) delete environment[key];
}
Object.assign(environment, productionEnvironment, {
  EXPO_NO_DOTENV: '1',
  NODE_ENV: 'production',
});

run('node_modules/.bin/expo', ['export', '--platform', 'web', '--clear'], environment);
run(process.execPath, ['scripts/prepare-production-output.mjs'], environment);

function parseEnvironment(source) {
  const result = {};
  for (const [index, rawLine] of source.split(/\r?\n/u).entries()) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) continue;
    const separator = line.indexOf('=');
    if (separator <= 0) throw new Error(`Baris env production tidak valid: ${index + 1}`);
    const key = line.slice(0, separator).trim();
    const value = line.slice(separator + 1).trim();
    if (!/^[A-Z][A-Z0-9_]*$/u.test(key) || !value) {
      throw new Error(`Baris env production tidak valid: ${index + 1}`);
    }
    result[key] = value;
  }
  return result;
}

function run(command, args, env) {
  const result = spawnSync(command, args, { env, stdio: 'inherit' });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
}
