import { createClient } from 'npm:@supabase/supabase-js@2.112.3';
import { isAuthorizedJobRequest } from '../_shared/job_auth.ts';
import { loadSupabaseRuntimeKeys } from '../_shared/supabase_keys.ts';

const jsonHeaders = { 'Content-Type': 'application/json; charset=utf-8' };

type ClaimedReceipt = Readonly<{
  id: string;
  user_id: string;
  object_paths: string[];
  attempt_count: number;
}>;

Deno.serve(async (request) => {
  if (request.method !== 'POST') return response({ error: 'Metode tidak didukung.' }, 405);
  if (!await isAuthorizedJobRequest(request, 'PROVISIONAL_CLEANUP_JOB_SECRET')) {
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

  const body = await request.json().catch(() => ({})) as { batchSize?: number };
  const batchSize = Math.min(Math.max(body.batchSize ?? 20, 1), 100);
  const client = createClient(supabaseUrl, secretKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  let completed = 0;
  let failed = 0;

  for (let index = 0; index < batchSize; index += 1) {
    const claimed = await client.rpc('claim_provisional_cancellation');
    if (claimed.error) return response({ error: 'Antrean cleanup belum dapat diklaim.' }, 500);
    if (claimed.data === null) break;
    const receipt = claimed.data as ClaimedReceipt;
    try {
      if (receipt.object_paths.length > 0) {
        const removal = await client.storage.from('payment-evidence').remove(receipt.object_paths);
        if (removal.error) throw new Error('storage_remove_failed');
      }
      const revoked = await client.rpc('revoke_provisional_cancellation_sessions', {
        target_receipt_id: receipt.id,
      });
      if (revoked.error || revoked.data !== true) throw new Error('session_revoke_failed');

      const deletion = await client.auth.admin.deleteUser(receipt.user_id, false);
      if (deletion.error && !/not found/iu.test(deletion.error.message)) {
        throw new Error('auth_delete_failed');
      }
      const finalized = await client.rpc('complete_provisional_cancellation', {
        target_receipt_id: receipt.id,
      });
      if (finalized.error || finalized.data !== true) throw new Error('receipt_finalize_failed');
      completed += 1;
    } catch (error) {
      failed += 1;
      await client.rpc('fail_provisional_cancellation', {
        target_receipt_id: receipt.id,
        failure_code: error instanceof Error ? error.message : 'unknown',
      });
    }
  }

  return response({ completed, failed }, failed > 0 ? 207 : 200);
});

function response(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}
