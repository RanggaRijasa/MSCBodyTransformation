# Phase 00 Capability and State Parity Matrix

Parity berarti perilaku, authorization, privacy, state, dan acceptance setara
atau lebih ketat; bukan translasi Swift baris demi baris. Route detail tetap
dibekukan di [Routes and Roles](./ROUTES_AND_ROLES.md).

## Guest dan public surface

| Capability | Route web | State wajib | Source reference | Adaptasi web |
|---|---|---|---|---|
| Landing | `/` | session-aware CTA, unavailable/error aman | Keputusan WEB-014/landing design | Halaman marketing sebelum app shell |
| Participant shell public | `/hari-ini`, `/program`, `/peringkat`, `/coach` | logged out, public loading/empty/error/offline | AppShell + Guest tests | Bottom nav PWA; tidak ada fixture personal |
| Program catalog/detail | `/program`, `/program/[programId]` | available, closed, scheduled, active, completed, capacity full | Participant program UI/domain | Server-render public-safe response |
| Public leaderboard | `/peringkat` | no program, equal score, fewer than five, final snapshot | scoring/leaderboard tests | Tidak ada weight/private identifiers |
| Winner poster | Home/public reads | empty, published, historical | managed content/winner tests | Responsive image; cache hanya public asset |
| Coach directory/profile | `/coach`, `/coach/[coachId]` | approved visible, empty/error | Coach directory tests | Public identifier, bukan raw QR |
| Auth gate | `/masuk`, `/daftar`, callback | cancel, invalid callback, expired intent, retry | Auth tests | Google + feature-gated email; Apple tidak diport |

Guest tetap logged-out state, bukan role atau anonymous Supabase identity.

## Peserta

| Capability | Route | State/edge wajib | Authority |
|---|---|---|---|
| Hari ini/fokus | `/hari-ini` | no active program, before/after dates, multi-program focus, timezone boundary | Server day access + enrollment context |
| Katalog enrollment | `/program` | Diikuti/Tersedia/Riwayat, cutoff, full, duplicate, repository error | Public read + server enrollment operation |
| QR Coach preflight | `/program/[id]/gabung` | denied/unavailable camera, invalid/mismatched QR, same Coach, expired pending intent | Protected QR resolver; no typed fallback |
| Manual payment | `/pembayaran/[paymentId]` | awaiting, upload, under review, correction, approved, expired, reversal message | Payment operations/ledger; browser is not authoritative |
| Program activity | `/program/[id]` | loading, empty day, hidden/locked/available/read-only, today focus | Server-resolved day access |
| Article/video/form | `/program/[id]/langkah/[stepId]` | resume, threshold, missing answer, retry, duplicate submit | Protected submission operation |
| Quiz | same | all required, one attempt, exact threshold, failed, Admin reopen | Server score; answer key never in Participant DTO |
| Photo answer | same | gallery/camera, denial, invalid MIME/size, retry/orphan cleanup | Private Storage + durable submission |
| Weigh-in | same | initial/daily/final, final missing, final before initial, gain, Decimal | Protected weigh-in + score operation |
| Profile | `/profil`, `/profil/edit` | avatar fallback, edit validation, read-only email, session expiry | Own-profile projection |
| Ganti Coach | `/profil/ganti-coach` | valid QR, mismatch, confirmation, server conflict | Admin transfer remains authoritative; no raw code |
| Account deletion | `/akun/hapus` | reauth, cancel, failure, cleanup/retention | Edge Function + server audit |

## Coach

| Capability | Route | State/edge wajib | Privacy boundary |
|---|---|---|---|
| Dashboard | `/coach-area` | empty roster, metrics error, program filter | Assigned participants only |
| Peserta saya | `/coach-area/peserta` | Belum terdaftar/Belum mulai/Tertinggal, search/filter, history | Current Coach assignment |
| Detail peserta | `/coach-area/peserta/[id]` | loading/not found, progress, submission, chronological weights | Weight only on private detail |
| Pemeriksaan | `/coach-area/pemeriksaan` | empty/pending/error/filter/retry | No participant outside assignment |
| Review detail | `/coach-area/pemeriksaan/[id]` | auto/manual evidence, answer key, approve/reject conflict/idempotency | Private image short-lived; reason required |
| Aktivitas | `/coach-area/aktivitas` | today default, 7/30 days, empty | Never include evidence image or weight |
| Peringkat | `/coach-area/peringkat` | related programs, ties/history | Public-safe scores plus assignment marker |
| QR Coach | `/coach-area/qr` | render/error/offline | Opaque payload; no copy raw identifier |
| Profil | `/coach-area/profil` | edit public fields/error | Own-profile operation |
| Pengajuan/renewal | `/pengajuan-coach` | eligibility, accepted pending payment, payment review, active/expired/rejected | Application/payment/role/access separate |

