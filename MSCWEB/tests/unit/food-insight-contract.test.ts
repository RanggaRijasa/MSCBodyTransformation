import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

const migration = readFileSync('../supabase/migrations/20260814122036_w06_5_async_food_insight.sql', 'utf8');
const optInGuard = readFileSync('../supabase/migrations/20260822022849_w08_food_insight_opt_in_guard.sql', 'utf8');
const retryInvalidOutput = readFileSync('../supabase/migrations/20260823031218_w08_retry_invalid_food_insight_jobs.sql', 'utf8');
const imageOnlyPolicy = readFileSync('../supabase/migrations/20260823093724_food_insight_image_only_policy.sql', 'utf8');
const worker = readFileSync('../supabase/functions/process-food-insight/index.ts', 'utf8');
const provider = readFileSync('../supabase/functions/_shared/food-insight/providers.ts', 'utf8');
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

  it('prevents disabled configurations from being claimed or reconciled into provider work', () => {
    expect(optInGuard).toContain("question.analysis_mode <> 'food'");
    expect(optInGuard).toContain("question.analysis_mode = 'food'");
    expect(optInGuard).toContain("question.kind = 'photo_upload'");
    expect(optInGuard).toContain("status = 'unavailable'");
    expect(optInGuard).toContain("terminal_error_code = 'configuration_invalid'");
  });

  it('worker sends only downloaded image bytes to the provider', () => {
    const providerCall = worker.match(/provider\.analyze\(([^;]+);/su)?.[1] ?? '';
    expect(providerCall).toContain('imageBytes: bytes');
    for (const forbidden of ['rubric', 'question', 'step', 'program', 'participant', 'weight', 'signed', 'private_photo_path']) expect(providerCall).not.toContain(forbidden);
    expect(worker).not.toContain('console.log');
  });

  it('removes rubric and program identifiers from the claimed provider payload', () => {
    const claimPayload = imageOnlyPolicy.slice(imageOnlyPolicy.indexOf("return jsonb_build_object("), imageOnlyPolicy.indexOf("end;\n$$;", imageOnlyPolicy.indexOf("return jsonb_build_object(")));
    for (const forbidden of ['submission_id', 'question_id', 'analysis_version', 'rubric', 'rubric_version']) {
      expect(claimPayload).not.toContain(`'${forbidden}'`);
    }
    expect(imageOnlyPolicy).toContain("'food_rating_policy_v2_image_only'");
    expect(imageOnlyPolicy).toContain("'food_insight_output_v2_image_only'");
    expect(imageOnlyPolicy).toContain("'shake_detected'");
  });

  it('requires a compatible routed model and retries malformed free-model output within the bounded policy', () => {
    expect(provider).toContain('require_parameters: true');
    expect(provider).toContain("sort: 'price'");
    expect(provider).toContain('max_price: { prompt: 0.10, completion: 0.40 }');
    expect(provider).toContain("'google/gemma-4-26b-a4b-it'");
    expect(provider).toContain("'google/gemma-3-12b-it'");
    expect(provider).toContain('this.selectedModel = body.model');
    expect(worker).toContain("failure.code === 'invalid_output'");
    expect(retryInvalidOutput).toContain("terminal_error_code = 'invalid_output'");
    expect(retryInvalidOutput).toContain('attempt_count < job.max_attempts');
  });

  it('documents server-only placeholders without a committed credential', () => {
    for (const name of ['FOOD_AI_PROVIDER', 'FOOD_AI_BASE_URL', 'FOOD_AI_API_KEY', 'FOOD_AI_MODELS', 'FOOD_AI_MODEL', 'FOOD_AI_WORKER_SECRET']) expect(environment).toContain(`${name}=`);
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
    expect(participantForm).toContain("question.kind === 'video_upload'");
    expect(participantForm).toContain('Analisis foto dengan AI');
    expect(participantForm).not.toContain('Bukti foto diperlukan');
    expect(participantForm).not.toContain('Jawaban aktivitas sudah tercatat. Kamu tidak perlu mengirim ulang.');
    expect(card).not.toContain('Jawaban sudah terkirim. Hasil AI akan muncul otomatis tanpa menahan pemeriksaan Coach.');
    expect(card).not.toContain('Kami akan mencoba lagi bila memungkinkan. Bukti dan status program tetap aman.');
  });
});
