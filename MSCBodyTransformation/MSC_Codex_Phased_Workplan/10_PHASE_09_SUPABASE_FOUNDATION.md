# Phase 09: Supabase Foundation

> Status: workplan aktif sudah direkonsiliasi pada 4 Agustus 2026 dengan
> `PROGRAM_END_TO_END_REMEDIATION_WORKPLAN.md` Phase E2E-10 dan
> `PROGRAM_END_TO_END_IMPLEMENTATION_STATUS.md`.
>
> Artefak schema, RLS dasar, storage, dan dua RPC sudah tersedia di
> repository. Deployment, verifikasi local/staging, operasi server penuh,
> adapter iOS, dan pengujian keamanan belum selesai.

## Otoritas dan batas dokumen

Workplan ini menggantikan seluruh isi Phase 09 lama yang masih memuat program
invite, Coach wallet, seat credit, bukti timbang terpisah, dan konsep lain yang
sudah dihapus.

Sumber keputusan produk dan kontrak:

- `PROGRAM_END_TO_END_REMEDIATION_WORKPLAN.md`
- `PROGRAM_END_TO_END_CONTRACT_MATRIX.md`
- `PROGRAM_END_TO_END_IMPLEMENTATION_STATUS.md`
- `Contracts/program-api-v1.openapi.yaml`

Jika terdapat konflik, dokumen remediation dan contract matrix berlaku.

Phase ini hanya membangun fondasi backend dan adapter. Phase ini tidak:

- Mengaktifkan Google OAuth atau Sign in with Apple production.
- Menyelesaikan seluruh UI autentikasi; itu milik Phase 10.
- Mengaktifkan transaksi StoreKit production; itu milik Phase 12.
- Menyediakan App Store Connect atau Google Play credential di client.
- Menghapus local demo mode atau mock repositories.
- Memindahkan business rule authoritative ke SwiftUI View.

## Tujuan

Membuat backend Supabase shared untuk iOS dan Android berdasarkan domain
contract yang sudah terbukti pada vertical slice lokal, lalu menghubungkannya
ke repository protocol tanpa menulis ulang feature UI.

Hasil Phase 09 harus menyediakan:

- Migration database yang reproducible.
- RLS dan storage boundary yang teruji.
- Operasi server atomik untuk mutation penting.
- Fondasi adapter Supabase di iOS.
- Satu vertical slice staging yang berjalan end-to-end.
- Local demo mode yang tetap dapat digunakan tanpa internet.

## Prasyarat

- [x] Track A Phase 00 sampai Phase 08 stabil pada source iOS lokal.
- [x] Domain contract program typed dan state per enrollment tersedia.
- [x] Kontrak lintas platform OpenAPI tersedia.
- [x] Program invite, approval enrollment, Coach wallet, dan seat credit sudah
  dihapus dari kontrak aktif.
- [x] Satu current Coach dan same-Coach QR guard sudah menjadi keputusan
  authoritative.
- [ ] Supabase CLI dan Docker tersedia untuk local stack, atau project staging
  tersedia.
- [ ] Environment local, staging, dan production dipisahkan secara eksplisit.
- [ ] Dokumentasi dan changelog Supabase terbaru diperiksa kembali sebelum
  migration atau client dependency diubah.
- [ ] Keputusan Data API exposure dan grants untuk setiap schema/table
  didokumentasikan.
- [ ] Tidak ada secret yang akan dimasukkan ke target iOS atau repository.

## Baseline yang sudah tersedia

Artefak berikut sudah ada, tetapi keberadaannya belum membuktikan bahwa backend
sudah berhasil dijalankan atau aman untuk production:

- [x] `supabase/config.toml`.
- [x] `supabase/migrations/20260802000000_program_end_to_end.sql`.
- [x] `supabase/seed.sql` yang sengaja tidak berisi identity atau data wellness
  production-like.
- [x] `supabase/README.md` dengan external gate dan command verifikasi.
- [x] `Contracts/program-api-v1.openapi.yaml`.
- [x] Schema contract, indexes, RLS dasar, dua storage bucket, free-enrollment
  RPC, dan Admin Coach-transfer RPC tertulis dalam migration.
