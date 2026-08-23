import { describe, expect, it } from 'vitest';

import { publicCoachSchema, publicLeaderboardRowSchema, publicProgramSchema } from '../../src/features/public/public-models';

const id = '11111111-1111-4111-8111-111111111111';

describe('public read model boundary', () => {
  it('accepts only the approved public program projection', () => {
    const value = publicProgramSchema.parse({
      id,
      title: 'Program publik',
      summary: 'Langkah harian terarah.',
      status: 'active',
      starts_on: '2026-08-12',
      ends_on: '2026-08-31',
      timezone: 'Asia/Makassar',
      pricing_mode: 'free',
      program_days: [],
    });
    expect(value.title).toBe('Program publik');
  });

  it('rejects leaderboard data without the required public identity and never models weight', () => {
    expect(() => publicLeaderboardRowSchema.parse({ id, program_id: id, rank: 1, total_points: 100 })).toThrow();
    expect(Object.keys(publicLeaderboardRowSchema.shape)).not.toContain('weight');
    expect(Object.keys(publicLeaderboardRowSchema.shape)).not.toContain('initial_weight');
  });

  it('memodelkan foto profil aman untuk semua pembaca leaderboard', () => {
    const value = publicLeaderboardRowSchema.parse({
      id,
      program_id: id,
      participant_id: id,
      participant_display_name: 'Peserta MSC',
      avatar_url: 'https://example.invalid/avatar.jpg',
      avatar_reference: id,
      rank: 1,
      progress_percentage: 50,
      total_points: 100,
    });

    expect(value.avatar_url).toBe('https://example.invalid/avatar.jpg');
    expect(value.avatar_reference).toBe(id);
  });

  it('models Coach without QR or private participant relationships', () => {
    expect(Object.keys(publicCoachSchema.shape)).toEqual([
      'id',
      'handle',
      'display_name',
      'professional_headline',
      'biography',
      'city',
      'photo_reference',
      'is_verified',
    ]);
    expect(Object.keys(publicCoachSchema.shape)).not.toContain('coach_qr_identifier');
    expect(Object.keys(publicCoachSchema.shape)).not.toContain('current_coach_id');
  });
});
