import { readdirSync, statSync } from 'node:fs';
import { basename, join } from 'node:path';

function walk(directory) {
  return readdirSync(directory).flatMap((entry) => {
    const path = join(directory, entry);
    return statSync(path).isDirectory() ? walk(path) : [path];
  });
}

const budgets = Object.freeze({
  appBootstrapBytes: 2_750_000,
  heroImageBytes: 350_000,
  javascriptFileCount: 60,
  largestJavaScriptBytes: 1_650_000,
  landingCriticalBytes: 64_000,
  totalJavaScriptBytes: 3_200_000,
});

const files = walk('dist');
const javascript = files.filter((file) => file.endsWith('.js'));
const totalJavaScriptBytes = javascript.reduce((total, file) => total + statSync(file).size, 0);
const largestJavaScriptBytes = Math.max(...javascript.map((file) => statSync(file).size));
const appBootstrapPattern = /\/(?:__common|entry|__expo-metro-runtime|_layout)-[^/]+\.js$/u;
const appBootstrapBytes = javascript
  .filter((file) => appBootstrapPattern.test(file))
  .reduce((total, file) => total + statSync(file).size, 0);
const landingCriticalFiles = ['dist/landing.css', 'dist/install-pwa.js', 'dist/register-sw.js'];
const landingCriticalBytes = landingCriticalFiles.reduce((total, file) => total + statSync(file).size, 0);
const heroImageBytes = statSync('dist/images/landing-hero.jpg').size;

const measurements = {
  appBootstrapBytes,
  heroImageBytes,
  javascriptFileCount: javascript.length,
  largestJavaScriptBytes,
  landingCriticalBytes,
  totalJavaScriptBytes,
};

for (const [metric, limit] of Object.entries(budgets)) {
  if (measurements[metric] > limit) {
    throw new Error(`${metric} melewati budget: ${measurements[metric]} > ${limit}`);
  }
}

process.stdout.write(`${JSON.stringify({ budgets, measurements }, null, 2)}\n`);
process.stdout.write(`Bundle terbesar: ${basename(javascript.sort((left, right) => statSync(right).size - statSync(left).size)[0])}\n`);
