import { z } from 'zod';

export const enrollmentSchema = z.object({
  id: z.string().uuid(),
  program_id: z.string().uuid(),
  coach_id: z.string().uuid(),
  status: z.enum(['pending', 'active', 'completed', 'cancelled', 'rejected']),
  enrolled_at: z.string(),
  completed_at: z.string().nullable(),
});

export const dayAccessSchema = z.object({
  enrollment_id: z.string().uuid(),
  program_id: z.string().uuid(),
  program_day_id: z.string().uuid(),
  day_number: z.number().int().positive(),
  access_state: z.enum(['available', 'locked', 'hidden', 'read_only']),
  is_current_day: z.boolean(),
});

export const submissionSchema = z.object({
  id: z.string().uuid(),
  enrollment_id: z.string().uuid(),
  step_id: z.string().uuid(),
  attempt_sequence: z.number().int().positive(),
  status: z.enum(['draft', 'pending', 'approved', 'rejected', 'superseded']),
  review_note: z.string().nullable(),
  submitted_at: z.string(),
});

export const scoreSchema = z.object({
  enrollment_id: z.string().uuid(),
  activity_points: z.number().int(),
  quiz_points: z.number().int(),
  weight_points: z.number().int(),
  adjustment_points: z.number().int(),
  progress_percentage: z.number().min(0).max(100),
  rank: z.number().int().positive().nullable(),
  recalculated_at: z.string(),
});

export const assignedCoachSchema = z.object({
  user_id: z.string().uuid(),
  public_profile_id: z.string().uuid(),
  display_name: z.string(),
  city: z.string().nullable(),
  provider_avatar_url: z.string().nullable(),
  is_public: z.boolean(),
  is_approved: z.boolean(),
});

export const participantProfileSchema = z.object({
  public_profile_id: z.string().uuid(),
  display_name: z.string().min(1),
  city: z.string().nullable(),
  provider_avatar_url: z.string().nullable(),
});

export type ParticipantEnrollment = z.infer<typeof enrollmentSchema>;
export type ParticipantDayAccess = z.infer<typeof dayAccessSchema>;
export type ParticipantSubmission = z.infer<typeof submissionSchema>;
export type ParticipantScore = z.infer<typeof scoreSchema>;
export type ParticipantAssignedCoach = z.infer<typeof assignedCoachSchema>;
export type ParticipantProfile = z.infer<typeof participantProfileSchema>;

export type ParticipantReadState =
  | 'loading'
  | 'loaded'
  | 'empty'
  | 'offline'
  | 'forbidden'
  | 'sessionExpired'
  | 'error';
