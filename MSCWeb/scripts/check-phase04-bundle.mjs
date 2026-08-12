import { readdir, readFile, stat } from "node:fs/promises";
import { join } from "node:path";

const chunkDirectory = join(process.cwd(), ".next", "static", "chunks");
const chunkNames = (await readdir(chunkDirectory)).filter((name) => name.endsWith(".js"));
const chunks = await Promise.all(
  chunkNames.map(async (name) => ({
    content: await readFile(join(chunkDirectory, name), "utf8"),
    name,
    size: (await stat(join(chunkDirectory, name))).size,
  })),
);

const mediaChunks = chunks.filter(({ content }) =>
  ["_maxScansPerSecond", "Memproses dan menghapus metadata", "Pindai QR Coach"].some((marker) =>
    content.includes(marker),
  ),
);
if (mediaChunks.length === 0) throw new Error("Chunk media Phase 04 tidak ditemukan.");

const maximumRawChunkBytes = 100_000;
const oversized = mediaChunks.filter(({ size }) => size > maximumRawChunkBytes);
if (oversized.length > 0) {
  throw new Error(
    `Chunk media melewati 100 KB: ${oversized.map(({ name, size }) => `${name}=${size}`).join(", ")}`,
  );
}

const landingManifest = await readFile(
  join(process.cwd(), ".next", "server", "app", "(marketing)", "page_client-reference-manifest.js"),
  "utf8",
);
const serializedLandingManifest = landingManifest.match(
  /__RSC_MANIFEST\[[^\]]+\]=(\{.*\});?\s*$/s,
)?.[1];
if (!serializedLandingManifest) {
  throw new Error("Manifest landing Next 16 tidak dapat dibaca.");
}
const parsedLandingManifest = JSON.parse(serializedLandingManifest);
const landingMediaModules = Object.entries(parsedLandingManifest.clientModules).filter(
  ([modulePath]) =>
    modulePath.includes("/src/features/device-media/components/") ||
    modulePath.includes("/src/features/device-media/index"),
);
const landingRouteChunkPatterns = [
  /static\/chunks\/app\/layout-[^/]+\.js$/,
  /static\/chunks\/app\/\(marketing\)\/layout-[^/]+\.js$/,
  /static\/chunks\/app\/\(marketing\)\/page-[^/]+\.js$/,
];
const bundledLandingMediaModules = landingMediaModules.filter(([modulePath, entry]) => {
  if (!Array.isArray(entry.chunks)) {
    throw new Error(`Daftar chunk tidak valid untuk ${modulePath}.`);
  }
  return entry.chunks.some((chunk) =>
    landingRouteChunkPatterns.some((pattern) => pattern.test(chunk)),
  );
});
if (bundledLandingMediaModules.length > 0) {
  throw new Error("Media/QR tidak boleh masuk initial landing route.");
}

const landingCssEntrypoints = [
  "src/app/layout",
  "src/app/(marketing)/layout",
  "src/app/(marketing)/page",
];
if (
  !parsedLandingManifest.entryCSSFiles ||
  typeof parsedLandingManifest.entryCSSFiles !== "object"
) {
  throw new Error("Daftar entry CSS landing tidak tersedia.");
}
const normalizedCssEntries = Object.entries(parsedLandingManifest.entryCSSFiles).map(
  ([entrypoint, entries]) => [entrypoint.replaceAll("\\", "/"), entries],
);
for (const requiredEntrypoint of landingCssEntrypoints) {
  if (!normalizedCssEntries.some(([entrypoint]) => entrypoint.endsWith(`/${requiredEntrypoint}`))) {
    throw new Error(`Entry CSS landing wajib tidak ditemukan: ${requiredEntrypoint}.`);
  }
}
const landingCssPaths = new Set(
  normalizedCssEntries
    .filter(([entrypoint]) =>
      landingCssEntrypoints.some((allowed) => entrypoint.endsWith(`/${allowed}`)),
    )
    .flatMap(([, entries]) => entries)
    .map((entry) => {
      if (typeof entry === "string" && entry) return entry;
      if (!entry || typeof entry !== "object" || entry.inlined || !entry.path) {
        throw new Error("CSS landing inline/tanpa path belum didukung oleh gate bundle.");
      }
      return entry.path;
    }),
);
if (landingCssPaths.size < 2) {
  throw new Error("CSS root dan marketing wajib terpisah serta terukur pada landing.");
}
const landingCss = (
  await Promise.all(
    [...landingCssPaths].map((relativePath) =>
      readFile(join(process.cwd(), ".next", relativePath), "utf8"),
    ),
  )
).join("\n");
if (
  [".qr-scanner", ".image-acquisition", ".program-video"].some((marker) =>
    landingCss.includes(marker),
  )
) {
  throw new Error("CSS media/QR tidak boleh masuk initial landing route.");
}

console.log(
  `Budget media valid: ${mediaChunks.map(({ name, size }) => `${name}=${size} B`).join(", ")}; landing terpisah.`,
);
