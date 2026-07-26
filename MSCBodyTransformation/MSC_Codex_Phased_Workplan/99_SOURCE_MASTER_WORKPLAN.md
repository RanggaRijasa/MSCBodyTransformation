# Codex Workplan: iOS SwiftUI Weight-Loss Program MVP

> Working title: **MSC Body Transformation**  
> Primary platform: **iOS / iPadOS**  
> Future platform: **Android Kotlin + Jetpack Compose** using the same Supabase backend  
> Source of truth: This file  
> Last updated: 26 July 2026

---

## 1. Mission

Build a production-ready native iOS application where participants join a multi-day weight-loss program, complete daily steps with photo evidence, earn points, submit initial and final body weight, and compete on a leaderboard.

The application has three authenticated roles:

1. **Participant**
   - Joins a program through a coach invite or QR code.
   - Submits initial weight before starting.
   - Views the steps available for the current program day.
   - Reads step instructions and supporting image/video content.
   - Uploads photo evidence for every required step.
   - Completes steps and earns points.
   - Submits final weight at the end of the program.
   - Views progress, points, leaderboard, coaches, and final winners.

2. **Coach**
   - Has a public coach profile with name and photo.
   - Purchases participant-seat credit packs through native Apple In-App Purchase.
   - Chooses an available program and generates an invite/QR code.
   - Participant seat credits are consumed only when a participant successfully joins.
   - Monitors assigned participants, their progress, answers, uploads, and points.
   - Reviews evidence when a program uses coach-review scoring.

3. **Admin**
   - Has all coach monitoring abilities.
   - Can manually enroll a participant in any program as a fallback.
   - Manages coaches and role assignments.
   - Uses an in-app CMS to create, edit, schedule, publish, complete, and archive programs.
   - Configures duration, dates, descriptions, daily steps, points, media, and day visibility rules.
   - Uploads winner banners and other managed application content without changing code.
   - Can lock final winners and apply audited score corrections.

---

## 2. Product and Technical Decisions

These decisions are defaults for the MVP. Do not change them silently.

### 2.1 Platform

- Use **Swift 6** and **SwiftUI**.
- Minimum deployment target: **iOS 17.0**.
- Build with the latest stable Xcode available in the development environment.
- Support iPhone first and ensure layouts remain usable on iPad.
- Use native Apple frameworks wherever practical.
- Use **Jetpack Compose** later for Android. Do not share UI code between platforms.

### 2.2 Architecture

Use feature-oriented modular architecture with clear dependency boundaries:

```text
SwiftUI View
    ↓
Feature State / @Observable Model
    ↓
Use Case / Domain Service
    ↓
Repository Protocol
    ↓
Supabase / StoreKit / Native Framework Adapter
```

Rules:

- SwiftUI views must not directly perform Supabase queries.
- Business rules must not live only in the client.
- Scoring, seat consumption, role authorization, invite redemption, and payment credit grants must be enforced server-side.
- Use `@Observable`, `@State`, `@Environment`, and value types appropriately.
- Avoid a view model for trivial local UI state.
- Use protocol-based dependency injection for testability.
- Do not use global mutable singletons except an immutable app configuration object and root dependency container.

### 2.3 Dependencies

Allowed third-party dependency:

- `supabase-swift`, pinned to an exact compatible release and committed in `Package.resolved`.

Do not add dependencies for:

- Networking
- Image loading
- QR generation
- QR scanning
- Logging
- Navigation
- Analytics
- StoreKit
- Testing
- Dependency injection

Use Apple frameworks instead:

- SwiftUI
- Observation
- AuthenticationServices
- StoreKit 2
- PhotosUI
- AVKit
- AVFoundation
- VisionKit where available
- CoreImage
- ImageIO
- UserNotifications
- OSLog
- Network
- UniformTypeIdentifiers
- CryptoKit

### 2.4 Authentication

Implement:

- Email registration and password login through Supabase Auth.
- Email confirmation.
- Forgot/reset password.
- Google OAuth through Supabase Auth using `ASWebAuthenticationSession`, PKCE, and an application callback URL.
- Sign in with Apple through `AuthenticationServices` and Supabase ID-token exchange.
- Logout.
- Session restoration.
- Account deletion inside the app.

Google OAuth is required by the product brief. Sign in with Apple is a release requirement unless a documented App Review exemption applies.

Do not:

- Use Google profile data for authorization.
- Put user roles in editable user metadata.
- Allow users to self-select coach or admin roles.

Role defaults:

- New registrations become `participant`.
- Admin promotes an approved account to `coach`.
- The first admin is seeded manually through a secure migration or server-side operation.

### 2.5 Payments

Use native **StoreKit 2** In-App Purchase.

MVP product type:

- Consumable participant-seat credit packs.

Suggested product identifiers:

```text
com.example.msc.coach_seats_10
com.example.msc.coach_seats_25
com.example.msc.coach_seats_50
```

The product IDs are placeholders until the final bundle identifier is selected.

Rules:

- Only approved coaches can see and buy seat packs.
- Never trust a client-only purchase result to grant credits.
- Send the Apple-signed transaction to a Supabase Edge Function.
- Verify the transaction server-side using Apple-signed JWS data and the official App Store Server Library when runtime-compatible.
- Store every Apple transaction idempotently with a unique transaction identifier.
- Grant credits through a server-side transaction only after successful verification.
- Listen to `Transaction.updates` for interrupted or delayed purchases.
- Finish StoreKit transactions only after the backend confirms durable credit grant.
- Implement App Store Server Notifications V2 for refunds and purchase lifecycle reconciliation.
- Keep sandbox and production records clearly separated.
- Do not expose App Store private keys in the iOS app.

Default seat policy:

- One successful participant enrollment consumes one seat.
- Opening or scanning a QR code does not consume a seat.
- Duplicate enrollment in the same program does not consume another seat.
- Admin manual enrollment does not consume a coach seat, but requires an audit reason.

### 2.6 Program Time

- Store all timestamps in UTC.
- Each program has an IANA timezone.
- Default program timezone: `Asia/Makassar`.
- The server, not the device clock, determines the active program day.
- Do not rely solely on the participant device timezone to unlock steps.

### 2.7 Scoring

Program scoring consists of:

```text
Total points = approved step points + weight-loss points + audited adjustments
```

Weight formula:

```text
weight_loss_kg = max(initial_weight_kg - final_weight_kg, 0)
weight_points = round(weight_loss_kg × program.weight_points_per_kg)
```

Default:

```text
weight_points_per_kg = 800
```

This represents 80 points per 0.1 kg. It must remain configurable per program.

