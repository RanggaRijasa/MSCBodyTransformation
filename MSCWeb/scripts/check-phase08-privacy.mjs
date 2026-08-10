import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const publicSurfaceFiles = [
  "src/features/coach/components/coach-dashboard.tsx",
  "src/features/coach/components/coach-roster.tsx",
  "src/features/coach/components/coach-program-hub.tsx",
];

for (const path of publicSurfaceFiles) {
  const source = await readFile(new URL(`../${path}`, import.meta.url), "utf8");
  assert.doesNotMatch(
    source,
    /weight_kg|weightKilograms|private_photo_path|photo_object_path/i,
    `${path} membawa field privat ke feed/list.`,
  );
  assert.doesNotMatch(
    source,
    /console\.(?:debug|info|log|warn|error)/,
    `${path} tidak boleh mencatat data Coach.`,
  );
}

const feedRepository = await readFile(
  new URL(
    "../src/infrastructure/supabase/coach/supabase-coach-feed-repository.ts",
    import.meta.url,
  ),
  "utf8",
);
const activityBoundary = feedRepository.slice(
  feedRepository.indexOf("export async function listCoachActivityRepository"),
);
assert.doesNotMatch(
  activityBoundary,
  /weight_kg|weightKilograms|private_photo_path|photo_object_path/i,
  "Feed aktivitas membawa field privat.",
);
assert.doesNotMatch(
  activityBoundary,
  /console\.(?:debug|info|log|warn|error)/,
  "Feed aktivitas tidak boleh mencatat data Coach.",
);

const mediaRoute = await readFile(
  new URL(
    "../src/app/api/coach/submissions/[submissionId]/photos/[questionId]/route.ts",
    import.meta.url,
  ),
  "utf8",
);
assert.match(
  mediaRoute,
  /Cache-Control["']:\s*["']private, no-store, max-age=0["']/,
  "Media privat wajib private dan no-store.",
);
assert.match(
  mediaRoute,
  /["']?Vary["']?:\s*["']Cookie["']/,
  "Respons media privat wajib bervariasi berdasarkan sesi.",
);

console.log("Boundary privasi Phase 08 valid.");
