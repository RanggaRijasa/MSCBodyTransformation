# Phase 11: Real Data, Public Guest Reads, and Server Operations

> Status: implementasi lokal berlangsung. Gate 11.0, Slice 11.1, dan Slice
> 11.2 sudah diimplementasikan serta diverifikasi; Slice berikutnya adalah
> 11.3. Pekerjaan fase ini dilakukan terhadap Supabase lokal; hosted `main`
> tetap production dan tidak disentuh tanpa persetujuan deployment
> production yang eksplisit.

## Tujuan

Mengganti `phase11Fallback` secara bertahap dengan read model, command
adapter, dan operasi server authoritative yang memakai Supabase lokal.

Phase 11 bukan pembangunan backend dari nol. Fase ini:

- memakai ulang schema, RLS, private Storage, Auth/profile, enrollment,
  submission, review, dan score-refresh foundation dari Phase 09 dan 10;
- menutup gap schema dan operasi server yang masih nyata;
- membatasi Data API dengan explicit grants, RLS, dan RPC privileges;
- membuat Guest membaca data publik tanpa Auth identity;
- menghubungkan feature repositories ke Supabase satu vertical slice pada
  satu waktu;
- mempertahankan repository lokal hanya untuk preview, deterministic tests,
  dan mode demo lokal.

## Keputusan hasil audit

### Yang sudah tersedia dan tidak boleh dibuat ulang

| Area | Baseline yang sudah ada |
|---|---|
| Auth | Supabase Auth lokal, session persistence, Google OAuth, Apple OAuth, provider-aware reauthentication, dan account deletion |
| Profile | Bootstrap Participant, provider display name/avatar defaults, update profile, dan onboarding handoff |
| Program schema | Program, hari, langkah, pertanyaan, pilihan, protected answer key, deadline, dan store-product mapping |
| Participant data | Enrollment, submission, jawaban, quiz result, weigh-in, score, dan adjustment tables |
| Closure data | Winner snapshot, winner rows, poster, dan audit events |
| Commerce foundation | Transaction dan program entitlement tables; verifikasi StoreKit tetap Phase 12 |
| Server operations | Free enrollment, Admin enrollment, Coach transfer, prepare/finalize submission, Coach review, dan score refresh |
| Storage | Private buckets, path/ownership policies, upload adapter, dan orphan inspection/recording foundation |
| Tests | pgTAP grants/RLS/private-media/operations/Auth tests dan integration race/Auth/media tests |
| iOS adapters | Native Foundation Data API, RPC, upload, and submission coordinator foundation |

### Gap nyata setelah audit

- Pada mode Supabase, hanya Auth, session, dan Participant profile yang sudah
  memakai adapter real. Repository feature lain masih diarahkan ke
  `phase11Fallback`.
- `SupabaseProgramCatalogRepository` dan command adapters Phase 09 belum
  menjadi implementasi penuh dari repository yang dipakai feature.
- Transport Data API saat ini mengharuskan access token. Guest membutuhkan
  mode publishable-key/`anon` tanpa membuat anonymous Supabase Auth user.
- Belum ada public-safe Data API contract untuk katalog, leaderboard,
  winner/poster, dan approved Coach directory.
- Belum ada aggregate persistence untuk Coach application, attestation,
  terms acceptance, submission, dan Admin decision.
- Production repository contract masih mengandung mutasi mock-authoritative,
  termasuk `FakeCoachPurchaseResult`, client-side audit append, score/winner
  mutation, dan role approval. Kontrak ini tidak boleh langsung dipakai oleh
  adapter production.
- Operasi quiz reopen, weigh-in/correction, program publish/duplicate,
  winner lock, dan poster publication belum authoritative dan lengkap.
- Private-media authorization sudah mempunyai foundation, tetapi signed
  reads, durable upload lifecycle, dan executable orphan cleanup belum
  selesai sebagai feature flow.
- Contract OpenAPI belum memuat seluruh public read dan Coach application
  surface serta belum menandai secara konsisten operasi yang sudah tersedia.

### Koreksi terhadap workplan lama

- Member level, account purpose, dan onboarding status sudah ditambahkan di
  Phase 10; Phase 11 hanya mengaudit constraint dan authorization-nya.
- Free enrollment, Admin manual enrollment, Coach transfer, submission
  prepare/finalize, review, dan score refresh sudah mempunyai operasi
  server. Phase 11 mengeraskan serta menghubungkannya, bukan membuat ulang.
- Hosted Supabase bukan prasyarat Phase 11. Seluruh implementasi dan
  destructive verification Phase 11 dilakukan lokal.
- “Staging” tidak digunakan. Strategi lingkungan tetap:
  Development = Supabase lokal, Production = hosted `main`.
