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

- [ ] `StepScoreCalculator`
- [ ] `WeightScoreCalculator`
- [ ] `EnrollmentScoreCalculator`
- [ ] `ProgressCalculator`
- [ ] `ProgramDayResolver`
- [ ] `VisibilityPolicyEvaluator`
- [ ] `LeaderboardSorter`
- [ ] `WinnerSelector`

Semua service harus deterministic dan mudah diuji.

## Step scoring rules

- [ ] Approved submission mendapat published step points.
- [ ] Pending submission mendapat zero authoritative points.
- [ ] Rejected submission mendapat zero points.
- [ ] Duplicate submission tidak menggandakan poin.
- [ ] Optional step dapat memberi poin bila completed.
- [ ] Inactive step tidak dihitung.
- [ ] Client input points tidak pernah diterima sebagai source.
- [ ] Local mock mengambil points dari fixture `ProgramStep`.

## Weight scoring rules

- [ ] Initial dan final weight memakai `Decimal`.
- [ ] Weight loss negatif menjadi zero points.
- [ ] Multiplier harus positif.
- [ ] Rounding rule didokumentasikan dan konsisten.
- [ ] Missing final weight menghasilkan zero weight points dan incomplete state.
- [ ] Weight values tidak ditampilkan pada public leaderboard.
- [ ] Admin adjustment dipisahkan dari weight points.

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

- [ ] Current user rank.
- [ ] Top five emphasis.
- [ ] Full ranking.
- [ ] Provisional state while scoring open.
- [ ] Final locked snapshot.
- [ ] Participant display name privacy decision.
- [ ] Placeholder avatar.
- [ ] Equal score tie presentation.
- [ ] Ranking remains deterministic.
- [ ] Winner banner integration with local content.

## Winner lock local simulation

- [ ] Admin can preview top five.
- [ ] Confirmation required.
- [ ] Create local immutable winner snapshot.
- [ ] Later mock score changes do not silently alter locked winners.
- [ ] Display warning when scores change after lock.
- [ ] Reset available only in Debug fixture tooling.

## Time and visibility simulation

- [ ] Store sample program timezone as IANA identifier.
- [ ] Use injected clock.
- [ ] Resolve active day using program timezone.
- [ ] Past policy: hidden, read-only, open.
- [ ] Future policy: hidden, read-only, open.
- [ ] Device date override for Debug.
- [ ] Do not hard-code Asia/Makassar in service; use program value.

## Test matrix

### Weight

- [ ] 80.0 to 79.9.
- [ ] 80.0 to 79.0.
- [ ] No loss.
- [ ] Weight gain.
- [ ] Decimal precision.
- [ ] Custom multiplier.
- [ ] Missing final.

### Step

- [ ] All approved.
- [ ] Pending.
- [ ] Rejected.
- [ ] Mixed.
- [ ] Duplicate completion.
- [ ] Optional step.
- [ ] Zero-point step.
- [ ] Invalid negative point fixture rejected.

### Ranking

- [ ] Different total points.
- [ ] Same total, different step points.
- [ ] Same step points, different weight points.
- [ ] Same points, different completion time.
- [ ] Fully equal values use deterministic UUID.
- [ ] Top five with fewer than five participants.
- [ ] Winner lock stability.

### Time

- [ ] Program timezone differs from device.
- [ ] Day boundary.
- [ ] Daylight-saving timezone fixture.
- [ ] Before start.
- [ ] After end.
- [ ] Hidden future day.
- [ ] Read-only past day.

## UI integration

- [ ] Participant score updates after local completion.
- [ ] Coach review updates ranking.
- [ ] Final weigh-in updates weight points.
- [ ] Admin adjustment updates total but remains separate.
- [ ] Leaderboard animates gently and respects Reduce Motion.
- [ ] Do not show fake "server verified" label in local demo.

## Larangan scope

Jangan:

- Menyebut local score production-authoritative.
- Mengirim score ke backend.
- Menggunakan `Double` untuk canonical weight logic.
- Menampilkan private weight on leaderboard.
- Mengubah winner snapshot silently.
- Mengandalkan device clock tanpa injected program timezone logic.

## Exit criteria

- [ ] Domain scoring tests lengkap dan lulus.
- [ ] Leaderboard deterministic.
- [ ] Participant, coach, dan admin UI menggunakan service yang sama.
- [ ] Local winner lock bekerja.
- [ ] Scoring specification siap diterjemahkan ke server operation.
- [ ] Clean build.

## Progress log

### Log
