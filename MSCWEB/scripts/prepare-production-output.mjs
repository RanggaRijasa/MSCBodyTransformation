import { copyFileSync, existsSync } from 'node:fs';

if (!existsSync('dist/index.html') || !existsSync('dist/landing.html')) {
  throw new Error('Output Expo atau landing statis belum tersedia.');
}

copyFileSync('dist/index.html', 'dist/app.html');
copyFileSync('dist/landing.html', 'dist/index.html');
process.stdout.write('Output production siap: index.html statis + app.html SPA.\n');
