# Phase 09: Supabase Foundation

> Status: implementasi lokal Phase 09 selesai pada 4 Agustus 2026 dan sudah
> direkonsiliasi dengan
> `PROGRAM_END_TO_END_REMEDIATION_WORKPLAN.md` Phase E2E-10 dan
> `PROGRAM_END_TO_END_IMPLEMENTATION_STATUS.md`.
>
> PostgreSQL 17, migration, grants, RLS, private Storage, operasi server
> vertical slice, adapter iOS, serta test migration/RLS/race/E2E lokal sudah
> lulus. Development memakai Supabase lokal melalui Colima; hosted `main`
> tetap dicadangkan untuk production dan tidak disentuh pada Phase 09.
> Operasi produk yang lebih luas dilanjutkan pada Phase 11/12.

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
- Satu vertical slice Supabase lokal yang berjalan end-to-end.
- Local demo mode yang tetap dapat digunakan tanpa internet.

## Prasyarat

- [x] Track A Phase 00 sampai Phase 08 stabil pada source iOS lokal.
- [x] Domain contract program typed dan state per enrollment tersedia.
- [x] Kontrak lintas platform OpenAPI tersedia.
- [x] Program invite, approval enrollment, Coach wallet, dan seat credit sudah
  dihapus dari kontrak aktif.
- [x] Satu current Coach dan same-Coach QR guard sudah menjadi keputusan
  authoritative.
- [x] Supabase CLI dan Docker tersedia untuk local stack.
- [x] Environment development lokal dan hosted production dipisahkan secara
  eksplisit; tidak ada hosted development/staging branch.
- [x] Dokumentasi dan changelog Supabase terbaru diperiksa kembali sebelum
  migration atau client dependency diubah.
- [x] Keputusan Data API exposure dan grants untuk setiap schema/table
  didokumentasikan.
- [x] Tidak ada secret yang dimasukkan ke target iOS atau repository.

## Baseline yang sudah tersedia

Artefak berikut sudah ada, tetapi keberadaannya belum membuktikan bahwa backend
sudah berhasil dijalankan atau aman untuk production:

- [x] `supabase/config.toml`.
- [x] `supabase/migrations/20260802000000_program_end_to_end.sql`.
- [x] `supabase/migrations/20260804043720_phase09_data_api_hardening.sql`
  untuk explicit grants dan privileged-function hardening.
- [x] `supabase/seed.sql` yang sengaja tidak berisi identity atau data wellness
  production-like.
- [x] `supabase/README.md` dengan external gate dan command verifikasi.
- [x] `Contracts/program-api-v1.openapi.yaml`.
- [x] Schema contract, indexes, RLS dasar, dua storage bucket, free-enrollment
  RPC, dan Admin Coach-transfer RPC tertulis dalam migration.
- [x] Migration dijalankan dari database kosong.
- [x] Database lint dan advisors lulus.
- [x] Policy matrix diuji menggunakan identity Participant, Coach, Admin, dan
  user yang tidak terkait.
- [ ] Migration production dideploy ke hosted `main` hanya setelah seluruh
  gate Phase 09 dan release terkait lulus.
- [x] Aplikasi iOS mempunyai adapter Supabase berbasis Foundation tanpa
  dependency pihak ketiga.

## Aturan dependency dan konfigurasi

Keputusan dependency Phase 09:

- [x] Versi resmi `supabase-swift` diperiksa; versi terbaru saat eksekusi
  adalah `2.54.1` dengan kebutuhan Xcode 16.4+, Swift 6.1+, dan iOS 16+.
- [x] Adapter vertical slice menggunakan native Foundation `URLSession`;
  tidak ada package yang perlu dipin dan tidak ada lockfile baru.
- [x] Gunakan configuration per environment.
- [x] Masukkan hanya project URL dan publishable key yang memang aman berada
  di public client.
- [x] Pastikan Release tidak dapat memakai Supabase lokal secara tidak sengaja.
- [x] Pertahankan local demo configuration tanpa Supabase.

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

