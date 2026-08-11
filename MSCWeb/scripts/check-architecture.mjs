import { readdir, readFile } from "node:fs/promises";
import path from "node:path";

const projectRoot = process.cwd();
const sourceRoot = path.join(projectRoot, "src");
const violations = [];

async function collectSourceFiles(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const files = [];

  for (const entry of entries) {
    const entryPath = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      files.push(...(await collectSourceFiles(entryPath)));
    } else if (/\.(?:ts|tsx)$/.test(entry.name)) {
      files.push(entryPath);
    }
  }

  return files;
}

function importsFrom(source) {
  return [...source.matchAll(/(?:import|export)\s+(?:[^"']+\s+from\s+)?["']([^"']+)["']/g)].map(
    (match) => match[1],
  );
}

for (const file of await collectSourceFiles(sourceRoot)) {
  const relativePath = path.relative(projectRoot, file);
  const source = await readFile(file, "utf8");

  for (const importedPath of importsFrom(source)) {
    if (
      relativePath.startsWith("src/domain/") &&
      /^(?:react|next|@supabase\/|@\/features\/|@\/infrastructure\/)/.test(importedPath)
    ) {
      violations.push(`${relativePath}: domain mengimpor ${importedPath}`);
    }

    if (
      /^(?:src\/features\/|src\/app\/|src\/shared\/)/.test(relativePath) &&
      /^(?:@supabase\/|@\/infrastructure\/supabase\/)/.test(importedPath)
    ) {
      violations.push(`${relativePath}: UI mengimpor Supabase langsung (${importedPath})`);
    }

    const featureMatch = relativePath.match(/^src\/features\/([^/]+)\//);
    const importedFeatureMatch = importedPath.match(/^@\/features\/([^/]+)\/(.+)$/);
    if (featureMatch && importedFeatureMatch && featureMatch[1] !== importedFeatureMatch[1]) {
      violations.push(
        `${relativePath}: gunakan public entry point feature ${importedFeatureMatch[1]}`,
      );
    }
  }
}

if (violations.length > 0) {
  throw new Error(`Pelanggaran arsitektur:\n${violations.join("\n")}`);
}

console.log("Boundary arsitektur valid.");
