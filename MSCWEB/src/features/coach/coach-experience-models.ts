import { z } from 'zod';

export const memberLevelSchema = z.enum([
  'member', 'sc', 'sb', 'supervisor', 'world_team', 'tab_team',
  'get_team', 'millionaire_team', 'presidents_team',
]);

export type MemberLevel = z.infer<typeof memberLevelSchema>;

export const memberLevelPresentation: Record<MemberLevel, { label: string; price: number | null }> = {
  member: { label: 'Member', price: null },
  sc: { label: 'SC', price: 100_000 },
  sb: { label: 'SB', price: 100_000 },
  supervisor: { label: 'Supervisor', price: 150_000 },
  world_team: { label: 'World Team', price: 150_000 },
  tab_team: { label: 'TAB Team', price: 200_000 },
  get_team: { label: 'GET Team', price: 200_000 },
  millionaire_team: { label: 'Millionaire Team', price: 200_000 },
  presidents_team: { label: 'President’s Team', price: 200_000 },
};

const coachApplicationRowSchema = z.object({
  id: z.string().uuid(),
  applicant_user_id: z.string().uuid(),
  display_name_snapshot: z.string(),
  phone_number_snapshot: z.string(),
  member_level_snapshot: memberLevelSchema,
  has_completed_hom_sts: z.boolean(),
  has_completed_ict: z.boolean(),
  status: z.enum(['draft', 'ineligible', 'submitted', 'accepted_pending_payment', 'active', 'rejected', 'expired']),
  submitted_at: z.string().nullable(),
  decided_at: z.string().nullable(),
  rejection_reason: z.string().nullable(),
});

export const coachApplicationAggregateSchema = z.object({
  application: coachApplicationRowSchema,
  payment: z.record(z.string(), z.unknown()).nullable(),
  entitlement: z.object({
    status: z.string(),
    starts_at: z.string(),
    ends_at: z.string(),
  }).passthrough().nullable(),
  is_eligible: z.boolean(),
});

export const coachPaymentOrderSchema = z.object({
  id: z.string().uuid(),
  owner_user_id: z.string().uuid(),
  purpose: z.literal('coach_access'),
  coach_application_id: z.string().uuid(),
  program_id: z.null(),
  pending_enrollment_id: z.null(),
  coach_user_id_snapshot: z.null(),
  amount_minor: z.number().int().positive(),
  currency: z.literal('IDR'),
  declared_method: z.enum(['bank_transfer', 'static_qris']),
  destination_version: z.number().int().positive(),
  bank_code_snapshot: z.string(),
  bank_name_snapshot: z.string(),
  account_name_snapshot: z.string(),
  account_reference_snapshot: z.string(),
  qris_object_path_snapshot: z.string().nullable(),
  instructions_snapshot: z.string(),
  status: z.enum(['awaiting_evidence', 'under_review', 'correction_required', 'approved', 'expired', 'cancelled', 'rejected', 'reversal_pending', 'reversed']),
  latest_rejection_reason: z.string().nullable(),
  evidence_submitted_at: z.string().nullable(),
  version: z.number().int().positive(),
  created_at: z.string(),
  updated_at: z.string(),
});

const coachParticipantSchema = z.object({
  participant_id: z.string().uuid(),
  display_name: z.string(),
  avatar_url: z.string().nullable(),
  city: z.string(),
  program_id: z.string().uuid(),
  program_title: z.string(),
  enrollment_status: z.enum(['active', 'completed']),
  progress_percentage: z.number().int(),
  total_points: z.number().int(),
  rank: z.number().int().nullable(),
});

const coachParticipantEnrollmentSchema = z.object({
  enrollment_id: z.string().uuid(),
  program_id: z.string().uuid(),
  program_title: z.string(),
  enrollment_status: z.enum(['active', 'completed']),
  starts_on: z.string(),
  ends_on: z.string(),
  timezone: z.string(),
  progress_percentage: z.number().min(0).max(100),
  total_points: z.number().int(),
  rank: z.number().int().positive().nullable(),
  last_activity_at: z.string(),
  completed_step_count: z.number().int().nonnegative(),
  due_step_count: z.number().int().nonnegative(),
  completed_due_step_count: z.number().int().nonnegative(),
  total_step_count: z.number().int().nonnegative(),
  evidence_count: z.number().int().nonnegative(),
  active_day_count: z.number().int().nonnegative(),
});

