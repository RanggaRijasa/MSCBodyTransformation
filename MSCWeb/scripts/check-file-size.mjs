import { readdir, readFile } from "node:fs/promises";
import path from "node:path";

const projectRoot = process.cwd();
const sourceRoots = ["src", "tests", "scripts", "development"];
const reviewed = [];
const blocked = [];

async function collectFiles(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const files = [];

  for (const entry of entries) {
    const entryPath = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      files.push(...(await collectFiles(entryPath)));
    } else if (/\.(?:css|mjs|ts|tsx)$/.test(entry.name)) {
      files.push(entryPath);
    }
  }

  return files;
}

for (const sourceRoot of sourceRoots) {
  const files = await collectFiles(path.join(projectRoot, sourceRoot));
  for (const file of files) {
    const lines = (await readFile(file, "utf8")).split(/\r?\n/);
    if (lines.at(-1) === "") lines.pop();
    const lineCount = lines.length;
    const relativePath = path.relative(projectRoot, file);

    if (lineCount > 500) {
      blocked.push(`${relativePath}: ${lineCount} baris`);
    } else if (lineCount > 400) {
      reviewed.push(`${relativePath}: ${lineCount} baris`);
    }
  }
}

for (const warning of reviewed) {
  console.warn(`REVIEW ${warning}`);
}

if (blocked.length > 0) {
  throw new Error(`File handwritten melewati 500 baris:\n${blocked.join("\n")}`);
}

console.log("Ukuran file handwritten valid.");
