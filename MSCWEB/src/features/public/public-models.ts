import { z } from 'zod';

const nullableText = z.string().nullable().optional();

const publicProgramQuestionOptionSchema = z.object({
  id: z.string().uuid(),
  option_order: z.number().int(),
  title: z.string(),
  media_path: nullableText,
  media_alt_text: nullableText,
}).passthrough();

const publicProgramQuestionSchema = z.object({
  id: z.string().uuid(),
  question_order: z.number().int(),
  kind: z.string(),
  prompt: z.string(),
  analysis_mode: z.enum(['none', 'food']).default('none'),
  analysis_rubric: nullableText,
  analysis_rubric_version: nullableText,
  program_question_options: z.array(publicProgramQuestionOptionSchema).default([]),
}).passthrough();

export const publicProgramStepSchema = z.object({
  id: z.string().uuid(),
  step_order: z.number().int(),
  title: z.string(),
  instructions: nullableText,
  content_kind: z.string(),
  completion_policy: z.string(),
  verification_mode: z.string(),
  media_path: nullableText,
  media_alt_text: nullableText,
  video_required: z.boolean().nullable().optional().transform((value) => value ?? false),
  video_threshold: z.number().int().min(0).max(100).nullable().optional().transform((value) => value ?? 100),
  video_autoplay: z.boolean().nullable().optional().transform((value) => value ?? false),
  program_questions: z.array(publicProgramQuestionSchema).default([]),
}).passthrough();

const publicProgramDaySchema = z.object({
  id: z.string().uuid(),
  day_number: z.number().int(),
  title: z.string(),
  summary: nullableText,
  scheduled_on: nullableText,
  program_steps: z.array(publicProgramStepSchema).default([]),
}).passthrough();

export const publicProgramSchema = z.object({
  id: z.string().uuid(),
  title: z.string(),
  summary: nullableText,
  category: nullableText,
  status: z.enum(['scheduled', 'active', 'completed', 'archived']),
  starts_on: z.string(),
  ends_on: nullableText,
  timezone: z.string(),
  participant_limit: z.number().int().nullable().optional(),
  registration_closes_at: nullableText,
  cover_path: nullableText,
  cover_alt_text: nullableText,
  past_step_policy: z.string().optional(),
  future_step_policy: z.string().optional(),
  wellness_disclaimer: nullableText,
  points_per_activity: z.number().int().optional().default(0),
  points_per_weight_kg: z.number().optional().default(0),
  quiz_passing_percentage: z.number().int().optional().default(0),
  pricing_mode: z.string(),
  desired_price: z.number().nullable().optional(),
  program_days: z.array(publicProgramDaySchema).default([]),
}).passthrough();

export const publicCoachSchema = z.object({
  id: z.string().uuid(),
  display_name: z.string(),
  biography: z.string().nullable().default(''),
  city: z.string().nullable().default(''),
  photo_reference: z.string().nullable().optional(),
});

export const publicLeaderboardRowSchema = z.object({
  id: z.string().uuid(),
  program_id: z.string().uuid(),
  participant_id: z.string().uuid(),
  participant_display_name: z.string(),
  rank: z.number().int().positive(),
  progress_percentage: z.number(),
  total_points: z.number().int(),
});

export const publicWinnerSchema = z.object({
  id: z.string().uuid(),
  program_id: z.string().uuid(),
  participant_id: z.string().uuid(),
  participant_display_name: z.string(),
  rank: z.number().int().positive(),
  total_points: z.number().int(),
  locked_at: z.string(),
});

export const publicWinnerPosterSchema = z.object({
  id: z.string().uuid(),
  title: z.string(),
  body: z.string(),
  program_id: z.string().uuid(),
  is_published: z.literal(true),
}).passthrough();

export type PublicProgram = z.infer<typeof publicProgramSchema>;
export type PublicProgramDay = PublicProgram['program_days'][number];
export type PublicProgramStep = PublicProgramDay['program_steps'][number];
export type PublicProgramQuestion = PublicProgramStep['program_questions'][number];
export type PublicCoach = z.infer<typeof publicCoachSchema>;
export type PublicLeaderboardRow = z.infer<typeof publicLeaderboardRowSchema>;
export type PublicWinner = z.infer<typeof publicWinnerSchema>;
export type PublicWinnerPoster = z.infer<typeof publicWinnerPosterSchema>;
