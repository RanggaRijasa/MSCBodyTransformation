# Arsitektur

## Arah dependensi

```text
SwiftUI View
  → feature state / @Observable
  → use case / domain service
  → repository protocol
  → local actor atau adapter eksternal
  → Supabase / StoreKit / Play Billing
```

View tidak menentukan otorisasi, scoring, atau transaksi. Domain tidak
mengimpor SwiftUI, UIKit, StoreKit, Supabase, maupun Play Billing.

## Aggregate program

```text
ParticipantProfile
 └─ currentCoachID
    └─ ProgramEnrollment[]
       ├─ Program published contract
       ├─ Coach snapshot
       ├─ StepSubmission + typed answers
       ├─ QuizAttemptResult[]
       ├─ WeighIn initial/daily/final, terikat ke step
       ├─ ScoreBreakdown
       └─ Entitlement / payment reference
```

Semua runtime state dipisahkan berdasarkan `enrollmentID`. Program tidak
memiliki poin per langkah; scoring berada pada
`ProgramScoringConfiguration`.

## Lapisan repository

- `ProgramRepository`: catalog dan published program.
- `AdminProgramDraftRepository`: draft lossless dan editor.
- `EnrollmentRepository`: same-Coach guard dan enrollment idempoten.
- `SubmissionRepository`: typed answers, review, quiz history, reopen.
- `WeighInRepository`: nilai awal/akhir per enrollment, nilai harian per
  step, dan koreksi Admin.
- `LeaderboardRepository`: rekonsiliasi, ranking, winner snapshot.
- `ManagedContentRepository`: poster terkait program/snapshot.
- `AuditRepository`: mutation istimewa dengan actor dan alasan.

`InMemoryAppRepository` adalah adapter deterministik untuk demo/test.
`Contracts/program-api-v1.openapi.yaml` dan migration Supabase mendefinisikan
boundary adapter produksi serta Android.

## Konten dan scoring

Admin draft dipetakan lossless ke renderer Peserta. Foto adalah
`StepSubmissionAnswer.localPhotoReference`. Kuis dinilai otomatis dan answer
key hanya tersedia pada boundary Coach/Admin.

```text
total =
  approved_activity_points
  + quiz_correct_answer_points
  + weight_points
  + adjustment_points
```

Weight math memakai `Decimal`. Winner lock menghasilkan snapshot immutable.
Timbang harian hanya menjadi riwayat progres. `weight_points` selalu memakai
selisih timbang awal dan akhir.

## Commerce

Satu program/cohort mempunyai external Product ID unik per platform. Desired
price Admin bukan harga authoritative. StoreKit/Play Billing menghasilkan
transaksi platform; backend memverifikasi, membuat entitlement lintas
platform, lalu mengaktifkan enrollment dan leaderboard secara atomik.

Private store credential hanya boleh berada di backend.

## Media

`NativeImageProcessor` menormalisasi orientasi, ukuran, JPEG, dan metadata.
Foto pertanyaan disimpan private pada backend; avatar/media publik dipisah.
Cover program selalu gambar dan disimpan sebagai media publik program.
Video lokal mendukung resume, konfigurasi autoplay, serta completion
threshold.

## Navigasi dan platform

Setiap tab mempunyai `NavigationStack` sendiri. Admin dibuka pada Dashboard.
iOS 26+ memakai Liquid Glass secara selektif; iOS 17–25 memakai fallback
native. Android harus memetakan kontrak OpenAPI yang sama tanpa menyalin
aturan authoritative ke client.
