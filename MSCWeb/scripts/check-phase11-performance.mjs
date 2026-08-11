import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";
import { gzipSync } from "node:zlib";

const webRoot = new URL("../", import.meta.url).pathname;
const nextRoot = join(webRoot, ".next");
if (!existsSync(nextRoot)) throw new Error("Jalankan `pnpm build` sebelum gate performa Phase 11.");

const routes = [
  ["landing", "server/app/(marketing)/page_client-reference-manifest.js", 280],
  ["peserta", "server/app/(participant)/hari-ini/page_client-reference-manifest.js", 300],
  ["coach", "server/app/coach-area/page_client-reference-manifest.js", 300],
  ["admin", "server/app/admin/page_client-reference-manifest.js", 300],
];

function manifestChunks(relativePath) {
  const source = readFileSync(join(nextRoot, relativePath), "utf8");
  const assignment = source.indexOf(" = ", source.indexOf("\n") + 1);
  if (assignment < 0) throw new Error(`Manifest route tidak valid: ${relativePath}`);
  const manifest = JSON.parse(source.slice(assignment + 3).replace(/;\s*$/, ""));
  return new Set(
    Object.values(manifest.clientModules).flatMap((entry) =>
      entry.chunks.filter((chunk) => chunk.endsWith(".js")),
    ),
  );
}

function gzipBytes(relativeAsset) {
  const normalized = relativeAsset.replace(/^\/_next\//, "");
  return gzipSync(readFileSync(join(nextRoot, normalized)), { level: 9 }).byteLength;
}

const globalCssBytes = readdirSync(join(nextRoot, "static/chunks"))
  .filter((name) => name.endsWith(".css"))
  .reduce((total, name) => total + gzipBytes(`static/chunks/${name}`), 0);

for (const [label, manifest, maximumKiB] of routes) {
  const bytes = [...manifestChunks(manifest)].reduce((total, chunk) => total + gzipBytes(chunk), 0);
  const totalKiB = (bytes + globalCssBytes) / 1024;
  if (totalKiB > maximumKiB)
    throw new Error(`${label}: ${totalKiB.toFixed(1)} KiB gzip melebihi ${maximumKiB} KiB.`);
  console.log(`${label}: ${totalKiB.toFixed(1)} KiB gzip (batas ${maximumKiB} KiB)`);
}

const screenshotBudgets = [
  ["public/images/pwa-participant-rc-v1.jpg", 100],
  ["public/images/pwa-coach-rc-v1.jpg", 200],
];
for (const [relativePath, maximumKiB] of screenshotBudgets) {
  const sizeKiB = statSync(join(webRoot, relativePath)).size / 1024;
  if (sizeKiB > maximumKiB)
    throw new Error(`${relativePath}: ${sizeKiB.toFixed(1)} KiB melebihi ${maximumKiB} KiB.`);
  console.log(`${relativePath}: ${sizeKiB.toFixed(1)} KiB (batas ${maximumKiB} KiB)`);
}

console.log("Budget artefak performa Phase 11 lulus.");
