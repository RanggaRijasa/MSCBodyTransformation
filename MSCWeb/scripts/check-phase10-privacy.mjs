import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const root = new URL("../", import.meta.url);
const [domain, repository, closureMigration, paidPublishMigration] = await Promise.all(
  [
    "src/domain/participant/participant-program.ts",
    "src/infrastructure/supabase/programs/supabase-participant-repository.ts",
    "supabase/migrations/20260810130000_phase10_scoring_closure.sql",
    "supabase/migrations/20260810131000_phase10_paid_program_publish.sql",
  ].map((path) => readFile(new URL(path, root), "utf8")),
);

const forbiddenPublicFields =
  /weight(?:_kg|Kilograms)|private_(?:photo|answer)|evidence|phone|email|payment|account_reference|signed_url/i;
const leaderboardType = domain.slice(
  domain.indexOf("export type PublicLeaderboardEntry"),
  domain.indexOf("export type PublicWinner"),
);
const leaderboardAdapter = repository.slice(
  repository.indexOf("async listLeaderboard"),
  repository.indexOf("async listWinners"),
);
const leaderboardSql = closureMigration.slice(
  closureMigration.indexOf("create or replace function public.list_public_leaderboard"),
  closureMigration.indexOf("create or replace function public.get_program_closure_preflight"),
);

for (const [surface, source] of [
  ["DTO leaderboard publik", leaderboardType],
  ["adapter leaderboard publik", leaderboardAdapter],
  ["SQL leaderboard publik", leaderboardSql],
]) {
  assert.ok(source.length > 0, `${surface} tidak ditemukan.`);
  assert.doesNotMatch(source, forbiddenPublicFields, `${surface} membawa field privat.`);
}

for (const requiredField of [
  "participant_display_name",
  "participant_id",
  "program_id",
  "progress_percentage",
  "rank",
  "total_points",
]) {
  assert.ok(leaderboardSql.includes(`'${requiredField}'`), `Field publik ${requiredField} hilang.`);
}

assert.match(leaderboardSql, /enrollment\.id asc/);
assert.match(leaderboardSql, /limit result_limit\s+offset result_offset/);
assert.doesNotMatch(
  paidPublishMigration,
  /program_scores|score_adjustments|weight_points|quiz_points|activity_points/,
  "Handoff manual commerce tidak boleh mengubah semantik scoring.",
);

console.log("Kontrak leaderboard dan closure Phase 10 privacy-safe.");
