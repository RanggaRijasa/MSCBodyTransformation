import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

import { coachActivityFeedSchema, coachLeaderboardEntrySchema, coachParticipantDetailSchema, coachParticipantDirectorySchema, coachWorkspaceSchema, memberLevelPresentation, publicCoachProfileSchema } from '@/features/coach/coach-experience-models';

describe('kontrak pengalaman Coach W06', () => {
  it('menetapkan harga setiap level tanpa nominal dari client bebas', () => {
    expect(memberLevelPresentation.member.price).toBeNull();
    expect(memberLevelPresentation.sc.price).toBe(100_000);
    expect(memberLevelPresentation.sb.price).toBe(100_000);
    expect(memberLevelPresentation.supervisor.price).toBe(150_000);
    expect(memberLevelPresentation.world_team.price).toBe(150_000);
    expect(memberLevelPresentation.tab_team.price).toBe(200_000);
    expect(memberLevelPresentation.get_team.price).toBe(200_000);
    expect(memberLevelPresentation.millionaire_team.price).toBe(200_000);
    expect(memberLevelPresentation.presidents_team.price).toBe(200_000);
  });

  it('read model publik tidak memiliki ID auth, QR, atau jalur bukti privat', () => {
    expect(Object.keys(publicCoachProfileSchema.shape)).not.toContain('coach_user_id');
    expect(Object.keys(publicCoachProfileSchema.shape)).not.toContain('coach_qr_identifier');
    expect(Object.keys(publicCoachProfileSchema.shape)).not.toContain('payment_evidence');
    expect(Object.keys(publicCoachProfileSchema.shape)).not.toContain('is_verified_editable');
    expect(publicCoachProfileSchema.shape.photo_kind.safeParse('storage').success).toBe(true);
    expect(publicCoachProfileSchema.shape.photo_kind.safeParse('provider').success).toBe(false);
  });

  it('workspace menyimpan QR hanya pada batas privat Coach', () => {
    expect(Object.keys(coachWorkspaceSchema.shape)).toContain('qr_payload');
    const source = readFileSync('src/features/coach/CoachWorkspaceComponents.tsx', 'utf8');
    expect(source).not.toContain('selectable>{payload}');
    expect(source).not.toContain('navigator.clipboard.writeText(payload)');
    expect(source).toContain('Kode internal tidak ditampilkan atau dapat disalin');
    expect(source).toContain('isQrDarkModule(value)');
    expect(source).not.toContain('value === 0');
  });

  it('ringkasan Dashboard Coach mengikuti tiga metrik iOS', () => {
    const source = readFileSync('src/features/coach/CoachWorkspaceComponents.tsx', 'utf8');
    expect(source).toContain('Ringkasan pendampingan');
    expect(source).toContain('label="peserta"');
    expect(source).toContain('label="progres"');
    expect(source).toContain('label="program aktif"');
    expect(source).toContain("program.status === 'active'");
    expect(source).toContain('Math.floor');
    expect(source).not.toContain('Akses aktif sampai');
    expect(source).not.toContain('<Metric label="Perlu diperiksa"');
  });

  it('tab Program Coach memakai ulang perjalanan program Participant dan memisahkan enrollment pribadi', () => {
    const coachRoute = readFileSync('src/app/coach/programs.tsx', 'utf8');
    const catalogRoute = readFileSync('src/app/app/programs.tsx', 'utf8');
    const paymentRoute = readFileSync('src/app/app/payments/[programId].tsx', 'utf8');
    const paymentFlow = readFileSync('src/features/payment/ParticipantPaymentFlow.tsx', 'utf8');
    const repository = readFileSync('src/features/participant/participant-repository.ts', 'utf8');
    const migration = readFileSync('../supabase/migrations/20260813062314_w06_coach_program_participation.sql', 'utf8');

    expect(coachRoute).toContain("export { default } from '../app/programs'");
    expect(catalogRoute).toContain("state.account.role === 'participant' || state.account.role === 'coach'");
    expect(paymentRoute).toContain("state.account.role === 'participant' || state.account.role === 'coach'");
    expect(repository).toContain(".eq('participant_id', actorId)");
    expect(repository).toContain(".in('enrollment_id', enrollmentIds)");
    expect(migration).toContain("role in ('participant', 'coach')");
    expect(migration).toContain("program_participant.role = 'coach'");
    expect(migration).toContain('coach.user_id <> program_participant.user_id');
    expect(migration).toContain("actor_profile.role = 'coach' and target_coach.user_id <> actor_id");
    expect(paymentFlow).toContain('Pindai QR Coach milikmu sendiri untuk melanjutkan. QR Coach lain tidak dapat digunakan.');
    expect(paymentFlow).toContain('Pindai QR Coach milikmu');
  });

  it('migrasi mengaktifkan RLS, keputusan atomik, dan snapshot publik terpisah', () => {
    const sql = readFileSync('../supabase/migrations/20260813051840_w06_coach_experience.sql', 'utf8');
    expect(sql).toContain('alter table public.coach_public_profile_drafts enable row level security');
    expect(sql).toContain('approve_coach_payment_and_activate');
    expect(sql).toContain("statement_timestamp() + interval '3 months'");
    expect(sql).toContain('coach_public_profiles');
    expect(sql).toContain('jsonb_strip_nulls');
    expect(sql).toContain('private.has_active_coach_access(published.coach_user_id)');
    expect(sql).toContain("check (photo_kind = 'storage')");
    expect(sql).not.toContain("photo_kind := 'provider'");
    expect(sql).toContain('allocate_my_coach_public_media_path');
    expect(sql).toContain('coach_public_media_namespaces');
  });

  it('periksa bukti mengikuti struktur iOS tanpa konsep bintang', () => {
    const components = readFileSync('src/features/coach/CoachReviewComponents.tsx', 'utf8');
    const repository = readFileSync('src/features/coach/coach-review-repository.ts', 'utf8');

    expect(components).toContain('Filter bukti');
    expect(components).toContain('Riwayat program');
    expect(components).toContain('Perlu persetujuan');
    expect(components).toContain('Poin otomatis');
    expect(components).toContain('Persetujuan Coach diperlukan');
    expect(components).toContain('Bukti yang dikirim');
    expect(components).toContain('label="Kembali ke dashboard"');
    expect(components).toContain("router.replace('/coach')");
    expect(components).not.toMatch(/bintang|coachRating|ratingSection/iu);
    expect(repository).toContain('instructions,content_kind,verification_mode');
    expect(repository).toContain('points_per_activity');
    expect(repository).toContain('quiz_attempt_results');
  });

  it('peserta saya mengikuti direktori, filter, detail privat, dan progres iOS', () => {
    const components = readFileSync('src/features/coach/CoachParticipantComponents.tsx', 'utf8');
    const migration = readFileSync('../supabase/migrations/20260813095648_w06_coach_participant_directory_detail.sql', 'utf8');
    const weighInProgressMigration = readFileSync('../supabase/migrations/20260822024334_w08_coach_weigh_in_progress_read_model.sql', 'utf8');
    const dueProgressMigration = readFileSync('../supabase/migrations/20260822040354_w08_coach_due_progress_attention.sql', 'utf8');
    const attentionPolicy = readFileSync('src/features/coach/coach-participant-attention.ts', 'utf8');

    expect(Object.keys(coachParticipantDirectorySchema.shape)).toEqual(['participants', 'programs']);
    expect(Object.keys(coachParticipantDetailSchema.shape)).toEqual([
      'participant', 'enrollment', 'program', 'summary', 'weigh_ins', 'submissions', 'days',
    ]);
    expect(components).toContain('Cari nama atau kota');
    expect(components).toContain('Filter dan urutkan');
    expect(components).toContain('Riwayat program');
    expect(components).toContain('Riwayat berat badan');
    expect(components).toContain('Aktivitas terbaru');
    expect(components).toContain('Lihat bukti');
    expect(components).toContain('Lihat progres');
    expect(components).toContain('Rincian progres');
    expect(components).toContain('Muat bukti ${mediaLabel}');
    expect(components).toContain('accessibilityState={{ expanded }}');
    expect(components).toContain('if (!objectPath || !requested) return;');
    expect(migration).toContain('get_my_coach_participant_directory');
    expect(migration).toContain('get_my_coach_participant_detail');
    expect(migration).toContain('enrollment.coach_id = caller_id');
    expect(migration).toContain("submission.status <> 'draft'");
    expect(migration).toContain("raise exception 'permission_denied'");
    expect(migration).toContain('public.weigh_ins');
    expect(migration).toContain('private_photo_path');
    expect(weighInProgressMigration).toContain('w08_coach_enrollment_progress_metrics');
    expect(weighInProgressMigration).toContain("step.content_kind = 'initial_weigh_in' and weigh_in.kind = 'initial'");
    expect(weighInProgressMigration).toContain("'completed_step_count'");
    expect(weighInProgressMigration).toContain("'active_day_count'");
    expect(weighInProgressMigration).toContain("'\"approved\"'::jsonb");
    expect(dueProgressMigration).toContain("'due_step_count'");
    expect(dueProgressMigration).toContain("'completed_due_step_count'");
    expect(dueProgressMigration).toContain("target.pace = 'self_paced'");
    expect(attentionPolicy).toContain('completed_due_step_count < enrollment.due_step_count');
    expect(components).toContain('needsCoachAttention(enrollment)');
    expect(components).not.toContain('progress_percentage < 50');
  });

  it('aktivitas terbaru mengikuti jenis, filter, tanggal, dan navigasi iOS', () => {
    const components = readFileSync('src/features/coach/CoachActivityComponents.tsx', 'utf8');
    const migration = readFileSync('../supabase/migrations/20260814031900_w06_coach_activity_feed.sql', 'utf8');

    expect(Object.keys(coachActivityFeedSchema.shape)).toEqual(['items', 'programs']);
    expect(components).toContain('Filter aktivitas');
    expect(components).toContain('Riwayat program');
    expect(components).toContain('Jenis aktivitas');
    expect(components).toContain('7 hari terakhir');
    expect(components).toContain('30 hari terakhir');
    expect(components).toContain('Aktivitas sebelumnya');
    expect(components).toContain('Mengirim bukti untuk');
    expect(components).toContain('Menyelesaikan langkah');
    expect(components).toContain('Bergabung ke program');
    expect(components).toContain('Menyelesaikan program');
    expect(components).toContain("router.push('/coach/reviews')");
    expect(migration).toContain('get_my_coach_activity_feed');
    expect(migration).toContain('enrollment.coach_id = caller_id');
    expect(migration).toContain("private.has_active_coach_access(caller_id)");
    expect(migration).toContain('revoke execute on function public.get_my_coach_activity_feed() from public, anon');
  });

  it('peringkat bersama mengikuti podium iOS dan membatasi rincian Coach pada Pesertamu', () => {
    const components = readFileSync('src/features/leaderboard/LeaderboardExperience.tsx', 'utf8');
    const migration = readFileSync('../supabase/migrations/20260814040500_w06_shared_leaderboard.sql', 'utf8');

    expect(Object.keys(coachLeaderboardEntrySchema.shape)).toEqual([
      'id', 'program_id', 'participant_id', 'participant_display_name', 'avatar_url',
      'avatar_reference',
      'rank', 'progress_percentage', 'total_points', 'is_assigned_to_coach',
      'step_points', 'weight_points', 'adjustment_points',
    ]);
    expect(components).toContain('leaderboard.podium');
    expect(components).toContain('Peringkat lainnya');
    expect(components).toContain('Pesertamu');
    expect(components).toContain('Riwayat peringkat');
    expect(components).toContain('Rincian poin');
    expect(components).toContain('Poin penurunan berat badan');
    expect(components).toContain('entry.assignedToCoach ? openDetails : undefined');
    expect(migration).toContain('private.has_active_coach_access(caller_id)');
    expect(migration).toContain('enrollment.coach_id = caller_id as is_assigned_to_coach');
    expect(migration).toContain('case when ranked.is_assigned_to_coach then ranked.weight_points else null end');
    expect(migration).toContain('revoke all on function public.get_my_coach_leaderboard(uuid, integer, integer) from anon');
    expect(migration).not.toContain('weight_kg');
  });

  it('fixture periksa bukti bersifat lokal dan dapat diulang', () => {
    const source = readFileSync('scripts/ensure-coach-review-preview.mjs', 'utf8');

    expect(source).toContain("['127.0.0.1', 'localhost']");
    expect(source).toContain('Pengujian lokal review');
    expect(source).toContain('2 perlu tindakan, 1 poin otomatis, 1 riwayat ditolak');
    expect(source).toContain("upsert: true");
  });
});
