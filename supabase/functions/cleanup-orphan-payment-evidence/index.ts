import { createClient } from 'npm:@supabase/supabase-js@2.112.3';
import { isAuthorizedJobRequest } from '../_shared/job_auth.ts';
import { loadSupabaseRuntimeKeys } from '../_shared/supabase_keys.ts';

const jsonHeaders = {
  'Cache-Control': 'no-store',
  'Content-Type': 'application/json; charset=utf-8',
};

type OrphanCandidate = Readonly<{ object_name: string }>;
type RetentionCandidate = Readonly<{ attempt_id: string; object_name: string }>;

Deno.serve(async (request) => {
  if (request.method !== 'POST') return response({ error: 'Metode tidak didukung.' }, 405);
  if (!await isAuthorizedJobRequest(request, 'PAYMENT_CLEANUP_JOB_SECRET')) {
    return response({ error: 'Tidak diizinkan.' }, 401);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  let secretKey: string;
  try {
    ({ secretKey } = loadSupabaseRuntimeKeys());
  } catch {
    return response({ error: 'Konfigurasi job belum lengkap.' }, 503);
  }
  if (!supabaseUrl) return response({ error: 'Konfigurasi job belum lengkap.' }, 503);

  const body = await request.json().catch(() => ({})) as {
    dryRun?: boolean;
    batchSize?: number;
    minimumAgeHours?: number;
  };
  const dryRun = body.dryRun !== false;
  const batchSize = Math.min(Math.max(body.batchSize ?? 100, 1), 500);
  const minimumAgeHours = Math.max(body.minimumAgeHours ?? 72, 24);
  const client = createClient(supabaseUrl, secretKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  if (!dryRun) await client.rpc('reconcile_payment_evidence_retention_claims');

  const [orphanResult, retentionResult] = await Promise.all([
    client.rpc('list_payment_evidence_orphans', {
      minimum_age: `${minimumAgeHours} hours`,
      batch_size: batchSize,
      dry_run: dryRun,
    }),
    client.rpc('list_payment_evidence_retention_candidates', {
      batch_size: batchSize,
      dry_run: dryRun,
    }),
  ]);
  if (orphanResult.error || retentionResult.error) {
    return response({ error: 'Daftar kandidat belum dapat dibuat.' }, 500);
  }

  const orphanCandidates = (orphanResult.data ?? []) as OrphanCandidate[];
  const retentionCandidates = (retentionResult.data ?? []) as RetentionCandidate[];
  let orphanDeletedCount = 0;
  let retentionDeletedCount = 0;
  let skippedCount = 0;
  let failedCount = 0;

  if (!dryRun) {
    for (const candidate of orphanCandidates) {
      const latest = await client.rpc('list_payment_evidence_orphans', {
        minimum_age: `${minimumAgeHours} hours`,
        batch_size: batchSize,
        dry_run: false,
      });
      const stillOrphan = !latest.error && (latest.data ?? []).some(
        (row: OrphanCandidate) => row.object_name === candidate.object_name,
      );
      if (!stillOrphan) {
        skippedCount += 1;
        continue;
      }
      const removal = await client.storage.from('payment-evidence').remove([
        candidate.object_name,
      ]);
      if (removal.error) failedCount += 1;
      else orphanDeletedCount += 1;
    }

    for (const candidate of retentionCandidates) {
      const claim = await client.rpc('claim_payment_evidence_retention', {
        target_attempt_id: candidate.attempt_id,
      });
      if (claim.error || claim.data !== true) {
        skippedCount += 1;
        continue;
      }
      const removal = await client.storage.from('payment-evidence').remove([
        candidate.object_name,
      ]);
      if (removal.error) {
        failedCount += 1;
        await client.rpc('release_payment_evidence_retention', {
          target_attempt_id: candidate.attempt_id,
        });
        continue;
      }
      const completion = await client.rpc('complete_payment_evidence_retention', {
        target_attempt_id: candidate.attempt_id,
      });
      if (completion.error || completion.data !== true) failedCount += 1;
      else retentionDeletedCount += 1;
    }
  }

  await client.from('audit_events').insert({
    kind: dryRun ? 'payment_evidence_cleanup_dry_run' : 'payment_evidence_cleanup_executed',
    summary: dryRun
      ? 'Pemindaian cleanup bukti pembayaran selesai.'
      : 'Cleanup bukti pembayaran selesai.',
    payload: {
      orphan_candidate_count: orphanCandidates.length,
      retention_candidate_count: retentionCandidates.length,
      orphan_deleted_count: orphanDeletedCount,
      retention_deleted_count: retentionDeletedCount,
      skipped_count: skippedCount,
      failed_count: failedCount,
      minimum_orphan_age_hours: minimumAgeHours,
      retention_days: 30,
    },
  });

  return response({
    dryRun,
    orphanCandidateCount: orphanCandidates.length,
    retentionCandidateCount: retentionCandidates.length,
    orphanDeletedCount,
    retentionDeletedCount,
    skippedCount,
    failedCount,
  }, failedCount > 0 ? 207 : 200);
});

function response(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}
