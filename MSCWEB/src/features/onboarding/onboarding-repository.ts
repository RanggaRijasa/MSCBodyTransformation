import { z } from 'zod';

import type { AccountPurpose, ConfirmedCoach, OnboardingSessionContext, ProvisionalProfile } from './onboarding-models';
import {
  cancellationResultSchema,
  confirmedCoachSchema,
  onboardingSessionContextSchema,
  provisionalProfileSchema,
} from './onboarding-models';
import type { MemberLevel } from '@/features/coach/coach-experience-models';
import { getSupabaseBrowserClient } from '@/shared/supabase/client';

export class OnboardingError extends Error {
  constructor(readonly code: 'validation' | 'expired' | 'invalidCoach' | 'conflict' | 'forbidden' | 'missingProfile' | 'unknown', message?: string) {
    super(message ?? {
      validation: 'Periksa kembali data yang belum lengkap.',
      expired: 'Waktu pendaftaran berakhir. Masuk kembali untuk memulai dengan aman.',
      invalidCoach: 'QR Coach tidak valid atau Coach sudah tidak aktif. Minta QR terbaru lalu pindai kembali.',
      conflict: 'Data berubah di tab lain. Muat ulang lalu lanjutkan dari langkah terbaru.',
      forbidden: 'Pendaftaran ini tidak dapat diakses oleh akun tersebut.',
      missingProfile: 'Pendaftaran sudah dibersihkan. Masuk kembali bila ingin membuat akun.',
      unknown: 'Pendaftaran belum dapat diproses. Coba lagi.',
    }[code]);
    this.name = 'OnboardingError';
  }
}

export type SaveProvisionalProfileCommand = Readonly<{
  displayName: string;
  phoneNumber: string;
  memberLevel: MemberLevel;
  purpose: AccountPurpose;
  expectedVersion: number;
}>;

export class SupabaseOnboardingRepository {
  private readonly client = getSupabaseBrowserClient();

  async getSessionContext(): Promise<OnboardingSessionContext> {
    const response = await this.client.rpc('get_my_session_context');
    return parse(response.data, response.error, onboardingSessionContextSchema);
  }

  async getProfile(): Promise<ProvisionalProfile> {
    const response = await this.client.rpc('get_my_provisional_onboarding_profile');
    return parse(response.data, response.error, provisionalProfileSchema);
  }

  async saveProfile(command: SaveProvisionalProfileCommand): Promise<ProvisionalProfile> {
    const response = await this.client.rpc('save_my_provisional_onboarding_profile', {
      new_display_name: command.displayName.trim(),
      new_phone_number: command.phoneNumber,
      new_member_level: command.memberLevel,
      new_account_purpose: command.purpose,
      expected_version: command.expectedVersion,
    });
    return parse(response.data, response.error, provisionalProfileSchema);
  }

  async validateCoachQr(rawPayload: string): Promise<ConfirmedCoach> {
    const response = await this.client.rpc('validate_participant_onboarding_coach_qr', {
      coach_qr: rawPayload,
    });
    return parse(response.data, response.error, confirmedCoachSchema);
  }

  async finalizeParticipant(rawPayload: string, expectedVersion: number): Promise<void> {
    const response = await this.client.rpc('finalize_participant_onboarding', {
      coach_qr: rawPayload,
      expected_version: expectedVersion,
    });
    if (response.error) throw mapOnboardingError(response.error);
  }

  async prepareCoachHandoff(expectedVersion: number): Promise<ProvisionalProfile> {
    const response = await this.client.rpc('prepare_coach_application_handoff', {
      expected_version: expectedVersion,
    });
    return parse(response.data, response.error, provisionalProfileSchema);
  }

  async requestCancellation(idempotencyKey: string): Promise<'queued' | 'retained' | 'completed'> {
    const response = await this.client.rpc('request_my_provisional_cancellation', {
      request_idempotency_key: idempotencyKey,
    });
    const result = parse(response.data, response.error, cancellationResultSchema);
    if (result.status === 'retained' || result.status === 'completed') return result.status;
    return 'queued';
  }
}

function parse<T>(data: unknown, error: { message: string; code?: string; status?: number } | null, schema: z.ZodType<T>): T {
  if (error) throw mapOnboardingError(error);
  const parsed = schema.safeParse(Array.isArray(data) ? data[0] : data);
  if (!parsed.success) throw new OnboardingError('unknown');
  return parsed.data;
}

export function mapOnboardingError(error: { message: string; code?: string; status?: number }): OnboardingError {
  if (/session_profile_missing|profile_not_found/iu.test(error.message)) return new OnboardingError('missingProfile');
  if (/provisional_identity_expired/iu.test(error.message)) return new OnboardingError('expired');
  if (/coach_qr_invalid/iu.test(error.message)) return new OnboardingError('invalidCoach');
  if (/version_conflict|idempotency_conflict|already/iu.test(error.message)) return new OnboardingError('conflict');
  if (error.status === 403 || error.code === '42501' || /permission_denied|not_editable/iu.test(error.message)) return new OnboardingError('forbidden');
  if (/invalid|incomplete|required|ineligible|not_ready/iu.test(error.message)) return new OnboardingError('validation');
  return new OnboardingError('unknown');
}

let repository: SupabaseOnboardingRepository | undefined;
export function getOnboardingRepository() {
  repository ??= new SupabaseOnboardingRepository();
  return repository;
}
