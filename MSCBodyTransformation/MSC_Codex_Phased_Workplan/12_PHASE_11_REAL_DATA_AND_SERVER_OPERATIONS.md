# Phase 11: Real Data, Public Guest Reads, and Server Operations

> Status: ditulis ulang 4 Agustus 2026 setelah Phase 09.5. Kontrak invite,
> wallet, seat credit, dan Coach role sebelum approval tidak berlaku.

## Tujuan

Mengganti repository lokal secara bertahap dengan Supabase adapters dan
operasi server authoritative tanpa mengubah UI Phase 09.5 atau kontrak
program E2E.

## Prasyarat

- Phase 09 Supabase foundation dan local vertical slice lulus.
- Phase 09.5 Guest/Auth/Profile/Coach application UI selesai.
- Phase 10 Supabase Auth, session, dan profile bootstrap lulus lokal.
- Colima dan Supabase lokal dipakai untuk migration/RLS/race test.
- Hosted `main` tetap production dan tidak dipakai untuk development.

## Authority boundaries

- Guest adalah session logged-out, bukan row `auth.users`.
- `anon` hanya membaca public-safe program, public leaderboard projection,
  winner poster, dan approved/public Coach directory.
- Profile, nomor HP, application, payment, entitlement, weight, submission,
  answer key, dan private media tidak public.
- Self-registration selalu Participant.
- Client dapat mengirim profile dan attestations, tetapi tidak dapat menulis
  payment verified, Admin decision, protected role, QR, atau entitlement.
- Semua privileged operations memeriksa caller, memakai explicit
  `search_path`, least-privilege execute grants, idempotency key, dan audit.

## Schema dan public-safe reads

- [ ] Tambahkan Member level stable enum/raw value.
- [ ] Tambahkan Coach application, attestation snapshot, terms version,
  status, submitted timestamp, dan decision.
- [ ] Pisahkan payment record, role, dan Coach entitlement dari application.
- [ ] Pastikan satu active application per user.
- [ ] Tambahkan public-safe views/RPC untuk katalog, leaderboard, winners, dan
  Coach directory memakai `security_invoker` atau RLS yang sesuai.
- [ ] Berikan explicit `anon`/`authenticated` grants hanya ke public-safe
  surface.
- [ ] Jangan memberi `anon` SELECT pada private tables.

## Coach application operations

- [ ] Create/update draft application milik caller secara idempoten.
- [ ] Submit hanya bila level SC+, HOM STS, ICT, terms version, dan payment
  verified.
- [ ] Applicant hanya membaca application/payment/entitlement miliknya.
- [ ] Admin list/detail menampilkan eligibility dan payment state read-only.
- [ ] Atomic approval mengunci application/payment, menghitung ulang
  eligibility, memverifikasi entitlement, mengubah protected role ke Coach,
  membuat Coach profile/QR bila belum ada, dan menulis audit.
- [ ] Rejection wajib alasan dan tidak menghapus payment record.
- [ ] Repeated approve/reject aman dan menghasilkan hasil konsisten.
- [ ] Expired entitlement menolak Coach operations walau client masih
  menampilkan cached role.

## Program operations

- [ ] Free enrollment: active public program + same-Coach QR guard +
  leaderboard entry atomik.
- [ ] Paid enrollment menunggu entitlement verified dari Phase 12.
- [ ] Typed submission prepare/finalize, required answer, private media
  ownership, quiz single attempt, dan orphan cleanup.
- [ ] Initial/daily/final weigh-in validation dengan Decimal dan audit
  correction.
- [ ] Coach review dan score reconciliation idempoten.
- [ ] Publish/duplicate program, winner lock, dan poster publication.
- [ ] Admin manual enrollment dan Coach transfer memerlukan reason/audit.
- [ ] Client tidak pernah mengirim authoritative points atau store price.

## Storage

- [ ] Private buckets tetap private.
- [ ] Path terikat ke caller, enrollment, submission, dan question.
- [ ] MIME/size/normalized JPEG divalidasi.
- [ ] Signed read atau authenticated download hanya untuk owner,
  assigned Coach, dan Admin.
- [ ] Retry tidak membuat duplicate answer/media.
- [ ] Orphan cleanup dapat diaudit dan tidak menghapus durable media.

## Adapter rollout

Integrasikan satu vertical slice per waktu:

1. Public Guest catalog/directory/winners/leaderboard.
2. Authenticated profile dan Coach application.
3. Program catalog dan enrollment.
4. Submission/media/weigh-in.
5. Coach monitoring/review.
6. Admin CMS/server operations.
7. Authoritative scoring/leaderboard/winner/poster.

Local mock tetap tersedia untuk preview dan deterministic UI tests.

## Tests

- [ ] Fresh local reset, lint, advisors, and explicit grants test.
- [ ] RLS matrix: anon, applicant, unrelated Participant, assigned Coach,
  expired Coach, Admin.
- [ ] Metadata role escalation ditolak.
- [ ] Guest cannot read profile/application/payment/private media.
- [ ] Duplicate application/submit/approve/reject.
- [ ] Concurrent approval/rejection.
- [ ] Payment missing atau eligibility incomplete memblokir approval.
- [ ] Expired entitlement memblokir Coach operation.
- [ ] Enrollment/submission/review race.
- [ ] Storage ownership dan orphan cleanup.
- [ ] iOS integration menggunakan konfigurasi local Supabase.

## Exit criteria

- [ ] Guest public reads bekerja tanpa Auth identity dan tidak bocor PII.
- [ ] Participant profile/application bekerja dengan RLS.
- [ ] Coach approval authoritative, idempoten, dan teraudit.
- [ ] Coach access memerlukan role approved dan entitlement active.
- [ ] Participant, Coach, dan Admin critical server flow lulus.
- [ ] Private media tidak dapat diakses user tidak terkait.
- [ ] Local demo tetap berfungsi tanpa Supabase.
- [ ] Tidak ada konsep invite, wallet, atau seat credit.

## Progress log

### 4 Agustus 2026 — Rekonsiliasi Phase 09.5

- Menghapus seluruh requirement invite/wallet/seat-credit lama.
- Menambahkan public-safe Guest reads, Member level, Coach application,
  payment/approval/role/entitlement separation, dan atomic Admin decision.
- Tidak ada migration atau deployment yang dilakukan oleh perubahan dokumen
  ini; semua checkbox Phase 11 tetap pekerjaan berikutnya.
