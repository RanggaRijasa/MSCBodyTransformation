# Checkpoint goal Phase 01–10

> Dibuat: 10 Agustus 2026
>
> Status goal: SELESAI LOKAL
>
> Write scope: hanya `MSCWeb/`

## Batas yang tetap berlaku

- Jangan menulis, memindahkan, atau menghapus proyek iOS, `Contracts/`,
  `supabase/` root, atau file lain di luar `MSCWeb/`.
- Hosted Supabase `main`, deployment, DNS, OAuth production, dan secrets belum
  disentuh.
- Supabase lokal boleh dipakai untuk gate; jangan menjalankan reset/destructive
  terhadap local stack tanpa approval eksplisit pengguna.
- Jangan menjalankan operasi Git mutating.

## Status phase

- Phase 00: selesai.
- Phase 01: selesai.
- Phase 02 dan 02A: selesai.
- Phase 03: selesai lokal.
- Phase 04: selesai lokal.
- Phase 05: selesai lokal; workplan, manifest, dan README sudah diperbarui.
- Phase 06: selesai lokal.
- Phase 07: selesai lokal; seluruh DoD dan gate lokal lulus.
- Phase 08: selesai lokal; seluruh DoD dan gate lokal lulus.
- Phase 09: selesai lokal; seluruh DoD dan gate lokal lulus.
- Phase 10: selesai lokal; seluruh DoD dan gate lokal lulus.

## Hasil terverifikasi terakhir

- `corepack pnpm verify`: PASS.
  - 33 file Vitest, 154 test PASS.
  - lint, typecheck, production build 39 halaman, architecture, localization,
    contract, privacy, dan bundle gate PASS.
- `corepack pnpm test:phase05:local`: PASS.
  - 49 pgTAP existing.
  - 12 assertion race/BOLA.
  - 4 Chromium E2E termasuk paid order handoff.
- `corepack pnpm test:gallery --update-snapshots`: PASS.
  - 30 check Chromium/WebKit + axe.
  - Baseline marketing Peserta dan Coach sudah dilihat manual dan layak.
- Gate Phase 06 terkini:
  - Supabase DB lint: PASS, tanpa schema error.
  - 37 pgTAP manual payment: PASS.
  - Integration atomicity/RLS/race/retention/expiry/renewal: PASS.
  - 3 Chromium E2E program dan Coach: PASS.
  - 14 gallery Chromium/WebKit + axe: PASS.
- Gate Phase 07 terkini:
  - Supabase DB lint: PASS, tanpa schema error.
  - 31 pgTAP, 15 assertion race/idempotensi, dan 16 assertion private-media:
    PASS.
  - Satu Chromium critical journey gabung hingga leaderboard: PASS.
  - Full gallery 16 Chromium/WebKit + axe: PASS.
- Gate Phase 08 terkini:
  - Supabase DB lint: PASS tanpa schema error.
  - 37 pgTAP, 15 assertion race/idempotensi, dan 16 assertion private-media:
    PASS.
  - Empat Chromium journey Coach: PASS.
  - Full gallery 20 Chromium/WebKit + axe: PASS.
  - `pnpm verify`: 30 file/138 Vitest, typecheck, build 37 halaman, privacy dan
    media bundle gate: PASS.
- Gate Phase 09 terkini:
  - Supabase DB lint: PASS tanpa schema error.
  - 53 pgTAP dan 13 unit/component fokus: PASS.
  - Enam Chromium journey Admin/payment: PASS.
  - Full gallery 26 Chromium/WebKit + axe: PASS.
  - `pnpm verify`: 32 file/145 Vitest, typecheck, build 39 halaman,
    architecture, privacy, dan media bundle gate: PASS.
- Gate Phase 10 terkini:
  - Supabase DB lint: PASS tanpa schema error.
  - 63 pgTAP, termasuk scoring/closure, manual-commerce publish, dan volume 250
    peserta: PASS.
  - 47 unit/component fokus dan tujuh regresi Chromium Phase 06/07/09: PASS.
  - Dua full cross-role journey Chromium/WebKit: PASS.
  - Full gallery 30 Chromium/WebKit + axe: PASS.
  - `pnpm verify`: 33 file/154 Vitest, typecheck, build 39 halaman,
    architecture, localization, contract, privacy, dan media bundle gate: PASS.

## Fresh migration gate Phase 06

Fresh local migration chain dijalankan setelah approval eksplisit dengan guard
hostname dan token:

```bash
cd /Users/ranggarijasa/Documents/MSCBodyTransformation/MSCWeb
ALLOW_LOCAL_DB_RESET=phase06 PATH="/opt/homebrew/opt/node@24/bin:$PATH" \
  corepack pnpm test:phase06:fresh-local
```

Hasil: PASS. Perintah menghapus data Supabase lokal, menjalankan ulang migration
root existing, lalu menerapkan migration Phase 06 dari `MSCWeb/`. Hosted
Supabase tidak disentuh. Gate Phase 06 kemudian diulang dan tetap lulus.

## Implementasi Phase 07–10 yang sudah ada

- Migration additive profil/avatar/perubahan Coach:
  `supabase/migrations/20260810100000_phase07_participant_experience.sql`.
- Home, program activity, typed content/questions, private photo upload,
  initial/daily/final weigh-in, ranking, Coach directory, dan profile.
- Shared program content preview untuk Participant serta konteks Coach/Admin.
- Submission idempotency, cancellation, multi-tab, review lifecycle, failed
  quiz, weight/privacy, dan QR-only Coach change telah diuji.
- Audit rinci: `docs/progress/PHASE_07_DOD_AUDIT.md`.
- Dashboard/roster/detail/review/activity/leaderboard/profile/QR Coach,
  Coach-as-Participant, entitlement/assignment RLS, answer key privat, dan
  migration additive Phase 08.
- Audit rinci: `docs/progress/PHASE_08_DOD_AUDIT.md`.
- Audit Admin rinci: `docs/progress/PHASE_09_DOD_AUDIT.md`.
- Audit scoring, leaderboard, closure, full journey, dan marketing capture:
  `docs/progress/PHASE_10_DOD_AUDIT.md`.

## Langkah berikutnya

Goal Phase 01–10 selesai lokal. Phase 11 belum dimulai dan tidak termasuk goal
ini. Deployment hosted, DNS, OAuth production, dan migration production tetap
gate Phase 12 yang memerlukan approval eksplisit.

## Catatan keamanan

- Tidak ada raw QR, bukti pembayaran, signed URL, rekening production,
  service key, token, atau credential yang ditulis dalam checkpoint ini.
- Fixture rekening dan identitas hanya data lokal deterministik/non-production.
- Test cleanup menargetkan UUID fixture sendiri dan memverifikasi hostname
  database lokal sebelum SQL cleanup.