- [x] Jalankan fresh reset dan perbaiki seluruh migration error.
- [x] Verifikasi enum/check constraint cocok dengan OpenAPI dan raw value
  domain Swift.
- [x] Verifikasi foreign key, delete behavior, unique constraint, dan index
  untuk seluruh mutation serta policy.
- [x] Verifikasi akses Data API dan least-privilege grants terpisah dari RLS.
- [x] Tambahkan migration baru untuk setiap perubahan; jangan mengedit
  migration yang sudah pernah dideploy.
- [x] Jalankan database lint dan advisors, lalu selesaikan temuan security dan
  performance.
- [x] Pastikan migration dapat digunakan oleh Android tanpa bergantung pada
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

- [x] Uji setiap policy dengan identity nyata; review source SQL saja tidak
  dihitung sebagai lulus.
- [x] Uji Participant tidak dapat membaca Participant lain.
- [x] Uji Coach tidak dapat membaca Participant Coach lain.
- [x] Uji Participant tidak dapat membaca answer key melalui table, view,
  function, nested relation, atau Data API.
- [x] Uji nilai berat tidak bocor ke feed, leaderboard, winner response, log,
  atau public view.
- [x] Uji role dan current Coach tidak dapat diubah oleh user.
- [x] Audit seluruh `SECURITY DEFINER`, default execute privilege, dan
  `search_path`.
- [x] Tidak ada exposed view baru; helper privileged tetap di schema
  `private` yang tidak diekspos.
- [x] Pastikan policy UPDATE yang ditambahkan mempunyai SELECT policy,
  `USING`, dan `WITH CHECK` yang sesuai.
- [x] Tambahkan index untuk field yang digunakan pada policy apabila hasil
  advisor atau profiling memerlukannya.
- [x] Jalankan matriks RLS dan database advisors setelah setiap perubahan
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

- [x] Tetapkan path convention yang mengikat object ke participant,
  enrollment, submission, dan question tanpa mengekspos raw Coach QR.
- [x] Tambahkan MIME allowlist dan final size limit yang sesuai hasil image
  processing iOS.
- [x] Uji upload baru, retry, replacement/upsert, delete, dan read; upsert
  memerlukan policy SELECT, INSERT, dan UPDATE yang sesuai.
- [x] Sediakan signed private access untuk Coach/Admin terkait tanpa
  menjadikan bucket publik.
- [x] Normalisasi orientasi, resize, dan hapus metadata lokasi sebelum upload.
- [x] Tambahkan kandidat orphan cleanup yang aman dan audit hasil penghapusan
  tanpa menyimpan raw private path pada audit.
- [x] Hapus local temporary file hanya setelah upload dan record database
  tersimpan secara durable.
- [x] Uji unrelated Participant dan unrelated Coach tidak dapat membaca,
  membuat signed URL, mengganti, atau menghapus private media.
- [x] Pastikan private path dan signed URL tidak masuk log atau analytics.

## Atomic server operations

Sudah tersedia pada migration baseline:

- [x] `enroll_free_program`: validasi Participant, QR Coach, same-Coach guard,
  program gratis, kapasitas, idempotent enrollment, dan leaderboard entry.
- [x] `admin_transfer_coach`: validasi Admin, alasan, current Coach,
  enrollment berstatus `initiated`, `waiting_for_payment`, atau `active`
  diperbarui, serta audit dicatat.

Operasi vertical slice Phase 09:

- [x] Primitive same-Coach QR dipakai oleh enrollment gratis.
- [x] Siapkan submission draft idempoten sebelum private upload.
- [x] Submit typed step answers.
- [x] Submit satu quiz attempt dan hitung hasil tanpa membocorkan answer key.
- [x] Review Coach approve/reject secara idempoten dan teraudit.
- [x] Recalculate activity, quiz, weight, adjustment, total score, progress,
  dan rank secara authoritative.
- [x] Validasi ownership, active day dari server clock, timezone, kapasitas,
  dan program state di server.
- [x] Gunakan idempotency key, uniqueness, advisory lock, atau row lock pada
  mutation vertical slice yang dapat diulang.
- [x] Client vertical slice tidak dapat mengirim total points, authoritative
  price, role, current Coach, atau entitlement result.

