import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

const migration = readFileSync('supabase/migrations/20260814122036_w06_5_async_food_insight.sql', 'utf8');
const worker = readFileSync('supabase/functions/process-food-insight/index.ts', 'utf8');
const environment = readFileSync('.env.example', 'utf8');
const card = readFileSync('src/features/food-insight/FoodInsightCard.tsx', 'utf8');
const participantForm = readFileSync('src/features/participant/ParticipantSubmissionForm.tsx', 'utf8');
const coachReview = readFileSync('src/features/coach/CoachReviewComponents.tsx', 'utf8');

describe('W06.5 durable and privacy contract', () => {
  it('defines question mode, unique job/result version, retry lease, reconciliation, and audited correction', () => {
    for (const marker of [
      "analysis_mode in ('none', 'food')", 'unique (submission_id, analysis_version)',
      "status in ('queued', 'processing', 'retry_scheduled', 'completed', 'failed', 'unavailable')",
      'for update skip locked', 'reconcile_food_insight_jobs', 'food_insight_rating_corrected',
      'correction_conflict', 'correction_reason_required',
    ]) expect(migration).toContain(marker);
  });

  it('keeps result separate from submission, score, approval, and leaderboard mutation', () => {
    const resultTable = migration.slice(migration.indexOf('create table if not exists public.food_insight_results'), migration.indexOf('create table if not exists public.food_insight_corrections'));
    expect(resultTable).not.toContain('points');
    expect(resultTable).not.toContain('approval');
    expect(migration).not.toContain('update public.program_scores');
    expect(migration).not.toContain('update public.step_submissions set status');
  });

  it('worker sends downloaded bytes and rubric, not identity, weight, signed URL, or object path to provider', () => {
    const providerCall = worker.match(/provider\.analyze\(([^;]+);/su)?.[1] ?? '';
    expect(providerCall).toContain('imageBytes: bytes');
    expect(providerCall).toContain('rubric: job.rubric');
    for (const forbidden of ['participant', 'weight', 'signed', 'private_photo_path']) expect(providerCall).not.toContain(forbidden);
    expect(worker).not.toContain('console.log');
  });

  it('documents server-only placeholders without a committed credential', () => {
    for (const name of ['FOOD_AI_PROVIDER', 'FOOD_AI_BASE_URL', 'FOOD_AI_API_KEY', 'FOOD_AI_MODEL', 'FOOD_AI_WORKER_SECRET']) expect(environment).toContain(`${name}=`);
    expect(environment).not.toMatch(/FOOD_AI_API_KEY=\S+/u);
    expect(environment).not.toContain('sk-or-');
  });

  it('renders every nonblocking insight state, accessible stars, disclosure, and a secondary Coach correction', () => {
    for (const copy of ['Analisis sedang diproses', 'Insight tidak tersedia', 'Analisis belum berhasil', 'Perkiraan dari foto', 'dari 5 bintang']) {
      expect(card).toContain(copy);
    }
    expect(participantForm).toContain('Hindari wajah dan dokumen pribadi di dalam foto');
    expect(coachReview).toContain('allowCorrection');
    expect(card).toContain('Koreksi rating AI');
    expect(coachReview).not.toContain('Penilaian Coach');
  });
});
