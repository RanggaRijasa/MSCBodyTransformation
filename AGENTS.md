# MSC Body Transformation iOS Project Guidelines

This file defines the working rules for Codex and any other coding agent operating in this repository.

## Project Context

The project is a native iOS and iPadOS application for multi-day body-transformation programs.

The app has three authenticated roles:

- Participant completes daily program steps, uploads photo evidence, submits initial and final weight, earns points, and views the leaderboard.
- Coach receives one unique enrollment QR identifier and monitors assigned participants.
- Admin manages programs, people, content, enrollment fallbacks, score corrections, and final winners.

Primary technical direction:

- Swift 6.
- SwiftUI.
- Minimum deployment target iOS 17.
- Native Apple frameworks wherever practical.
- Liquid Glass on iOS 26 and later.
- Native SwiftUI fallback on iOS 17 through iOS 25.
- Swift Testing for unit and integration-style Swift tests.
- XCTest and XCUIAutomation for UI tests.
- Supabase, OAuth, and production StoreKit integration are deferred to their assigned phases.
- Android will be implemented later with Kotlin and Jetpack Compose using the same backend contract.

## MSCWeb Conversion Scope

For every task or Codex goal concerning the Web/PWA conversion:

- All new files and modifications for the Web/PWA implementation must remain
  inside `MSCWeb/`.
- Read and follow `MSCWeb/AGENTS.md` before working on any Web/PWA phase.
- Files outside `MSCWeb/`, including the iOS project, `Contracts`, `supabase`,
  and root documentation, are read-only references unless the user explicitly
  authorizes a change to a specific path.
- A Web/PWA goal does not implicitly expand its write scope beyond `MSCWeb/`,
  even when it requires read-only audits of the existing iOS or backend code.
- If completion requires changing shared backend files, contracts, hosted
  Supabase, DNS, domain configuration, production OAuth, or deployment state,
  stop at that gate and obtain explicit user authorization first.
- Never move, delete, archive, or rewrite the existing iOS project as part of
  the conversion. Moving `MSCWeb/` to a new repository remains a user-approved
  cutover action after parity has been verified.

## Required Reading Before Work

Before changing code:

1. Read `00_START_HERE.md`.
2. Read `UI_REFERENCE_SHEET.md` before creating or changing UI.
3. Read the single phase file assigned for the current task.
4. Inspect the current repository structure and nearby implementation patterns.
5. Work only within the assigned phase unless the user explicitly expands the scope.
6. Do not silently implement tasks from a later phase.

For Phase 00 through Phase 08:

- Do not add Supabase.
- Do not configure Google OAuth.
- Do not configure Sign in with Apple production flow.
- Do not connect App Store Connect.
- Do not perform live StoreKit purchases.
- Use mock repositories, fixtures, local media, and Debug-only scenarios.

## Output Style for Coding Agents

When generating or editing code:

- Provide complete files rather than fragments unless the user asks for a patch or excerpt.
- State the intended repository path for every new or replaced file.
- Keep names consistent with this file and the current phase workplan.
- Prefer code that compiles over theoretical or illustrative code.
- Do not claim a task is complete without running the smallest relevant build or test command when the environment permits it.
- Report the exact build and test commands that were run and whether they passed.
- When a framework API is uncertain, isolate it behind a small service or adapter and add a specific TODO naming the API or decision that must be verified.
- Do not invent Apple, Supabase, StoreKit, OAuth, or third-party APIs.
- Do not add package dependencies unless the user explicitly requests them.
- Use native frameworks before proposing a dependency.
- Preserve privacy, wellness, and non-diagnostic wording.
- Keep user-facing error messages direct and actionable.
- Do not expose implementation secrets, tokens, private URLs, or sensitive user data in examples, logs, previews, or test fixtures.

## Language and Localization Rules

