import { z } from 'zod';

const nullableText = z.string().nullable().optional();

export const adminProgramStatusSchema = z.enum(['draft', 'scheduled', 'active', 'completed', 'archived']);
export type AdminProgramStatus = z.infer<typeof adminProgramStatusSchema>;

export const adminQuestionOptionSchema = z.object({
  id: z.string().uuid(), option_order: z.number().int().positive(), title: z.string(),
  media_path: nullableText, media_alt_text: nullableText,
});

export const adminAnswerKeySchema = z.object({
  question_id: z.string().uuid(),
  accepted_text_values: z.array(z.string()).default([]),
  number_value: z.coerce.number().nullable(),
  selected_option_ids: z.array(z.string().uuid()).default([]),
  matching_mode: z.string().default('exact'),
});

export const adminQuestionSchema = z.object({
  id: z.string().uuid(), question_order: z.number().int().positive(), kind: z.string(), prompt: z.string(),
  analysis_mode: z.enum(['none', 'food']).default('none'), analysis_rubric: nullableText,
  analysis_rubric_version: nullableText, media_kind: z.enum(['image', 'video']).nullable().optional(),
  media_path: nullableText, media_alt_text: nullableText, options: z.array(adminQuestionOptionSchema).default([]),
  answer_key: adminAnswerKeySchema.nullable().optional(),
});

export const adminStepSchema = z.object({
  id: z.string().uuid(), step_order: z.number().int().positive(), title: z.string(), instructions: z.string().nullable().default(''),
  content_kind: z.enum(['article', 'video', 'form', 'quiz', 'initial_weigh_in', 'daily_weigh_in', 'final_weigh_in']),
  completion_policy: z.string(), verification_mode: z.string(), media_path: nullableText, media_alt_text: nullableText,
  video_required: z.boolean().default(false), video_threshold: z.number().int().min(0).max(100).nullable().default(100),
  video_autoplay: z.boolean().default(false), questions: z.array(adminQuestionSchema).default([]),
});

export const adminDaySchema = z.object({
  id: z.string().uuid(), day_number: z.number().int().positive(), title: z.string(), summary: nullableText,
  scheduled_on: z.string(), steps: z.array(adminStepSchema).default([]),
});

export const adminProgramSchema = z.object({
  id: z.string().uuid(), source_program_id: z.string().uuid().nullable().optional(), title: z.string(), summary: z.string().nullable().default(''),
  category: z.string().nullable().default(''), cover_path: nullableText, cover_alt_text: nullableText,
  status: adminProgramStatusSchema, pace: z.enum(['scheduled', 'self_paced']), duration_mode: z.string(),
  starts_on: z.string(), ends_on: z.string(), timezone: z.string(), participant_limit: z.number().int().nullable(),
  registration_closes_at: nullableText, past_step_policy: z.string(), future_step_policy: z.string(),
  wellness_disclaimer: z.string().nullable().default(''), points_per_activity: z.number().int(),
  points_per_weight_kg: z.coerce.number(), quiz_passing_percentage: z.number().int(),
  default_verification_mode: z.enum(['automatic', 'coach_review']).default('coach_review'), pricing_mode: z.enum(['free', 'paid']),
  desired_price: z.coerce.number().nullable(), published_at: nullableText, created_at: z.string(), updated_at: z.string(),
  days: z.array(adminDaySchema).default([]),
});

export type AdminProgram = z.infer<typeof adminProgramSchema>;
export type AdminDay = z.infer<typeof adminDaySchema>;
export type AdminStep = z.infer<typeof adminStepSchema>;
export type AdminQuestion = z.infer<typeof adminQuestionSchema>;

export const adminDashboardSchema = z.object({
  program_counts: z.object({ draft: z.number(), scheduled: z.number(), active: z.number(), completed: z.number(), archived: z.number() }),
  active_participant_count: z.number(), pending_reviews: z.number(), pending_coach_approvals: z.number(),
  pending_payments: z.number(), pending_moderation: z.number(), ai_attention: z.number(),
  audit_events: z.array(z.object({ id: z.string().uuid(), kind: z.string(), subject_id: z.string().uuid().nullable(), summary: z.string(), created_at: z.string() })),
});
export type AdminDashboard = z.infer<typeof adminDashboardSchema>;