Operasi berikut bukan exit criteria Phase 09 dan tetap menjadi scope Phase
11/12:

- [ ] Phase 11: publish program dengan validasi contract lengkap.
- [ ] Phase 11: duplicate program dengan seluruh nested ID baru dan tanpa
  store mapping atau runtime state.
- [ ] Phase 11/12: initiate paid enrollment tanpa memberikan entitlement dari
  client-only state.
- [ ] Phase 11: reopen quiz attempt oleh Admin dengan alasan, sequence, dan
  audit.
- [ ] Phase 11: submit serta correct weigh-in dengan uniqueness, ordering,
  alasan, dan audit.
- [ ] Phase 11: lock immutable winner snapshot.
- [ ] Phase 11: publish winner poster yang terikat pada snapshot.

## Seed dan test fixtures

- [x] `seed.sql` tidak menyalin identity, private media, atau data wellness
  production.
- [x] Buat deterministic integration-test setup untuk Admin, Coach,
  Participant, dan unrelated users melalui mekanisme test yang aman.
- [x] Buat sample program yang setara dengan fixture lokal tanpa memakai data
  pribadi nyata.
- [x] Tambahkan fixture Phase 09 untuk scheduled free program, form foto,
  typed answers, dan quiz otomatis.
- [ ] Phase 11/12: perluas fixture ke seluruh content/question type,
  self-paced program, dan paid program ketika operasinya tersedia.
- [x] Pisahkan fixture local/test dari production.
- [x] Pastikan reset local atau seed destructive tidak pernah dapat menyasar
  production; command destructive wajib memakai `--local`.

## Fondasi adapter iOS

- [x] Gunakan native Foundation `URLSession` setelah versi resmi
  `supabase-swift` diverifikasi dan dependency dinilai tidak diperlukan untuk
  vertical slice ini.
- [x] Buat `SupabaseClientProviding` sebagai boundary sempit.
- [x] Isolasi DTO dan generated payload dari domain models.
- [x] Tambahkan mapping DTO ke domain dan domain command ke request payload.
- [x] Map database, RLS, storage, offline, timeout, conflict, dan unknown error
  menjadi typed domain error.
- [x] Buat repository adapter per vertical slice; jangan membuat satu giant
  Supabase manager.
- [x] Pertahankan View dan feature state menggunakan repository protocol.
- [x] Jangan mengimpor Supabase types ke domain model.
- [x] Jangan menjalankan query Supabase langsung dari SwiftUI View.
- [x] Gunakan local Supabase Auth identity hanya untuk integration Phase 09;
  production auth tetap dikerjakan pada Phase 10.
- [x] Pertahankan mock adapter dan Debug local demo mode.

## Urutan implementasi

Kerjakan satu vertical slice pada satu waktu:

1. Siapkan Supabase CLI/Docker dan verifikasi environment lokal.
2. Jalankan fresh migration, lint, advisors, serta baseline RLS tests.
3. Hardening grants, RLS, storage policies, dan private-media access.
4. Implementasikan atomic operations beserta concurrency/idempotency tests.
5. Tambahkan adapter Foundation pada boundary client yang sempit.
6. Integrasikan program catalog read.
7. Integrasikan free enrollment dengan same-Coach QR guard.
8. Integrasikan satu typed submission termasuk private photo.
9. Integrasikan Coach review dan authoritative score refresh.
10. Jalankan vertical slice Supabase lokal end-to-end.

Program catalog, enrollment, submission, review, dan scoring yang lebih luas
tetap dilanjutkan secara bertahap pada Phase 11. Phase 09 harus membuktikan
fondasi dan satu vertical slice, bukan memigrasikan seluruh UI sekaligus.

## Verifikasi

### Environment dan migration

- [x] Catat versi Supabase CLI yang digunakan: `2.111.0`.
- [x] Jalankan local stack dari `supabase/config.toml`.
- [x] Fresh database reset lulus.
- [x] Migration list sesuai.
- [x] Database lint lulus.
- [x] Database advisors tidak mempunyai blocker security.
- [x] Development menggunakan migration lokal sebagai satu-satunya source.