- Pembayaran verified, StoreKit transaction verification, refund, renewal,
  dan entitlement lifecycle tetap milik Phase 12.
- SMTP/domain tetap skipped dan tidak menjadi gate Phase 11.

## Prasyarat dan gate

- [x] Phase 09 Supabase foundation dan local vertical slice tersedia.
- [x] Phase 09.5 Guest/Auth/Profile/Coach application UI dan mock domain
  tersedia.
- [x] Phase 10 Supabase Auth, session, profile bootstrap, provider defaults,
  dan immediate account deletion tersedia.
- [x] Validasi OAuth lokal Google dan Apple dinyatakan berhasil oleh pengguna
  pada 5 Agustus 2026.
- [x] Hosted `main` ditetapkan sebagai production dan tidak digunakan untuk
  development.
- [x] Sebelum migration Phase 11 pertama, verifikasi `colima status`,
  `docker info`, dan `supabase status`.
- [x] Sebelum `supabase db reset --local`, minta persetujuan destructive
  operation baru dan pastikan target benar-benar lokal.
- [x] Catat baseline migration, pgTAP, integration test, build, dan current
  API-contract result sebelum slice pertama.

## Batas scope

### Termasuk Phase 11

- Public Guest reads.
- Authenticated Participant/Coach/Admin reads.
- Coach application persistence dan Admin decision boundary.
- Free enrollment dan Admin enrollment/transfer.
- Submission, quiz, weigh-in, review, score, leaderboard, winner, dan poster
  server operations.
- Private media authorization dan lifecycle.
- Native iOS Supabase repositories serta removal of feature fallback pada
  mode `debug_local_supabase`.
- RLS, grants, function privileges, audit, idempotency, dan race tests.

### Ditunda ke Phase 12

- StoreKit product loading dan purchase state machine.
- Apple transaction verification.
- Google Play purchase verification untuk Android.
- Paid-program enrollment activation.
- Coach-access payment verification.
- Real entitlement issuance, renewal, expiry reconciliation, refund,
  revocation, rejection-credit, dan cross-platform commerce reconciliation.

Phase 11 boleh membuat schema/operation seam yang dibutuhkan Phase 12, tetapi:

- aplikasi tidak boleh mengubah payment menjadi `verified`;
- aplikasi tidak boleh membuat entitlement;
- `FakeCoachPurchaseResult` tidak boleh masuk ke adapter Supabase;
- success-path approval yang memerlukan verified payment hanya boleh dites
  dengan privileged deterministic database fixture di test setup, tidak
  melalui UI atau client production.

### Ditunda ke Phase 13

- Deployment migration/function/config ke hosted `main`.
- Hosted Google dan Apple provider configuration.
- Release URL dan publishable key.
- Production Security/Performance Advisor sign-off.
- TestFlight dan final physical-device matrix terhadap hosted backend.

## Authority boundaries

- Guest adalah logged-out app state, bukan `UserRole` dan bukan row
  `auth.users`.
- Publishable key mengidentifikasi aplikasi publik; authorization tetap
  ditentukan oleh role `anon`/`authenticated`, explicit grants, dan RLS.
- `anon` hanya boleh membaca proyeksi publik yang ditentukan secara eksplisit.
- Profile privat, nomor HP, application, payment, entitlement, body weight,
  submission, answer key, private media, dan audit tidak public.
- Self-registration selalu membuat Participant.
- Editable profile dan `raw_user_meta_data` tidak pernah menentukan role,
  eligibility, harga, payment, entitlement, atau authorization.
- Protected role dibaca dari server-controlled data.
- Client boleh mengirim input, idempotency key, dan attestations; client tidak
  boleh mengirim authoritative points, store price, verified payment, Admin
  decision, protected role, Coach QR, entitlement, winner, atau audit event.
- Semua privileged mutation dijalankan sebagai satu server transaction,
  mengautorisasi caller di server, memakai server clock, dan menulis audit.
- `SECURITY DEFINER` hanya dipakai bila benar-benar diperlukan, selalu dengan
  fixed `search_path`, schema-qualified references, input validation, serta
  `EXECUTE` yang dicabut dari `PUBLIC`, `anon`, dan role lain sebelum
  diberikan kembali secara minimum.
- Function privilege dan table/view grants adalah boundary terpisah dari RLS;
  keduanya wajib berada di migration dan diuji.

## Strategi public Data API

Guest request menggunakan project URL dan publishable key tanpa user JWT.
Request tersebut menjalankan role Postgres `anon`; ini berbeda dari
anonymous Supabase Auth user.

Untuk setiap public surface, pilih kontrak yang paling sempit:

1. Gunakan direct table/view read hanya bila column projection, row policy,
   dan grants tidak membuka base data privat.
2. Gunakan `security_invoker` view bila caller memang aman diberi akses ke
   underlying objects dan RLS-nya cukup.
3. Gunakan fixed-projection RPC bila base table tidak boleh diberikan kepada
   `anon`. RPC tersebut hanya mengembalikan field publik, mempunyai filter
   publik yang tetap, dan mengikuti aturan `SECURITY DEFINER` di atas.

Tidak boleh memberi `anon SELECT` luas pada private base tables hanya agar
sebuah view dapat bekerja.

Public contract minimum:

- published and registration-visible program catalog;
- approved/public Coach directory tanpa contact/private profile data;
- public leaderboard projection tanpa body weight atau private identifiers;
- locked winner projection;
- published winner poster metadata dan public media reference yang memang
  disetujui untuk publik.

## Urutan implementasi

Setiap slice harus menyelesaikan contract, migration, database tests, iOS
adapter, focused Swift tests, dan simulator build sebelum slice berikutnya.

### 11.0 — Baseline dan contract reconciliation

- [x] Jalankan readiness checks lokal.
- [x] Dengan persetujuan destructive baru, jalankan fresh local reset dari
  seluruh migration/seed.
- [x] Jalankan seluruh pgTAP dan integration tests yang sudah ada.
- [x] Jalankan database lint lokal dan selesaikan warning security yang
  relevan sebelum menambah surface baru.
- [x] Inventarisasi table/view/function grants untuk `anon`,
  `authenticated`, `service_role`, dan `PUBLIC`.
- [x] Inventarisasi semua `SECURITY DEFINER` function beserta owner,
  `search_path`, dan executable roles.
- [x] Rekonsiliasi
  `Contracts/program-api-v1.openapi.yaml`,
  `PROGRAM_END_TO_END_CONTRACT_MATRIX.md`, dan migration yang sudah ada.
- [x] Tandai setiap endpoint sebagai `existing-needs-wiring`, `new-phase11`,
  atau `deferred-phase12`.
- [x] Tetapkan stable error codes untuk authorization, validation, conflict,
  cutoff, capacity, duplicate, offline, timeout, dan unknown failure.

#### Gate 11.0

- [x] Fresh baseline hijau tanpa mengubah hosted project.
- [x] Tidak ada fungsi privileged yang executable oleh role yang tidak
  semestinya.
- [x] Tidak ada endpoint Phase 12 yang akan diimplementasikan diam-diam di
  Phase 11.

### 11.1 — Public Guest transport dan reads

#### Backend

- [x] Buat public-safe contract untuk katalog program.
- [x] Buat public-safe contract untuk approved Coach directory.
- [x] Buat public-safe leaderboard projection.
- [x] Buat public-safe locked winners dan published poster projection.
- [x] Berikan explicit object/function grants hanya ke `anon` dan
  `authenticated` yang membutuhkannya.
- [x] Pastikan base private tables tetap tidak dapat dibaca `anon`.
- [x] Tambahkan deterministic ordering, pagination/limit, dan filter yang
  dapat memakai index.

#### iOS

- [x] Pisahkan request authorization menjadi public `anon` dan authenticated
  user-session mode.
- [x] Public mode mengirim publishable key dan tidak mengharuskan access
  token.
- [x] Public mode tidak memanggil anonymous sign-in.
- [x] Implementasikan typed DTO dan repository untuk empat public surfaces.
- [x] Hubungkan Guest Home/Program/Coach/Peringkat ke repository real saat
  `MSC_APP_MODE=debug_local_supabase`.
- [x] Pertahankan fixture repository untuk preview dan mode demo lokal.
- [x] Jangan fallback diam-diam ke fixture ketika Supabase real gagal;
  tampilkan loading, empty, atau actionable error state.

#### Tests

- [x] `anon` dapat membaca hanya field dan row publik.
- [x] Guest tidak dapat membaca profile, application, payment, entitlement,
  enrollment, weight, submission, answer key, private media, atau audit.
- [x] Public DTO tidak mempunyai field PII yang dapat terisi tanpa sengaja.
- [x] Request test membuktikan Guest tidak mengirim user bearer token.

#### Gate 11.1

- [x] Seluruh Guest public screens memakai Supabase lokal tanpa Auth identity.
- [x] Tidak ada private-data leakage pada direct REST/RPC attempts.

### 11.2 — Authenticated read models dan repository boundaries

- [x] Audit protocol repository lama dan pisahkan read operation dari
  privileged command.
- [x] Jangan membuat adapter production untuk client-side authoritative
  mutations seperti `save(program:)`, `append(audit:)`,
  `setCoachApproval`, `lockTopFive`, atau raw score adjustment.