## Admin

| Capability | Route | State/edge wajib | Operation rule |
|---|---|---|---|
| Dashboard/audit | `/admin`, `/admin/audit` | empty, attention, error, pagination | Admin claim + audited reads |
| Payment queue | `/admin/pembayaran` | approaching start, pending, correction, expired, reversal | No evidence in logs/cache |
| Payment decision | `/admin/pembayaran/[id]` | concurrent decision, wrong amount/account, late/full, duplicate | Protected idempotent operation + reason |
| Programs | `/admin/program` | draft/scheduled/active/completed/archived, search | Server lifecycle |
| Draft/settings | `/admin/program/baru`, `/admin/program/[id]/pengaturan` | invalid dates, cutoff, capacity, price/scoring lock | Protected save/publish |
| Content builder | `/admin/program/[id]/konten` | all content/question types, invalid answer key, copy day conflict | Lossless published contract |
| Preview | `/admin/program/[id]/pratinjau` | Participant/Coach mode | Reuse runtime renderer; wrapper only differs |
| Closure/winners | program hub | pending review, missing final weight, failed quiz, <5 winners, stable lock | Server snapshot immutable |
| People | `/admin/orang`, `/admin/orang/[id]` | role segments, profile variants, Coach transfer/manual enrollment | Reason + lifecycle/capacity/payment guard |
| Managed content | `/admin/konten` | empty gallery, image required, reorder/publish error | Poster tied to program + winner snapshot |

## Cross-cutting state matrix

Setiap capability hanya mengimplementasikan state yang relevan, tetapi tidak
boleh silently drop state dari baris berikut.

| State | UI expectation | Test layer |
|---|---|---|
| Loading | Skeleton/progress tanpa stale private data | Component |
| Empty | Penjelasan Bahasa Indonesia + next action bila ada | Component/E2E |
| Validation | Field-linked actionable error | Unit/component |
| Authorization | Generic denial/redirect tanpa resource existence leak | Integration/E2E |
| Conflict/idempotency | Safe retry, tidak menggandakan mutation | Integration |
| Offline/timeout | Tidak mengaku mutation berhasil | Component/E2E |
| Permission denied | Actionable camera/photo state; no typed fallback | Device/E2E |
| Session expiry | Kembali ke login dan preserve only safe pending intent | Integration/E2E |
| Unknown server enum | Fail closed, telemetry allowlist, no fallback value | Contract |
| Dark/contrast/reduced motion | Semantik tetap jelas tanpa warna/animasi | Accessibility |

## Deliberate platform adaptations

| iOS | Web/PWA | Acceptance |
|---|---|---|
| NavigationStack/sheet | URL history, dialog/bottom sheet, browser back | Focus restored; deep link aman; no history trap |
| TabView | Mobile bottom nav; Admin sidebar desktop | Active route semantic dan keyboard reachable |
| PhotosPicker/camera wrapper | File input capture hint + MediaDevices spike | Permission only on action; orientation/metadata/size preserved |
| QR camera | Browser scanner adapter | Safari/Chrome device matrix; no manual code |
| AVPlayer | HTML media | Autoplay fallback, resume, server completion threshold |
| Keychain | Secure HttpOnly cookie/session boundary | No refresh token/private draft in localStorage |
| App Store | Install prompt/A2HS guidance | iOS Safari instruction and standalone lifecycle |
| StoreKit | Manual transfer evidence + Admin review | Server-authoritative ledger/entitlement |
| Sign in with Apple | Tidak diport | Existing Apple identities handled only by legacy/decommission plan |
| Native offline shell | Service worker static shell | Auth HTML/API/signed URL/evidence never cached |

## Konsep historis yang dilarang

- Program invite, invite composer/history, typed Coach/invite code fallback.
- Coach wallet, seat credit, seat-pack commerce.
- Program access non-public atau Admin enrollment approval.
- Poin per langkah dan photo evidence terpisah dari typed answer.
- Global/onboarding weigh-in; weigh-in hanya content enrollment-scoped.
- Guest sebagai role/user, client-writable role/payment/score/entitlement.
- Tombol upload media demo atau generated fixture pada production surface.

Semua item parity mempunyai target route, state, authority, dan test handoff.
Detail mapping test ada di
[iOS to Web Test Mapping](../testing/IOS_TO_WEB_TEST_MAPPING.md).