Rules:

- The client never submits its own calculated score as authoritative.
- Step points come from the published program-step record.
- Rejected or invalidated submissions contribute zero points.
- Negative weight points are not allowed.
- Weight must use a decimal numeric type, not binary floating-point, in Postgres.
- Score adjustments require admin role, a reason, and an audit record.

Default tie-break order:

1. Total points, descending.
2. Approved step points, descending.
3. Weight points, descending.
4. Time all required work was completed, ascending.
5. Enrollment id, ascending, as a deterministic final tie-break.

### 2.8 Submission Verification

Each program has a verification mode:

```text
automatic
coach_review
```

- `automatic`: valid completion receives points immediately, but coach/admin can later reject evidence and points are removed.
- `coach_review`: submission remains pending and points are not included until approved.

Every required step must have at least one photo evidence upload before completion.

---

## 3. MVP Scope

### 3.1 Included

- Role-based registration and login.
- Google OAuth, Sign in with Apple, email/password.
- Email verification and reset password.
- Participant onboarding and profile.
- Public coach directory.
- Program catalog for eligible users.
- Coach participant-seat purchases through StoreKit 2.
- Coach wallet and credit ledger.
- QR invite generation and scanning.
- Atomic program enrollment.
- Initial and final weight submission.
- Daily program timeline.
- Step details with image/video.
- Required evidence upload.
- Completion and review status.
- Point calculation.
- Participant progress.
- Coach participant monitoring.
- Admin in-app CMS.
- Admin manual enrollment fallback.
- Leaderboard and top five winners.
- Admin winner banners and managed content.
- Accessibility.
- Light and dark appearances.
- Liquid Glass on iOS 26+ with native fallback for iOS 17–25.
- Unit, integration, StoreKit, and UI tests.
- Privacy, account deletion, audit logs, and App Store release preparation.

### 3.2 Explicitly Out of Scope for MVP

- Android client implementation.
- Web admin panel.
- HealthKit integration.
- Apple Watch app.
- Chat or social feed.
- Live video classes.
- AI recommendations.
- External payment methods inside the iOS app.
- Subscription billing.
- Multi-coach ownership for one participant within one enrollment.
- Multi-language localization beyond preparing string resources.
- Full offline completion or offline media upload.
- Public participant photo feed.

---

## 4. User Journeys

### 4.1 Participant Journey

1. Install and launch app.
2. Register with email/password, Google, or Apple.
3. Verify email when applicable.
4. Complete profile and accept privacy/health disclaimer.
5. Scan a coach QR code or enter invite code.
6. View program summary, coach, dates, rules, and consent.
7. Confirm enrollment.
8. Submit required initial weight.
9. Open Today screen.
10. Read each available step.
11. Upload photo evidence and optional answer.
12. Complete step.
13. View pending/approved status and updated progress.
14. Continue through all program days.
15. Submit final weight during the allowed final window.
16. View final score, leaderboard, and winners.

### 4.2 Coach Journey

1. Register and wait for admin role approval.
2. Open coach dashboard.
3. Buy a participant-seat pack through StoreKit 2.
4. See verified wallet balance.
5. Select an available program.
6. Generate invite with capacity and expiry.
7. Share or display QR code.
8. Monitor who joins and remaining capacity.
9. View participant progress and missing steps.
10. Review evidence for programs using coach review.
11. View leaderboard for the program.

### 4.3 Admin Journey

1. Log in with an admin account.
2. Create a draft program.
3. Configure dates, timezone, scoring, and visibility.
4. Add program days and ordered steps.
5. Add descriptions, points, images, and videos.
6. Preview the participant experience.
7. Publish the program.
8. Assign or allow coaches.
9. Monitor enrollment and program progress.
10. Manually add a participant when required.
11. Manage coach approvals and profiles.
12. Apply audited corrections when required.
13. Close scoring and lock top five winners.
14. Upload winner graphics or banners.
15. Archive completed programs.

---

## 5. iOS Navigation and Screens

Use `TabView` and a separate `NavigationStack` per tab. Preserve each tab's navigation path.

### 5.1 Shared Screens

- Launch/splash state.
- Login.
- Registration.
- Email verification notice.
- Forgot password.
- Reset password callback.
- Profile completion.
- Account settings.
- Privacy and terms.
- Account deletion.
- Coach directory.
- Media viewer.
- Network/error states.

### 5.2 Participant Tabs

Suggested tabs:

1. **Today**
   - Current program day.
   - Required steps.
   - Completion summary.
   - Weight prompt when applicable.

2. **Program**
   - Program overview.
   - Day timeline.
   - Locked/past/future states.
   - Overall progress.

3. **Leaderboard**
   - Current rank and points.
   - Top five emphasized.
   - Full eligible ranking.
   - Provisional/final state.

4. **Coaches**
   - Active coach directory.
   - Assigned coach detail.

5. **Profile**
   - Personal data.
   - Enrollments.
   - Settings and logout.

### 5.3 Coach Tabs

Suggested tabs:

1. **Dashboard**
   - Wallet balance.
   - Active programs.
   - Participant summary.

2. **Participants**
   - Filters by program and status.
   - Participant detail and evidence.
   - Review queue.

3. **Invite**
   - Available programs.
   - Generate QR.
   - Invite history and capacity.

4. **Leaderboard**
   - Program selector.
   - Rankings and status.

5. **Profile**
   - Public coach profile.
   - Purchase history.
   - Settings.

### 5.4 Admin Tabs

Suggested tabs:

1. **Overview**
2. **Programs**
3. **People**
4. **Content**
5. **Settings**

Use role-adaptive tab configuration rather than a single tab layout containing hidden inaccessible views.

---

## 6. Native UI Strategy

### 6.1 iOS 26 and Later

- Prefer standard SwiftUI controls so the system automatically adopts the current visual language.
- Use native Liquid Glass APIs for selected interactive surfaces.
- Use `GlassEffectContainer` when multiple related glass elements appear together.
- Apply `.glassEffect` after layout and visual modifiers.
- Use interactive glass only for actionable controls.
- Prefer `.buttonStyle(.glass)` and `.buttonStyle(.glassProminent)` for suitable actions.
- Do not place glass on every card or list row.
- Do not use custom blur stacks to imitate system glass.
- Respect Reduce Transparency and Increase Contrast settings.

Good candidates:

- Floating primary action area.
- Compact filter controls.
- QR action panel.
- Leaderboard rank badge.
- Media overlay controls.

Poor candidates:

- Long text surfaces.
- Every step row.
- Full-screen content backgrounds.
- Dense CMS forms.

