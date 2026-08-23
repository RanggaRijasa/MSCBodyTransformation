import type { SupabaseClient } from '@supabase/supabase-js';

import { registerPrivateSignedUrl } from '@/shared/auth/private-cache';

export const DEFAULT_SIGNED_MEDIA_TTL_SECONDS = 60;

export type PrivateMediaBucket =
  | 'question-photos'
  | 'question-videos'
  | 'payment-evidence'
  | 'payment-destination-assets'
  | 'coach-public-media';

export type PrivateMediaObjectReference = Readonly<{
  bucket: PrivateMediaBucket;
  objectPath: string;
}>;

export type PrivateMediaErrorCode =
  | 'unauthenticated'
  | 'invalidReference'
  | 'uploadRejected'
  | 'downloadRejected'
  | 'deleteRejected'
  | 'signedUrlRejected';

const PRIVATE_MEDIA_ERROR_MESSAGES: Record<PrivateMediaErrorCode, string> = {
  unauthenticated: 'Sesi Anda berakhir. Masuk lagi untuk melanjutkan.',
  invalidReference: 'Referensi media tidak valid. Muat ulang halaman lalu coba lagi.',
  uploadRejected: 'Media tidak dapat diunggah. Periksa koneksi lalu coba lagi.',
  downloadRejected: 'Media tidak dapat dimuat. Periksa koneksi lalu coba lagi.',
  deleteRejected: 'Media sementara tidak dapat dibersihkan. Coba lagi.',
  signedUrlRejected: 'Akses media tidak dapat dibuat. Muat ulang halaman lalu coba lagi.',
};

export class PrivateMediaError extends Error {
  readonly code: PrivateMediaErrorCode;

  constructor(code: PrivateMediaErrorCode) {
    super(PRIVATE_MEDIA_ERROR_MESSAGES[code]);
    this.name = 'PrivateMediaError';
    this.code = code;
  }
}

export type PrivateMediaUploadResult = Readonly<{
  objectId: string;
}>;

export type EphemeralSignedMediaUrl = Readonly<{
  url: string;
  expiresAt: Date;
}>;

export class SupabasePrivateMediaAdapter {
  constructor(
    private readonly client: SupabaseClient,
    private readonly now: () => Date = () => new Date(),
  ) {}

  async upload(
    reference: PrivateMediaObjectReference,
    body: Blob | ArrayBuffer,
    contentType = 'image/jpeg',
  ): Promise<PrivateMediaUploadResult> {
    validateObjectReference(reference);
    await this.requireAuthenticatedUser();

    let response: Awaited<ReturnType<ReturnType<SupabaseClient['storage']['from']>['upload']>>;
    try {
      response = await this.client.storage.from(reference.bucket).upload(reference.objectPath, body, {
        contentType,
        cacheControl: '0',
        upsert: false,
      });
    } catch {
      throw new PrivateMediaError('uploadRejected');
    }

    if (response.error !== null || response.data === null) {
      throw new PrivateMediaError('uploadRejected');
    }

    return { objectId: response.data.id };
  }

  async download(reference: PrivateMediaObjectReference): Promise<Blob> {
    validateObjectReference(reference);
    await this.requireAuthenticatedUser();

    let response: Awaited<ReturnType<ReturnType<SupabaseClient['storage']['from']>['download']>>;
    try {
      response = await this.client.storage
        .from(reference.bucket)
        .download(reference.objectPath, {}, { cache: 'no-store' });
    } catch {
      throw new PrivateMediaError('downloadRejected');
    }

    if (response.error !== null || response.data === null) {
      throw new PrivateMediaError('downloadRejected');
    }

    return response.data;
  }

  async createSignedUrl(
    reference: PrivateMediaObjectReference,
  ): Promise<EphemeralSignedMediaUrl> {
    validateObjectReference(reference);
    await this.requireAuthenticatedUser();

    let response: Awaited<
      ReturnType<ReturnType<SupabaseClient['storage']['from']>['createSignedUrl']>
    >;
    try {
      response = await this.client.storage
        .from(reference.bucket)
        .createSignedUrl(reference.objectPath, DEFAULT_SIGNED_MEDIA_TTL_SECONDS);
    } catch {
      throw new PrivateMediaError('signedUrlRejected');
    }

    if (response.error !== null || response.data === null) {
      throw new PrivateMediaError('signedUrlRejected');
    }

    registerPrivateSignedUrl(response.data.signedUrl);
    return {
      url: response.data.signedUrl,
      expiresAt: new Date(this.now().getTime() + DEFAULT_SIGNED_MEDIA_TTL_SECONDS * 1_000),
    };
  }

  async remove(reference: PrivateMediaObjectReference): Promise<void> {
    validateObjectReference(reference);
    await this.requireAuthenticatedUser();
    try {
      const response = await this.client.storage.from(reference.bucket).remove([reference.objectPath]);
      if (response.error !== null) throw response.error;
    } catch {
      throw new PrivateMediaError('deleteRejected');
    }
  }

  private async requireAuthenticatedUser(): Promise<void> {
    let response: Awaited<ReturnType<SupabaseClient['auth']['getUser']>>;
    try {
      response = await this.client.auth.getUser();
    } catch {
      throw new PrivateMediaError('unauthenticated');
    }
    if (response.error !== null || response.data.user === null) {
      throw new PrivateMediaError('unauthenticated');
    }
  }
}

function validateObjectReference(reference: PrivateMediaObjectReference): void {
  if (
    reference.objectPath.trim() === '' ||
    reference.objectPath.startsWith('/') ||
    reference.objectPath.includes('\\') ||
    reference.objectPath.split('/').some((segment) => segment === '' || segment === '..') ||
    /[\u0000-\u001F\u007F]/u.test(reference.objectPath)
  ) {
    throw new PrivateMediaError('invalidReference');
  }
}