Command final harus dipastikan melalui `supabase --help` pada versi CLI yang
terpasang. Baseline command yang sudah didokumentasikan di repository:

```bash
supabase start
supabase db reset --local
supabase db lint --local
```

### Security dan concurrency

- [x] Full RLS matrix Phase 09 lulus.
- [x] Data API grants matrix lulus.
- [x] Participant cross-account access ditolak.
- [x] Coach cross-assignment access ditolak.
- [x] Answer key tidak dapat dibaca Participant.
- [x] Private-media ownership dan signed-access tests lulus.
- [x] Wrong-Coach QR race lulus.
- [x] Capacity race lulus.
- [x] Duplicate enrollment lulus.
- [x] Duplicate submission lulus.
- [x] Quiz attempt race lulus.
- [x] Score reconciliation approve/reject/retry lulus.
- [ ] Phase 11: weigh-in uniqueness dan correction audit lulus.
- [ ] Phase 11: winner lock concurrency lulus.

### iOS

- [x] DTO mapping tests lulus.
- [x] Repository adapter tests lulus.
- [x] Error mapping tests lulus.
- [x] iOS Debug build lulus dengan adapter Supabase lokal.
- [x] Program catalog → QR Coach → free enrollment → typed submission →
  Coach review → score refresh berjalan pada Supabase lokal.
- [x] Local demo mode tetap lulus tanpa internet.
- [x] Tidak ada secret atau sensitive value pada app bundle dan log.

## Exit criteria

- [x] Fresh local Supabase reset dan lint lulus.
- [x] Production deployment dikeluarkan dari exit criteria Phase 09; hosted
  `main` tetap tidak disentuh sampai gate release eksplisit setelah Phase
  11/12.
- [x] Full RLS, grants, storage, race, dan idempotency matrix Phase 09 lulus.
- [x] Seluruh operasi server yang dibutuhkan vertical slice tersedia.
- [x] Participant tidak dapat membaca data atau private media user lain.
- [x] Coach tidak dapat membaca Participant Coach lain.
- [x] Participant tidak dapat membaca answer key.
- [x] Client tidak dapat menentukan role, current Coach, total points,
  authoritative price, atau entitlement.
- [x] Aplikasi iOS menjalankan satu vertical slice nyata dengan Supabase lokal
  melalui repository adapter.
- [x] Local demo mode tetap berjalan.
- [x] Tidak ada primary UI rewrite.
- [x] Tidak ada secret yang tersimpan di aplikasi atau repository.
- [x] Remaining server operations dan scope Phase 11/12 tercatat secara
  eksplisit.

## Strategi environment

Keputusan environment Phase 09:

- Development database, Auth, Storage, Realtime, dan Data API berjalan lokal
  melalui Supabase CLI, Docker, dan Colima.
- Hosted project branch `main` adalah production dan tidak menerima migration
  selama pekerjaan development.
- Supabase Branching dan hosted development/staging tidak digunakan, sehingga
  tidak ada Branching Compute Hours.
- Debug adapter memakai local URL dan local publishable/anon credential dari
  `supabase status`; credential lokal tidak disimpan pada Release bundle.
- Production URL dan publishable key baru dipasang pada konfigurasi Release
  ketika production deployment secara eksplisit disetujui.
- `service_role`, database password, JWT secret, dan credential sensitif lain
  tidak pernah masuk aplikasi atau repository.

Konsekuensi yang diterima:

- Supabase lokal hanya tersedia saat Mac, Colima, dan local stack berjalan.
- Simulator atau perangkat pengujian harus dapat menjangkau Mac yang
  menjalankan local stack.
- Tidak ada hosted endpoint untuk QA jarak jauh atau pengujian saat Mac mati.
- Hosted-only behavior tetap diverifikasi saat production deployment gate;
  deployment tidak boleh dilakukan sebagai eksperimen pada `main`.

## Referensi resmi yang wajib diperiksa saat eksekusi

- Supabase changelog, terutama entry `breaking-change`.
- Supabase Row Level Security documentation.
- Supabase Storage access-control documentation.
- Supabase CLI local-development dan migration workflow.
- Supabase Swift client documentation dan release notes.