### 6.2 iOS 17–25 Fallback

Gate iOS 26 APIs explicitly:

```swift
if #available(iOS 26, *) {
    // Native Liquid Glass presentation
} else {
    // Standard SwiftUI material or grouped background
}
```

Fallback rules:

- Prefer standard `List`, `Form`, `NavigationStack`, `TabView`, and system backgrounds.
- Use `.thinMaterial` or `.ultraThinMaterial` only where it improves hierarchy.
- Use `RoundedRectangle` with semantic fills such as `Color(uiColor: .secondarySystemBackground)`.
- Do not attempt to reproduce Liquid Glass manually.
- Keep layout and interaction behavior equivalent across OS versions.

### 6.3 Design System

Create native semantic tokens, not hard-coded brand styling throughout views:

```text
AppSpacing
AppRadius
AppTypography
AppElevation
AppMotion
AppStatusStyle
```

Use asset catalog colors with light/dark variants. Do not encode status using color alone.

---

## 7. Accessibility Requirements

Accessibility is part of the Definition of Done, not a later polish pass.

Required:

- Dynamic Type including accessibility sizes.
- VoiceOver labels, values, hints, and logical order.
- Minimum 44×44 point interactive targets.
- Sufficient contrast in light and dark appearances.
- Reduce Motion-compatible animations.
- Reduce Transparency-compatible surfaces.
- No information represented only through color.
- Text alternatives for program media where meaningful.
- Accessible names for uploaded evidence.
- Clear loading, error, empty, locked, pending, approved, and rejected states.
- Keyboard navigation for iPad where practical.
- Accessibility identifiers for critical UI tests.

Do not block core usage when camera or photo permission is denied. Explain the requirement and allow the user to retry permission or choose the photo library.

---

## 8. Repository Structure

Use a single Xcode project and feature-oriented folders.

```text
MSCBodyTransformation/
├── App/
│   ├── MSCBodyTransformationApp.swift
│   ├── AppEnvironment.swift
│   ├── AppConfiguration.swift
│   ├── AppRouter.swift
│   └── RootView.swift
├── Core/
│   ├── Auth/
│   ├── Database/
│   ├── Storage/
│   ├── Commerce/
│   ├── Media/
│   ├── QR/
│   ├── Logging/
│   ├── Networking/
│   └── Utilities/
├── Domain/
│   ├── Models/
│   ├── Repositories/
│   ├── UseCases/
│   ├── Scoring/
│   └── Validation/
├── Features/
│   ├── Authentication/
│   ├── Onboarding/
│   ├── ParticipantToday/
│   ├── ProgramTimeline/
│   ├── StepSubmission/
│   ├── WeighIn/
│   ├── Leaderboard/
│   ├── CoachDirectory/
│   ├── CoachDashboard/
│   ├── CoachParticipants/
│   ├── CoachInvites/
│   ├── CoachStore/
│   ├── AdminPrograms/
│   ├── AdminPeople/
│   ├── AdminContent/
│   └── Settings/
├── SharedUI/
│   ├── Components/
│   ├── Styles/
│   ├── Accessibility/
│   └── PreviewSupport/
├── Resources/
│   ├── Assets.xcassets
│   ├── Localizable.xcstrings
│   ├── PrivacyInfo.xcprivacy
│   └── Products.storekit
├── Tests/
│   ├── DomainTests/
│   ├── RepositoryTests/
│   ├── FeatureTests/
│   └── TestSupport/
└── UITests/
    ├── AuthenticationUITests.swift
    ├── ParticipantFlowUITests.swift
    ├── CoachFlowUITests.swift
    ├── AdminFlowUITests.swift
    └── AccessibilityUITests.swift

supabase/
├── config.toml
├── migrations/
├── functions/
│   ├── verify-app-store-transaction/
│   ├── app-store-notifications-v2/
│   ├── delete-account/
│   └── managed-media-cleanup/
├── seed.sql
└── tests/
    ├── rls/
    ├── scoring/
    ├── invites/
    └── commerce/
```

---

## 9. Supabase Data Model

Use UUID primary keys and `timestamptz`. Add `created_at` and `updated_at` where relevant.

### 9.1 Enums

Suggested database enums:

```text
app_role: participant, coach, admin
program_status: draft, scheduled, active, completed, archived
verification_mode: automatic, coach_review
submission_status: draft, submitted, approved, rejected
visibility_policy: hidden, read_only, open
invite_status: active, exhausted, expired, revoked
purchase_environment: sandbox, production
purchase_status: received, verified, granted, rejected, refunded, revoked
ledger_entry_type: purchase, enrollment, admin_grant, admin_debit, refund
weigh_in_type: initial, final
```

### 9.2 `profiles`

Purpose: shared user profile.

Key fields:

```text
id uuid primary key references auth.users(id)
role app_role not null default participant
full_name text not null
avatar_path text null
phone text null
is_active boolean not null default true
onboarding_completed_at timestamptz null
created_at timestamptz
updated_at timestamptz
```

Security:

- User can read/update permitted fields on own profile.
- User cannot update role or active status.
- Authenticated users can read only the public subset for active coaches.
- Admin can manage roles and active status.

Prefer a public security-invoker view for coach directory fields rather than granting broad profile access.

### 9.3 `coach_profiles`

Purpose: public coach information and approval state.

```text
coach_id uuid primary key references profiles(id)
bio text null
public_photo_path text null
is_approved boolean not null default false
is_public boolean not null default false
display_order integer not null default 0
created_at timestamptz
updated_at timestamptz
```

### 9.4 `programs`

```text
id uuid primary key
name text not null
description text not null
cover_media_path text null
start_date date not null
end_date date not null
timezone text not null default 'Asia/Makassar'
status program_status not null default draft
verification_mode verification_mode not null default automatic
past_step_policy visibility_policy not null default read_only
future_step_policy visibility_policy not null default hidden
weight_points_per_kg integer not null default 800
initial_weigh_in_open_at timestamptz null
initial_weigh_in_close_at timestamptz null
final_weigh_in_open_at timestamptz null
final_weigh_in_close_at timestamptz null
published_at timestamptz null
scoring_locked_at timestamptz null
created_by uuid not null
created_at timestamptz
updated_at timestamptz
```

Constraints:

- `end_date >= start_date`.
- Positive weight multiplier.
- Published programs must have at least one day and one step.
- Scoring fields become immutable after enrollment begins unless changed through an audited admin operation.

### 9.5 `program_days`

```text
id uuid primary key
program_id uuid not null
day_number integer not null
title text null
description text null
scheduled_date date not null
created_at timestamptz
updated_at timestamptz
unique(program_id, day_number)
unique(program_id, scheduled_date)
```