- [x] Definisikan typed authenticated read models untuk:
  - own profile and onboarding state;
  - own enrollment contexts;
  - days, steps, questions, and current access state;
  - own submissions, quiz results, weigh-ins, and score;
  - assigned-Coach context;
  - role-specific dashboard summaries.
- [x] Gunakan explicit server filter selain RLS pada query yang mengakses
  own/assigned rows.
- [x] Implementasikan mapping domain yang lossless dan stabil terhadap null,
  empty, dan enum raw values.
- [x] Hubungkan read repositories ke `AppRepositories` satu per satu.
- [x] Hapus `phase11Fallback` hanya untuk repository yang sudah mempunyai
  complete real implementation dan complete state handling; authenticated
  Participant read path tidak lagi memakai fallback, sedangkan command dan
  role surface Slice berikutnya tetap dipertahankan.

#### Gate 11.2

- [x] Participant yang login memuat state miliknya dari Supabase lokal.
- [x] Unrelated Participant tidak dapat membaca data Participant lain.
- [x] Tidak ada View yang melakukan database query langsung.

### 11.3 — Coach application dan protected role decision

#### Schema

- [ ] Tambahkan Coach application aggregate dengan stable status.
- [ ] Simpan immutable applicant identity reference.
- [ ] Simpan member-level snapshot, HOM STS, ICT, terms version, timestamps,
  submission state, dan decision state.
- [ ] Enforce tepat satu active application per user.
- [ ] Pisahkan application, payment evidence/state, protected role, Coach
  profile/QR, dan Coach-access entitlement.
- [ ] Pastikan user tidak dapat mengubah payment verification, decision,
  role, QR, atau entitlement melalui direct Data API.

#### Operations

- [ ] Create/update own draft secara idempoten.
- [ ] Submit application hanya setelah field dan attestations lengkap.
- [ ] Applicant hanya membaca application miliknya.
- [ ] Admin list/detail memakai server-computed eligibility dan read-only
  payment state.
- [ ] Rejection memerlukan alasan dan bersifat idempoten.
- [ ] Approval:
  - mengunci application dan payment/entitlement reference;
  - menghitung ulang eligibility;
  - memerlukan server-controlled verified payment dan valid entitlement;
  - mengubah protected role ke Coach;
  - membuat Coach profile dan unique opaque QR bila belum ada;
  - menulis audit di transaction yang sama.
- [ ] Repeated approve/reject mengembalikan hasil konsisten.
- [ ] Conflict approve-versus-reject hanya menghasilkan satu terminal
  decision.
- [ ] Coach operation memeriksa approved role dan active Coach entitlement
  pada server.

#### Phase 12 seam

- [ ] Ganti `FakeCoachPurchaseResult` pada production boundary dengan
  server-owned payment reference/state contract.
- [ ] Phase 11 client tidak menyediakan tombol atau shortcut untuk
  memalsukan payment verified.
- [ ] Database success test memakai privileged deterministic fixture hanya
  di test setup.
- [ ] App flow yang membutuhkan real payment tetap menampilkan state handoff
  yang jelas sampai Phase 12.

#### Gate 11.3

- [ ] Applicant tidak dapat self-promote.
- [ ] Admin decision authoritative, idempoten, dan teraudit.
- [ ] Payment verified saja tidak mengubah role.

### 11.4 — Program catalog, QR, dan enrollment

- [ ] Hubungkan existing published program catalog adapter ke domain
  repository yang digunakan feature.
- [ ] Rekonsiliasi `enroll_free_program` dengan contract:
  - authenticated Participant caller;
  - program active dan registration window terbuka;
  - capacity checked in transaction;
  - unique opaque Coach QR resolved server-side;
  - first Coach assignment berlaku konsisten lintas program;
  - different-Coach QR ditolak;
  - enrollment dan leaderboard/score row dibuat atomik;
  - duplicate request idempoten.
- [ ] Hubungkan Admin manual enrollment existing RPC dengan mandatory reason,
  override rules, dan audit.
- [ ] Hubungkan Coach transfer existing RPC dengan mandatory reason,
  assignment guard, dan audit.
- [ ] Preserve pending program/Coach intent melalui Auth tanpa menyimpan raw
  QR dalam log atau user metadata.
- [ ] Paid enrollment tetap mengembalikan Phase 12 handoff, bukan membuat
  client-only enrollment.

#### Tests

- [ ] Invalid/mismatched Coach QR.
- [ ] Inactive Coach.
- [ ] Duplicate enrollment.
- [ ] Concurrent last-capacity enrollment.
- [ ] Exact registration cutoff.
- [ ] Admin override after cutoff.
- [ ] Same-Coach across programs dan different-Coach rejection.
- [ ] Unrelated user tidak dapat membaca atau mengubah enrollment.