- The primary product language is Bahasa Indonesia.
- All production-facing copy must use Bahasa Indonesia.
- Keep wording clear, friendly, concise, non-judgmental, and non-diagnostic.
- Use sentence case.
- Do not mix English into production UI except for proper names, technology names, or approved product terminology.
- Use the terminology defined in `UI_REFERENCE_SHEET.md`.
- Use `Localizable.xcstrings` from the beginning, even while Indonesian is the only supported language.
- Do not duplicate reusable user-facing copy across Views.
- Use locale `id-ID` for number, percentage, body-weight, date, time, and currency formatting.
- Use native `FormatStyle` APIs rather than manually formatted strings.
- Preserve explicit program timezones and show WITA or another relevant zone when needed.
- Test Indonesian text wrapping at large Dynamic Type sizes.
- App-owned UI must remain in Bahasa Indonesia regardless of the device
  language. Keep `AppConfiguration.indonesianLocaleIdentifier` set to `id-ID`
  and inject its `Locale` at the root `WindowGroup`; do not fall back to
  `Locale.current` for app copy or product formatting.
- English is allowed only for approved product names, technology names, or
  established feature terms such as `Coach`. System-owned surfaces such as
  the native photo picker or permission dialog may continue to follow the
  device language.
- Every runtime `String(localized:)` call must include a Bahasa Indonesia
  `defaultValue`, including search prompts, filter summaries, formatted copy,
  and strings passed into `String(format:)`. Do not assume an `id` entry in
  `Localizable.xcstrings` will be used as fallback while the Xcode project
  development region is `en`.
- Before completing localization or UI-copy changes, launch the affected flow
  at least once with a non-Indonesian app locale such as
  `-AppleLanguages (en) -AppleLocale en_US`. Verify that no localization key
  such as `feature.section.label` is visible. Add or update a focused UI test
  for dynamic localized strings when practical.
- Before completing localization or UI-copy changes, run
  `scripts/check_localization_catalog.sh`. A machine-style key without a
  non-empty Indonesian catalog value is a failing check.
- A visible localization key is a release-blocking UI defect. Fix the catalog
  entry and the runtime fallback; do not hide it with layout changes or
  screenshot-only workarounds.

## Phase Discipline

- Work on one phase at a time.
- Select the smallest coherent vertical slice from the current phase.
- Implement production code and its focused tests together.
- Build before moving to another vertical slice.
- Fix compiler errors before continuing.
- Fix warnings involving concurrency, availability, unsafe behavior, or privacy before marking work complete.
- Update a phase checkbox only after the relevant implementation has been verified.
- Add a short entry to the phase progress log with:
  - Files changed.
  - Assumptions.
  - Build command.
  - Test command.
  - Result.
  - Remaining blockers.
- Do not refactor unrelated files while implementing a phase task.

## Xcode Project File Restrictions

- Do not edit `project.pbxproj` unless the user explicitly instructs you to edit it.
- Do not make incidental formatting, ordering, identifier, or reference changes inside `project.pbxproj`.
- Do not use scripts or tools that regenerate the Xcode project unless explicitly requested.
- Do not introduce XcodeGen, Tuist, or another project generator unless explicitly requested.
- Prefer adding files inside existing synchronized groups or folders when the current project setup supports automatic discovery.
- When a new file requires target membership or an Xcode project change, create the source file in the correct folder, then stop and report the exact manual Xcode step required.
- Never modify signing, capabilities, bundle identifiers, entitlements, schemes, or build settings unless the current task explicitly requires it.

## Git Restrictions

- Do not run `git add`.
- Do not run `git commit`.
- Do not run `git push`.
- Do not create, switch, rename, merge, rebase, or delete branches.
- Do not open or update pull requests.
- Do not tag releases.
- Do not stash or discard user changes.
- Do not run destructive Git commands.
- Do not modify `.git` internals.
- Perform any Git operation only when the user explicitly requests that exact action.
- Reading repository state with non-mutating commands such as `git status`, `git diff`, `git log`, or `git branch --show-current` is allowed when useful.
- Never claim changes were committed or pushed unless the user explicitly requested the operation and it completed successfully.

## Architecture Rules

Use the following dependency direction:

```text
SwiftUI View
    ↓
Feature State / @Observable Model
    ↓
Use Case or Domain Service
    ↓
Repository Protocol
    ↓
Mock Adapter now
    ↓
Supabase, StoreKit, or native external adapter later
```

Rules:

