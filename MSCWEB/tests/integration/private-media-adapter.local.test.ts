import { randomUUID } from 'node:crypto';

import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { expect, it } from 'vitest';

import { SupabasePrivateMediaAdapter } from '../../src/shared/media/supabase-private-media-adapter';

const localUrl = process.env.API_URL;
const serviceRoleKey = process.env.SERVICE_ROLE_KEY;
const canRun = localUrl !== undefined && serviceRoleKey !== undefined;

it.runIf(canRun)('runs the browser adapter against the provisioned local private bucket', async () => {
  const url = new URL(localUrl as string);
  expect(['127.0.0.1', 'localhost']).toContain(url.hostname);

  const serviceClient = createClient(localUrl as string, serviceRoleKey as string, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const objectPath = `w00-adapter/${randomUUID()}.jpg`;
  const adapterClient = {
    auth: {
      getUser: async () => ({ data: { user: { id: 'w00-local-adapter' } }, error: null }),
    },
    storage: serviceClient.storage,
  } as unknown as SupabaseClient;
  const adapter = new SupabasePrivateMediaAdapter(
    adapterClient,
    () => new Date('2026-08-12T00:00:00.000Z'),
  );
  const reference = { bucket: 'question-photos' as const, objectPath };

  try {
    const upload = await adapter.upload(
      reference,
      Uint8Array.from([0xff, 0xd8, 0xff, 0xd9]).buffer,
    );
    expect(upload.objectId).toBeTruthy();

    const downloaded = await adapter.download(reference);
    expect(downloaded.size).toBe(4);

    const signed = await adapter.createSignedUrl(reference);
    expect(signed.url).toContain('/storage/v1/object/sign/question-photos/');
    expect(signed.expiresAt.toISOString()).toBe('2026-08-12T00:01:00.000Z');
    const signedDownload = await fetch(signed.url, { cache: 'no-store' });
    expect(signedDownload.ok).toBe(true);
  } finally {
    await serviceClient.storage.from('question-photos').remove([objectPath]);
  }
});
