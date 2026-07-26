# Phase 07: Local Scoring, Progress, and Leaderboard Simulation

## Tujuan

Mengimplementasikan aturan domain scoring dan leaderboard secara lokal agar UI dapat diuji. Implementasi ini menjadi executable specification untuk backend, tetapi bukan authoritative production source.

## External dependency status

**Lokal sepenuhnya.**

## Formula MVP

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

Default:

```text
weight_points_per_kg = 800
```

Ini mewakili 80 poin per 0,1 kg dan harus dapat dikonfigurasi per program.

## Domain services

Buat pure services:

- [x] `StepScoreCalculator`
- [x] `WeightScoreCalculator`
- [x] `EnrollmentScoreCalculator`
- [x] `ProgressCalculator`
- [x] `ProgramDayResolver`
- [x] `VisibilityPolicyEvaluator`
- [x] `LeaderboardSorter`
- [x] `WinnerSelector`

Semua service harus deterministic dan mudah diuji.

## Step scoring rules

- [x] Approved submission mendapat published step points.
- [x] Pending submission mendapat zero authoritative points.
- [x] Rejected submission mendapat zero points.
- [x] Duplicate submission tidak menggandakan poin.
- [x] Optional step dapat memberi poin bila completed.
- [x] Inactive step tidak dihitung.
- [x] Client input points tidak pernah diterima sebagai source.
- [x] Local mock mengambil points dari fixture `ProgramStep`.

## Weight scoring rules

- [x] Initial dan final weight memakai `Decimal`.
- [x] Weight loss negatif menjadi zero points.
- [x] Multiplier harus positif.
- [x] Rounding rule didokumentasikan dan konsisten.
- [x] Missing final weight menghasilkan zero weight points dan incomplete state.
- [x] Weight values tidak ditampilkan pada public leaderboard.
- [x] Admin adjustment dipisahkan dari weight points.

## Progress rules

Definisikan dengan jelas:

- Required step count.
- Completed required step count.
- Pending review behavior.
- Rejected step behavior.
- Optional step behavior.
- Overall program completion.
- Current day completion.

Jangan menyamakan progress dengan total points.

## Tie-break order

1. Total points descending.
2. Approved step points descending.
3. Weight points descending.
4. Completion timestamp ascending.
5. Enrollment UUID stable order sebagai final deterministic fallback.

## Leaderboard behavior

- [x] Current user rank.
- [x] Top five emphasis.
- [x] Full ranking.
- [x] Provisional state while scoring open.
- [x] Final locked snapshot.
- [x] Participant display name privacy decision.
- [x] Placeholder avatar.
- [x] Equal score tie presentation.
- [x] Ranking remains deterministic.
- [x] Winner banner integration with local content.

## Winner lock local simulation

- [x] Admin can preview top five.
- [x] Confirmation required.
- [x] Create local immutable winner snapshot.
- [x] Later mock score changes do not silently alter locked winners.
- [x] Display warning when scores change after lock.
- [x] Reset available only in Debug fixture tooling.

## Time and visibility simulation

- [x] Store sample program timezone as IANA identifier.
- [x] Use injected clock.
- [x] Resolve active day using program timezone.
- [x] Past policy: hidden, read-only, open.
- [x] Future policy: hidden, read-only, open.
- [x] Device date override for Debug.
- [x] Do not hard-code Asia/Makassar in service; use program value.

## Test matrix

### Weight

- [x] 80.0 to 79.9.
- [x] 80.0 to 79.0.
- [x] No loss.
- [x] Weight gain.
- [x] Decimal precision.
- [x] Custom multiplier.
- [x] Missing final.

### Step

- [x] All approved.
- [x] Pending.
- [x] Rejected.
- [x] Mixed.
- [x] Duplicate completion.
- [x] Optional step.
- [x] Zero-point step.
- [x] Invalid negative point fixture rejected.

### Ranking

- [x] Different total points.
- [x] Same total, different step points.
- [x] Same step points, different weight points.
- [x] Same points, different completion time.
- [x] Fully equal values use deterministic UUID.
- [x] Top five with fewer than five participants.
- [x] Winner lock stability.

### Time

- [x] Program timezone differs from device.
- [x] Day boundary.
- [x] Daylight-saving timezone fixture.
- [x] Before start.
- [x] After end.
- [x] Hidden future day.
- [x] Read-only past day.

## UI integration

- [x] Participant score updates after local completion.
- [x] Coach review updates ranking.
- [x] Final weigh-in updates weight points.
- [x] Admin adjustment updates total but remains separate.
- [x] Leaderboard animates gently and respects Reduce Motion.
- [x] Do not show fake "server verified" label in local demo.

## Larangan scope

Jangan:

- Menyebut local score production-authoritative.
- Mengirim score ke backend.
- Menggunakan `Double` untuk canonical weight logic.
- Menampilkan private weight on leaderboard.
- Mengubah winner snapshot silently.
- Mengandalkan device clock tanpa injected program timezone logic.

## Exit criteria

- [x] Domain scoring tests lengkap dan lulus.
- [x] Leaderboard deterministic.
- [x] Participant, coach, dan admin UI menggunakan service yang sama.
- [x] Local winner lock bekerja.
- [x] Scoring specification siap diterjemahkan ke server operation.
- [x] Clean build.

## Progress log

### Log

#### 2026-07-26 — Scoring, progress, ranking, dan winner lock lokal

- Files changed: service scoring domain, adapter aturan program, repository
  in-memory, use case hari aktif, Participant store dan leaderboard, Admin
  winner management, fixture multiplier, test scoring, dan UI test.
- Assumptions: semua `ProgramStep` yang masuk ke program terbit dianggap
  langkah aktif; Admin draft menyaring `isActive == false` sebelum menjadi
  `Program`. Nama peserta pada leaderboard adalah nama tampilan publik.
- Build command:
  `xcodebuild -project MSCBodyTransformation.xcodeproj -scheme MSCBodyTransformation -configuration Debug -destination 'platform=iOS Simulator,id=C63135B7-AF6A-42C0-8993-DF4C72589FE1' SWIFT_VERSION=6 SWIFT_STRICT_CONCURRENCY=complete IPHONEOS_DEPLOYMENT_TARGET=17.0 build`.
- Test command: seluruh target Swift Testing, UI winner lock/adjustment, dan
  journey Coach.
- Result: 16/16 test fokus Phase 07 lulus; seluruh 76 unit test lulus; UI
  lock snapshot dan journey Coach lulus; build bersih tanpa warning.
- Remaining blockers: score lokal adalah executable specification dan belum
  authoritative sampai diterjemahkan ke operation server pada fase backend.