Program days are materialized at publish time rather than inferred differently by each client.

### 9.6 `program_steps`

```text
id uuid primary key
program_day_id uuid not null
sort_order integer not null
title text not null
description text not null
points integer not null
media_type text null
media_path text null
requires_photo boolean not null default true
requires_text_answer boolean not null default false
is_required boolean not null default true
is_active boolean not null default true
created_at timestamptz
updated_at timestamptz
unique(program_day_id, sort_order)
```

Constraints:

- Points cannot be negative.
- Published step scoring must not be directly editable after participants have submitted work.

### 9.7 `program_coaches`

```text
program_id uuid not null
coach_id uuid not null
is_active boolean not null default true
created_at timestamptz
primary key(program_id, coach_id)
```

### 9.8 `coach_wallets`

```text
coach_id uuid primary key
available_seats integer not null default 0
updated_at timestamptz
```

The balance is server-controlled. The client has read-only access to its own wallet.

### 9.9 `coach_credit_ledger`

```text
id uuid primary key
coach_id uuid not null
entry_type ledger_entry_type not null
quantity integer not null
balance_after integer not null
reference_type text not null
reference_id text not null
note text null
created_by uuid null
created_at timestamptz
unique(entry_type, reference_type, reference_id)
```

Use an append-only ledger. No client update/delete access.

### 9.10 `coach_invites`

```text
id uuid primary key
program_id uuid not null
coach_id uuid not null
token_hash text not null unique
max_uses integer not null
used_count integer not null default 0
expires_at timestamptz not null
status invite_status not null default active
created_at timestamptz
revoked_at timestamptz null
```

Rules:

- Store only a hash of the invite token.
- Raw token is returned only at creation time.
- QR contains an opaque token or approved universal link.
- Do not encode user role, credit balance, or trusted IDs as authoritative QR data.

### 9.11 `program_enrollments`

```text
id uuid primary key
program_id uuid not null
participant_id uuid not null
coach_id uuid null
invite_id uuid null
status text not null
joined_at timestamptz not null
completed_at timestamptz null
step_points integer not null default 0
weight_points integer not null default 0
adjustment_points integer not null default 0
total_points integer not null default 0
last_activity_at timestamptz null
created_at timestamptz
updated_at timestamptz
unique(program_id, participant_id)
```

Scores are server-maintained cached values for efficient lists. The source of truth remains submissions, weigh-ins, and adjustments.

### 9.12 `weigh_ins`

```text
id uuid primary key
enrollment_id uuid not null
weigh_in_type weigh_in_type not null
weight_kg numeric(6,2) not null
evidence_path text null
submitted_at timestamptz not null
verified_at timestamptz null
verified_by uuid null
created_at timestamptz
updated_at timestamptz
unique(enrollment_id, weigh_in_type)
```

Constraints:

- Validate a reasonable configurable weight range.
- Initial and final submissions must be within their configured windows unless admin overrides with audit.

### 9.13 `step_submissions`

```text
id uuid primary key
enrollment_id uuid not null
step_id uuid not null
answer_text text null
status submission_status not null default draft
submitted_at timestamptz null
reviewed_at timestamptz null
reviewed_by uuid null
rejection_reason text null
points_awarded integer not null default 0
created_at timestamptz
updated_at timestamptz
unique(enrollment_id, step_id)
```

### 9.14 `submission_evidence`

```text
id uuid primary key
submission_id uuid not null
storage_path text not null
mime_type text not null
byte_size bigint not null
width integer null
height integer null
created_at timestamptz
```

Support one or more photos in schema, even if the first MVP UI requires exactly one.

### 9.15 `score_adjustments`

```text
id uuid primary key
enrollment_id uuid not null
points integer not null
reason text not null
created_by uuid not null
created_at timestamptz
```

Admin only. Append-only.

### 9.16 `purchase_transactions`

```text
id uuid primary key
coach_id uuid not null
product_id text not null
transaction_id text not null unique
original_transaction_id text null
environment purchase_environment not null
quantity_purchased integer not null
credits_granted integer not null default 0
status purchase_status not null
purchased_at timestamptz null
verified_at timestamptz null
refunded_at timestamptz null
signed_transaction_hash text null
created_at timestamptz
updated_at timestamptz
```

Do not store secrets or unnecessary full payment payloads.

### 9.17 `program_winners`

```text
program_id uuid not null
position integer not null
enrollment_id uuid not null
locked_at timestamptz not null
locked_by uuid not null
primary key(program_id, position)
unique(program_id, enrollment_id)
```

Constraint: position 1 through 5.

### 9.18 `managed_content`

```text
id uuid primary key
content_type text not null
title text null
body text null
media_path text null
program_id uuid null
sort_order integer not null default 0
visible_from timestamptz null
visible_until timestamptz null
is_active boolean not null default true
created_by uuid not null
created_at timestamptz
updated_at timestamptz
```

Use for winner banners, home announcements, and managed visual content.

### 9.19 `audit_logs`

```text
id uuid primary key
actor_id uuid null
action text not null
entity_type text not null
entity_id text not null
before_data jsonb null
after_data jsonb null
reason text null
request_id uuid null
created_at timestamptz
```

Audit at minimum:

- Role changes.
- Coach approval.
- Manual enrollment.
- Program publish and scoring-field changes.
- Score adjustment.
- Evidence rejection.
- Credit grants/debits.
- Winner locking.

---

## 10. Server-Side Operations

Implement privileged business operations as Postgres functions or Edge Functions. Keep ordinary CRUD behind RLS.

### 10.1 `redeem_program_invite(raw_token)`

Atomic transaction:

1. Hash incoming token.
2. Lock invite row.
3. Validate active status, expiry, usage capacity, and program availability.
4. Validate current user is an active participant.
5. Return existing enrollment without charging if already enrolled.
6. Lock coach wallet row.
7. Ensure sufficient seat balance.
8. Insert enrollment.
9. Increment invite usage.
10. Decrement wallet.
11. Append ledger entry.
12. Append audit record.
13. Return enrollment summary.

Test concurrent redemption attempts.

### 10.2 `submit_step(enrollment_id, step_id, evidence_ids, answer)`

Server validates:

- Caller owns enrollment.
- Step belongs to enrollment program.
- Step is currently accessible according to program timezone and visibility policy.
- Required evidence exists and is owned by caller.
- Required text answer is present.
- Duplicate completion is idempotent.
- Points come from `program_steps.points`.
- Status becomes approved for automatic mode or submitted for review mode.
- Enrollment cached score and last activity are recalculated.

