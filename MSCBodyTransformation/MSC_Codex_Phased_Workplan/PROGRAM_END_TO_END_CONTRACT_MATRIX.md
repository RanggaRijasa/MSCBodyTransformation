# Matriks Kontrak Program End-to-End

Status: authoritative companion untuk
`PROGRAM_END_TO_END_REMEDIATION_WORKPLAN.md`.

Dokumen ini menjelaskan pemilik setiap field, consumer runtime, batas privasi,
dan jalur migrasi. Phase lama hanya menjadi catatan historis bila bertentangan
dengan matriks ini.

## Matriks Admin → runtime → server

| Area | Field authoritative | Admin | Peserta | Coach | Server |
|---|---|---|---|---|---|
| Identitas | `id`, `sourceProgramID`, judul, ringkasan, kategori | Membuat dan menduplikasi | Membaca | Membaca | Menjaga ID dan lineage |
| Cover | image reference dan alternative text | Upload gambar | Membaca gambar | Membaca gambar | Menjaga metadata/media |
| Lifecycle | status, start/end, timezone | Menerbitkan/menutup | Membaca status efektif | Membaca status efektif | Menentukan transisi |
| Ritme | scheduled/self-paced, duration mode | Mengatur | Menentukan hari tersedia | Menghitung expected progress | Menentukan akses hari |
| Kapasitas | participant limit | Mengatur | Melihat availability | Tidak mengubah | Menegakkan atomik |
| Batas pendaftaran | `registrationClosesAt` exact timestamp atau `null` | Mengatur; dapat melakukan enrollment manual setelah tutup dengan alasan | Melihat cutoff; self-enrollment ditolak tepat pada/selewat cutoff | Tidak mengubah | Mengunci program, mengecek server clock, dan mengaudit override Admin |
| Akses | publik | Tidak ada picker | Memilih dari katalog | Tidak mengundang | Menegakkan program publik |
| Commerce | gratis/berbayar, desired price, platform availability | Mengatur intent | Membaca harga store | Tidak mengubah | Memetakan produk/entitlement |
| Scoring | activity points, weight points/kg, quiz threshold | Mengatur sebelum enrollment | Melihat aturan | Melihat breakdown | Menghitung authoritative |
| Hari | ID, order, date/offset, visibility policy | Menyusun dan menyalin isi antarhari; memilih tersedia/terkunci/disembunyikan | Menjalankan sesuai policy | Memantau | Menentukan availability |
| Langkah | ID, order, kind, instructions, media, completion policy | Menyusun | Merender | Melihat konteks | Memvalidasi submission |
| Pertanyaan | ID, kind, prompt, options/media | Menyusun | Menjawab | Melihat saat berwenang | Memvalidasi payload |
| Answer key | answer key objektif | Menyusun | **Tidak pernah menerima** | Membaca untuk konteks | Menilai kuis |
| Coach | `ParticipantProfile.coachID` | Transfer dengan alasan | Membaca | Membaca assignment | Menjaga satu Coach aktif |
| Enrollment | program, participant, Coach snapshot, status | Membaca/admin fallback; hanya deadline yang boleh dioverride | Memilih per program | Membaca yang terkait | Membuat idempoten; lifecycle, kapasitas, Coach, dan pembayaran tetap authoritative |
| Submission | answers per `questionID`, status, attempt | Membaca | Membuat/memperbaiki | Review subjektif/foto | Validasi dan audit |
| Timbang | enrollment, step, kind awal/harian/akhir, Decimal, waktu | Koreksi dengan alasan | Mengisi dari content step | Melihat riwayat privat; tidak di feed | Menghitung weight points dari awal-akhir saja |
| Peringkat | score breakdown dan rank | Menutup/mengunci | Membaca tanpa berat privat | Membaca program terkait | Menghitung deterministik |
| Pemenang | immutable snapshot | Mengunci | Membaca | Membaca | Menjaga snapshot |
| Poster | program dan winner snapshot | Mengunggah/menerbitkan | Membaca di Home | Membaca bila relevan | Menjaga relasi |

