import { z } from 'zod';

const nullableText = z.string().nullable().optional();

const publicProgramStepSchema = z.object({
  id: z.string().uuid(),
  step_order: z.number().int(),
  title: z.string(),
  instructions: nullableText,
  content_kind: z.string(),
  completion_policy: z.string(),
  verification_mode: z.string(),
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
  wellness_disclaimer: nullableText,
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
export type PublicCoach = z.infer<typeof publicCoachSchema>;
export type PublicLeaderboardRow = z.infer<typeof publicLeaderboardRowSchema>;
export type PublicWinner = z.infer<typeof publicWinnerSchema>;
export type PublicWinnerPoster = z.infer<typeof publicWinnerPosterSchema>;
