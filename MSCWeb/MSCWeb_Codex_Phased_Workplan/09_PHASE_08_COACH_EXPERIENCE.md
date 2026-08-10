# Phase 08: Coach Experience

> Status: BELUM DIMULAI

## Tujuan

Memport dashboard, roster, attention, participant detail, review queue,
activity, leaderboard, profile, QR, dan Coach-as-Participant dengan privacy
boundary yang sama atau lebih ketat.

## Slice 08.1 — Dashboard dan program

- [ ] Identity, active period/expiry, metrics, active programs, review count,
  participant attention, activity, leaderboard, QR quick actions.
- [ ] `Peserta saya` memuat attention count; jangan buat duplicate quick action.
- [ ] Expired/inactive/pending Coach melihat actionable locked state tanpa
  kehilangan Participant access.
- [ ] Coach dapat mengikuti program sebagai Participant melalui shared
  participant renderer/context, bukan duplicate implementation.

## Slice 08.2 — Roster/attention

- [ ] Search/filter/sort stable and server-scoped.
- [ ] Status `Belum terdaftar`, `Belum mulai`, `Tertinggal` dibedakan dengan
  text/icon, bukan warna saja.
- [ ] Coach hanya melihat participant yang authoritative assigned.
- [ ] No weight/evidence preview pada roster.

## Slice 08.3 — Participant detail privat

- [ ] Identity, enrollment/program progress, score breakdown, steps,
  submissions, answers, and authorized evidence.
- [ ] Riwayat berat awal/harian/akhir kronologis hanya di detail privat.
- [ ] Program switch dan historical Coach snapshot rules teruji.
- [ ] Signed media access short-lived/no-cache dan tidak bocor antarparticipant.

## Slice 08.4 — Review queue

- [ ] Pending queue dengan filter program/type/time.
- [ ] Detail answer, photo, answer key hanya sesuai permission.
- [ ] Approve/reject idempoten; rejection wajib alasan; optional rating sesuai
  existing contract bila masih berlaku.
- [ ] Duplicate reviewer/race/retry/stale submission/reopened attempt handled.
- [ ] Score reconciliation exactly once setelah approval.

## Slice 08.5 — Activity/leaderboard

- [ ] Activity default hari ini; explicit 7/30 days atau previous activity.
- [ ] Feed tidak menampilkan weight atau evidence image.
- [ ] Leaderboard program-scoped dan public-safe fields only.
- [ ] Filter memakai shared pattern dari design system.

## Slice 08.6 — Profile dan QR

- [ ] Public profile, bio, visibility, avatar, legal, logout/delete.
- [ ] QR stable/opaque, display/share fallback aman, no raw identifier copy.
- [ ] Expiry/renewal/payment status via manual commerce.
- [ ] Pending/rejected application tetap Participant.

## Verification

- [ ] Port relevant Phase04 Coach tests dan contract cases.
- [ ] Integration RLS/assignment/history/review/idempotency/score tests.
- [ ] E2E Dashboard -> roster -> detail -> approve/reject -> score; expiry and
  renewal; QR enrollment; Coach participates as Participant.
- [ ] Negative access: other Coach, Guest, Participant, expired Coach.
- [ ] Weight/photo feed leakage and cache/log scans.
- [ ] Mobile/desktop responsive, keyboard, screen reader, WebKit/Chromium.
- [ ] Lint, typecheck, test, build lulus.

## Definition of done

- Coach capability lengkap dan role-scoped.
- Feed/list/public routes tidak membocorkan weight/evidence.
- Review exactly-once and auditable.
- Coach expiry tidak mencabut Participant base account.
- Feature terpecah per dashboard/roster/review/activity/profile/QR.