## Matriks Guest, membership, dan Coach access

| Area | Owner authoritative | Guest | Participant/applicant | Admin | Backend phase |
|---|---|---|---|---|---|
| Guest access | Session state | Public read tanpa user row | — | — | Public-safe view/grant tanpa anonymous signup |
| Auth identity | `auth.users.id` + provider identity | Tidak membuat identity | Login/registrasi; tidak memilih role | Tidak memakai metadata client untuk role | Phase 10 Auth lifecycle |
| Session | Auth service + Keychain device-only cache | Logged out | Restore/refresh/logout melalui `SessionRepository` | Boundary yang sama | Phase 10; hosted policy Phase 13 |
| Profile | `profiles.user_id`, role, display name, phone, member level, purpose, onboarding status/expiry | Tidak membaca | Menulis field allowlisted miliknya | Membaca sesuai kebutuhan | Phase 10 profile bootstrap/RLS |
| Penghapusan akun | Edge Function + Auth Admin server-side | — | Reauthentication lalu immediate deletion; media privat dan data program dihapus | Admin self-delete ditolak; relationship Coach harus dialihkan | Phase 10 lokal; hosted retention review Phase 13 |
| Pending enrollment | Secure local intent + server revalidation | Memilih program sebelum login | TTL/nonce/environment; QR opaque bukan authorization | — | Phase 10 persistence; Phase 11 enrollment adapter |
| Member level | Profile/application snapshot | Tidak membaca | Memilih; tidak memberi capability | Membaca | Phase 10/11 validation |
| Eligibility | Domain/server rule | — | Attest HOM STS dan ICT | Membaca hasil | Server menghitung ulang |
| Coach application | Application aggregate | — | Membuat satu active application | Approve/reject | Phase 11 atomic operation |
| Price band | Server/store mapping | — | Membaca preview | Membaca | Phase 12 authoritative mapping |
| Payment | Store verification | — | Tidak dapat menandai verified | Membaca | Phase 12 idempotent verification |
| Approval | Protected server decision | — | Tidak dapat menulis | Konfirmasi/rejection reason | Phase 11 atomic dan audited |
| Role | Protected role table | Tidak ada | Tetap Participant selama pending | Tidak mengedit metadata client | Berubah hanya setelah approval valid |
| Entitlement | Server clock/store state | Public only | Membaca miliknya | Membaca untuk review | Phase 12 expiry/renewal/revocation |

Phase 09.5 mengimplementasikan presentation dan repository lokal untuk
matriks ini. Kolom Backend belum production dan tidak boleh disimpulkan
selesai dari fake payment atau local Admin approval.

## Inventory migrasi source

| Source lama | Masalah | Target | Strategi |
|---|---|---|---|
| `AdminProgramAccess` | Mode selain publik sudah tidak berlaku | Program selalu publik | Hapus dari editor dan mapping; decoder lama mengabaikan nilai |
| `ProgramStep.points` | Poin tidak boleh per langkah | `ProgramScoringConfiguration.pointsPerActivity` | Konversi fixture memakai nilai program; API lama deprecated selama transisi |
| `weightPointsPerKilogram` langsung di `Program` | Konfigurasi tersebar | `ProgramScoringConfiguration` | Decode lama ke scoring configuration |
| `StepRequirement`/`photoEvidence` | Bukti terpisah menduplikasi pertanyaan | `ProgramQuestionDefinition.photoUpload` | Konversi setiap requirement menjadi question |
| `SubmissionEvidence` | Payload tidak typed dan tidak terikat question | `StepSubmissionAnswer` | Konversi berdasarkan requirement/question ID |
| `AdminQuizQuestionKind.fileUpload` | Upload file umum tidak didukung | `.photoUpload` | Raw-value decoder menerima legacy `file_upload` lalu menulis `photo_upload` |
| `isRequired` pada pertanyaan interaktif | Semua interaktif wajib | Derived dari question kind | Decoder lama diabaikan; heading/text tidak interaktif |
| `initial/finalWeighInWindowHours` | Timbang global | `ProgramContentKind.initial/daily/finalWeighIn` | Fixture lama mendapat content step eksplisit; harian terikat ke step |
| `CoachInvite`, `InviteRepository` | QR bukan undangan program | Coach QR validator/enrollment operation | Hapus UI/use case program invite |
| `CoachWallet`, ledger, seat credit | Model commerce salah | Program purchase + entitlement | Tidak dimigrasikan ke runtime baru |
| `ProgramEnrollment.pending` | Approval Admin tidak berlaku | initiated/waiting payment/active | Decode `pending` sebagai `initiated` bila belum ada pembayaran |
| `reassignCoach` dari Peserta | Melanggar satu Coach aktif | Admin transfer operation | Hapus dari profil Peserta; alasan dan audit wajib |
| Snapshot satu program di `ParticipantJourneyStore` | State bocor antarprogram | `ProgramEnrollmentContext` collection | Fokus program hanya selector UI |
| Leaderboard seed-only | Enrollment baru tidak mendapat entry | Atomic enrollment activation | Repository membuat score entry kosong |
| `AdminProgramDraft.program()` lama | Mapping kehilangan field | Published contract lossless | Satu mapper dengan round-trip test |

