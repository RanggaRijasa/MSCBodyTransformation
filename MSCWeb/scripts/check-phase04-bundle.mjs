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
if (landingManifest.includes("qr-scanner") || landingManifest.includes("device-media")) {
  throw new Error("Media/QR tidak boleh masuk initial landing route.");
}

console.log(
  `Budget media valid: ${mediaChunks.map(({ name, size }) => `${name}=${size} B`).join(", ")}; landing terpisah.`,
);