Jangan menyalin command, API signature, atau configuration key dari ingatan.
Periksa dokumentasi sesuai versi yang benar-benar digunakan.

## Progress log

### 4 Agustus 2026 — Phase 09 local foundation selesai

- Files changed:
  - `supabase/migrations/20260804054430_phase09_vertical_slice_server_operations.sql`.
  - `supabase/tests/database/003_phase09_vertical_slice_operations.test.sql`.
  - `supabase/tests/integration/submission_review_races.mjs`.
  - `supabase/tests/integration/setup_ios_vertical_slice.mjs`.
  - `supabase/tests/integration/verify_ios_vertical_slice.mjs`.
  - `MSCBodyTransformation/Infrastructure/Supabase/SupabaseClient.swift`.
  - `MSCBodyTransformation/Infrastructure/Supabase/SupabaseDTOs.swift`.
  - `MSCBodyTransformation/Infrastructure/Supabase/SupabaseRepositories.swift`.
  - `MSCBodyTransformationTests/Phase09SupabaseFoundationTests.swift`.
  - `supabase/README.md`.
  - `supabase/COLIMA_LOCAL_DEVELOPMENT.md`.
  - Workplan Phase 09 ini.
- Assumptions:
  - Scope Phase 09 adalah satu vertical slice lokal yang membuktikan fondasi,
    bukan seluruh operasi produk Phase 11/12.
  - Adapter memakai Foundation `URLSession`; versi resmi `supabase-swift`
    `2.54.1` sudah diperiksa tetapi dependency tidak diperlukan.
  - Hosted `main` tetap production dan tidak menerima migration atau fixture
    selama penyelesaian Phase 09.
- Build commands:
  - XcodeBuildMCP `build_run_sim` pada iPhone 17, iOS 26.5.
  - `xcodebuild test` terfokus untuk
    `Phase09SupabaseFoundationTests`.
- Test commands:
  - `supabase db reset --local`.
  - `supabase migration list --local`.
  - `supabase db lint --local --level warning --fail-on error`.
  - `supabase db advisors --local --type all --level warn --fail-on error`.
  - `supabase db diff --local`.
  - `supabase test db --local supabase/tests/database`.
  - `node supabase/tests/integration/private_media_storage.mjs`.
  - `node supabase/tests/integration/enrollment_races.mjs`.
  - `node supabase/tests/integration/submission_review_races.mjs`.
  - Live iOS local setup, focused test, dan persisted-result verifier.
  - `xcodebuild test` untuk seluruh target
    `MSCBodyTransformationTests`.
- Result:
  - Debug build dan launch lulus tanpa warning.
  - Sembilan focused iOS adapter/E2E tests lulus.
  - Seluruh 144 Swift unit/integration-style tests lulus.
  - Live catalog → QR Coach → free enrollment → private photo → typed
    submission → Coach review → authoritative score refresh lulus; database
    memuat score 10, progress 100%, dan rank 1.
  - Fresh PostgreSQL 17 reset, migration list, lint, dan advisors lulus.
  - Schema diff terhadap shadow database kosong tidak menemukan drift.
  - 76 pgTAP, 16 Storage API, 10 enrollment race, dan 15
    submission/review/quiz race assertions lulus.
  - Database lokal dikembalikan ke fresh migration state setelah test.
  - Tidak ada perubahan `project.pbxproj`, package dependency, primary UI,
    credential, atau hosted production.
- Remaining blockers:
  - Tidak ada blocker lokal untuk menutup Phase 09.
  - Combined scheme UI-test invocation terpisah tidak dapat meluncurkan
    `MSCBodyTransformationUITests-Runner` karena Xcode Simulator
    `RequestDenied`/`no debugger version`; Phase 09 tidak mengubah UI dan
    build/run serta seluruh Swift tests tetap lulus.
  - Deployment hosted `main` tetap release gate eksternal setelah Phase 11/12.
  - Production Auth dimulai pada Phase 10; operasi produk yang lebih luas
    tetap pada Phase 11 dan commerce verification pada Phase 12.