## Status migrasi fixture dan test

- `Resources/Fixtures/coaches.json`: wallet, ledger, dan invite sudah dihapus.
- `Resources/Fixtures/programs.json`: step points/requirements sudah
  dikonversi menjadi scoring/content typed; timbang awal, harian, dan akhir
  menjadi content step.
- `Resources/Fixtures/submissions.json`: evidence sudah dikonversi menjadi
  typed answers.
- `Resources/Fixtures/leaderboard.json`: hanya data demo pembacaan; vertical
  slice baru harus dapat mulai dari daftar kosong.
- Unit test Phase 03–08 sudah memakai Coach identifier, answers typed,
  activity points program-wide, dan skenario `coach_identifier`.
- `ProgramEndToEndContractTests` mencakup round trip, cover gambar, kebijakan
  hari mendatang, timbang harian step-scoped, duplikasi, question types,
  kuis/reopen, same-Coach guard, closure, poster, dan koreksi timbang.
- UI regression lintas peran tetap perlu diperluas pada release gate.

## Baseline dan hasil remediation 2 Agustus 2026

- Generic iOS Debug build — **lulus**.
- Explicit iOS Simulator Debug build pada
  `8DC6E4ED-CC5F-4E20-8556-F4E23ABF5DB9` — **lulus**.
- Unit/integration — **128 tests dalam 13 suites lulus**.
- Empat UI regression kritis — **lulus**: fixed Program header, fixed Konten
  header, Indonesian runtime fallback, dan Admin default Dashboard.
- JSON fixture/localization dan syntax OpenAPI YAML divalidasi.
- Full UI release matrix, staging, store sandbox, Android, dan perangkat fisik
  belum dianggap lulus. Rinciannya berada di
  `PROGRAM_END_TO_END_IMPLEMENTATION_STATUS.md`.

Amendment 3 Agustus 2026 untuk cover gambar, future policy `available`, dan
timbang harian lulus 134 unit/integration tests serta UI journey Admin dan
Coach yang relevan. OpenAPI, migration draft, fixture, dan localization ikut
divalidasi.

## Aturan stabilitas contract

- Enum raw value memakai `snake_case` dan tidak boleh diganti setelah backend
  atau Android menggunakannya.
- Domain tidak mengimpor SwiftUI, StoreKit, Supabase, atau Play Billing.
- Participant DTO tidak pernah memuat answer key.
- Semua mutation membawa idempotency key ketika adapter server dibuat.
- Harga client hanya presentasi; entitlement server adalah sumber kebenaran.
- Guest tidak pernah dipetakan menjadi role atau anonymous Auth identity.
- Member level, application, payment, approval, role, dan entitlement adalah
  state terpisah; satu state tidak boleh menyiratkan state berikutnya.
- Semua audit reason disimpan sebagai data, bukan hanya copy UI.
