# Phase 04: Coach Experience UI

## Tujuan

Membangun seluruh coach-facing experience dengan mock wallet, mock programs, mock participants, local invites, dan review queue.

## External dependency status

**Lokal sepenuhnya.**

Tidak ada StoreKit transaction, Supabase, atau external QR redemption.

## Screen inventory

### Dashboard

- [x] Public coach identity.
- [x] Mock wallet seat balance.
- [x] Active programs.
- [x] Total assigned participants.
- [x] Completion metrics.
- [x] Missing step count.
- [x] Pending review count.
- [x] Quick actions.
- [x] Offline and error states.

### Participants

- [x] Participant list.
- [x] Search.
- [x] Filter by program.
- [x] Filter by completion status.
- [x] Filter by review status.
- [x] Sort by progress, points, dan last activity.
- [x] Participant row with progress.
- [x] Empty filter state.

### Participant detail

- [x] Profile summary.
- [x] Program and enrollment summary.
- [x] Initial/final weight availability.
- [x] Daily completion timeline.
- [x] Step submissions.
- [x] Evidence thumbnails.
- [x] Text answers.
- [x] Score breakdown.
- [x] Missing-step indicators.
- [x] Private-data warning and access context.

### Review queue

- [x] Pending submissions list.
- [x] Evidence viewer.
- [x] Step instruction context.
- [x] Approve action.
- [x] Reject action.
- [x] Rejection reason required.
- [x] Confirmation.
- [x] Updated local score after decision.
- [x] Undo is not required. Use a new explicit review action if allowed.

### Invite

- [x] Available program selector.
- [x] Mock seat balance.
- [x] Invite capacity.
- [x] Expiry configuration.
- [x] Generate local opaque token.
- [x] Generate QR image locally.
- [x] Share sheet for local invite.
- [x] Invite history.
- [x] Revoke local invite.
- [x] Exhausted and expired states.
- [x] Explain that production seat consumption happens only after successful enrollment.

### Coach store preview

This phase only builds UI and local product fixtures.

- [x] Seat pack cards: 10, 25, and 50.
- [x] Local sample price text.
- [x] Purchase CTA disabled or routed to demo confirmation.
- [x] Purchase state previews: loading, available, purchasing, pending, success, cancelled, error.
- [x] Purchase history mock.
- [x] Clear label that Debug demo does not perform a real purchase.
- [x] Do not instantiate live StoreKit transaction flow.

### Leaderboard

- [x] Program selector.
- [x] Top five.
- [x] Current coach participants marker.
- [x] Provisional and final states.
- [x] Score detail.

### Profile

- [x] Public coach profile editor UI.
- [x] Photo picker placeholder or local picker.
- [x] Bio.
- [x] Visibility status.
- [x] Purchase history mock.
- [x] Settings.

## Local behavior

- [x] Approve submission updates local participant points.
- [x] Reject requires reason and removes local awarded points.
- [x] Generate invite decrements nothing.
- [x] Local mock redemption consumes seat only after successful enrollment.
- [x] Duplicate enrollment consumes no additional seat.
- [x] Insufficient seat state blocks local redemption.
- [x] Coach cannot navigate to unrelated participant fixture.
- [x] Coach store demo can simulate successful credit grant through Debug-only action.

## State architecture

Pisahkan:

- Dashboard feature state.
- Participant list state.
- Participant detail state.
- Review queue state.
- Invite composer state.
- Store preview state.
- Coach profile state.

Jangan membuat satu `CoachViewModel` besar.

## Previews

- [x] Coach dashboard normal.
- [x] Wallet zero.
- [x] Pending review.
- [x] No participants.
- [x] Participant complete.
- [x] Participant falling behind.
- [x] Evidence rejected.
- [x] Invite active.
- [x] Invite exhausted.
- [x] Purchase success preview.
- [x] Largest Dynamic Type.
- [x] Dark mode.

## Tests

### Swift Testing

- [x] Coach filters.
- [x] Review decision validation.
- [x] Rejection reason required.
- [x] Local score recalc.
- [x] Invite capacity.
- [x] Duplicate local enrollment.
- [x] Wallet cannot become negative in mock.
- [x] Unrelated participant access is blocked by mock repository contract.

### UI tests

- [x] Launch as coach.
- [x] Open participant detail.
- [x] Open evidence.
- [x] Approve submission.
- [x] Generate local invite QR.
- [x] Open store preview.
- [x] Verify no real purchase prompt occurs.

## Larangan scope

Jangan:

- Mengakses App Store Connect.
- Membuat live purchase.
- Menganggap mock access check sebagai pengganti RLS.
- Mengunggah coach profile ke server.
- Menyimpan transaction id palsu sebagai production model.
- Menambahkan service secrets.

## Exit criteria

- [x] Coach journey dapat didemokan tanpa internet.
- [x] Review action mengubah local score.
- [x] Invite dan QR dapat dibuat lokal.
- [x] Store UI lengkap tetapi tidak melakukan transaksi live.
- [x] Coach hanya melihat assigned participant fixtures.
- [x] Test lulus dan clean build.

## Progress log

### Log

#### 2026-07-26 — Phase 04 selesai

- Files changed: feature state terpisah untuk dashboard, peserta, detail,
  review queue, invite composer, store preview, leaderboard, dan profil;
  layar Coach lengkap; generator QR Core Image; app-shell routing; repository
  mock untuk save profil, revoke invite, access check, pemakaian dan grant
  kuota; localization; preview matrix; Swift Testing dan XCTest UI.
- Assumptions: bukti media tetap berupa placeholder lokal dan tidak
  menampilkan path privat; harga paket adalah fixture rupiah lokal; QR memuat
  deep link `mscbody://invite/` yang hanya digunakan demo; mock access check
  tidak dianggap sebagai pengganti RLS. Tidak ada StoreKit, Supabase, OAuth,
  networking, package baru, atau perubahan `project.pbxproj`.
- Build command: XcodeBuildMCP `build_run_sim(launchArgs:
  ["-DemoRole", "coach", "-DemoScenario", "coach_review_queue",
  "-SkipDemoLanding"])` pada iPhone 17 Pro dan iPad Pro 13-inch;
  `build_sim()` untuk konfigurasi Debug dan Release dengan
  `SWIFT_VERSION=6`, `SWIFT_STRICT_CONCURRENCY=complete`, dan
  `IPHONEOS_DEPLOYMENT_TARGET=17.0`.
- Test command: XcodeBuildMCP `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationTests/Phase04CoachTests"])`,
  `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testCoachCompletesCriticalLocalJourney"])`,
  dan `test_sim()` untuk seluruh scheme.
- Result: sepuluh test Phase 04 serta UI journey Coach lulus; seluruh 46 test,
  build Debug iPhone/iPad, dan build Release lulus tanpa warning. Dashboard
  diverifikasi di dark mode dan accessibility Dynamic Type terbesar; grid
  berubah menjadi satu kolom agar teks tidak terpotong.
- Remaining blockers: tidak ada blocker lokal. Media production, backend/RLS,
  dan transaksi StoreKit tetap ditunda ke phase yang ditetapkan.