- SwiftUI Views render state and forward user actions.
- Views must not perform database queries.
- Views must not contain authoritative scoring or authorization rules.
- Keep business rules in domain services or use cases.
- Keep persistence and external-system logic in repository implementations or adapters.
- Keep reusable UI in `SharedUI`.
- Keep feature-specific UI inside its feature folder.
- Use protocol-based boundaries when the implementation must be mocked, tested, or replaced later.
- Avoid protocols for trivial single-use code that gains no testability or substitution benefit.
- Prefer value types and narrow state ownership.
- Use `@State`, `@Binding`, `@Observable`, and `@Environment` according to actual ownership.
- Avoid global mutable singletons.
- Shared root dependencies belong in the app environment or root dependency container.
- Do not pass Supabase, StoreKit, UIKit, or SwiftUI-specific types into domain models.
- Domain models should remain portable to the future Android implementation.

## Clean Code Rules

Code must be understandable, maintainable, and separated by responsibility.

### File structure

- Do not place unrelated features in one large file.
- Split code by feature and responsibility:
  - Views.
  - Feature state or ViewModels.
  - Services and use cases.
  - Repositories.
  - Models.
  - Utilities.
  - Shared components.
- Keep SwiftUI Views focused on rendering and interaction.
- Extract subviews when a View becomes difficult to scan.
- Extract service methods when a function performs more than one job.
- Avoid a single Participant, Coach, or Admin ViewModel that owns every screen.
- Do not introduce an abstraction only to reduce the line count of one simple function.

### Naming

- Use clear and descriptive names.
- Prefer names that communicate intent rather than implementation detail.
- Avoid vague names such as `data`, `item`, `thing`, `manager`, `helper`, or `temp` unless their scope is truly generic and obvious.
- Boolean names should read naturally, such as:
  - `isSubmittingEvidence`
  - `hasCompletedInitialWeighIn`
  - `shouldShowLockedDayExplanation`
- Function names should describe both the action and result, such as:
  - `loadTodayProgram()`
  - `validateSubmissionRequirements()`
  - `calculateWeightPoints()`
  - `saveProgramDraft()`
  - `generateCoachQRCode()`

### Comments and TODOs

- Add comments only when they explain intent, constraints, tradeoffs, or non-obvious behavior.
- Do not narrate obvious code line by line.
- Explain why a workaround exists.
- Every TODO must be specific and actionable.
- Good:
  - `TODO: Replace the local clock result with the server-resolved active program day in Phase 11.`
- Bad:
  - `TODO: Fix later.`

### Constants

- Do not scatter magic numbers or repeated strings.
- Place repeated limits, filenames, route identifiers, UserDefaults keys, mock scenario names, and storage paths in named constants.
- Keep reused user-facing copy in a consistent location.
- Keep persisted enum raw values stable and machine-readable.
- Use `Decimal` for canonical weight calculations.
- Use integer values for points.

### Reuse

- Do not copy and paste business logic.
- Extract shared logic when it is used more than once or when extraction clarifies a complex flow.
- Prefer small concrete services over large generic managers.
- Avoid `AnyView` as a routine type-erasure workaround.
- Avoid giant utility files.
- Keep formatters and parsers focused.

## UI Reference and Brand Rules

`UI_REFERENCE_SHEET.md` is the source of truth for visual work.

Brand colors:

- Black.
- Red.
- Yellow.

Implementation rules:

- Use semantic Asset Catalog colors with separate light and dark appearance values.
- Do not place hard-coded hex values inside feature Views.
- Use red for primary actions and active emphasis.
- Use yellow for achievements, ranks, and limited attention states.
- Use black or near-black for strong identity and selected surfaces.
- Do not use yellow as small body text on a light background.
- Do not communicate status through color alone.
- Keep forms, lists, and long content on neutral system surfaces.
- Verify light mode, dark mode, Increase Contrast, Reduce Transparency, and Differentiate Without Color.
- Use San Francisco through semantic SwiftUI text styles.
- Use Dynamic Type.
- Do not add a custom font unless explicitly requested.
- Use `.monospacedDigit()` for points, ranks, weights, timers, and other changing numeric values.
- Render profile images through the shared `UserAvatar`. When no image is
  available, use the neutral native blank-person fallback systemwide; do not
  generate initials or role-specific colored placeholder avatars.