### 4 Agustus 2026 — Panduan operasional Colima dan Supabase lokal

- Files changed:
  - `AGENTS.md`.
  - `supabase/COLIMA_LOCAL_DEVELOPMENT.md`.
  - `supabase/README.md`.
  - `MSCBodyTransformation/MSC_Codex_Phased_Workplan/10_PHASE_09_SUPABASE_FOUNDATION.md`.
- Assumptions:
  - Colima tetap memakai profile `default` dengan 6 CPU, 8 GiB memory, disk
    60 GiB, architecture `aarch64`, dan runtime Docker.
  - User ingin menghidupkan runtime hanya saat backend lokal diperlukan.
- Build command:
  - Tidak dijalankan; perubahan dokumentasi saja.
- Test commands:
  - `colima status`.
  - `colima list`.
  - `docker info --format '{{.ServerVersion}}'`.
  - `supabase start --help`.
  - `supabase stop --help`.
  - `git diff --check`.
- Result:
  - Panduan start, status, shutdown, preservasi data, dan perintah destruktif
    tersedia dan ditautkan dari README serta instruksi agent.
  - Colima terverifikasi berjalan dengan Docker daemon aktif.
- Remaining blockers:
  - Tidak ada blocker untuk dokumentasi operasional.
  - Operasi server dan adapter iOS Phase 09 tetap menjadi pekerjaan berikutnya.

### 4 Agustus 2026 — Keputusan local development dan hosted production

- Files changed:
  - `AGENTS.md`.
  - `supabase/README.md`.
  - `MSCBodyTransformation/MSC_Codex_Phased_Workplan/10_PHASE_09_SUPABASE_FOUNDATION.md`.
- Assumptions:
  - User menerima konsekuensi local stack hanya tersedia saat Mac dan Colima
    berjalan.
  - Hosted `main` diperlakukan sebagai production dan tidak boleh dipakai
    untuk eksperimen development.
  - Supabase Branching dan project development kedua tidak digunakan.
- Build command:
  - Tidak dijalankan; perubahan strategi environment dan dokumentasi saja.
- Test command:
  - `git diff --check`.
- Result:
  - Persistent `development` branch dan biaya Branching dihapus dari rencana.
  - Development tetap memakai PostgreSQL 17, Auth, Storage, dan Data API lokal.
  - Aturan yang sama ditetapkan sebagai instruksi wajib repository di
    `AGENTS.md`.
  - Production deployment menjadi gate eksplisit terpisah setelah seluruh
    migration, operasi server, security test, dan adapter lokal lulus.
- Remaining blockers:
  - Operasi server selain dua RPC baseline, orphan cleanup, adapter iOS, dan
    vertical slice Supabase lokal belum selesai.

### 4 Agustus 2026 — Local backend, RLS, race, dan private-media gate

- Files changed:
  - `.gitignore`.
  - `supabase/migrations/20260804043720_phase09_data_api_hardening.sql`.
  - `supabase/migrations/20260804050012_phase09_policy_performance_hardening.sql`.
  - `supabase/migrations/20260804050646_phase09_private_media_hardening.sql`.
  - `supabase/tests/database/001_phase09_grants_and_rls.test.sql`.
  - `supabase/tests/database/002_phase09_private_media.test.sql`.
  - `supabase/tests/integration/private_media_storage.mjs`.
  - `supabase/tests/integration/enrollment_races.mjs`.
  - `supabase/README.md`.
  - `MSCBodyTransformation/MSC_Codex_Phased_Workplan/10_PHASE_09_SUPABASE_FOUNDATION.md`.
- Assumptions:
  - Colima memakai 6 CPU, 8 GiB RAM, dan disk 60 GiB.
  - Object private memakai path
    `participant/enrollment/submission/question/object.jpg`.
  - Artifact upload sudah dinormalisasi pipeline iOS menjadi JPEG maksimal
    1600 px; bucket membatasi JPEG hingga 8 MiB.
- Build command:
  - Tidak dijalankan; perubahan ini hanya backend SQL, tests, dan dokumentasi.
