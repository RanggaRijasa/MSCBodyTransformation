import { createClient } from 'npm:@supabase/supabase-js@2.112.3';
import { isAuthorizedJobRequest } from '../_shared/job_auth.ts';
import { loadSupabaseRuntimeKeys } from '../_shared/supabase_keys.ts';
import { createFoodVisionProvider } from '../_shared/food-insight/providers.ts';
import { FoodVisionProviderError } from '../_shared/food-insight/contracts.ts';
import { validateFoodInsight } from '../_shared/food-insight/validate-food-insight.ts';

const jsonHeaders = { 'Content-Type': 'application/json; charset=utf-8' };

Deno.serve(async (request) => {
  if (request.method !== 'POST') return Response.json({ error: 'Metode tidak didukung.' }, { status: 405, headers: jsonHeaders });
  if (!await isAuthorizedJobRequest(request, 'FOOD_AI_WORKER_SECRET')) {
    return Response.json({ error: 'Tidak diizinkan.' }, { status: 401, headers: jsonHeaders });
  }
  const url = Deno.env.get('SUPABASE_URL');
  let secretKey: string;
  try { ({ secretKey } = loadSupabaseRuntimeKeys()); }
  catch { return Response.json({ error: 'Konfigurasi worker belum lengkap.' }, { status: 503, headers: jsonHeaders }); }
  if (!url) return Response.json({ error: 'Konfigurasi worker belum lengkap.' }, { status: 503, headers: jsonHeaders });
  const client = createClient(url, secretKey, { auth: { persistSession: false, autoRefreshToken: false } });
  const environment = Object.fromEntries(['FOOD_AI_PROVIDER', 'FOOD_AI_BASE_URL', 'FOOD_AI_API_KEY', 'FOOD_AI_MODELS', 'FOOD_AI_MODEL', 'FOOD_AI_FAKE_SCENARIO'].map((key) => [key, Deno.env.get(key)]));
  let provider;
  try { provider = createFoodVisionProvider(environment); await provider.preflight(); }
  catch { return Response.json({ error: 'Provider tidak kompatibel.' }, { status: 503, headers: jsonHeaders }); }

  await client.rpc('reconcile_food_insight_jobs', { target_analysis_version: 'food_insight_v1' });
  const requested = await request.json().catch(() => ({})) as { batchSize?: number };
  const batchSize = Math.min(Math.max(requested.batchSize ?? 5, 1), 20);
  let completed = 0; let failed = 0;
  for (let index = 0; index < batchSize; index += 1) {
    const claimed = await client.rpc('claim_food_insight_job', { lease_seconds: 90, target_submission_id: null });
    const job = claimed.data as null | { id: string; private_photo_path: string; lease_token: string };
    if (claimed.error || !job) break;
    try {
      const downloaded = await client.storage.from('question-photos').download(job.private_photo_path);
      if (downloaded.error) throw new FoodVisionProviderError('provider_unavailable', true);
      const bytes = new Uint8Array(await downloaded.data.arrayBuffer());
      const raw = await provider.analyze({ imageBytes: bytes, mimeType: 'image/jpeg' });
      const result = validateFoodInsight(raw);
      const completion = await client.rpc('complete_food_insight_job', { target_job_id: job.id, target_lease_token: job.lease_token, validated_result: result, provider_name: provider.providerName, model_alias: provider.modelAlias });
      if (completion.error) throw new FoodVisionProviderError('provider_unavailable', true);
      completed += 1;
    } catch (error) {
      const failure = error instanceof FoodVisionProviderError ? error : new FoodVisionProviderError('provider_unavailable', true);
      await client.rpc('fail_food_insight_job', {
        target_job_id: job.id,
        target_lease_token: job.lease_token,
        error_code: failure.code,
        retryable: failure.retryable || failure.code === 'invalid_output',
      });
      failed += 1;
    }
  }
  return Response.json({ completed, failed }, { headers: jsonHeaders });
});