- [ ] Migration dijalankan dari database kosong.
- [ ] Database lint dan advisors lulus.
- [ ] Policy matrix diuji menggunakan identity Participant, Coach, Admin, dan
  user yang tidak terkait.
- [ ] Migration dideploy ke Supabase staging.
- [ ] Aplikasi iOS mempunyai dependency dan adapter Supabase.

## Aturan dependency dan konfigurasi

Pada Phase 09, setelah ada persetujuan eksplisit untuk menambahkan dependency:

- [ ] Periksa versi `supabase-swift` yang kompatibel dari dokumentasi dan
  changelog resmi.
- [ ] Pin versi kompatibel secara tepat.
- [ ] Simpan lockfile yang dihasilkan Xcode/Swift Package Manager.
- [ ] Gunakan configuration per environment.
- [ ] Masukkan hanya project URL dan publishable key yang memang aman berada
  di public client.
- [ ] Pastikan Release tidak dapat memakai local/staging project secara tidak
  sengaja.
- [ ] Pertahankan local demo configuration tanpa Supabase.

Dilarang memasukkan ke aplikasi atau repository:

- `service_role` atau secret key.
- Database password.
- JWT signing secret.
- App Store Connect private key.
- Google service-account credential.
- Google OAuth client secret.
- Token, private media URL, raw Coach QR identifier, atau data berat pada log.

## Schema database

Schema berikut sudah tercakup pada migration baseline:

- [x] Profiles, role server-controlled, dan satu `current_coach_id`.
- [x] Coach QR identifier dan approval state.
- [x] Programs dan lineage `source_program_id`.
- [x] Program scoring configuration.
- [x] Program days dan typed content steps.
- [x] Questions, options, dan protected answer keys.
- [x] Store product mapping per platform dan environment.
- [x] Program enrollments dengan snapshot Coach.
- [x] Submission attempts dan typed answers.
- [x] Quiz attempt results.
- [x] Initial, daily, dan final weigh-ins menggunakan `numeric`.
- [x] Program scores dan score adjustments.
- [x] Commerce transactions dan cross-platform entitlements.
- [x] Winner snapshots, winner rows, dan winner posters.
- [x] Audit events.
- [x] UUID, `timestamptz`, dan `numeric` digunakan pada boundary yang relevan.
- [x] Tidak ada tabel program invite, Coach wallet, credit ledger, atau seat
  credit.
- [x] Tidak ada tabel bukti timbang terpisah.

Pekerjaan schema yang masih harus dilakukan:

- [ ] Jalankan fresh reset dan perbaiki seluruh migration error.
- [ ] Verifikasi enum/check constraint cocok dengan OpenAPI dan raw value
  domain Swift.
- [ ] Verifikasi foreign key, delete behavior, unique constraint, dan index
  untuk seluruh mutation serta policy.
- [ ] Verifikasi akses Data API dan least-privilege grants terpisah dari RLS.
- [ ] Tambahkan migration baru untuk setiap perubahan; jangan mengedit
  migration yang sudah pernah dideploy.
- [ ] Jalankan database lint dan advisors, lalu selesaikan temuan security dan
  performance.
- [ ] Pastikan migration dapat digunakan oleh Android tanpa bergantung pada
  tipe Swift.

## Row Level Security

Baseline yang sudah tertulis:

- [x] RLS diaktifkan pada seluruh tabel `public` yang dibuat migration.
- [x] Peserta dapat membaca program published.
- [x] Peserta dapat membaca enrollment, submission, answer, quiz result,
  timbang, transaksi, dan entitlement miliknya sesuai policy.
- [x] Peserta tidak mempunyai policy untuk membaca answer key.
- [x] Coach scope berasal dari current Coach server-controlled.
- [x] Coach dapat membaca enrollment, submission, answer, quiz result, dan
  timbang Participant yang ditugaskan.
- [x] Coach tidak mendapat akses ke Participant milik Coach lain melalui
  policy yang ditulis.
- [x] Admin mempunyai policy untuk CMS dan audit yang terkontrol.
- [x] Role dan current Coach tidak mempunyai self-update policy.
- [x] Helper privileged berada pada schema `private`.
- [x] RPC `SECURITY DEFINER` mempunyai explicit `search_path`, pemeriksaan
  caller, revoke default execute, dan grant terbatas ke `authenticated`.

