import { createClient } from '@supabase/supabase-js';
import { randomUUID } from 'node:crypto';
import { expect, it } from 'vitest';

const localUrl = process.env.API_URL;
const publishableKey = process.env.PUBLISHABLE_KEY ?? process.env.ANON_KEY;
const secretKey = process.env.SECRET_KEY ?? process.env.SERVICE_ROLE_KEY;
const canRun = localUrl !== undefined && publishableKey !== undefined && secretKey !== undefined;

it.runIf(canRun)('reads only the signed-in Participant program state from local Supabase', async () => {
  const url = new URL(localUrl as string);
  expect(['127.0.0.1', 'localhost']).toContain(url.hostname);

  const service = createClient(localUrl as string, secretKey as string, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const suffix = randomUUID();
  const email = `w03-participant-${suffix}@test.invalid`;
  const password = `W03-${suffix}!`;
  const programId = randomUUID();
  const dayIds = [randomUUID(), randomUUID(), randomUUID()];
  const stepIds = Array.from({ length: 7 }, () => randomUUID());
  let userId: string | undefined;

  try {
    const { data: identities, error: identitiesError } = await service.auth.admin.createUser({ email, password, email_confirm: true });
    expect(identitiesError).toBeNull();
    userId = identities.user?.id;
    expect(userId).toBeTruthy();

    const { data: admins } = await service.from('profiles').select('user_id').eq('role', 'admin').limit(1);
    const { data: coaches } = await service.from('profiles').select('user_id').eq('role', 'coach').limit(1);
    const adminId = admins?.[0]?.user_id;
    const coachId = coaches?.[0]?.user_id;
    expect(adminId).toBeTruthy();
    expect(coachId).toBeTruthy();

    expect((await service.from('profiles').update({
      role: 'participant',
      display_name: 'Peserta W03',
      current_coach_id: coachId,
      onboarding_status: 'active',
      provisional_expires_at: null,
      finalized_at: new Date().toISOString(),
    }).eq('user_id', userId as string)).error).toBeNull();

    const today = localDate(0);
    expect((await service.from('programs').insert({
      id: programId,
      title: 'Program W03 lokal',
      summary: 'Program lengkap untuk verifikasi browser Participant.',
      status: 'active',
      pace: 'scheduled',
      duration_mode: 'specific_dates',
      starts_on: localDate(-1),
      ends_on: localDate(1),
      timezone: 'Asia/Makassar',
      past_step_policy: 'read_only',
      future_step_policy: 'locked',
      wellness_disclaimer: 'Program wellness non-diagnostik.',
      points_per_activity: 10,
      points_per_weight_kg: 100,
      quiz_passing_percentage: 70,
      pricing_mode: 'free',
      published_at: new Date().toISOString(),
      created_by: adminId as string,
    })).error).toBeNull();

    expect((await service.from('program_days').insert([
      { id: dayIds[0], program_id: programId, day_number: 1, title: 'Mulai', scheduled_on: localDate(-1) },
      { id: dayIds[1], program_id: programId, day_number: 2, title: 'Hari ini', scheduled_on: today },
      { id: dayIds[2], program_id: programId, day_number: 3, title: 'Besok', scheduled_on: localDate(1) },
    ])).error).toBeNull();

    const kinds = ['article', 'video', 'form', 'quiz', 'initial_weigh_in', 'daily_weigh_in', 'final_weigh_in'];
    expect((await service.from('program_steps').insert(kinds.map((kind, index) => ({
      id: stepIds[index],
      program_day_id: dayIds[1] as string,
      step_order: index + 1,
      title: `Langkah ${kind}`,
      instructions: 'Ikuti petunjuk program.',
      content_kind: kind,
      completion_policy: kind === 'quiz'
        ? 'automatic_quiz'
        : kind.includes('weigh_in')
          ? 'submit_weigh_in'
          : kind === 'video'
            ? 'watch_video'
            : kind === 'form'
              ? 'answer_all_questions'
              : 'mark_complete',
      verification_mode: kind === 'form' ? 'coach_review' : 'automatic',
      video_required: kind === 'video',
      video_threshold: kind === 'video' ? 80 : null,
      video_autoplay: false,
    })))).error).toBeNull();

    expect((await service.from('program_enrollments').insert({
      id: suffix,
      program_id: programId,
      participant_id: userId as string,
      coach_id: coachId as string,
      status: 'active',
    })).error).toBeNull();
    expect((await service.from('program_scores').insert({
      enrollment_id: suffix,
      activity_points: 20,
      quiz_points: 10,
      weight_points: 0,
      adjustment_points: 0,
      progress_percentage: 25,
      rank: 3,
    })).error).toBeNull();
    expect((await service.from('step_submissions').insert({
      enrollment_id: suffix,
      step_id: stepIds[2] as string,
      status: 'pending',
      idempotency_key: `w03-${suffix}`,
    })).error).toBeNull();

    const participant = createClient(localUrl as string, publishableKey as string, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    expect((await participant.auth.signInWithPassword({ email, password })).error).toBeNull();

    const [programs, enrollments, access, submissions, scores, coach] = await Promise.all([
      participant.rpc('list_public_programs', { target_program_id: programId, result_limit: 1, result_offset: 0 }),
      participant.from('program_enrollments').select('id, program_id, coach_id, status, enrolled_at, completed_at'),
      participant.rpc('list_my_program_day_access'),
      participant.from('step_submissions').select('id, enrollment_id, step_id, attempt_sequence, status, review_note, submitted_at'),
      participant.from('program_scores').select('enrollment_id, activity_points, quiz_points, weight_points, adjustment_points, progress_percentage, rank, recalculated_at'),
      participant.rpc('get_my_assigned_coach'),
    ]);

    for (const result of [programs, enrollments, access, submissions, scores, coach]) {
      expect(result.error).toBeNull();
    }
    expect(programs.data).toHaveLength(1);
    expect((programs.data?.[0] as { program_days?: unknown[] }).program_days).toHaveLength(3);
    expect(enrollments.data?.map(({ program_id }) => program_id)).toContain(programId);
    const accessRows = (access.data ?? []) as Array<{ program_id: string; is_current_day: boolean; access_state: string }>;
    expect(accessRows.filter(({ program_id }) => program_id === programId)).toHaveLength(3);
    expect(accessRows.find(({ program_id, is_current_day }) => program_id === programId && is_current_day)?.access_state).toBe('available');
    expect(submissions.data?.[0]?.status).toBe('pending');
    expect(scores.data?.[0]?.progress_percentage).toBe(25);
    expect(coach.data).toHaveLength(1);

    const serializedPublic = JSON.stringify(programs.data);
    for (const privateField of ['participant_id', 'initial_weight', 'final_weight', 'coach_qr_identifier']) {
      expect(serializedPublic).not.toContain(privateField);
    }
  } finally {
    if (programId) await service.from('programs').delete().eq('id', programId);
    if (userId) await service.auth.admin.deleteUser(userId);
  }
});

function localDate(offsetDays: number): string {
  const value = new Date(Date.now() + offsetDays * 86_400_000);
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Makassar',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(value);
  const get = (type: Intl.DateTimeFormatPartTypes) => parts.find((part) => part.type === type)?.value;
  return `${get('year')}-${get('month')}-${get('day')}`;
}
