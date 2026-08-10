import { readFile } from "node:fs/promises";

const catalogPath = "src/shared/i18n/id.ts";
const source = await readFile(catalogPath, "utf8");
const emptyValuePattern = /:\s*["'`]\s*["'`]/;

if (emptyValuePattern.test(source)) {
  throw new Error(`${catalogPath} memuat nilai localization kosong.`);
}

const requiredSections = ["common", "error", "foundation", "landing", "notFound"];
for (const section of requiredSections) {
  if (!new RegExp(`\\b${section}\\s*:`).test(source)) {
    throw new Error(`${catalogPath} kehilangan section ${section}.`);
  }
}

console.log("Katalog Bahasa Indonesia valid.");
