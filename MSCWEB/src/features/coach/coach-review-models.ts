import { z } from 'zod';

export const coachReviewAnswerSchema = z.object({
  id: z.string().uuid(),
  question_id: z.string().uuid(),
  prompt: z.string(),
  text_value: z.string().nullable(),
  number_value: z.number().nullable(),
  selected_option_ids: z.array(z.string().uuid()),
  selected_option_titles: z.array(z.string()),
  private_photo_path: z.string().nullable(),
});

export const coachReviewItemSchema = z.object({
  id: z.string().uuid(),
  enrollment_id: z.string().uuid(),
  status: z.enum(['pending', 'approved', 'rejected', 'superseded']),
  submitted_at: z.string(),
  reviewed_at: z.string().nullable(),
  review_note: z.string().nullable(),
  participant: z.object({
    id: z.string().uuid(),
    display_name: z.string(),
    avatar_url: z.string().nullable(),
  }),
  program: z.object({
    id: z.string().uuid(),
    title: z.string(),
    ends_on: z.string(),
    timezone: z.string(),
    points_per_activity: z.number().int().nonnegative(),
  }),
  day: z.object({ day_number: z.number().int().positive(), title: z.string() }),
  step: z.object({
    id: z.string().uuid(),
    title: z.string(),
    instructions: z.string(),
    content_kind: z.string(),
    verification_mode: z.enum(['automatic', 'coach_review']),
  }),
  answers: z.array(coachReviewAnswerSchema),
  quiz_result: z.object({
    correct_count: z.number().int().nonnegative(),
    total_count: z.number().int().positive(),
    percentage: z.number().int().min(0).max(100),
    passed: z.boolean(),
    awarded_points: z.number().int().nonnegative(),
  }).nullable(),
});

export type CoachReviewAnswer = z.infer<typeof coachReviewAnswerSchema>;
export type CoachReviewItem = z.infer<typeof coachReviewItemSchema>;