### 10.3 `review_submission(submission_id, decision, reason)`

- Only assigned coach or admin.
- Assigned coach can review only their participant in the relevant program.
- Admin can review any submission.
- Approval awards authoritative step points.
- Rejection removes awarded points and requires a reason.
- Recalculate enrollment score and rank source.
- Audit decision.

### 10.4 `submit_weigh_in(enrollment_id, type, weight_kg, evidence_path)`

- Validate ownership and window.
- Upsert only when editing is allowed.
- Lock after window closes unless admin override.
- Recalculate weight points when final weight exists.
- Do not allow client-supplied weight points.

### 10.5 `admin_enroll_participant(program_id, participant_id, coach_id, reason)`

- Admin only.
- Idempotent.
- Does not consume a seat.
- Requires reason.
- Audit.

### 10.6 `publish_program(program_id)`

Validate:

- Dates and timezone.
- At least one day.
- Every day has at least one active step.
- Step order uniqueness.
- Required scoring and visibility values.
- Media references exist.
- Materialize scheduled dates.
- Set immutable scoring snapshot/version.

### 10.7 `lock_program_winners(program_id)`

- Admin only.
- Program must be completed or scoring manually closed.
- Calculate deterministic top five.
- Save snapshot to `program_winners`.
- Audit.

### 10.8 Purchase Verification Edge Function

Input:

```text
signed transaction / transaction id
expected product id
current authenticated Supabase user
```

Process:

1. Validate Supabase JWT and coach role.
2. Verify Apple-signed transaction.
3. Confirm bundle id, product id, environment, and transaction state.
4. Map product id to seat quantity server-side.
5. Insert transaction idempotently.
6. Lock coach wallet.
7. Grant credits and append ledger entry.
8. Return authoritative wallet balance.

Never accept seat quantity from the client as authoritative.

### 10.9 App Store Notifications V2 Edge Function

- Accept Apple signed notification payload.
- Verify JWS.
- Handle test notifications.
- Handle refunds/revocations.
- Mark transaction status.
- Remove only unused credits automatically.
- If refunded credits were already consumed, create an admin review flag instead of corrupting existing enrollments.
- Return appropriate success code only after durable processing.
- Ensure notification processing is idempotent.

---

## 11. Row Level Security Plan

Enable RLS on every exposed table before granting Data API access.

Rules:

- Never include `service_role` in the iOS app.
- Use publishable key in the app.
- Do not authorize using editable `user_metadata`.
- Store privileged role data in protected server-controlled tables or app metadata maintained only by trusted server code.
- If helper functions use `SECURITY DEFINER`, place them in a non-exposed schema, set a safe `search_path`, revoke execution from `PUBLIC`, grant only required roles, and run database advisors.
- Use security-invoker views where available.
- Use least-privilege grants because newly created tables may not be automatically exposed to the Data API.

### 11.1 Participant Permissions

Participant may:

- Read own profile and allowed public coach fields.
- Read published programs they are eligible to view.
- Read own enrollment.
- Read accessible program days and steps.
- Create/read own evidence and submissions.
- Submit own weigh-ins.
- Read leaderboard-safe participant display data.

Participant may not:

- Change role.
- Read private evidence belonging to another participant.
- Modify step points.
- Modify cached score.
- Enroll without a valid atomic server operation.
- Read coach wallet or purchase details.

### 11.2 Coach Permissions

Coach may:

- Read own wallet and ledger.
- Create/revoke own invites for assigned available programs.
- Read participants assigned through their enrollment.
- Read assigned participant evidence.
- Review assigned participant submissions.
- Read relevant leaderboard data.

Coach may not:

- Grant own credits.
- Promote roles.
- Edit program scoring.
- Read participants belonging only to another coach.
- Manually alter scores.

### 11.3 Admin Permissions

Admin can manage application data through explicit policies and server operations. Sensitive actions still require audit logs.

---

## 12. Storage Design

Create separate buckets by access pattern.

### 12.1 Buckets

```text
avatars-public
coach-public
program-media
step-evidence-private
weigh-in-evidence-private
managed-content-public
```

### 12.2 Evidence Path Convention

```text
programs/{program_id}/participants/{participant_id}/steps/{step_id}/{uuid}.jpg
```

### 12.3 Storage Rules

- Evidence buckets are private.
- Participant uploads only into an authorized path for their own enrollment.
- Participant reads own evidence.
- Assigned coach reads evidence for assigned participants.
- Admin reads all evidence.
- Public coach and managed content buckets contain only explicitly approved public media.
- Enforce MIME type allowlists and file-size limits.
- Use Storage API for object operations; do not mutate storage metadata rows directly.
- Remove orphaned uploads through a scheduled cleanup process.

### 12.4 iOS Media Processing

Before upload:

- Normalize orientation.
- Resize overly large images.
- Encode to JPEG or HEIC based on compatibility decision.
- Strip unnecessary metadata, especially location metadata.
- Keep enough quality for coach review.
- Display upload progress.
- Retry safely without creating duplicate evidence records.

Use:

- `PhotosPicker` for library selection.
- Native camera capture with AVFoundation or an isolated native camera wrapper.
- `ImageIO` for resizing and metadata control.
- `AVKit.VideoPlayer` for program video.

---

## 13. QR Invite Design

### 13.1 Generation

Use Core Image `CIQRCodeGenerator`.

QR payload preference:

1. Universal Link when a verified domain is available.
2. Custom app URL plus in-app scanner fallback during early MVP.

Example conceptual payload:

```text
https://app.example.com/join/{opaque_token}
```

### 13.2 Scanning

- Prefer VisionKit `DataScannerViewController` where supported.
- Provide AVFoundation barcode-scanner fallback.
- Parse only approved host/scheme and route.
- Never execute arbitrary URLs.
- Require authentication before final redemption.
- Preserve pending invite token through login/onboarding.

### 13.3 Security

- Use random high-entropy tokens.
- Store token hash only.
- Set expiry and max uses.
- Allow coach revoke.
- Perform all trusted validation server-side.

---

## 14. Admin CMS Rules

### 14.1 Program Editor

Use a staged flow:

1. Basics.
2. Dates and timezone.
3. Scoring and visibility.
4. Days.
5. Steps and media.
6. Preview.
7. Publish.

Support drafts and autosave explicit state, but do not publish automatically.

### 14.2 Published Program Editing

After first enrollment:

- Name, descriptive copy, and media may be editable with audit.
- Dates, multiplier, step points, required status, and step identity require a controlled revision workflow.
- Never silently change historical scores.
- If scoring must change, apply a versioned migration/recalculation with admin reason and audit.