export const adminPersonSchema = z.object({
  user_id: z.string().uuid(), role: z.enum(['participant', 'coach', 'admin']), display_name: z.string(), email: z.string().nullable().optional(),
  city: nullableText, phone_number: nullableText, professional_headline: nullableText.optional(), photo_reference: z.string().uuid().nullable().optional(), provider_avatar_url: nullableText, member_level: nullableText,
  current_coach_id: z.string().uuid().nullable().optional(), current_coach_name: nullableText,
  coach_is_approved: z.boolean().nullable().optional(), coach_is_public: z.boolean().nullable().optional(), coach_biography: nullableText,
  application_id: z.string().uuid().nullable().optional(), application_status: nullableText,
  public_handle: nullableText, profile_published: z.boolean().default(false), created_at: z.string(),
});
export type AdminPerson = z.infer<typeof adminPersonSchema>;

export const adminEvidenceSchema = z.object({
  submission_id: z.string().uuid(), participant_id: z.string().uuid(), participant_name: z.string(),
  program_id: z.string().uuid(), program_title: z.string(), step_title: z.string(), submitted_at: z.string().nullable(), status: z.string(),
});
export type AdminEvidence = z.infer<typeof adminEvidenceSchema>;

export const adminModerationItemSchema = z.object({
  id: z.string().uuid(), coach_user_id: z.string().uuid(), coach_name: z.string(), item_kind: z.enum(['testimonial', 'before_after']),
  title: z.string(), body: z.string(), media_object_path: nullableText, media_preview_url: z.string().url().optional(), includes_third_party: z.boolean(), permission_attested: z.boolean(),
  moderation_status: z.enum(['pending', 'approved', 'rejected']), content_version: z.number().int().positive(),
  moderation_version: z.number().int().positive(), moderation_note: nullableText, submitted_at: z.string(), moderated_at: nullableText,
});
export type AdminModerationItem = z.infer<typeof adminModerationItemSchema>;

export const adminFoodOperationSchema = z.object({
  job_id: z.string().uuid(), submission_id: z.string().uuid(), participant_name: z.string(), program_title: z.string(), step_title: z.string(),
  status: z.string(), attempt_count: z.number().int(), max_attempts: z.number().int(), terminal_error_code: nullableText,
  analysis_version: z.string(), provider_name: nullableText, model_alias: nullableText, policy_version: nullableText,
  output_policy_version: nullableText, result_id: z.string().uuid().nullable().optional(), effective_rating: z.number().int().nullable().optional(),
  result_version: z.number().int().nullable().optional(), updated_at: z.string(),
});
export type AdminFoodOperation = z.infer<typeof adminFoodOperationSchema>;

export const adminAuditSchema = z.object({
  id: z.string().uuid(), actor_id: z.string().uuid().nullable(), actor_name: nullableText,
  kind: z.string(), subject_id: z.string().uuid().nullable(), summary: z.string(), created_at: z.string(),
});
export type AdminAudit = z.infer<typeof adminAuditSchema>;

export const adminClosureSchema = z.object({
  program_id: z.string().uuid(), program_status: adminProgramStatusSchema, enrollment_count: z.number(), pending_reviews: z.number(),
  missing_final_weigh_ins: z.number(), failed_quizzes: z.number(), winners_locked: z.boolean(),
});
export type AdminClosure = z.infer<typeof adminClosureSchema>;

export const adminWinnerPreviewSchema = z.object({
  enrollment_id: z.string().uuid(), participant_id: z.string().uuid(), participant_name: z.string(),
  rank: z.number().int().positive(), total_points: z.number().int(), progress_percentage: z.number(),
});
export type AdminWinnerPreview = z.infer<typeof adminWinnerPreviewSchema>;

export const adminPosterSchema = z.object({
  id: z.string().uuid(), program_id: z.string().uuid(), winner_snapshot_id: z.string().uuid(), media_path: z.string(),
  alt_text: z.string(), is_published: z.boolean(), published_at: z.string().nullable(), deleted_at: z.string().nullable(),
});
export type AdminPoster = z.infer<typeof adminPosterSchema>;

export const adminWinnerSnapshotSchema = z.object({ id: z.string().uuid(), program_id: z.string().uuid(), locked_at: z.string() });
export type AdminWinnerSnapshot = z.infer<typeof adminWinnerSnapshotSchema>;