export const coachParticipantDirectorySchema = z.object({
  participants: z.array(z.object({
    participant_id: z.string().uuid(),
    display_name: z.string(),
    avatar_url: z.string().nullable(),
    city: z.string(),
    enrollments: z.array(coachParticipantEnrollmentSchema),
  })),
  programs: z.array(z.object({
    program_id: z.string().uuid(),
    title: z.string(),
    ends_on: z.string(),
    timezone: z.string(),
  })),
});

export const coachParticipantDetailSchema = z.object({
  participant: z.object({
    participant_id: z.string().uuid(),
    display_name: z.string(),
    avatar_url: z.string().nullable(),
    city: z.string(),
  }),
  enrollment: z.object({
    enrollment_id: z.string().uuid(),
    status: z.enum(['active', 'completed']),
    enrolled_at: z.string(),
    completed_at: z.string().nullable(),
  }).nullable(),
  program: z.object({
    program_id: z.string().uuid(),
    title: z.string(),
    starts_on: z.string(),
    ends_on: z.string(),
    timezone: z.string(),
  }).nullable(),
  summary: z.object({
    progress_percentage: z.number().min(0).max(100),
    total_points: z.number().int(),
    rank: z.number().int().positive().nullable(),
    current_day: z.number().int().nonnegative(),
    completed_step_count: z.number().int().nonnegative(),
    total_step_count: z.number().int().nonnegative(),
    active_day_count: z.number().int().nonnegative(),
    evidence_count: z.number().int().nonnegative(),
  }),
  weigh_ins: z.array(z.object({
    id: z.string().uuid(),
    kind: z.enum(['initial', 'daily', 'final']),
    weight_kg: z.coerce.number().positive(),
    recorded_at: z.string(),
  })),
  submissions: z.array(z.object({
    id: z.string().uuid(),
    step_id: z.string().uuid(),
    step_title: z.string(),
    day_number: z.number().int().positive(),
    status: z.enum(['pending', 'approved', 'rejected', 'superseded']),
    submitted_at: z.string().nullable(),
    review_note: z.string().nullable(),
    answers: z.array(z.object({
      id: z.string().uuid(),
      prompt: z.string(),
      text_value: z.string().nullable(),
      number_value: z.coerce.number().nullable(),
      private_photo_path: z.string().nullable(),
      private_video_path: z.string().nullable().optional().transform((value) => value ?? null),
    })),
  })),
  days: z.array(z.object({
    id: z.string().uuid(),
    day_number: z.number().int().positive(),
    title: z.string(),
    scheduled_on: z.string(),
    steps: z.array(z.object({
      id: z.string().uuid(),
      step_order: z.number().int().positive(),
      title: z.string(),
      content_kind: z.string(),
      status: z.enum(['not_started', 'pending', 'approved', 'rejected', 'draft']),
    })),
  })),
});

const coachActivitySchema = z.object({
  submission_id: z.string().uuid(),
  participant_name: z.string(),
  program_title: z.string(),
  step_title: z.string(),
  status: z.enum(['pending', 'approved', 'rejected']),
  submitted_at: z.string(),
});

export const coachActivityFeedSchema = z.object({
  items: z.array(z.object({
    id: z.string(),
    participant_id: z.string().uuid(),
    participant_name: z.string(),
    avatar_url: z.string().nullable(),
    enrollment_id: z.string().uuid(),
    program_id: z.string().uuid(),
    program_title: z.string(),
    submission_id: z.string().uuid().nullable(),
    step_title: z.string().nullable(),
    kind: z.enum(['evidence_submitted', 'step_completed', 'participant_joined', 'program_completed']),
    evidence_status: z.enum(['pending', 'rejected']).nullable(),
    points: z.number().int().nonnegative().nullable(),
    occurred_at: z.string(),
    requires_review: z.boolean(),
  })),
  programs: coachParticipantDirectorySchema.shape.programs,
});

const coachProgramSchema = z.object({
  program_id: z.string().uuid(),
  title: z.string(),
  status: z.string(),
  starts_on: z.string(),
  ends_on: z.string(),
  timezone: z.string(),
  participant_count: z.number().int(),
  pending_review_count: z.number().int(),
});

const coachLeaderboardRowSchema = z.object({
  participant_id: z.string().uuid(),
  display_name: z.string(),
  avatar_url: z.string().nullable(),
  program_id: z.string().uuid(),
  program_title: z.string(),
  rank: z.number().int().nullable(),
  progress_percentage: z.number().int(),
  total_points: z.number().int(),
});

