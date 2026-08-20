import { z } from 'zod';

import { memberLevelSchema } from '@/features/coach/coach-experience-models';

export const onboardingStatusSchema = z.enum([
  'provisional', 'coach_handoff_pending', 'active', 'cleanup_pending',
]);

export const accountPurposeSchema = z.enum(['participant', 'coach_applicant']);
export const onboardingResumeStepSchema = z.enum([
  'profile', 'participant_coach', 'coach_eligibility', 'coach_payment',
  'coach_status', 'cleanup', 'active',
]);

export const onboardingSessionContextSchema = z.object({
  user_id: z.string().uuid(),
  role: z.enum(['participant', 'coach', 'admin']),
  onboarding_status: onboardingStatusSchema,
  account_purpose: accountPurposeSchema,
  profile_complete: z.boolean(),
  provisional_expires_at: z.string().nullable(),
  onboarding_version: z.number().int().positive(),
  resume_step: onboardingResumeStepSchema,
});

export const provisionalProfileSchema = z.object({
  user_id: z.string().uuid(),
  display_name: z.string(),
  phone_number: z.string().nullable(),
  member_level: memberLevelSchema.nullable(),
  account_purpose: accountPurposeSchema,
  onboarding_status: onboardingStatusSchema,
  onboarding_version: z.number().int().positive(),
});

export const confirmedCoachSchema = z.object({
  coach_id: z.string().uuid(),
  display_name: z.string(),
  city: z.string().nullable(),
  avatar_url: z.string().nullable(),
});

export const cancellationResultSchema = z.object({
  id: z.string().uuid().optional(),
  status: z.enum(['queued', 'processing', 'failed', 'completed', 'retained']),
});

export type OnboardingSessionContext = z.infer<typeof onboardingSessionContextSchema>;
export type AccountPurpose = z.infer<typeof accountPurposeSchema>;
export type ProvisionalProfile = z.infer<typeof provisionalProfileSchema>;
export type ConfirmedCoach = z.infer<typeof confirmedCoachSchema>;
export type OnboardingResumeStep = z.infer<typeof onboardingResumeStepSchema>;

export const onboardingPathForStep: Record<OnboardingResumeStep, string> = {
  profile: '/onboarding/profile',
  participant_coach: '/onboarding/participant/coach',
  coach_eligibility: '/onboarding/coach/eligibility',
  coach_payment: '/onboarding/coach/payment',
  coach_status: '/onboarding/coach/status',
  cleanup: '/onboarding/cleanup',
  active: '/app',
};
