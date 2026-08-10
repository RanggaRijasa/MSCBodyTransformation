# iOS to Web Test Mapping

> Baseline source: 18 Swift Testing files/194 test declarations dan 3 XCUI
> files/52 test methods. Phase 00 memetakan coverage; harness dibuat Phase 01.

## Fixture strategy

- Domain fixtures TypeScript deterministic memakai UUID, clock, timezone, dan
  locale tetap; tidak menyalin fixture Swift sebagai blob besar.
- Contract fixtures dibuat dari published program schema dan DTO public/private
  yang sama, dengan golden payload hanya untuk boundary stabil.
- Repository integration memakai Supabase lokal fresh/migration-equivalent,
  bukan hosted `main` dan bukan silent fallback mock.
- E2E memakai seed khusus test yang idempotent, scoped, dan tidak memuat media
  atau PII nyata.
- Media fixture kecil disimpan di `tests/fixtures` dan tidak pernah tersedia
  sebagai tombol upload pada UI.
- Browser clock, ID, network failure, permission, role, dan program timezone
  dapat diinjeksi atau dikontrol oleh test harness.

## Swift Testing mapping

| Source suite | Target web | Coverage yang dipertahankan |
|---|---|---|
| `MSCBodyTransformationTests.swift` | `tests/unit/shared/app-configuration.test.ts` | locale id-ID, clock dan ID deterministic |
| `Phase01DomainRuleTests.swift` | `tests/unit/domain/program-rules.test.ts` | progress duplicate/rejected, day access, no negative weight points, errors |
| `Phase01FixtureTests.swift` | `tests/contract/fixture-compatibility.test.ts` | load/invalid fixture, Decimal, enum raw values |
| `Phase01RepositoryTests.swift` | `tests/integration/repositories/idempotency.test.ts` | duplicate enrollment, concurrent completion, deterministic scenarios |
| `Phase02NavigationTests.swift` | `tests/component/navigation/role-routes.test.tsx` | role routes, isolated tab history, reduced motion, status semantics |
| `Phase03ParticipantTests.swift` | `tests/unit/participant` + `tests/integration/participant` | today, answers, weight locale, day access, enrollment cutoff, points |
| `Phase04CoachTests.swift` | `tests/unit/coach` + `tests/integration/coach` | roster/filter/feed/privacy/review/idempotency/assignment |
| `Phase05AdminCMSTests.swift` | `tests/unit/admin-programs` + component | validation, schedules, content IDs, publish, manual enrollment, winners |
| `Phase06NativeMediaTests.swift` | `tests/unit/media` + browser integration | resize, MIME/size, metadata, opaque QR, required photo, cleanup |
| `Phase07LocalScoringTests.swift` | `tests/unit/domain/scoring.test.ts` | Decimal, breakdown, tie-break, <5 winners, timezone |
| `Phase08AccessibilityReliabilityTests.swift` | `tests/accessibility/state-presentation.test.tsx` | explicit scenarios, icons + labels, errors, recovery |
| `Phase095GuestAuthCoachApplicationTests.swift` | `tests/unit/auth-coach-application` | Guest privacy, eligibility/pricing, no self-promotion, 3-month access |
| `Phase09SupabaseFoundationTests.swift` | `tests/integration/supabase-adapters` | DTO privacy, RPC contract, idempotency, durable media, typed errors |
| `Phase10AuthenticationTests.swift` | `tests/unit/auth` + contract | provider identity, config fail-closed, PKCE/state/TTL, secure storage boundary |
| `Phase11PublicGuestReadsTests.swift` | `tests/integration/public-reads.test.ts` | no bearer/user identity, public DTO, fixed RPC |
| `Phase11AuthenticatedReadsTests.swift` | `tests/integration/authenticated-reads.test.ts` | bearer/cookie boundary, lossless DTO, unknown enum rejection |
| `Phase12StoreKitCommerceTests.swift` | legacy contract tests + manual payment replacement | preserve recovery/idempotency intent; replace StoreKit UI with evidence flow |
| `ProgramEndToEndContractTests.swift` | `tests/contract/program-e2e-contract.test.ts` | lossless mapping, all content/questions, quiz, Coach guard, closure, audit |

StoreKit-specific adapter behavior tetap menjadi legacy iOS evidence dan tidak
diport. Business invariants—opaque intent, verification sebelum entitlement,
idempotency, recovery, refund/reversal—dipetakan ke manual commerce tests.

## XCUI mapping

| Source | Target Playwright/component | Journey groups |
|---|---|---|
| `MSCBodyTransformationUITests.swift` | `tests/e2e/participant`, `coach`, `admin`, `accessibility` | shell/navigation, public privacy, Participant journey, Coach review, Admin CMS/closure, dark/Dynamic Type equivalent, offline/error |
| `Phase095GuestAuthUITests.swift` | `tests/e2e/guest-auth-coach-application.spec.ts` | OAuth-first auth, safe pending intent, no personal Guest data, Coach eligibility/payment states |
| `MSCBodyTransformationUITestsLaunchTests.swift` | smoke projects per browser | app boot, route boundary, no localization key |

XCUI gestures diadaptasi ke browser history/focus semantics. Fixed header,
swipe-to-delete, native photo picker, dan leading-edge back tidak disalin
literal; target web menguji hasil interaction dan accessibility yang setara.

## Mandatory web edge cases

| Area | Cases |
|---|---|
| Program | no active program, empty steps, locked/hidden/available day, cutoff exact boundary, full capacity, duplicate enrollment |
| Submission | missing photo/answer, pending, rejected + resubmit history, duplicate submit, repository failure |
| Quiz | missing answer, exact threshold, failed, second attempt, Admin reopen, no answer-key leak |
| Weigh-in | missing final, final-before-initial, daily duplicate, weight gain, Decimal fraction, correction reason |
| Scoring | pending gets no points, duplicate approval, adjustment separate, equal score, fewer than five winners, immutable lock |
| Coach | invalid/mismatched QR, different assignment denied, empty review queue, activity hides weight/photo |
| Auth | Guest no identity, expired session, invalid/replayed callback, pending-intent TTL/environment, role fail-closed |
| Media | permission denied, unavailable camera, MIME spoof, oversize, orientation, metadata removal, upload retry/orphan |
| Manual payment | expiry, evidence-before-expiry hold, late transfer full/available, 3 attempts, duplicate approval, reversal, retention |
| PWA | offline, stale update, logout/account switch, standalone, private no-cache |
| Accessibility | keyboard, focus restore, 200% zoom, dark, contrast, reduced motion, status without color |

## Browser and device targets

- Desktop Chromium runs in CI from Phase 01 onward for stable E2E.
- Safari iOS and Chrome Android are required manual/automated device gates in
  Phase 04/11/13 for camera, picker, PWA install, standalone, and lifecycle.
- Browser-specific failures do not boleh ditutup dengan test skip permanen;
  gunakan capability detection dan explicit unavailable state.

## Exit rule per migrated test

Test dapat dianggap dipetakan selesai bila target path, deterministic fixture,
expected authority, privacy assertion, dan layer test sudah jelas. Test baru
dianggap implemented hanya setelah harness tersedia dan command lulus; dokumen
ini tidak mengklaim web tests sudah berjalan pada Phase 00.
