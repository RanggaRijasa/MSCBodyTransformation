import { createClient } from 'npm:@supabase/supabase-js@2.112.3';

const jsonHeaders = { 'Content-Type': 'application/json; charset=utf-8' };

Deno.serve(async (request) => {
  const expectedSecret = Deno.env.get('PAYMENT_CLEANUP_JOB_SECRET');
  if (!expectedSecret || request.headers.get('authorization') !== `Bearer ${expectedSecret}`) {
    return new Response(JSON.stringify({ error: 'Tidak diizinkan.' }), { status: 401, headers: jsonHeaders });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !serviceRoleKey) {
    return new Response(JSON.stringify({ error: 'Konfigurasi job belum lengkap.' }), { status: 503, headers: jsonHeaders });
  }

  const body = await request.json().catch(() => ({})) as { dryRun?: boolean; batchSize?: number; minimumAgeHours?: number };
  const dryRun = body.dryRun !== false;
  const batchSize = Math.min(Math.max(body.batchSize ?? 100, 1), 500);
  const minimumAgeHours = Math.max(body.minimumAgeHours ?? 72, 24);
  const client = createClient(supabaseUrl, serviceRoleKey, { auth: { persistSession: false, autoRefreshToken: false } });
  const candidates = await client.rpc('list_payment_evidence_orphans', {
    minimum_age: `${minimumAgeHours} hours`,
    batch_size: batchSize,
    dry_run: dryRun,
  });
  if (candidates.error) return new Response(JSON.stringify({ error: 'Daftar kandidat belum dapat dibuat.' }), { status: 500, headers: jsonHeaders });

  const names = (candidates.data ?? []).map((row: { object_name: string }) => row.object_name);
  let deletedCount = 0;
  let failedCount = 0;
  if (!dryRun) {
    for (const name of names) {
      const latest = await client.rpc('list_payment_evidence_orphans', { minimum_age: `${minimumAgeHours} hours`, batch_size: batchSize, dry_run: false });
      const stillOrphan = !latest.error && (latest.data ?? []).some((row: { object_name: string }) => row.object_name === name);
      if (!stillOrphan) continue;
      const removal = await client.storage.from('payment-evidence').remove([name]);
      if (removal.error) failedCount += 1;
      else deletedCount += 1;
    }
  }

  await client.from('audit_events').insert({
    kind: dryRun ? 'payment_evidence_cleanup_dry_run' : 'payment_evidence_cleanup_executed',
    summary: dryRun ? 'Pemindaian bukti pembayaran yatim selesai.' : 'Pembersihan bukti pembayaran yatim selesai.',
    payload: { candidate_count: names.length, deleted_count: deletedCount, failed_count: failedCount, minimum_age_hours: minimumAgeHours },
  });

  return new Response(JSON.stringify({ dryRun, candidateCount: names.length, deletedCount, failedCount }), { status: failedCount > 0 ? 207 : 200, headers: jsonHeaders });
});
