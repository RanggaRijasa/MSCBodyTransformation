import { existsSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import { gzipSync } from "node:zlib";

const webRoot = new URL("../", import.meta.url).pathname;
const nextRoot = join(webRoot, ".next");
if (!existsSync(nextRoot)) throw new Error("Jalankan `pnpm build` sebelum gate performa Phase 11.");

const rootEntrypoints = ["src/app/layout", "src/app/error"];
const routes = [
  {
    absoluteMaximumKiB: 280,
    baselineKiB: 102,
    entrypoints: [
      ...rootEntrypoints,
      "src/app/(marketing)/layout",
      "src/app/(marketing)/error",
      "src/app/(marketing)/page",
    ],
    label: "landing",
    manifest: "server/app/(marketing)/page_client-reference-manifest.js",
  },
  {
    absoluteMaximumKiB: 300,
    baselineKiB: 112,
    entrypoints: [
      ...rootEntrypoints,
      "src/app/(participant)/layout",
      "src/app/(participant)/error",
      "src/app/(participant)/hari-ini/page",
    ],
    label: "peserta",
    manifest: "server/app/(participant)/hari-ini/page_client-reference-manifest.js",
  },
  {
    absoluteMaximumKiB: 300,
    baselineKiB: 103.8,
    entrypoints: [
      ...rootEntrypoints,
      "src/app/coach-area/layout",
      "src/app/coach-area/error",
      "src/app/coach-area/page",
    ],
    label: "coach",
    manifest: "server/app/coach-area/page_client-reference-manifest.js",
  },
  {
    absoluteMaximumKiB: 300,
    baselineKiB: 111.7,
    entrypoints: [
      ...rootEntrypoints,
      "src/app/admin/layout",
      "src/app/admin/error",
      "src/app/admin/page",
    ],
    label: "admin",
    manifest: "server/app/admin/page_client-reference-manifest.js",
  },
];
const routeRegressionAllowanceKiB = 10;
const globalCssBaselineKiB = 14.31;
const globalCssRegressionAllowanceKiB = 5;

function manifestAssets(relativePath, entrypoints) {
  const source = readFileSync(join(nextRoot, relativePath), "utf8");
  const next16Assignment = source.match(/__RSC_MANIFEST\[[^\]]+\]=(\{.*\});?\s*$/s);
  const legacyAssignment = source.indexOf(" = ", source.indexOf("\n") + 1);
  const serializedManifest =
    next16Assignment?.[1] ??
    (legacyAssignment >= 0 ? source.slice(legacyAssignment + 3).replace(/;\s*$/, "") : undefined);
  if (!serializedManifest) throw new Error(`Manifest route tidak valid: ${relativePath}`);

  const manifest = JSON.parse(serializedManifest);
  const javascript = new Set(
    Object.values(manifest.clientModules).flatMap((entry) =>
      entry.chunks.filter((chunk) => chunk.endsWith(".js")),
    ),
  );
  const stylesheetPath = (entry, entrypoint) => {
    if (typeof entry === "string") return entry;
    if (entry.inlined || !entry.path) {
      throw new Error(`CSS inline/tanpa path belum didukung pada ${entrypoint} (${relativePath}).`);
    }
    return entry.path;
  };
  const stylesheets = new Set(
    Object.entries(manifest.entryCSSFiles ?? {})
      .filter(([entrypoint]) =>
        entrypoints.some((allowed) => entrypoint.replaceAll("\\", "/").endsWith(`/${allowed}`)),
      )
      .flatMap(([, entries]) => entries)
      .map((entry) => stylesheetPath(entry, "route"))
      .filter((entry) => entry?.endsWith(".css")),
  );
  const globalStylesheets = new Set(
    Object.entries(manifest.entryCSSFiles ?? {})
      .filter(([entrypoint]) => /[/\\]src[/\\]app[/\\]layout$/.test(entrypoint))
      .flatMap(([, entries]) => entries)
      .map((entry) => stylesheetPath(entry, "root layout"))
      .filter((entry) => entry?.endsWith(".css")),
  );
  if (globalStylesheets.size === 0) {
    throw new Error(`Global CSS root tidak ditemukan pada ${relativePath}.`);
  }

  return { globalStylesheets, javascript, stylesheets };
}