export const coachLeaderboardEntrySchema = z.object({
  id: z.string().uuid(),
  program_id: z.string().uuid(),
  participant_id: z.string().uuid(),
  participant_display_name: z.string(),
  avatar_url: z.string().nullable(),
  avatar_reference: z.string().uuid().nullable().optional(),
  rank: z.number().int().positive(),
  progress_percentage: z.number().min(0).max(100),
  total_points: z.number().int(),
  is_assigned_to_coach: z.boolean(),
  step_points: z.number().int().nullable(),
  weight_points: z.number().int().nullable(),
  adjustment_points: z.number().int().nullable(),
});

export const coachWorkspaceSchema = z.object({
  profile: z.object({
    display_name: z.string(),
    city: z.string(),
    professional_headline: z.string().nullable().optional(),
    photo_reference: z.string().uuid().nullable().optional(),
    provider_avatar_url: z.string().nullable(),
    profile_avatar_path: z.string().nullable(),
  }),
  entitlement: z.object({ starts_at: z.string(), ends_at: z.string() }),
  pending_review_count: z.number().int(),
  assigned_participant_count: z.number().int(),
  participants: z.array(coachParticipantSchema),
  activity: z.array(coachActivitySchema),
  programs: z.array(coachProgramSchema),
  leaderboard: z.array(coachLeaderboardRowSchema),
  qr_payload: z.string().min(16),
});

const coachProfileItemSchema = z.object({
  id: z.string().uuid(),
  item_kind: z.enum(['testimonial', 'before_after']),
  title: z.string(),
  body: z.string(),
  media_object_path: z.string().nullable(),
  includes_third_party: z.boolean(),
  permission_attested: z.boolean(),
  moderation_status: z.enum(['pending', 'approved', 'rejected']),
  moderation_note: z.string().nullable(),
});

export const coachProfileDraftSchema = z.object({
  identity: z.object({
    display_name: z.string(),
    provider_avatar_url: z.string().nullable(),
    profile_avatar_path: z.string().nullable(),
    is_verified: z.boolean(),
  }),
  draft: z.object({
    public_handle: z.string(),
    profile_photo_object_path: z.string().nullable(),
    profile_photo_preview_url: z.string().url().optional(),
    professional_headline: z.string(),
    biography: z.string(),
    service_area: z.string(),
    instagram_url: z.string(),
    tiktok_url: z.string(),
    website_url: z.string(),
    whatsapp_number: z.string(),
    phone_number: z.string(),
    show_instagram: z.boolean(),
    show_tiktok: z.boolean(),
    show_website: z.boolean(),
    show_whatsapp: z.boolean(),
    show_phone: z.boolean(),
  }).nullable(),
  published: z.boolean(),
  items: z.array(coachProfileItemSchema),
});

export const publicCoachProfileSchema = z.object({
  handle: z.string(),
  display_name: z.string(),
  photo_kind: z.literal('storage'),
  photo_reference: z.string().uuid(),
  professional_headline: z.string().optional(),
  biography: z.string().optional(),
  service_area: z.string().optional(),
  instagram_url: z.string().optional(),
  tiktok_url: z.string().optional(),
  website_url: z.string().optional(),
  whatsapp_number: z.string().optional(),
  phone_number: z.string().optional(),
  is_verified: z.literal(true),
  items: z.array(z.object({
    kind: z.enum(['testimonial', 'before_after']),
    title: z.string(),
    body: z.string().optional(),
    media_object_path: z.string().uuid().optional(),
  })),
});

export type CoachApplicationAggregate = z.infer<typeof coachApplicationAggregateSchema>;
export type CoachPaymentOrder = z.infer<typeof coachPaymentOrderSchema>;
export type CoachWorkspace = z.infer<typeof coachWorkspaceSchema>;
export type CoachLeaderboardEntry = z.infer<typeof coachLeaderboardEntrySchema>;
export type CoachParticipantDirectory = z.infer<typeof coachParticipantDirectorySchema>;
export type CoachParticipantDetail = z.infer<typeof coachParticipantDetailSchema>;
export type CoachActivityFeed = z.infer<typeof coachActivityFeedSchema>;
export type CoachProfileDraft = z.infer<typeof coachProfileDraftSchema>;
export type PublicCoachProfile = z.infer<typeof publicCoachProfileSchema>;
