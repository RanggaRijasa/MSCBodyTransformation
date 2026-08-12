import { QueryClient } from '@tanstack/react-query';
import { afterEach, describe, expect, it, vi } from 'vitest';

import { destinationForRole, parseAccountRole } from '../../src/shared/auth/account-role';
import { privateObjectUrlCountForTests, privateSignedUrlCountForTests, purgePrivateCaches, registerPrivateObjectUrl, registerPrivateSignedUrl } from '../../src/shared/auth/private-cache';

afterEach(() => vi.restoreAllMocks());

describe('server-controlled account role', () => {
  it.each(['participant', 'coach', 'admin'] as const)('accepts protected role %s', (role) => {
    expect(parseAccountRole(role)).toBe(role);
  });

  it('rejects editable or unknown metadata role', () => {
    expect(() => parseAccountRole('super-admin')).toThrow('Peran akun tidak dapat diverifikasi');
  });

  it('routes privileged roles to their protected shells', () => {
    expect(destinationForRole('participant', '/app/programs/program-1')).toBe('/app/programs/program-1');
    expect(destinationForRole('coach', '/app/profile')).toBe('/coach');
    expect(destinationForRole('admin', '/app/profile')).toBe('/admin');
  });
});

describe('private cache boundary', () => {
  it('removes only private account queries and revokes registered object URLs', () => {
    const queryClient = new QueryClient();
    queryClient.setQueryData(['public', 'programs'], [{ id: 'public' }]);
    queryClient.setQueryData(['private', 'owner-a', 'profile'], { weight: 'never-log' });
    const revoke = vi.spyOn(URL, 'revokeObjectURL').mockImplementation(() => undefined);
    registerPrivateObjectUrl('blob:https://app.example/private-photo');
    registerPrivateSignedUrl('https://local.example/storage/signed/private-photo');

    purgePrivateCaches(queryClient);

    expect(queryClient.getQueryData(['public', 'programs'])).toEqual([{ id: 'public' }]);
    expect(queryClient.getQueryData(['private', 'owner-a', 'profile'])).toBeUndefined();
    expect(revoke).toHaveBeenCalledWith('blob:https://app.example/private-photo');
    expect(privateObjectUrlCountForTests()).toBe(0);
    expect(privateSignedUrlCountForTests()).toBe(0);
  });
});