- Do not shrink production text to fit.
- Keep primary touch targets at least 44 by 44 points.
- Use the spacing, radius, button, and state-copy guidance from `UI_REFERENCE_SHEET.md`.

## Swift and Concurrency Rules

- Use Swift structured concurrency.
- Make long-running work cancellable when navigation or retry can invalidate it.
- Avoid unstructured `Task` creation unless ownership and cancellation are clear.
- Do not use `Task.detached` without a documented reason.
- Keep UI mutations on the main actor.
- Do not mark broad types `@MainActor` merely to silence warnings.
- Prefer `Sendable` domain values where appropriate.
- Isolate mutable mock repository storage safely, preferably with actors when concurrency is possible.
- Never suppress a concurrency warning without understanding the ownership issue.

## SwiftUI Rules

- Use `NavigationStack`.
- Use a separate navigation path per tab.
- Do not concatenate SwiftUI `Text` values with the `+` operator. It is
  deprecated in the iOS 26 SDK. Use localized interpolation in one `Text`,
  such as
  `Text("\(count, format: .number) \(Text("unit.days"))")`, while preserving
  native `FormatStyle` formatting and localization keys.
- Treat SDK deprecation warnings in changed code as required fixes before
  completion. Do not suppress a deprecation warning merely to obtain a clean
  build.
- Prefer `.sheet(item:)` when a selected model drives presentation.
- Use enum-driven presentation for mutually exclusive sheets and alerts.
- Use `.task` or `.task(id:)` for lifecycle-bound asynchronous loading.
- Always model loading, loaded, empty, and error states explicitly.
- Do not start network or repository work directly from `body`.
- Keep list identities stable.
- Use lazy containers for long lists.
- Use system controls and semantic styles before custom controls.
- Add previews for primary, loading, empty, error, dark mode, and large Dynamic Type states when useful.
- Add accessibility identifiers only where they improve critical UI testing.

## Liquid Glass and OS Availability

- Use native Liquid Glass APIs only on iOS 26 and later.
- Gate every iOS 26-only API with explicit availability checks.
- Provide a native SwiftUI fallback for iOS 17 through iOS 25.
- Prefer standard system controls because they naturally follow the platform design language.
- Use glass selectively for compact interactive surfaces.
- Do not place glass on every card, list row, form, or long-text surface.
- Use `GlassEffectContainer` for grouped glass elements when appropriate.
- Apply glass effects after layout and visual modifiers.
- Use interactive glass only for interactive elements.
- Respect Reduce Transparency, Increase Contrast, and Reduce Motion.
- Do not recreate Liquid Glass with custom blur stacks on older systems.
- If the installed Xcode SDK does not expose the expected Liquid Glass API, keep the implementation behind an availability adapter and document the exact blocked API rather than inventing a signature.

## Local-First Development Rules

For Phase 00 through Phase 08:

- The app must remain usable without internet access.
- Use in-memory repositories or deterministic bundled JSON fixtures.
- Use a Debug-only role switcher for Participant, Coach, and Admin.
- Use a Debug-only scenario selector for loading, empty, error, offline, and role-specific states.
- Do not compile Debug controls into Release.
- Use an injected clock for program-day simulation.
- Use deterministic identifiers in tests.
- Keep local scoring clearly labeled as demo behavior when shown in developer tooling.
- Do not label local results as server verified.
- Do not add hidden network calls.
- Do not block previews on external configuration.

## Supabase Environment Rules

For Phase 09 and later, the approved environment strategy is:

```text
Development → Supabase local through Supabase CLI, Docker, and Colima
Production  → hosted Supabase main project
Branching   → not used
```

Operational start, status, shutdown, and data-preservation commands are
documented in `supabase/COLIMA_LOCAL_DEVELOPMENT.md`.

Rules:

- Before starting development work that requires the local Supabase backend,
  check readiness in this order:
  - `colima status`.
  - `docker info`.
  - `supabase status` from the repository root.
- If Colima is not running, start it with `colima start`.
- If the Docker daemon is not ready after Colima starts, verify `docker info`
  before continuing.
- If the local Supabase stack is not running, start it from the repository
  root with `supabase start`.
