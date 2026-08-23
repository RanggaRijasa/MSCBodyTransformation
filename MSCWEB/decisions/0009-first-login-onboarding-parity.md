# ADR-0009 — First-login onboarding memakai provisional identity

Status: Accepted  
Date: 20 August 2026

## Context

iOS contract mewajibkan registrasi pertama melewati Nama, Nomor HP, Level Member, lalu tujuan `Lanjut sebagai Peserta` atau `Ajukan menjadi Coach`. Peserta harus memvalidasi QR Coach; applicant Coach harus menyelesaikan eligibility dan pembayaran sebelum application menunggu Admin.

MSCWEB saat ini hanya menampilkan Google login, memuat role dari dashboard summary, lalu langsung masuk ke app. Backend sebenarnya sudah membuat profile `provisional` dan mempunyai profile/Participant/Coach-handoff RPC, tetapi AuthProvider/UI tidak membaca atau menjalankan lifecycle tersebut. W06 Coach application hanya tersedia setelah account sudah menjadi active Participant.

Google OAuth selalu membuat Auth identity sebelum aplikasi mengetahui apakah user baru. Karena itu web tidak dapat secara literal menjanjikan “tidak ada akun sama sekali sebelum QR/pembayaran” seperti local iOS credential draft.

## Decision

- Tambahkan W07.4 remediation setelah completed W07 dan sebelum W08. W07.5/W07.6 kemudian ditunda pascapeluncuran oleh ADR-0010 tanpa mengubah onboarding authority ini.
- Google OAuth user baru mempunyai Auth identity + profile provisional, bukan active app account. Copy web memakai `akun MSC belum aktif`.
- Auth/session context membedakan guest, onboarding, cleanup, dan active; role Participant saja tidak cukup untuk private access.
- New provisional user diarahkan ke `/onboarding/profile` untuk Nama, HP, Level Member, dan purpose. Purpose Coach adalah application intent, bukan role selection.
- Participant purpose memindai QR Coach approved/public/active, lalu `finalize_participant_onboarding` mengaktifkan Participant/current Coach exactly once.
- Coach purpose memakai `prepare_coach_application_handoff`, W06 eligibility/application, dan manual payment. Satu proof-submit wrapper atomically memvalidasi/submits proof, memindahkan order ke `under_review`, dan mengaktifkan account sebagai Participant sambil mempertahankan application/payment pending Admin.
- Hanya Admin approval W06 yang mengaktifkan Coach. Rejection/correction mempertahankan Participant access dan application history.
- Existing active account bypasses first-login onboarding; active Participant tetap dapat mengajukan Coach dari Profile.
- Payment correction adalah nonterminal pada application/order yang sama; terminal application rejection menutup pasangan tersebut dan later reapplication membuat history baru.
- Pre-proof explicit cancellation membuat private idempotency receipt dan status cleanup pending. Worker kemudian membersihkan artifacts/media, mencabut seluruh session, dan menghapus Auth/profile; client akhirnya Guest meskipun response terakhir hilang. Setelah proof submitted, financial/application history tidak dihapus; user kembali sebagai Participant/status.
- Tab close tidak menjadi cleanup authority. Provisional draft dapat di-resume sampai expiry 24 jam; server scheduled cleanup menangani abandoned identity/artifacts.
- Safe preserved intent baru digunakan setelah active finalization dan authorization.

## Consequences

Positif:

- onboarding web mengikuti keputusan dan hierarchy iOS tanpa melanggar authority model;
- provisional Google identity tidak memperoleh private Participant capabilities;
- pilihan Coach tetap application, bukan role escalation;
- backend foundation yang sudah ada dapat direuse dan diuji, bukan dibangun paralel;
- cancellation/expiry mempunyai cleanup yang dapat dipulihkan dari failure.

Risiko/trade-offs:

- web menyimpan provisional identity maksimal 24 jam ketika tab ditutup tanpa explicit cancel;
- AuthProvider, route guards, RLS/RPC, Coach payment, dan cleanup harus diremediasi bersama agar tidak ada bypass;
- activating Participant after Coach proof submission adalah web-manual-payment adaptation terhadap iOS demo-payment flow;
- existing auth/E2E assumptions yang langsung menuju `/app` harus diperbarui tanpa merusak active users.
