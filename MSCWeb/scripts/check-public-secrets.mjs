import { readdir, readFile } from "node:fs/promises";
import path from "node:path";

const roots = ["src", "tests", "next.config.ts", ".env.example"];
const forbiddenPublicName =
  /NEXT_PUBLIC_[A-Z0-9_]*(?:SERVICE_ROLE|SECRET_KEY|DATABASE_PASSWORD|JWT_SECRET|PRIVATE_KEY)[A-Z0-9_]*/g;
const hostedSupabaseUrl = /https:\/\/[a-z]{20}\.supabase\.co/gi;
const violations = [];

async function collectFiles(target) {
  const stats = await readdir(target, { withFileTypes: true }).catch(() => undefined);
  if (!stats) {
    return [target];
  }

  const files = [];
  for (const entry of stats) {
    const entryPath = path.join(target, entry.name);
    if (entry.isDirectory()) {
      files.push(...(await collectFiles(entryPath)));
    } else {
      files.push(entryPath);
    }
  }
  return files;
}

for (const root of roots) {
  for (const file of await collectFiles(root)) {
    const source = await readFile(file, "utf8");
    for (const match of source.matchAll(forbiddenPublicName)) {
      violations.push(`${file}: forbidden public env ${match[0]}`);
    }
    if (hostedSupabaseUrl.test(source)) {
      violations.push(`${file}: hosted Supabase URL tidak boleh di-hard-code`);
    }
    hostedSupabaseUrl.lastIndex = 0;
  }
}

if (violations.length > 0) {
  throw new Error(`Pemeriksaan secret gagal:\n${violations.join("\n")}`);
}

console.log("Public environment dan hosted URL aman.");