- Start Colima and Supabase automatically only when the assigned task needs
  the local database, Auth, Storage, Data API, Studio, migrations, or backend
  tests. Do not start them for documentation-only, mock-only, preview-only, or
  unrelated UI work.
- Never stop Supabase or Colima automatically when an agent finishes a task.
  Leave shutdown to the user unless the user explicitly requests the exact
  stop operation.
- Use the local Supabase stack for database, Auth, Storage, Realtime, Data API,
  migrations, seeds, integration tests, and Debug adapter development.
- Treat the hosted `main` project as production. Do not use it for experiments,
  development fixtures, migration iteration, local testing, or destructive
  verification.
- Do not create Supabase preview branches, persistent branches, or a second
  hosted development/staging project unless the user explicitly changes this
  environment decision.
- Do not deploy migrations, functions, configuration, or seed data to hosted
  `main` without explicit user authorization for that production deployment.
- Every destructive development command, including database reset and test
  seeding, must explicitly target local Supabase. Use `--local` when the CLI
  command supports it and verify the target before execution.
- Debug configuration may use the local URL and local publishable or legacy
  anon credential returned by the running local stack. Do not copy generated
  local credentials into committed files.
- Release configuration must never point to localhost, a Mac LAN address, or
  another local Supabase endpoint.
- Production URL and publishable key may be added to Release configuration
  only during an explicitly authorized production integration task. Never add
  `service_role`, secret key, database password, or JWT secret to the app,
  repository, examples, fixtures, or logs.
- The accepted consequence is that Supabase-backed development works only
  while the Mac, Colima, and the local stack are running. Remote QA is not
  available under this strategy.
- Simulator and physical-device tests must account for local networking.
  Never hard-code a temporary LAN address into production source.

## Authentication and Role Rules

Until the assigned authentication phase:

- Use fake sessions only.
- Do not add live OAuth callback handling.
- Do not add provider SDKs.
- Do not add client secrets.

Guest and Coach application rules:

- Guest is a logged-out access state, not a fourth `UserRole`, not an
  authenticated Participant, and not an anonymous Supabase Auth user.
- Guest may browse the public Participant shell, but every personal mutation
  must pass through the centralized authentication gate.
- Never hydrate Guest screens with fixture or cached profile, enrollment,
  weight, submission, private-media, or current-Coach data.
- Login is the default authentication destination. Register and Forgot
  Password are separate destinations that return to Login.
- All self-registration methods create a Participant account first. Choosing
  Coach means applying; the client must never self-assign Coach or Admin.
- Member level is profile/application data, not an authorization claim.
- Coach application requires SC or higher plus explicit HOM STS and ICT
  attestations.
- Coach pricing is centralized: SC/SB Rp100.000, Supervisor/World Team
  Rp150.000, and TAB/GET/Millionaire/President’s Team Rp200.000 for a manual
  three-month period. `Member` cannot apply.
- A verified payment is not Coach approval. The applicant remains Participant
  until Admin review and an authoritative operation activate Coach access.
- Approval/rejection must be idempotent and audited. Rejection requires a
  reason; approval requires complete eligibility and verified payment.
- Phase 09.5 uses deterministic local fake auth and purchase adapters. Never
  present their outcomes as real Supabase Auth, OAuth, StoreKit, payment, or
  server verification.

## Participant Enrollment Rules

- Participant selects a visible active program before enrollment.
- Participant enrollment requires scanning the coach's unique QR.
- Do not expose a manual coach-code or invite-code field, button, fallback,
  deep link, or copyable raw identifier in production UI.
- Keep the coach enrollment identifier internal to the QR payload and domain
  matching boundary.
- If camera scanning is unavailable or denied, show an actionable unavailable
  state and allow the participant to close the scanner; do not fall back to
  typed codes.

When authentication is implemented:

- New registrations default to Participant.
- Users must not select Coach or Admin during self-registration.
- Do not authorize from editable profile metadata.
- Load privileged role information from protected server-controlled data.
- Preserve the selected program and pending opaque Coach QR validation
  through authentication.
- Treat Google, Apple, and email/password as identity methods for the same application account where supported.
- Keep authentication errors user-friendly and avoid logging tokens.