Verifikasi dan hardening yang masih harus dilakukan:

- [ ] Uji setiap policy dengan identity nyata; review source SQL saja tidak
  dihitung sebagai lulus.
- [ ] Uji Participant tidak dapat membaca Participant lain.
- [ ] Uji Coach tidak dapat membaca Participant Coach lain.
- [ ] Uji Participant tidak dapat membaca answer key melalui table, view,
  function, nested relation, atau Data API.
- [ ] Uji nilai berat tidak bocor ke feed, leaderboard, winner response, log,
  atau public view.
- [ ] Uji role dan current Coach tidak dapat diubah oleh user.
- [ ] Audit seluruh `SECURITY DEFINER`, default execute privilege, dan
  `search_path`.
- [ ] Gunakan security-invoker untuk setiap exposed view yang akan ditambahkan,
  atau letakkan view privileged di schema yang tidak exposed.
- [ ] Pastikan policy UPDATE yang ditambahkan mempunyai SELECT policy,
  `USING`, dan `WITH CHECK` yang sesuai.
- [ ] Tambahkan index untuk field yang digunakan pada policy apabila hasil
  advisor atau profiling memerlukannya.
- [ ] Jalankan matriks RLS dan database advisors setelah setiap perubahan
  security.

## Storage dan private media

Baseline yang sudah tertulis:

- [x] Bucket `public-media` untuk media yang memang publik.
- [x] Bucket private `question-photos` untuk jawaban unggah foto.
- [x] Baseline policy public-media read.
- [x] Baseline policy Participant upload berdasarkan folder identity.
- [x] Baseline policy private read untuk pemilik, current Coach terkait, dan
  Admin.
- [x] Batas ukuran awal bucket tercantum pada migration.
- [x] Tidak ada bucket bukti timbang karena timbang tidak memakai foto.

Pekerjaan storage yang masih harus dilakukan:

- [ ] Tetapkan path convention yang mengikat object ke participant,
  enrollment, submission, dan question tanpa mengekspos raw Coach QR.
- [ ] Tambahkan MIME allowlist dan final size limit yang sesuai hasil image
  processing iOS.
- [ ] Uji upload baru, retry, replacement/upsert, delete, dan read; upsert
  memerlukan policy SELECT, INSERT, dan UPDATE yang sesuai.
- [ ] Sediakan signed private access untuk Coach/Admin terkait tanpa
  menjadikan bucket publik.
- [ ] Normalisasi orientasi, resize, dan hapus metadata lokasi sebelum upload.
- [ ] Tambahkan orphan cleanup yang aman dan dapat diaudit.
- [ ] Hapus local temporary file hanya setelah upload dan record database
  tersimpan secara durable.
- [ ] Uji unrelated Participant dan unrelated Coach tidak dapat membaca,
  membuat signed URL, mengganti, atau menghapus private media.
- [ ] Pastikan private path dan signed URL tidak masuk log atau analytics.

## Atomic server operations

Sudah tersedia pada migration baseline:

- [x] `enroll_free_program`: validasi Participant, QR Coach, same-Coach guard,
  program gratis, kapasitas, idempotent enrollment, dan leaderboard entry.
- [x] `admin_transfer_coach`: validasi Admin, alasan, current Coach,
  enrollment berstatus `initiated`, `waiting_for_payment`, atau `active`
  diperbarui, serta audit dicatat.

Masih harus diimplementasikan dan diuji:

- [ ] Publish program dengan validasi contract lengkap.
- [ ] Duplicate program dengan seluruh nested ID baru dan tanpa store mapping
  atau runtime state.
- [ ] Primitive same-Coach QR yang dapat dipakai konsisten oleh enrollment
  gratis dan berbayar.
- [ ] Initiate paid enrollment tanpa memberikan entitlement dari client-only
  state.
- [ ] Submit typed step answers.
- [ ] Submit satu quiz attempt dan hitung hasil tanpa membocorkan answer key.
- [ ] Reopen quiz attempt oleh Admin dengan alasan, sequence, dan audit.
- [ ] Review Coach approve/reject secara idempoten.
- [ ] Submit serta correct weigh-in dengan uniqueness, ordering, alasan, dan
  audit.