### 14.3 Managed Winner Content

Admin can:

- Lock top five winners.
- Upload winner banner.
- Set title/body.
- Set visibility dates.
- Preview participant-facing result.
- Remove or archive content without deleting winner records.

---

## 15. Privacy, Safety, and Compliance

Weight values and evidence photos are sensitive personal data.

Required:

- Clear privacy policy.
- Data minimization.
- Private evidence storage.
- Role-scoped access.
- In-app account deletion.
- Explain retention and deletion behavior.
- No advertising use of weight or evidence data.
- Remove EXIF location metadata from evidence uploads.
- Health/wellness disclaimer: the app supports a wellness program and does not provide medical diagnosis or emergency care.
- Do not request HealthKit access in MVP.
- Ask camera/photo access only at point of use.
- Provide a way to report an inappropriate or incorrect program item to admin.
- Provide official contest rules if prizes or rewards are attached to leaderboard positions, including that Apple is not a sponsor.
- Prepare App Privacy responses and `PrivacyInfo.xcprivacy`.
- Provide App Review with demo participant, coach, and admin accounts plus a sample QR code.

---

## 16. Testing Strategy

### 16.1 Swift Testing

Use Swift Testing for unit and integration-style tests of Swift code.

Required suites:

- Weight score calculation.
- Step score aggregation.
- Tie-break ordering.
- Program day calculation across timezones and daylight changes.
- Visibility policy evaluation.
- Submission validation.
- Weigh-in validation.
- Invite token parsing.
- Purchase product mapping.
- Role-driven navigation configuration.
- Media validation and resize decisions.
- Error mapping.

Use:

- `@Test`.
- `#expect`.
- Parameterized tests.
- Async tests.
- Tags for smoke, domain, integration, and commerce.

### 16.2 XCTest UI Tests

Use XCTest/XCUIAutomation for UI tests.

Critical flows:

1. Email registration and login.
2. OAuth callback routing using controlled test configuration.
3. Participant scans code, joins, submits weight, uploads evidence, completes step.
4. Coach buys a sandbox seat pack and sees updated balance.
5. Coach generates invite.
6. Coach reviews a submission.
7. Admin creates and publishes a program.
8. Admin manually enrolls participant.
9. Leaderboard updates and top five render.
10. Account deletion flow.

Do not mix Swift Testing and XCTest APIs inside the same test implementation.

### 16.3 StoreKit Testing

- Create `Products.storekit`.
- Configure all seat packs.
- Test success, cancellation, pending, interrupted purchase, duplicate transaction, and refund behavior.
- Test local StoreKit configuration.
- Test App Store sandbox.
- Test through TestFlight before release.
- Test `Transaction.updates` recovery after app relaunch.
- Test backend idempotency.
- Test App Store Server Notification V2 test event.

### 16.4 Supabase Tests

Automate:

- Migration application from an empty database.
- Seed data.
- RLS access matrix for participant, assigned coach, unrelated coach, and admin.
- Invite redemption race conditions.
- Duplicate enrollment.
- Wallet cannot become negative.
- Duplicate Apple transaction cannot grant credits twice.
- Score recalculation after approve/reject.
- Final weight formula.
- Winner locking.
- Storage access boundaries.

### 16.5 Accessibility Tests

Test:

- Dynamic Type at largest sizes.
- VoiceOver labels and order.
- Reduce Motion.
- Reduce Transparency.
- Light and dark appearance.
- High contrast.
- Button target sizes.
- Error messages associated with fields.

### 16.6 Device and OS Matrix

At minimum:

- Small supported iPhone on iOS 17.
- Standard current iPhone on iOS 18 or later available runtime.
- iPhone on iOS 26 for Liquid Glass.
- Latest available iOS simulator/runtime.
- One physical device for camera, photo, Google OAuth, Apple login, and StoreKit sandbox validation.
- iPad simulator for layout sanity.

---

## 17. Observability and Error Handling

Use `Logger` from OSLog with privacy annotations.

Suggested categories:

```text
auth
programs
submissions
storage
commerce
invites
leaderboard
admin
navigation
```

Rules:

- Never log passwords, access tokens, refresh tokens, signed transactions, invite tokens, body weight, or private image URLs.
- Generate a request/correlation id for critical server operations.
- Map technical errors into user-actionable messages.
- Preserve detailed errors in secure developer logs without exposing them to users.
- Handle offline, timeout, expired session, forbidden, upload failure, duplicate submission, and server conflict states.

---

## 18. Performance Requirements

- Paginate participant and leaderboard lists.
- Use lazy containers.
- Avoid loading full-resolution images into list rows.
- Generate or request thumbnails.
- Compress uploads before network transfer.
- Cancel stale async tasks.
- Avoid duplicate Supabase subscriptions.
- Use Realtime only where it produces clear value.
- Prefer manual refresh plus lightweight live updates for leaderboard and review queue.
- Profile slow scrolling, image-heavy screens, and Liquid Glass surfaces.

---

## 19. App Store Release Requirements

Before submission:

- Final bundle identifier and signing.
- App icons and launch assets.
- Privacy policy and terms links.
- Account deletion implemented.
- Google login plus a Guideline 4.8-compatible alternative, normally Sign in with Apple.
- IAP products created and submitted in App Store Connect.
- StoreKit product descriptions and screenshots.
- App Store Server Notification V2 production and sandbox endpoints.
- Demo participant, coach, and admin credentials.
- Sample QR code in review notes.
- Explain coach seat-credit business model in review notes.
- Explain that coach seats are digital access credits and use StoreKit IAP.
- Explain camera/photo usage.
- Explain wellness purpose and that it is not medical advice.
- Complete App Privacy answers.
- Provide contest rules when prizes are offered.
- Verify no placeholder screens, links, or content.
- Test all roles through TestFlight.

---

## 20. Android-Portability Guardrails

The iOS app is first, but the backend contract must remain platform-neutral.

Required:

- No database column names containing `ios`, `swift`, or Apple-specific UI concepts unless the data is genuinely Apple-specific, such as purchase transaction records.
- Store enum values in stable English machine-readable form.
- Store dates as ISO-compatible Postgres date/timestamp types.
- Store money and points as integer/numeric types.
- Document every RPC input/output.
- Keep business rules server-side.
- Create sample JSON fixtures for every domain model.
- Create an API/data-contract document before Android development.
- Keep Apple commerce data in commerce-specific tables so Android billing can later add Google Play transactions without redesigning program data.

Future commerce abstraction:

```text
commerce_transactions
- platform: app_store | play_store
- external_transaction_id
- product_id
- verified_state
```

For MVP, Apple-specific transaction details may remain in `purchase_transactions`, but migrations must leave room for platform abstraction.

---

## 21. Delivery Phases

Codex must complete phases in order. Each phase ends with a build and tests. Do not begin a new phase while the current phase has compiler errors or failing critical tests.

### Phase 0: Repository Bootstrap

- [ ] Create or inspect Xcode project.
- [ ] Set iOS deployment target to 17.0.
- [ ] Enable strict concurrency checking appropriate for the project.
- [ ] Add `supabase-swift` through Swift Package Manager and pin the version.
- [ ] Create folder structure.
- [ ] Add build configurations: Debug, Staging, Release.
- [ ] Add configuration loading without committing secrets.
- [ ] Add placeholder `Products.storekit`.
- [ ] Add test targets using Swift Testing and XCTest UI testing.
- [ ] Add OSLog categories.
- [ ] Add lint-free native formatting conventions documented in `CONTRIBUTING.md`.
- [ ] Confirm clean simulator build.

**Exit criteria**

- App launches to a placeholder root state.
- Unit and UI test targets execute.
- No secrets are committed.

### Phase 1: Supabase Foundation

- [ ] Initialize Supabase local project.
- [ ] Review current Supabase changelog and breaking changes.
- [ ] Create enums and base tables through migrations.
- [ ] Create private helper schema.
- [ ] Enable RLS before grants.
- [ ] Add least-privilege Data API grants.
- [ ] Create storage buckets and policies.
- [ ] Seed one admin, coach, participant, and sample draft program for local development.
- [ ] Add database tests for roles and storage access.
- [ ] Run Supabase database advisors.
- [ ] Document migration and reset commands.

**Exit criteria**

- Fresh local reset produces working schema and seed.
- Participant cannot access another participant's private data.
- Coach cannot access unrelated participant data.

### Phase 2: Authentication and Session

- [ ] Implement Supabase client adapter.
- [ ] Implement session store and auth-state listener.
- [ ] Implement email registration.
- [ ] Implement email verification state.
- [ ] Implement email/password login.
- [ ] Implement forgot/reset password callback.
- [ ] Implement Google OAuth with native web authentication session.
- [ ] Implement Sign in with Apple.
- [ ] Implement profile onboarding.
- [ ] Implement role loading from protected backend data.
- [ ] Implement logout.
- [ ] Implement account deletion request.
- [ ] Preserve pending invite token through authentication.
- [ ] Add auth unit and UI tests.

**Exit criteria**

- All login methods produce a Supabase session.
- New users are participants.
- Users cannot promote themselves.
- App restores session after relaunch.

### Phase 3: App Shell and Native Design System

- [ ] Build role-adaptive app shell.
- [ ] Add per-tab navigation stacks.
- [ ] Add shared async content states.
- [ ] Add semantic design tokens.
- [ ] Add light/dark assets.
- [ ] Add iOS 26 Liquid Glass components with iOS 17–25 fallback.
- [ ] Add Dynamic Type and VoiceOver baseline.
- [ ] Add preview fixtures for three roles.
- [ ] Add accessibility identifiers.

**Exit criteria**

- Participant, coach, and admin receive correct tabs.
- iOS 26 and fallback UIs compile independently.
- Largest Dynamic Type remains usable on primary screens.

### Phase 4: Admin Program CMS

- [ ] Implement program repository and models.
- [ ] Implement admin draft list.
- [ ] Implement staged program editor.
- [ ] Implement day editor.
- [ ] Implement ordered step editor.
- [ ] Implement image/video upload for program media.
- [ ] Implement participant preview.
- [ ] Implement server-side publish validation.
- [ ] Implement published-program edit restrictions.
- [ ] Add audit entries.
- [ ] Add admin UI tests.

**Exit criteria**

- Admin can create, preview, and publish a valid program without code changes.
- Invalid programs cannot be published.

### Phase 5: Participant Enrollment and Program Experience

- [ ] Implement program invite parser.
- [ ] Implement QR scanner.
- [ ] Implement invite preview and confirmation.
- [ ] Implement atomic invite redemption.
- [ ] Implement initial weigh-in.
- [ ] Implement Today screen.
- [ ] Implement program timeline and locked states.
- [ ] Implement step detail with media.
- [ ] Implement evidence camera/library selection.
- [ ] Implement image normalization, resize, metadata stripping, and upload progress.
- [ ] Implement step completion.
- [ ] Implement final weigh-in.
- [ ] Implement progress summary.
- [ ] Add participant journey UI test.

**Exit criteria**

- Participant can complete the full seeded program.
- Required photo prevents premature completion.
- Day visibility follows server program timezone.

### Phase 6: Scoring and Leaderboard

- [ ] Implement authoritative score functions.
- [ ] Implement automatic and coach-review modes.
- [ ] Implement weight formula.
- [ ] Implement cached enrollment score recalculation.
- [ ] Implement deterministic leaderboard query/RPC.
- [ ] Implement current-rank card.
- [ ] Implement top-five presentation.
- [ ] Implement provisional/final labels.
- [ ] Implement winner locking.
- [ ] Add scoring and tie-break tests.

**Exit criteria**

- Client cannot forge points.
- Approval/rejection updates ranking correctly.
- Final winners remain stable after locking.

### Phase 7: Coach Wallet, StoreKit, and Invites

- [ ] Create App Store product mapping configuration.
- [ ] Implement StoreKit product loader.
- [ ] Implement coach store UI.
- [ ] Implement purchase state machine.
- [ ] Implement server transaction verification Edge Function.
- [ ] Implement idempotent wallet credit grant.
- [ ] Implement transaction update listener.
- [ ] Implement purchase history.
- [ ] Implement coach program selector.
- [ ] Implement invite creation and revoke.
- [ ] Implement QR generation.
- [ ] Implement invite capacity and expiry.
- [ ] Implement App Store Notifications V2 endpoint.
- [ ] Add StoreKit local and sandbox tests.

**Exit criteria**

- Verified purchase updates wallet exactly once.
- Duplicate callbacks do not duplicate credits.
- Enrollment consumes exactly one seat.
- Wallet never becomes negative.

### Phase 8: Coach Monitoring

- [ ] Implement coach dashboard metrics.
- [ ] Implement participant list with filters.
- [ ] Implement participant progress detail.
- [ ] Implement evidence viewer.
- [ ] Implement pending review queue.
- [ ] Implement approve/reject actions.
- [ ] Implement missing-step indicators.
- [ ] Add unrelated-coach access tests.

