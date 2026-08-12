import { createClient } from '@supabase/supabase-js';
import { expect, it } from 'vitest';

const localUrl = process.env.API_URL;
const publishableKey = process.env.PUBLISHABLE_KEY ?? process.env.ANON_KEY;
const canRun = localUrl !== undefined && publishableKey !== undefined;

it.runIf(canRun)('allows public RPCs but denies Guest profile and protected role reads', async () => {
  const url = new URL(localUrl as string);
  expect(['127.0.0.1', 'localhost']).toContain(url.hostname);
  const client = createClient(localUrl as string, publishableKey as string, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const programs = await client.rpc('list_public_programs', {
    target_program_id: undefined,
    result_limit: 5,
    result_offset: 0,
  });
  expect(programs.error).toBeNull();
  expect(Array.isArray(programs.data)).toBe(true);

  const privateProfiles = await client.from('profiles').select('*').limit(1);
  expect(privateProfiles.data ?? []).toHaveLength(0);

  const protectedRole = await client.rpc('get_my_dashboard_summary');
  expect(protectedRole.error).not.toBeNull();

  const serialized = JSON.stringify(programs.data);
  for (const forbidden of ['phone_number', 'coach_qr_identifier', 'initial_weight', 'final_weight', 'payment']) {
    expect(serialized).not.toContain(forbidden);
  }
});
