import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

const migration = readFileSync('../supabase/migrations/20260817014822_w07_admin_experience.sql', 'utf8');
const verificationMigration = readFileSync('../supabase/migrations/20260817090704_w07_admin_program_default_verification.sql', 'utf8');
const questionMediaMigration = readFileSync('../supabase/migrations/20260821055430_w08_question_video_and_prompt_media.sql', 'utf8');
const paidPublishMigration = readFileSync('../supabase/migrations/20260821072405_w08_paid_program_publish_handoff.sql', 'utf8');
const dashboard = readFileSync('src/features/admin/AdminDashboardComponents.tsx', 'utf8');
const programs = [
  'src/features/admin/AdminProgramComponents.tsx',
  'src/features/admin/AdminProgramEditorFlow.tsx',
  'src/features/admin/AdminProgramContentFlow.tsx',
].map((path) => readFileSync(path, 'utf8')).join('\n');
const people = readFileSync('src/features/admin/AdminPeopleComponents.tsx', 'utf8');
const content = readFileSync('src/features/admin/AdminContentComponents.tsx', 'utf8');
const settings = readFileSync('src/features/admin/AdminSettingsComponents.tsx', 'utf8');
const repository = readFileSync('src/features/admin/admin-repository.ts', 'utf8');
const queries = readFileSync('src/features/admin/admin-queries.ts', 'utf8');
const coachRepository = readFileSync('src/features/coach/coach-experience-repository.ts', 'utf8');
const coachApplications = readFileSync('src/features/coach/AdminCoachApplicationComponents.tsx', 'utf8');

describe('W07 Admin contract', () => {
  it('keeps the five iOS destinations and unique dashboard actions', () => {
    for (const label of ['Dashboard', 'Program', 'Orang', 'Konten', 'Pengaturan']) expect(readFileSync('src/shared/navigation/navigation-model.ts', 'utf8')).toContain(label);
    for (const label of ['Perlu tindakan', 'Buat program', 'Tambah poster', 'Gambaran hari ini', 'Aktivitas terbaru']) expect(dashboard).toContain(label);
    expect(dashboard).not.toContain('Kelola program');
    expect(dashboard).not.toContain('Kelola orang');
  });

  it('uses the Participant renderer for Admin preview and includes every content/question type', () => {
    expect(programs).toContain("from '@/features/participant/ParticipantProgramComponents'");
    expect(programs).toContain('ProgramDefinitionPreview');
    for (const kind of ['article', 'video', 'form', 'quiz', 'initial_weigh_in', 'daily_weigh_in', 'final_weigh_in']) expect(programs).toContain(`'${kind}'`);
    for (const kind of ['short_answer', 'long_answer', 'number', 'single_choice', 'multiple_choice', 'image_choice', 'photo_upload', 'video_upload', 'heading', 'text']) expect(programs).toContain(`'${kind}'`);
    for (const copy of ['Media panduan (opsional)', "picker('image')", "picker('video')", 'Aktifkan analisis AI makanan']) expect(programs).toContain(copy);
    expect(questionMediaMigration).toContain("'question-videos'");
    expect(questionMediaMigration).toContain("'program-question-media'");
    expect(questionMediaMigration).toContain('private_video_path');
  });

  it('persists the program verification default and exposes explicit day policies', () => {
    expect(verificationMigration).toContain('default_verification_mode');
    expect(verificationMigration).toContain("('automatic', 'coach_review')");
    for (const label of ['Otomatis', 'Pemeriksaan Coach', 'Tetap tersedia', 'Hanya baca', 'Tersedia lebih awal', 'Terkunci', 'Disembunyikan']) expect(programs).toContain(label);
  });

  it('routes authority writes through RPCs and records before/after audit state', () => {
    for (const operation of ['save_admin_program_draft', 'duplicate_admin_program_as_draft', 'archive_admin_program', 'admin_enroll_participant', 'admin_transfer_coach', 'admin_adjust_score', 'moderate_admin_coach_profile_item', 'correct_food_insight_rating', 'lock_program_winners']) expect(repository).toContain(operation);
    expect(repository).not.toMatch(/from\('programs'\)\.update/u);
    expect(repository).not.toMatch(/from\('program_scores'\)\.update/u);
    expect(migration).toContain("'before_status'");
    expect(migration).toContain("'after_status'");
    expect(migration).toContain("'content_version'");
  });

  it('publishes paid programs only after manual-payment readiness and surfaces failures', () => {
    expect(paidPublishMigration).toContain("target.pricing_mode = 'paid'");
    expect(paidPublishMigration).toContain('private.current_payment_destination()');
    expect(paidPublishMigration).toContain("raise exception 'program_paid_not_ready'");
    expect(programs).toContain('Tujuan pembayaran belum siap');
    expect(programs).toContain('Program belum diterbitkan');
    expect(queries).toContain('publicQueryKeys.programs');
  });

  it('updates the full program cache after a nested editor save', () => {
    expect(queries).toContain("command.kind === 'saveProgram'");
    expect(queries).toContain('cacheSavedAdminProgram(queryClient, command.program)');
    expect(queries).toContain('queryClient.setQueryData(adminKeys.program(program.id), program)');
    expect(programs).toContain('key={`${query.data.id}:${query.data.updated_at}`}');
  });

  it('preserves protected profile fields and redacts AI operations', () => {
    expect(people).toContain('Coach pendamping');
    expect(people).toContain('Alasan enrollment');
    expect(people).toContain('Alasan perubahan Coach');
    expect(content).toContain('Data sensitif disamarkan');
    const aiProjection = migration.slice(migration.indexOf('list_admin_food_insight_operations'), migration.indexOf('list_admin_audit_events'));
    for (const forbidden of ['private_photo_path', 'rubric', 'lease_token', 'API_KEY', 'prompt']) expect(aiProjection).not.toContain(forbidden);
  });

  it('never shows or edits secrets in settings', () => {
    expect(settings).toContain('tidak ditampilkan');
    for (const forbidden of ['SERVICE_ROLE_KEY', 'FOOD_AI_API_KEY', 'JWT_SECRET', 'S3_PROTOCOL_ACCESS_KEY_SECRET']) expect(settings).not.toContain(forbidden);
  });

  it('excludes legacy Coach payment orders that cannot be joined to an application', () => {
    expect(coachRepository).toContain(".not('coach_application_id', 'is', null)");
  });

  it('keeps the Coach directory separate from the application queue', () => {
    expect(people).toContain('Daftar Coach');
    expect(people).toContain('Aplikasi Coach');
    expect(people).toContain("pendingOnly ? 'applications' : 'directory'");
    expect(coachApplications).toContain('Muat 20 aplikasi lagi');
    expect(coachApplications).toContain('items.slice(0, visibleCount)');
  });
});