**Exit criteria**

- Coach sees only assigned participants.
- Review actions immediately recalculate authoritative score.

### Phase 9: Admin Power Tools and Managed Content

- [ ] Implement people and role management.
- [ ] Implement coach approval/public profile management.
- [ ] Implement admin manual enrollment with reason.
- [ ] Implement score adjustment with reason.
- [ ] Implement managed content editor.
- [ ] Implement winner banner upload.
- [ ] Implement audit log viewer.
- [ ] Add admin privilege tests.

**Exit criteria**

- Admin can recover failed enrollment without changing code.
- Every privileged correction is auditable.

### Phase 10: Accessibility, Reliability, and Performance

- [ ] Audit every critical screen with VoiceOver.
- [ ] Audit Dynamic Type.
- [ ] Audit Reduce Motion and Reduce Transparency.
- [ ] Add robust upload retry and orphan cleanup.
- [ ] Add pagination.
- [ ] Add thumbnail strategy.
- [ ] Add session-expiry recovery.
- [ ] Profile scroll and image memory.
- [ ] Profile Liquid Glass surfaces on iOS 26.
- [ ] Add graceful network-offline states.

**Exit criteria**

- No known critical accessibility blockers.
- No uncontrolled full-resolution image memory spikes.
- Interrupted upload can be retried safely.

### Phase 11: Security and Release Hardening

- [ ] Run full RLS matrix.
- [ ] Run database advisors.
- [ ] Verify no service-role key in app or repository.
- [ ] Verify OAuth redirect allowlist.
- [ ] Verify Apple and Google provider configuration.
- [ ] Verify account deletion.
- [ ] Verify private evidence cannot be accessed by URL without authorization.
- [ ] Verify purchase refund handling.
- [ ] Prepare privacy manifest and App Privacy answers.
- [ ] Prepare demo accounts and review QR.
- [ ] Prepare App Review notes.
- [ ] Run TestFlight end-to-end tests.

**Exit criteria**

- Release candidate passes all critical flows on a physical device.
- App Store reviewer can access all roles and review IAP behavior.

### Phase 12: Android Handoff Package

Do not build Android yet. Produce:

- [ ] Data dictionary.
- [ ] RPC/API contract document.
- [ ] Role and RLS matrix.
- [ ] Auth flow document.
- [ ] Scoring specification.
- [ ] Commerce abstraction notes.
- [ ] JSON fixtures.
- [ ] Screen inventory and user-flow diagrams.
- [ ] Android backlog using Kotlin, Compose, Credential Manager, Google Play Billing, and the same Supabase project.

---

## 22. Codex Execution Rules

Codex must follow this loop:

1. Read this file and the repository state.
2. Select the smallest coherent unchecked vertical slice.
3. State assumptions in the commit or task notes.
4. Implement production code and tests together.
5. Build before continuing.
6. Run the relevant tests.
7. Fix compiler warnings related to concurrency, availability, or unsafe behavior.
8. Update checkboxes and a brief progress log in this file.
9. Keep migrations append-only after they are shared.
10. Avoid unrelated refactors.

Mandatory rules:

- Never claim a task is complete without running the appropriate build/test command.
- Never put `service_role`, App Store private keys, or OAuth client secrets in the iOS target.
- Never use client-calculated points as source of truth.
- Never grant coach credits from an unverified purchase.
- Never authorize roles from editable user metadata.
- Never weaken RLS to fix a client error.
- Never add a third-party package without documenting why native frameworks are insufficient.
- Never use an iOS 26-only API without availability gating and fallback.
- Never modify a published program's scoring silently.

---

## 23. Verification Commands

Adapt schemes and destinations to the repository.

```bash
# Inspect schemes
xcodebuild -list

# Debug simulator build
xcodebuild \
  -scheme MSCBodyTransformation \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build

# Unit tests
xcodebuild \
  -scheme MSCBodyTransformation \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  test

# Supabase local reset
supabase db reset

# Supabase command discovery
supabase --help
supabase db --help

# Database advisors, when supported by installed CLI
supabase db advisors
```

Codex must discover current Supabase CLI syntax with `--help` instead of guessing commands.

---

## 24. Definition of Done

The MVP is done only when all of the following are true:

- Participant, coach, and admin authentication works.
- Google OAuth, Sign in with Apple, and email/password work on a physical device.
- New users cannot self-promote.
- Admin can build and publish a complete program in the app.
- Coach can purchase verified seat credits through StoreKit 2.
- Participant can join through a coach QR/invite.
- Seat consumption is atomic and idempotent.
- Participant can submit initial weight.
- Participant can complete daily steps only with required evidence.
- Program day visibility is server-authoritative.
- Participant can submit final weight.
- Step and weight points are calculated server-side.
- Coach can monitor assigned participants and evidence.
- Leaderboard is deterministic and shows top five.
- Admin can manually enroll and correct scores with audit history.
- Admin can upload winner content without code.
- Private evidence is protected by RLS and Storage policies.
- Account deletion exists inside the app.
- Liquid Glass works on iOS 26+ and native fallback works on iOS 17–25.
- Critical Swift Testing and XCTest UI suites pass.
- StoreKit local, sandbox, and notification tests pass.
- App is usable with Dynamic Type and VoiceOver.
- TestFlight end-to-end release candidate is accepted internally.
- App Store submission metadata, review accounts, QR, IAP items, privacy details, and review notes are complete.

---

## 25. Current External Documentation Checkpoints

Before implementing each subsystem, verify against current official documentation:

### Apple

- SwiftUI and Liquid Glass availability and performance guidance.
- Swift Testing and XCTest UI testing guidance.
- StoreKit 2 and StoreKit views.
- Consumable In-App Purchase behavior.
- App Store Server API and signed JWS transactions.
- App Store Server Notifications V2.
- App Review Guidelines, especially payments, login services, account deletion, privacy, health/wellness, and contests.
- AuthenticationServices and Sign in with Apple.

### Supabase

- Current changelog and breaking changes.
- Swift SDK installation and exact APIs.
- Google and Apple social login setup.
- Email/password authentication.
- Data API exposure and explicit grants.
- Row Level Security.
- Storage access control.
- Edge Functions runtime compatibility.
- Database advisors and CLI syntax.

Important current migration consideration:

- Do not assume newly created public tables are automatically exposed to the Data API. Apply explicit least-privilege grants only after RLS and policies exist.

---

## 26. Progress Log

Add concise dated entries below as Codex completes meaningful slices.

```text
YYYY-MM-DD — Phase X — Summary — Build/test result
```