## Scoring Rules

The client may calculate preview values for local UI and tests, but production scoring must become authoritative on the server.

Rules:

- Step points come from the published program-step definition.
- Pending or rejected submissions do not receive authoritative points.
- Duplicate completion must not duplicate points.
- Weight loss cannot produce negative points.
- Weight points use `Decimal`, not binary floating-point arithmetic.
- Adjustments remain separate from step and weight points.
- Do not display private weight values in the public leaderboard.
- Winner locking must create a stable snapshot.
- Do not silently change published scoring behavior.

Default formula:

```text
total_points =
    approved_step_points
    + weight_points
    + adjustment_points
```

```text
weight_loss_kg = max(initial_weight_kg - final_weight_kg, 0)
weight_points = rounded(weight_loss_kg × weight_points_per_kg)
```

## Media and Privacy Rules

Weight values and evidence photos are sensitive personal data.

- Never log passwords, access tokens, refresh tokens, raw Coach QR
  identifiers, body weight, answer-photo paths, or private media URLs.
- Use `PhotosPicker` for library selection when practical.
- Request camera or photo access only at the point of use.
- Keep camera integration behind a small native wrapper.
- Normalize image orientation.
- Resize oversized images outside the main thread.
- Remove unnecessary metadata, especially location metadata.
- Use thumbnails in lists.
- Clean temporary files.
- Do not add `Gunakan foto demo`, `Gunakan poster demo`, generated sample
  media, or equivalent upload shortcuts, including in Debug-only UI. Upload
  flows must use the actual native picker or camera path; deterministic media
  needed by tests belongs in test fixtures and must not be selectable from
  production screens.
- Do not place UIKit images in domain models.
- Preserve non-diagnostic health and wellness language.
- Do not add HealthKit in the MVP unless explicitly requested.

## Error Handling

- Use typed errors for meaningful domain failures.
- Map technical errors into user-actionable messages at the feature state or UI boundary.
- Do not silently ignore errors unless there is a deliberate documented fallback.
- Provide retry actions for recoverable failures.
- Distinguish validation, authorization, conflict, offline, timeout, and unknown failures.
- Do not expose raw backend or framework error text directly to users.

## Testing and Verification

Use Swift Testing for unit and integration-style Swift tests.

Use XCTest and XCUIAutomation for UI tests.

Testing rules:

- Add focused tests with each meaningful behavior change.
- Prefer deterministic fixtures over random test data.
- Use injected clocks and identifiers.
- Do not make one UI test depend on another.
- Use launch arguments for deterministic UI scenarios.
- Test edge cases, not only the happy path.
- Keep test names behavior-focused.
- Do not mix Swift Testing and XCTest APIs inside the same test implementation.
- Run the smallest useful test command after meaningful changes.
- Run a simulator build before marking a phase task complete.
- When a test cannot run, explain exactly why and what remains unverified.

Minimum recurring edge cases:

- No active program.
- Empty step list.
- Missing required evidence.
- Missing required answer.
- Locked day.
- Pending review.
- Rejected evidence.
- Missing final weight.
- Weight gain.
- Equal leaderboard scores.
- Fewer than five winners.
- Invalid or mismatched Coach QR.
- Duplicate enrollment.
- Program capacity reached.
- Permission denied.
- Offline state.
- Repository failure.
- Session expiry.

## Dependency Rules

- Do not add third-party packages unless the user explicitly requests them.
- Do not add a package because it makes a small task more convenient.
- Prefer Apple frameworks.
- If a dependency is approved:
  - Pin a compatible version.
  - Commit `Package.resolved` when Git actions are explicitly authorized.
  - Document why native APIs were insufficient.
  - Keep the dependency behind an adapter.
- Do not add an analytics, logging, navigation, QR, image loading, dependency injection, or testing package without explicit approval.

## Completion Report

At the end of a coding task, report:

1. What changed.
2. Where each file was added or edited.
3. Build command and result.
4. Test command and result.
5. Any manual Xcode step required.
6. Any blocked external configuration.
7. The next unchecked item in the current phase.

Do not include a Git commit hash unless the user explicitly requested and authorized a commit.
