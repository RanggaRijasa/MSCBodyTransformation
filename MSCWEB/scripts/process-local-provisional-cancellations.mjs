import { createClient } from '@supabase/supabase-js';

const apiUrl = process.env.API_URL;
const secretKey = process.env.SECRET_KEY;
const batchSize = Math.min(Math.max(Number(process.env.CLEANUP_BATCH_SIZE || 100), 1), 500);
const targetReceiptId = process.env.CLEANUP_RECEIPT_ID || null;

if (!apiUrl || !secretKey || !['127.0.0.1', 'localhost'].includes(new URL(apiUrl).hostname)) {
  throw new Error('Worker lokal menolak target non-lokal atau konfigurasi kosong.');
}

const client = createClient(apiUrl, secretKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});
let completed = 0;
let failed = 0;

for (let index = 0; index < batchSize; index += 1) {
  const claimed = await client.rpc('claim_provisional_cancellation', {
    target_receipt_id: targetReceiptId,
  });
  if (claimed.error) throw new Error('Antrean cleanup lokal belum dapat diklaim.');
  if (claimed.data === null) break;
  const receipt = claimed.data;
  try {
    if (receipt.object_paths.length > 0) {
      const removed = await client.storage.from('payment-evidence').remove(receipt.object_paths);
      if (removed.error) throw new Error('storage_remove_failed');
    }
    const revoked = await client.rpc('revoke_provisional_cancellation_sessions', {
      target_receipt_id: receipt.id,
    });
    if (revoked.error || revoked.data !== true) throw new Error('session_revoke_failed');
    const deletion = await client.auth.admin.deleteUser(receipt.user_id, false);
    if (deletion.error && !/not found/iu.test(deletion.error.message)) throw new Error('auth_delete_failed');
    const finalized = await client.rpc('complete_provisional_cancellation', {
      target_receipt_id: receipt.id,
    });
    if (finalized.error || finalized.data !== true) throw new Error('receipt_finalize_failed');
    completed += 1;
    if (targetReceiptId) break;
  } catch (error) {
    failed += 1;
    await client.rpc('fail_provisional_cancellation', {
      target_receipt_id: receipt.id,
      failure_code: error instanceof Error ? error.message : 'unknown',
    });
  }
}

process.stdout.write(`Cleanup provisional lokal: ${completed} selesai, ${failed} gagal.\n`);
if (failed > 0) process.exitCode = 1;