#### Gate 11.4

- [ ] Free enrollment critical path memakai server operation dari aplikasi.
- [ ] Tidak ada manual Coach code fallback atau client-side capacity claim.

### 11.5 — Participant activity, media, quiz, weigh-in, dan scoring

#### Submission dan media

- [ ] Harden dan hubungkan existing prepare/finalize submission operations.
- [ ] Enforce required answers dan evidence requirements berdasarkan
  published step definition.
- [ ] Preserve rejected submission history pada resubmission.
- [ ] Upload private JPEG yang sudah dinormalisasi hanya ke authorized path.
- [ ] Validate MIME, object size, ownership, enrollment, step, question, dan
  durable answer reference.
- [ ] Retry tidak membuat duplicate submission, answer, atau object.
- [ ] Signed/authenticated reads hanya untuk owner, assigned Coach, atau
  Admin.
- [ ] Implementasikan executable orphan cleanup yang audit-safe dan tidak
  menghapus durable media.

#### Quiz

- [ ] Score quiz dari protected answer key di server.
- [ ] Simpan satu attempt authoritative per enrollment/step.
- [ ] Tolak attempt kedua sampai Admin reopen.
- [ ] Tambahkan Admin reopen operation dengan reason dan audit.
- [ ] Client tidak menerima protected answer key.

#### Weigh-in

- [ ] Tambahkan initial/daily/final weigh-in operation.
- [ ] Gunakan numeric/Decimal-compatible canonical storage.
- [ ] Enforce timing, step link, uniqueness, dan ownership.
- [ ] Tambahkan Admin correction operation dengan reason dan audit.
- [ ] Weight gain menghasilkan nol weight points, bukan nilai negatif.
- [ ] Public leaderboard tidak pernah mengembalikan weight.

#### Score

- [ ] Jadikan score reconciliation server-authoritative.
- [ ] Approved step points berasal dari published definition.
- [ ] Pending/rejected submission tidak mendapat authoritative points.
- [ ] Duplicate completion tidak menggandakan points.
- [ ] Adjustment tetap terpisah dan hanya melalui privileged operation.
- [ ] Client hanya menampilkan authoritative breakdown/result.

#### Gate 11.5

- [ ] Participant dapat menyelesaikan free-program journey dengan Supabase
  lokal.
- [ ] Private media tidak dapat diakses user tidak terkait.
- [ ] Score tetap konsisten setelah retry, review, rejection, correction, dan
  reconciliation.

### 11.6 — Coach monitoring dan review

- [ ] Tambahkan assigned-participant roster read model.
- [ ] Tambahkan progress, activity history, and pending-review queue.
- [ ] Batasi private weight, answers, and media ke assigned Coach.
- [ ] Hubungkan existing review RPC dan score refresh ke Coach feature.
- [ ] Approval/rejection review wajib idempoten.
- [ ] Rejection memerlukan alasan.
- [ ] Expired/non-entitled Coach ditolak server walau role atau UI state
  tercache.
- [ ] Coach tidak dapat membuka Participant milik Coach lain.

#### Gate 11.6

- [ ] Coach critical read/review flow tidak memakai fixture pada mode
  Supabase.
- [ ] Cross-Coach direct REST/RPC attempts ditolak.

### 11.7 — Admin CMS, people, correction, dan program closure

- [ ] Tambahkan authoritative program draft save operation.
- [ ] Tambahkan program duplicate operation yang mengganti nested IDs dan
  menggeser tanggal secara konsisten.
- [ ] Tambahkan publish operation dengan full server validation dan audit.
- [ ] Hubungkan Admin people/application reads dan protected decisions.
- [ ] Tambahkan privileged score adjustment dengan reason dan audit.
- [ ] Hubungkan Admin enrollment dan Coach transfer operations.
- [ ] Tambahkan winner-lock operation:
  - menolak bila review/final-weight gate belum selesai;
  - tie-break deterministic;
  - mendukung kurang dari lima pemenang;
  - membuat stable immutable snapshot;
  - repeated lock tidak mengubah snapshot diam-diam.
- [ ] Tambahkan poster publication yang terkait program dan winner snapshot.
- [ ] Hanya published poster yang masuk public Guest projection.
- [ ] Hapus client-side direct `AuditRepository.append` dari production
  mutation flow; audit ditulis oleh server transaction.

#### Gate 11.7

- [ ] Admin critical flow memakai server authorization dan audit.
- [ ] Participant atau Coach tidak dapat menjalankan Admin RPC.
- [ ] Winner dan poster public projection berasal dari locked/published state.

### 11.8 — Fallback removal dan end-to-end local verification