- [ ] Recalculate activity, quiz, weight, adjustment, total score, progress,
  dan rank secara authoritative.
- [ ] Lock immutable winner snapshot.
- [ ] Publish winner poster yang terikat pada snapshot.
- [ ] Validasi ownership, active day dari server clock, timezone, kapasitas,
  dan program state di server.
- [ ] Gunakan idempotency key atau database uniqueness untuk setiap mutation
  yang dapat diulang.
- [ ] Pastikan client tidak pernah dapat mengirim total points, authoritative
  price, role, current Coach, atau entitlement result.

## Seed dan test fixtures

- [x] `seed.sql` tidak menyalin identity, private media, atau data wellness
  production.
- [ ] Buat deterministic integration-test setup untuk Admin, Coach,
  Participant, dan unrelated users melalui mekanisme test yang aman.
- [ ] Buat sample program yang setara dengan fixture lokal tanpa memakai data
  pribadi nyata.
- [ ] Tambahkan sample untuk seluruh content/question type, scheduled dan
  self-paced program, free dan paid program.
- [ ] Pisahkan fixture local/test/staging dari production.
- [ ] Pastikan reset staging atau seed destructive tidak pernah dapat menyasar
  production.

## Fondasi adapter iOS

- [ ] Tambahkan `supabase-swift` hanya setelah dependency disetujui dan
  versinya diverifikasi.
- [ ] Buat `SupabaseClientProviding` atau boundary sempit yang ekuivalen.
- [ ] Isolasi DTO dan generated payload dari domain models.
- [ ] Tambahkan mapping DTO ke domain dan domain command ke request payload.
- [ ] Map database, RLS, storage, offline, timeout, conflict, dan unknown error
  menjadi typed domain error.
- [ ] Buat repository adapter per vertical slice; jangan membuat satu giant
  Supabase manager.
- [ ] Pertahankan View dan feature state menggunakan repository protocol.
- [ ] Jangan mengimpor Supabase types ke domain model.
- [ ] Jangan menjalankan query Supabase langsung dari SwiftUI View.
- [ ] Gunakan fake session atau controlled staging identity hanya untuk
  integration Phase 09; production auth tetap dikerjakan pada Phase 10.
- [ ] Pertahankan mock adapter dan Debug local demo mode.

## Urutan implementasi

Kerjakan satu vertical slice pada satu waktu:

1. Siapkan Supabase CLI/Docker atau project staging dan verifikasi environment.
2. Jalankan fresh migration, lint, advisors, serta baseline RLS tests.
3. Hardening grants, RLS, storage policies, dan private-media access.
4. Implementasikan atomic operations beserta concurrency/idempotency tests.
5. Tambahkan client dependency dan adapter foundation.
6. Integrasikan program catalog read.
7. Integrasikan free enrollment dengan same-Coach QR guard.
8. Integrasikan satu typed submission termasuk private photo.
9. Integrasikan Coach review dan authoritative score refresh.
10. Jalankan vertical slice staging end-to-end.

Program catalog, enrollment, submission, review, dan scoring yang lebih luas
tetap dilanjutkan secara bertahap pada Phase 11. Phase 09 harus membuktikan
fondasi dan satu vertical slice, bukan memigrasikan seluruh UI sekaligus.

## Verifikasi

### Environment dan migration

- [ ] Catat versi Supabase CLI yang digunakan.
- [ ] Jalankan local stack dari `supabase/config.toml`.
- [ ] Fresh database reset lulus.
- [ ] Migration list sesuai.
- [ ] Database lint lulus.
- [ ] Database advisors tidak mempunyai blocker security.
- [ ] Staging deployment menggunakan migration yang sama dengan local.

Command final harus dipastikan melalui `supabase --help` pada versi CLI yang
terpasang. Baseline command yang sudah didokumentasikan di repository:

```bash
supabase start
supabase db reset --local
supabase db lint --local
```

### Security dan concurrency

