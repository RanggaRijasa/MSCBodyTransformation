import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';

const webEnvironment = parseEnvironment(readFileSync('.env.production.local', 'utf8'));
const serverEnvironment = parseEnvironment(readFileSync('supabase/.env.production.local', 'utf8'));
const bundle = walk('dist')
  .filter((file) => file.endsWith('.js') || file.endsWith('.html'))
  .map((file) => readFileSync(file, 'utf8'))
  .join('\n');

for (const required of [
  webEnvironment.EXPO_PUBLIC_SUPABASE_URL,
  webEnvironment.EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
  webEnvironment.EXPO_PUBLIC_AUTH_REDIRECT_URL,
]) {
  if (!required || !bundle.includes(required)) {
    throw new Error('Nilai public production yang diwajibkan tidak terbundle.');
  }
}

for (const key of [
  'PAYMENT_CLEANUP_JOB_SECRET',
  'PROVISIONAL_CLEANUP_JOB_SECRET',
  'FOOD_AI_WORKER_SECRET',
  'FOOD_AI_API_KEY',
]) {
  const secret = serverEnvironment[key];
  if (secret && bundle.includes(secret)) {
    throw new Error(`Secret server terdeteksi pada bundle: ${key}`);
  }
}

const localEnvironment = existsSync('.env.local')
  ? parseEnvironment(readFileSync('.env.local', 'utf8'))
  : {};
for (const key of ['EXPO_PUBLIC_SUPABASE_URL', 'EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY']) {
  const localValue = localEnvironment[key];
  const productionValue = webEnvironment[key];
  if (localValue && localValue !== productionValue && bundle.includes(localValue)) {
    throw new Error(`Nilai development terdeteksi pada bundle production: ${key}`);
  }
}

process.stdout.write('Bundle memakai public production env tanpa job/provider secret.\n');

function walk(directory) {
  return readdirSync(directory).flatMap((entry) => {
    const path = join(directory, entry);
    return statSync(path).isDirectory() ? walk(path) : [path];
  });
}

function parseEnvironment(source) {
  return Object.fromEntries(source.split(/\r?\n/u).flatMap((rawLine) => {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) return [];
    const separator = line.indexOf('=');
    if (separator <= 0) return [];
    return [[line.slice(0, separator).trim(), line.slice(separator + 1).trim()]];
  }));
}