- [ ] Ganti `AppRepositories(... phase11Fallback:)` dengan explicit real
  repository assembly untuk seluruh Phase 11 surface.
- [ ] Tidak ada repository feature yang diam-diam membaca fixture dalam mode
  `debug_local_supabase`.
- [ ] Mode demo lokal, previews, dan deterministic UI tests tetap memakai
  `InMemoryAppRepository`.
- [ ] Semua real repository memetakan loading, loaded, empty, offline,
  timeout, authorization, conflict, dan unknown error.
- [ ] Force-close/relaunch memulihkan session dan memuat ulang real data.
- [ ] Logout membersihkan private feature state sebelum Guest reads dimuat.
- [ ] Pergantian Google/Apple account tidak menampilkan cache akun sebelumnya.
- [ ] Jalankan focused UI tests untuk Guest, Participant, Coach, dan Admin.
- [ ] Jalankan localization catalog check bila ada copy UI yang berubah.
- [ ] Jalankan full Swift tests dan simulator build.
- [ ] Jalankan fresh local reset, pgTAP, integration, lint, dan local advisor
  review sebagai final Phase 11 gate.

## Test matrix minimum

### Database authorization

- [x] `anon`.
- [ ] Authenticated applicant.
- [x] Participant owner.
- [x] Unrelated Participant.
- [ ] Assigned Coach with active entitlement.
- [ ] Unassigned Coach.
- [ ] Expired/non-entitled Coach.
- [ ] Admin.
- [ ] Metadata role escalation attempt.
- [x] Direct table access versus intended RPC access.
- [x] Function execution by `PUBLIC`, `anon`, and unauthorized
  `authenticated` callers.

### Idempotency dan concurrency

- [ ] Duplicate Coach application draft/submit/approve/reject.
- [ ] Concurrent approve versus reject.
- [ ] Duplicate and concurrent enrollment.
- [ ] Last-capacity enrollment race.
- [ ] Duplicate prepare/finalize submission.
- [ ] Concurrent Coach review.
- [ ] Duplicate quiz attempt.
- [ ] Duplicate weigh-in.
- [ ] Repeated score reconciliation.
- [ ] Repeated winner lock dan poster publish.
- [ ] Duplicate object upload dan orphan cleanup.

### Privacy

- [x] Guest cannot read PII.
- [x] Leaderboard omits body weight.
- [x] Answer key never reaches Participant or Guest.
- [ ] Private media is not public and signed access is short-lived.
- [ ] Raw Coach QR, token, password, weight, and private path are absent from
  logs and user-facing technical errors.
- [ ] Logout/account switch clears private cached state.

### iOS adapter

- [x] Public request uses publishable key without Auth identity.
- [x] Authenticated request uses current session JWT.
- [ ] Expired session maps to centralized authentication handling.
- [x] DTO mapping covers null, empty, unknown enum, and date/timezone values.
- [x] Transport errors map to stable domain errors.
- [x] No silent fixture fallback in Supabase mode.
- [x] Local demo and previews remain deterministic and offline.

## Verification commands

Exact commands must tetap dikonfirmasi terhadap installed CLI help saat
implementasi dimulai. Baseline command set yang sudah dipakai repository:

```bash
supabase status
supabase db reset --local
supabase migration list --local
supabase db lint --local --level warning --fail-on error
supabase db advisors --local --type all --level warn --fail-on error
supabase db diff --local
supabase test db --local supabase/tests/database
node supabase/tests/integration/auth_lifecycle.mjs
node supabase/tests/integration/public_guest_reads.mjs
node supabase/tests/integration/authenticated_reads.mjs
node supabase/tests/integration/private_media_storage.mjs
node supabase/tests/integration/enrollment_races.mjs
node supabase/tests/integration/submission_review_races.mjs
scripts/check_localization_catalog.sh
xcodebuild test \
  -project MSCBodyTransformation.xcodeproj \
  -scheme MSCBodyTransformation \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  -parallel-testing-enabled NO \
  -only-testing:MSCBodyTransformationTests
```

Notes:

- `supabase db reset --local` is destructive and requires explicit approval
  immediately before execution.
- Integration scripts memerlukan environment lokal yang dihasilkan
  `supabase status -o env`; jangan simpan atau tampilkan credential tersebut
  di workplan, source control, atau log.
- Tambahkan integration script Phase 11 baru ke command set ini setelah
  script benar-benar dibuat; jangan mengacu pada wrapper yang belum ada.
- Localization check is required only when runtime UI copy changes, tetapi
  visible localization key tetap release-blocking.
- Hosted CLI targets are prohibited during Phase 11 implementation.

## Referensi teknis Supabase