- [ ] Full RLS matrix lulus.
- [ ] Data API grants matrix lulus.
- [ ] Participant cross-account access ditolak.
- [ ] Coach cross-assignment access ditolak.
- [ ] Answer key tidak dapat dibaca Participant.
- [ ] Private-media ownership dan signed-access tests lulus.
- [ ] Wrong-Coach QR race lulus.
- [ ] Capacity race lulus.
- [ ] Duplicate enrollment lulus.
- [ ] Duplicate submission lulus.
- [ ] Quiz attempt race lulus.
- [ ] Score reconciliation approve/reject/retry lulus.
- [ ] Weigh-in uniqueness dan correction audit lulus.
- [ ] Winner lock concurrency lulus.

### iOS

- [ ] DTO mapping tests lulus.
- [ ] Repository adapter tests lulus.
- [ ] Error mapping tests lulus.
- [ ] iOS Debug build lulus dengan staging adapter.
- [ ] Program catalog → QR Coach → free enrollment → typed submission →
  Coach review → score refresh berjalan pada staging.
- [ ] Local demo mode tetap lulus tanpa internet.
- [ ] Tidak ada secret atau sensitive value pada app bundle dan log.

## Exit criteria

- [ ] Fresh local Supabase reset dan lint lulus.
- [ ] Migration yang sama berhasil dideploy ke staging.
- [ ] Full RLS, grants, storage, race, dan idempotency matrix lulus.
- [ ] Seluruh operasi server yang dibutuhkan vertical slice tersedia.
- [ ] Participant tidak dapat membaca data atau private media user lain.
- [ ] Coach tidak dapat membaca Participant Coach lain.
- [ ] Participant tidak dapat membaca answer key.
- [ ] Client tidak dapat menentukan role, current Coach, total points,
  authoritative price, atau entitlement.
- [ ] Aplikasi iOS menjalankan satu vertical slice nyata dengan staging
  Supabase melalui repository adapter.
- [ ] Local demo mode tetap berjalan.
- [ ] Tidak ada primary UI rewrite.
- [ ] Tidak ada secret yang tersimpan di aplikasi atau repository.
- [ ] Remaining server operations dan scope Phase 11 tercatat secara eksplisit.

## External gate

Phase 09 belum dapat dinyatakan selesai tanpa:

- Supabase CLI dan Docker, atau Supabase project staging.
- Project URL dan publishable key staging.
- Service-side deployment environment.
- Controlled test identities untuk RLS matrix.
- Environment yang dapat menjalankan concurrency dan storage tests.

Mock, OpenAPI, migration source, atau review SQL saja tidak menggantikan
verifikasi tersebut.

## Referensi resmi yang wajib diperiksa saat eksekusi

- Supabase changelog, terutama entry `breaking-change`.
- Supabase Row Level Security documentation.
- Supabase Storage access-control documentation.
- Supabase CLI local-development dan migration workflow.
- Supabase Swift client documentation dan release notes.

Jangan menyalin command, API signature, atau configuration key dari ingatan.
Periksa dokumentasi sesuai versi yang benar-benar digunakan.

## Progress log

### 4 Agustus 2026 — Rekonsiliasi workplan

- Files changed:
  - `MSCBodyTransformation/MSC_Codex_Phased_Workplan/10_PHASE_09_SUPABASE_FOUNDATION.md`
- Assumptions:
  - E2E-10 dan implementation status adalah sumber authoritative.
  - Artefak migration yang ada adalah baseline contract, bukan bukti deployment.
  - `seed.sql` tetap kosong dari identity dan private wellness data; deterministic
    identity dibuat oleh integration-test setup.
- Verification:
  - Isi workplan dibandingkan dengan migration, Supabase README, E2E-10, dan
    implementation status.
  - Referensi resmi Supabase untuk RLS, Storage, CLI, dan breaking-change
    changelog diperiksa.
- Build command:
  - Tidak dijalankan; perubahan dokumentasi saja.
- Test command:
  - Tidak dijalankan; Supabase CLI/Docker atau staging belum tersedia.
- Result:
  - Workplan lama diganti dengan checklist yang mengikuti kontrak program
    terbaru dan status artefak aktual.
- Remaining blockers:
  - Local/staging Supabase verification, server operations penuh, adapter iOS,
    RLS/race tests, dan private-media hardening.