- Test commands:
  - `supabase start`.
  - `supabase db reset --local`.
  - `supabase migration list --local`.
  - `supabase db lint --local --level warning --fail-on error`.
  - `supabase db advisors --local --type all --level info --fail-on error`.
  - `supabase test db --local supabase/tests/database`.
  - `node supabase/tests/integration/private_media_storage.mjs` dengan
    environment local dari `supabase status -o env`.
  - `node supabase/tests/integration/enrollment_races.mjs` dengan environment
    local dari `supabase status -o env`.
- Result:
  - Fresh reset PostgreSQL 17 dan tiga migration hardening lulus.
  - Lint tidak menemukan schema error.
  - Advisors tidak mempunyai error atau warning. Info yang tersisa adalah
    unused index pada database kosong dan dua tabel server-only default-deny.
  - 45 assertion pgTAP lulus.
  - 16 assertion Storage API lulus, termasuk signed URL Coach/Admin.
  - 10 assertion concurrent enrollment lulus.
- Remaining blockers:
  - Catatan persistent branch pada saat pengujian ini sudah digantikan oleh
    keputusan environment local-development/hosted-production di atas.
  - Operasi server selain dua RPC baseline, orphan cleanup, adapter iOS, dan
    vertical slice Supabase lokal belum selesai.

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

### 4 Agustus 2026 — Data API grants dan function hardening

- Files changed:
  - `supabase/config.toml` (perubahan existing PostgreSQL 15 ke 17
    dipertahankan).
  - `supabase/migrations/20260804043720_phase09_data_api_hardening.sql`.
  - `supabase/README.md`.
  - `MSCBodyTransformation/MSC_Codex_Phased_Workplan/10_PHASE_09_SUPABASE_FOUNDATION.md`.
- Assumptions:
  - Seluruh fitur aplikasi Phase 09 memerlukan sesi authenticated; tidak ada
    raw-table Data API surface untuk `anon`.
  - Direct mutation Participant tetap ditutup sampai RPC atomik terkait
    tersedia.
  - Mutation CMS hanya dapat melewati policy Admin yang sudah ada.
  - `service_role` hanya digunakan server dan tidak pernah masuk mobile
    client atau repository.
- Build command:
  - Tidak dijalankan; perubahan hanya pada konfigurasi, SQL, dan dokumentasi
    backend.
- Test command:
  - `supabase --version`.
  - `supabase migration --help`.
  - `supabase migration new phase09_data_api_hardening`.
  - `supabase db lint --help`.
  - `supabase db reset --local`.
  - `supabase db lint --local --level error --fail-on error`.
  - PostgreSQL temporary syntax/ACL verification di `/private/tmp` dengan
    baseline migration, stub hosted-only `rls_auto_enable()`, lalu migration
    hardening.
  - `git diff --check`.
- Result:
  - Supabase CLI `2.111.0` tersedia.
  - Migration hardening dibuat melalui Supabase CLI.
  - PostgreSQL local configuration sudah diselaraskan ke major version 17.
  - Pemeriksaan whitespace dan patch dengan `git diff --check` lulus.
  - Kedua migration berhasil diterapkan berurutan pada PostgreSQL sementara.
  - ACL verification: 21 public tables, 19 authenticated-readable tables,
    enam Admin-CMS insertable tables, nol anon-readable tables, dan 21
    service-role-readable tables.
  - RPC enrollment tersedia hanya untuk authenticated; helper private hanya
    untuk authenticated/server; `rls_auto_enable()` tidak executable oleh
    anon atau authenticated.
  - Fresh reset berhenti dengan `LegacyDbBootstrapError` karena local service
    belum tersedia.
  - Lint berhenti dengan `ECONNREFUSED 127.0.0.1:54322`; CLI meminta Docker
    dijalankan dan `supabase start` digunakan.
  - Advisors belum dijalankan karena database lokal belum tersedia.
- Remaining blockers:
  - Pasang dan jalankan Docker-compatible runtime.
  - Jalankan fresh reset, lint, advisors, Data API grants matrix, dan full RLS
    tests sebelum deployment staging.