- [Securing your API](https://supabase.com/docs/guides/api/securing-your-api)
  untuk pemisahan explicit grants dan RLS.
- [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)
  untuk role `anon`/`authenticated`, policy, index, dan
  `security_invoker` view.
- [Database Functions](https://supabase.com/docs/guides/database/functions)
  untuk `SECURITY INVOKER`, `SECURITY DEFINER`, fixed `search_path`, dan
  function privileges.
- [Storage Buckets](https://supabase.com/docs/guides/storage/buckets/fundamentals)
  untuk private bucket, authenticated download, dan signed URL.
- [Data API explicit-grant breaking change](https://supabase.com/changelog/45329-breaking-change-tables-not-exposed-to-data-and-graphql-api-automatically)
  untuk memastikan migration Phase 11 tidak bergantung pada default grants.

## Exit criteria

- [ ] Guest public reads work without Auth identity and expose no PII.
- [ ] Participant critical free-program journey uses Supabase local.
- [ ] Coach critical monitoring/review journey uses Supabase local.
- [ ] Admin critical management/closure journey uses Supabase local.
- [ ] Coach application and Admin decision are authoritative, idempotent,
  protected, and audited.
- [ ] Payment verification remains impossible from the app and is clearly
  handed off to Phase 12.
- [ ] Protected Coach operation requires approved role and active
  server-controlled entitlement.
- [ ] Private media cannot be accessed by unrelated users.
- [ ] Authoritative score, leaderboard, winner, and poster behavior pass
  deterministic and race tests.
- [ ] All exposed tables/views/functions have explicit least-privilege
  grants and complete RLS/function privilege tests.
- [ ] No real-data repository uses `phase11Fallback` in
  `debug_local_supabase`.
- [ ] Local demo, previews, and deterministic tests remain available without
  Supabase.
- [ ] Fresh local reset, pgTAP, integration tests, Swift tests, simulator
  build, lint, and relevant advisors are green.
- [ ] No migration, seed, function, configuration, or credential has been
  deployed to hosted `main`.
- [ ] Tidak ada invite, wallet, seat credit, manual Coach code, atau
  client-authoritative commerce/role/scoring path.

## Handoff setelah Phase 11

1. Phase 12 mengimplementasikan StoreKit and server-side commerce
   verification terhadap contract seam Phase 11.
2. Phase 13 meminta persetujuan production eksplisit sebelum deployment ke
   hosted `main`.
3. Hosted Google/Apple provider, Release environment, advisors, TestFlight,
   dan physical-device matrix diselesaikan setelah hosted deployment.
4. SMTP/domain tetap skipped sampai keputusan produk berubah.

## Progress log

### 4 Agustus 2026 — Rekonsiliasi Phase 09.5

- Menghapus requirement invite/wallet/seat-credit lama.
- Menambahkan public-safe Guest reads, Member level, Coach application,
  payment/approval/role/entitlement separation, dan atomic Admin decision.
- Tidak ada migration atau deployment yang dilakukan.

### 5 Agustus 2026 — Audit pra-implementasi Phase 11

- Mencatat konfirmasi pengguna bahwa seluruh validasi OAuth lokal Google dan
  Apple berhasil.
- Mengaudit migration, pgTAP/integration tests, OpenAPI contract, Supabase
  adapters, repository assembly, Phase 10 handoff, Phase 12 boundary, dan
  current implementation status.
- Menetapkan bahwa Phase 11 adalah adapter/server-gap phase, bukan schema
  foundation ulang.
- Menandai `phase11Fallback` sebagai integration gap utama.
- Memisahkan Guest `anon` transport dari anonymous Auth identity.
- Menambahkan explicit grants, RLS, function privilege, `SECURITY DEFINER`,
  privacy, idempotency, race, dan fallback-removal gates.
- Memindahkan real payment verification dan entitlement lifecycle secara
  tegas ke Phase 12 serta hosted deployment ke Phase 13.
- Tidak menjalankan Supabase, database reset, build, test, atau deployment
  karena perubahan ini hanya audit dokumentasi.

### 6 Agustus 2026 — Gate 11.0 baseline dan contract reconciliation

- Menjalankan readiness checks, fresh `supabase db reset --local` setelah
  persetujuan eksplisit, migration list, schema diff, lint, dan advisors.
- Seluruh 10 migration, 139 pgTAP assertions, 22 Auth checks, 16 private
  media assertions, 14 enrollment race assertions, dan 15 submission/review
  race assertions lulus.
- Menyesuaikan integration fixture Phase 09 agar meng-upsert profile yang
  otomatis dibuat oleh Auth bootstrap Phase 10.
- Mengaudit 21 public tables, seluruh RLS/grant, private schema usage,
  function owner/search path/executable roles, dan default privileges.
- Menyimpan endpoint classification serta stable error catalog di
  `supabase/PHASE_11_GATE_11_0_BASELINE.md`.
- Simulator build/run lulus tanpa warning; 176 Swift tests lulus.
- OpenAPI YAML valid dan tidak ada schema drift.
- Hosted `main` tidak disentuh. Slice berikutnya adalah 11.1 Public Guest
  transport dan reads.

### 6 Agustus 2026 — Slice 11.1 Public Guest reads

- Menambahkan migration public projection untuk katalog program, approved
  Coach directory, leaderboard total, locked winners, dan published posters.
- Menambahkan public identifier terpisah agar Auth user ID, enrollment ID,
  raw Coach QR, nomor HP, weight breakdown, dan private references tidak
  masuk payload Guest.
- Membatasi execute privilege RPC ke `anon` dan `authenticated`; base private
  tables tetap tidak diberi `anon SELECT`.
- Memisahkan transport iOS `publicAnon` dari authenticated bearer transport
  serta menambahkan empat typed public repositories.
- Menghubungkan Guest Home, Program, Coach, dan Peringkat ke Supabase real
  pada `debug_local_supabase`; local demo dan preview tetap memakai fixture.
- Memperbarui OpenAPI public contract dengan publishable-key security dan
  public schemas tanpa additional properties.
- Fresh `supabase db reset --local` lulus untuk 11 migration; 175 pgTAP,
  22 Auth, 16 private-media, 14 enrollment-race, 15 submission/review-race,
  dan 22 Guest HTTP checks lulus.
- Database lint dan advisors tidak menemukan masalah; migration list sinkron
  dan schema diff kosong.
- Simulator build/run lulus tanpa warning, 179 Swift tests lulus, dan empat
  Guest tabs tervalidasi terhadap Supabase lokal tanpa Auth identity.
- Hosted `main` tidak disentuh. Slice berikutnya adalah 11.2 authenticated
  read models dan repository boundaries.

### 6 Agustus 2026 — Slice 11.2 Authenticated read models

- Memisahkan protocol read dan privileged command tanpa membuat adapter
  production untuk mutasi client-authoritative.
- Menambahkan authenticated Participant aggregate untuk own profile,
  onboarding, enrollment context, program content, server-resolved day
  access, submission/answer/quiz, weigh-in, own score, assigned Coach, dan
  dashboard summary.
- Menghubungkan `ParticipantJourneyStore` ke authenticated repository saat
  mode Supabase; state hari memakai hasil server dan jalur ini tidak
  melakukan silent fallback ke fixture. View tetap tidak mempunyai query
  database.
- Menambahkan fixed authenticated RPC projection, explicit caller filters,
  least-privilege execute grants, dan hardening `program_scores` agar
  breakdown privat hanya dapat dibaca owner, assigned Coach, atau Admin.
- Memperbarui OpenAPI, README backend, DTO mapping null/empty/unknown enum,
  authenticated bearer transport test, serta repository/store routing test.
- Files utama yang berubah: authenticated domain models dan repository
  protocols, Supabase client/DTO/repository, `AppRepositories`,
  `AppEnvironment`, `ParticipantJourneyStore`, OpenAPI, tiga migration Phase
  11, pgTAP/integration tests, dan workplan ini.
- Asumsi: Slice 11.2 menghubungkan read path Participant terlebih dahulu.
  Command Participant serta read/command Coach dan Admin tetap pada slice
  berikutnya dan tidak dipresentasikan sebagai server-authoritative.
- Build: `XcodeBuildMCP build_sim` pada iPhone 17 iOS 26.5 — lulus tanpa
  warning.
- Swift tests: `XcodeBuildMCP test_sim
  -only-testing:MSCBodyTransformationTests` — 184 lulus, 0 gagal.
- Database: fresh `supabase db reset --local` setelah persetujuan eksplisit;
  13 migration diterapkan. `supabase test db --local
  supabase/tests/database` — 200 assertion lulus.
- Integration: `public_guest_reads.mjs` — 22 checks; dan
  `authenticated_reads.mjs` — 27 checks; seluruhnya lulus terhadap loopback
  local stack.
- `supabase db lint --local --level warning --fail-on error` dan
  `supabase db advisors --local --type all --level warn --fail-on error`
  tidak menemukan masalah. Migration list sinkron dan schema diff kosong.
- Local OAuth test identities terhapus oleh fresh reset; provider
  configuration tetap ada, tetapi login manual berikutnya akan membuat akun
  test baru.
- Hosted `main` tidak disentuh. Blocker Slice 11.2 tidak ada; item berikutnya
  adalah Slice 11.3 Coach application dan protected role decision.
