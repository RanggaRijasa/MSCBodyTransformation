# Phase 08: Coach Experience

> Status: SELESAI LOKAL

## Tujuan

Memport dashboard, roster, attention, participant detail, review queue,
activity, leaderboard, profile, QR, dan Coach-as-Participant dengan privacy
boundary yang sama atau lebih ketat.

## Slice 08.1 — Dashboard dan program

- [x] Identity, active period/expiry, metrics, active programs, review count,
  participant attention, activity, leaderboard, QR quick actions.
- [x] `Peserta saya` memuat attention count; jangan buat duplicate quick action.
- [x] Expired/inactive/pending Coach melihat actionable locked state tanpa
  kehilangan Participant access.
- [x] Coach dapat mengikuti program sebagai Participant melalui shared
  participant renderer/context, bukan duplicate implementation.

## Slice 08.2 — Roster/attention

- [x] Search/filter/sort stable and server-scoped.
- [x] Status `Belum terdaftar`, `Belum mulai`, `Tertinggal` dibedakan dengan
  text/icon, bukan warna saja.
- [x] Coach hanya melihat participant yang authoritative assigned.
- [x] No weight/evidence preview pada roster.

## Slice 08.3 — Participant detail privat

- [x] Identity, enrollment/program progress, score breakdown, steps,
  submissions, answers, and authorized evidence.
- [x] Riwayat berat awal/harian/akhir kronologis hanya di detail privat.
- [x] Program switch dan historical Coach snapshot rules teruji.
- [x] Signed media access short-lived/no-cache dan tidak bocor antarparticipant.

## Slice 08.4 — Review queue

- [x] Pending queue dengan filter program/type/time.
- [x] Detail answer, photo, answer key hanya sesuai permission.
- [x] Approve/reject idempoten; rejection wajib alasan; optional rating sesuai
  existing contract bila masih berlaku.
- [x] Duplicate reviewer/race/retry/stale submission/reopened attempt handled.
- [x] Score reconciliation exactly once setelah approval.

## Slice 08.5 — Activity/leaderboard

- [x] Activity default hari ini; explicit 7/30 days atau previous activity.
- [x] Feed tidak menampilkan weight atau evidence image.
- [x] Leaderboard program-scoped dan public-safe fields only.
- [x] Filter memakai shared pattern dari design system.

## Slice 08.6 — Profile dan QR

- [x] Public profile, bio, visibility, avatar, legal, logout/delete.
- [x] QR stable/opaque, display/share fallback aman, no raw identifier copy.
- [x] Expiry/renewal/payment status via manual commerce.
- [x] Pending/rejected application tetap Participant.

## Verification

- [x] Port relevant Phase04 Coach tests dan contract cases.
- [x] Integration RLS/assignment/history/review/idempotency/score tests.
- [x] E2E Dashboard -> roster -> detail -> approve/reject -> score; expiry and
  renewal; QR enrollment; Coach participates as Participant.
- [x] Negative access: other Coach, Guest, Participant, expired Coach.
- [x] Weight/photo feed leakage and cache/log scans.
- [x] Mobile/desktop responsive, keyboard, screen reader, WebKit/Chromium.
- [x] Lint, typecheck, test, build lulus.

## Definition of done

- Coach capability lengkap dan role-scoped.
- Feed/list/public routes tidak membocorkan weight/evidence.
- Review exactly-once and auditable.
- Coach expiry tidak mencabut Participant base account.
- Feature terpecah per dashboard/roster/review/activity/profile/QR.

## External gate

Migration Phase 08 hanya diterapkan dan diuji pada Supabase lokal. Hosted
`main`, secrets, OAuth production, DNS, dan deployment tidak disentuh; seluruh
gate tersebut tetap berada pada Phase 12 dan memerlukan persetujuan eksplisit.

## Progress log

### 10 Agustus 2026 — selesai lokal

- Files changed: domain/use case/repository Coach, route dashboard/roster/
  detail/review/program/profile/QR, migration additive capability Coach-as-
  Participant, privacy scan, gallery, serta unit/component/pgTAP/E2E.
- Assumptions: assignment, entitlement, review, scoring, answer key, dan media
  tetap server-authoritative; hosted `main` dan seluruh path di luar `MSCWeb/`
  tetap read-only.
- Build command:
  `PATH="/opt/homebrew/opt/node@24/bin:$PATH" corepack pnpm verify`.
- Test commands:
  `PATH="/opt/homebrew/opt/node@24/bin:$PATH" corepack pnpm test:phase08:local`
  dan `PATH="/opt/homebrew/opt/node@24/bin:$PATH" corepack pnpm test:gallery`.
- Result: PASS — DB lint; 37 pgTAP; 15 assertion race; 16 assertion Storage;
  empat Chromium journey; 20 gallery Chromium/WebKit + axe; 30 file/138
  Vitest; lint, typecheck, production build 37 halaman, dan bundle gate.
- Remaining blockers: tidak ada untuk gate lokal. Deployment hosted tetap
  Phase 12 sesuai workplan.