function gzipBytes(relativeAsset) {
  const normalized = relativeAsset.replace(/^\/_next\//, "");
  return gzipSync(readFileSync(join(nextRoot, normalized)), { level: 9 }).byteLength;
}

let measuredGlobalCssBytes;

for (const { absoluteMaximumKiB, baselineKiB, entrypoints, label, manifest } of routes) {
  const assets = manifestAssets(manifest, entrypoints);
  const javascriptBytes = [...assets.javascript].reduce(
    (total, chunk) => total + gzipBytes(chunk),
    0,
  );
  const stylesheetBytes = [...assets.stylesheets].reduce(
    (total, stylesheet) => total + gzipBytes(stylesheet),
    0,
  );
  const totalKiB = (javascriptBytes + stylesheetBytes) / 1024;
  const regressionMaximumKiB = baselineKiB + routeRegressionAllowanceKiB;
  const maximumKiB = Math.min(regressionMaximumKiB, absoluteMaximumKiB);
  if (totalKiB > maximumKiB) {
    throw new Error(
      `${label}: ${totalKiB.toFixed(1)} KiB gzip melebihi baseline ${baselineKiB.toFixed(1)} + ` +
        `${routeRegressionAllowanceKiB} KiB (batas absolut ${absoluteMaximumKiB} KiB).`,
    );
  }
  const globalCssBytes = [...assets.globalStylesheets].reduce(
    (total, stylesheet) => total + gzipBytes(stylesheet),
    0,
  );
  measuredGlobalCssBytes ??= globalCssBytes;
  if (measuredGlobalCssBytes !== globalCssBytes) {
    throw new Error(`Global CSS berbeda antar-manifest route pada ${label}.`);
  }
  console.log(
    `${label}: ${totalKiB.toFixed(1)} KiB gzip ` +
      `(JS ${(javascriptBytes / 1024).toFixed(1)} + CSS ${(stylesheetBytes / 1024).toFixed(1)}; ` +
      `baseline ${baselineKiB.toFixed(1)} + ${routeRegressionAllowanceKiB} KiB)`,
  );
}

const globalCssKiB = (measuredGlobalCssBytes ?? 0) / 1024;
const globalCssMaximumKiB = globalCssBaselineKiB + globalCssRegressionAllowanceKiB;
if (globalCssKiB > globalCssMaximumKiB) {
  throw new Error(
    `Global CSS: ${globalCssKiB.toFixed(1)} KiB gzip melebihi baseline ` +
      `${globalCssBaselineKiB.toFixed(2)} + ${globalCssRegressionAllowanceKiB} KiB.`,
  );
}
console.log(
  `Global CSS: ${globalCssKiB.toFixed(1)} KiB gzip ` +
    `(baseline ${globalCssBaselineKiB.toFixed(2)} + ${globalCssRegressionAllowanceKiB} KiB)`,
);

const screenshotBudgets = [
  ["public/images/pwa-participant-rc-v1.jpg", 100],
  ["public/images/pwa-coach-rc-v1.jpg", 200],
  ["public/images/landing-participant-v1.jpg", 50],
  ["public/images/landing-coach-v1.jpg", 50],
  ["public/images/landing-admin-v1.jpg", 50],
];
for (const [relativePath, maximumKiB] of screenshotBudgets) {
  const sizeKiB = statSync(join(webRoot, relativePath)).size / 1024;
  if (sizeKiB > maximumKiB)
    throw new Error(`${relativePath}: ${sizeKiB.toFixed(1)} KiB melebihi ${maximumKiB} KiB.`);
  console.log(`${relativePath}: ${sizeKiB.toFixed(1)} KiB (batas ${maximumKiB} KiB)`);
}

console.log("Budget artefak performa Phase 11 lulus.");
