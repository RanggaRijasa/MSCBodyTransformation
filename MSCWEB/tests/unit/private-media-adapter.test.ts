import type { SupabaseClient } from '@supabase/supabase-js';
import { describe, expect, it, vi } from 'vitest';

import {
  PrivateMediaError,
  SupabasePrivateMediaAdapter,
} from '../../src/shared/media/supabase-private-media-adapter';

const REFERENCE = {
  bucket: 'question-photos' as const,
  objectPath: 'user-1/evidence-1.jpg',
};

function makeClient(options: { authenticated?: boolean } = {}) {
  const upload = vi.fn(async () => ({ data: { id: 'object-1' }, error: null }));
  const download = vi.fn(async () => ({ data: new Blob(['private']), error: null }));
  const createSignedUrl = vi.fn(async () => ({
    data: { signedUrl: 'http://localhost:54321/storage/v1/object/sign/private' },
    error: null,
  }));
  const remove = vi.fn(async () => ({ data: [], error: null }));
  const from = vi.fn(() => ({ upload, download, createSignedUrl, remove }));
  const getUser = vi.fn(async () => ({
    data: { user: options.authenticated === false ? null : { id: 'user-1' } },
    error: null,
  }));

  return {
    client: { auth: { getUser }, storage: { from } } as unknown as SupabaseClient,
    spies: { getUser, from, upload, download, createSignedUrl, remove },
  };
}

describe('Supabase private media adapter', () => {
  it('requires an authenticated user before touching Storage', async () => {
    const { client, spies } = makeClient({ authenticated: false });
    const adapter = new SupabasePrivateMediaAdapter(client);

    await expect(adapter.download(REFERENCE)).rejects.toEqual(
      new PrivateMediaError('unauthenticated'),
    );
    expect(spies.from).not.toHaveBeenCalled();
  });

  it('uploads private media without upsert or shared caching', async () => {
    const { client, spies } = makeClient();
    const adapter = new SupabasePrivateMediaAdapter(client);
    const body = new Blob(['jpeg'], { type: 'image/jpeg' });

    await expect(adapter.upload(REFERENCE, body)).resolves.toEqual({ objectId: 'object-1' });
    expect(spies.from).toHaveBeenCalledWith('question-photos');
    expect(spies.upload).toHaveBeenCalledWith(REFERENCE.objectPath, body, {
      contentType: 'image/jpeg',
      cacheControl: '0',
      upsert: false,
    });
  });

  it('downloads with a no-store fetch policy', async () => {
    const { client, spies } = makeClient();
    const adapter = new SupabasePrivateMediaAdapter(client);

    await adapter.download(REFERENCE);

    expect(spies.download).toHaveBeenCalledWith(REFERENCE.objectPath, {}, { cache: 'no-store' });
  });

  it('deletes only the explicit temporary object path', async () => {
    const { client, spies } = makeClient();
    await new SupabasePrivateMediaAdapter(client).remove(REFERENCE);
    expect(spies.remove).toHaveBeenCalledWith([REFERENCE.objectPath]);
  });

  it('creates a short-lived URL with an injected expiry clock', async () => {
    const { client, spies } = makeClient();
    const adapter = new SupabasePrivateMediaAdapter(
      client,
      () => new Date('2026-08-12T00:00:00.000Z'),
    );

    await expect(adapter.createSignedUrl(REFERENCE)).resolves.toEqual({
      url: 'http://localhost:54321/storage/v1/object/sign/private',
      expiresAt: new Date('2026-08-12T00:01:00.000Z'),
    });
    expect(spies.createSignedUrl).toHaveBeenCalledWith(REFERENCE.objectPath, 60);
  });

  it('rejects traversal before Storage calls', async () => {
    const { client, spies } = makeClient();
    const adapter = new SupabasePrivateMediaAdapter(client);

    await expect(
      adapter.download({ bucket: 'question-photos', objectPath: '../other/private.jpg' }),
    ).rejects.toMatchObject({ code: 'invalidReference' });
    expect(spies.getUser).not.toHaveBeenCalled();
  });
});
