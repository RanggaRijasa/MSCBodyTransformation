import type { AdminProgram, AdminProgramStatus } from './admin-models';

export type AdminProgramStage = 'settings' | 'content' | 'review';

export type AdminProgramIssue = Readonly<{ stage: AdminProgramStage; message: string }>;

export function validateAdminProgram(program: AdminProgram): AdminProgramIssue[] {
  const issues: AdminProgramIssue[] = [];
  if (program.title.trim().length < 3) issues.push({ stage: 'settings', message: 'Nama program minimal 3 karakter.' });
  if (program.summary?.trim().length === 0) issues.push({ stage: 'settings', message: 'Deskripsi program perlu diisi.' });
  if (!program.cover_path || !program.cover_alt_text?.trim()) issues.push({ stage: 'settings', message: 'Cover dan teks alternatif perlu dilengkapi.' });
  if (!validDateRange(program.starts_on, program.ends_on)) issues.push({ stage: 'settings', message: 'Tanggal selesai tidak boleh sebelum tanggal mulai.' });
  if (program.participant_limit !== null && program.participant_limit < 1) issues.push({ stage: 'settings', message: 'Kapasitas peserta minimal 1.' });
  if (program.points_per_activity < 0 || program.points_per_weight_kg < 0) issues.push({ stage: 'settings', message: 'Poin tidak boleh negatif.' });
  if (program.quiz_passing_percentage < 0 || program.quiz_passing_percentage > 100) issues.push({ stage: 'settings', message: 'Nilai lulus kuis harus 0–100%.' });
  if (program.pricing_mode === 'paid' && (!program.desired_price || program.desired_price <= 0)) issues.push({ stage: 'settings', message: 'Harga program berbayar perlu diisi.' });
  if (program.days.length === 0) issues.push({ stage: 'content', message: 'Tambahkan minimal satu hari program.' });
  for (const day of program.days) {
    if (day.steps.length === 0) issues.push({ stage: 'content', message: `Hari ke-${day.day_number} belum memiliki langkah.` });
    for (const step of day.steps) {
      if (step.title.trim().length === 0) issues.push({ stage: 'content', message: `Langkah pada hari ke-${day.day_number} belum memiliki judul.` });
      if (['form', 'quiz'].includes(step.content_kind) && step.questions.length === 0) issues.push({ stage: 'content', message: `${step.title || 'Langkah'} belum memiliki pertanyaan.` });
      for (const question of step.questions) {
        if (question.prompt.trim().length === 0) issues.push({ stage: 'content', message: 'Pertanyaan belum memiliki teks.' });
        if (question.media_path && !question.media_alt_text?.trim()) issues.push({ stage: 'content', message: `${question.prompt || 'Media pertanyaan'} memerlukan deskripsi aksesibilitas.` });
        if (step.content_kind === 'quiz' && !['number', 'single_choice', 'multiple_choice', 'image_choice'].includes(question.kind)) issues.push({ stage: 'content', message: `${question.prompt || 'Pertanyaan kuis'} harus berupa pertanyaan objektif. Gunakan Form untuk unggah foto atau video.` });
        if (['single_choice', 'multiple_choice', 'image_choice'].includes(question.kind) && question.options.length < 2) issues.push({ stage: 'content', message: `${question.prompt || 'Pertanyaan pilihan'} memerlukan minimal dua pilihan.` });
        if (step.content_kind === 'quiz' && ['single_choice', 'multiple_choice', 'image_choice'].includes(question.kind) && !question.answer_key?.selected_option_ids.length) issues.push({ stage: 'content', message: `${question.prompt || 'Pertanyaan kuis'} belum memiliki kunci jawaban.` });
      }
    }
  }
  if (program.points_per_weight_kg > 0) {
    const kinds = program.days.flatMap((day) => day.steps.map((step) => step.content_kind));
    if (kinds.filter((kind) => kind === 'initial_weigh_in').length !== 1 || kinds.filter((kind) => kind === 'final_weigh_in').length !== 1) issues.push({ stage: 'review', message: 'Poin berat membutuhkan tepat satu timbang awal dan satu timbang akhir.' });
  }
  return issues;
}

export function completedAdminStages(program: AdminProgram): number {
  const issues = validateAdminProgram(program);
  return (['settings', 'content', 'review'] as const).filter((stage) => !issues.some((issue) => issue.stage === stage)).length;
}

export function adminStatusLabel(status: AdminProgramStatus) {
  return ({ draft: 'Draft', scheduled: 'Terjadwal', active: 'Aktif', completed: 'Selesai', archived: 'Diarsipkan' })[status];
}

export function adminStatusTone(status: AdminProgramStatus): 'warning' | 'info' | 'success' {
  return status === 'draft' ? 'warning' : status === 'active' ? 'success' : 'info';
}

function validDateRange(start: string, end: string) {
  return /^\d{4}-\d{2}-\d{2}$/u.test(start) && /^\d{4}-\d{2}-\d{2}$/u.test(end) && end >= start;
}
