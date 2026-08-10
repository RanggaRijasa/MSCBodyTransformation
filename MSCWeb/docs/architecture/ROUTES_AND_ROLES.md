# Routes and Roles

Nama route final dapat disesuaikan di Phase 00, tetapi capability dan privacy
boundary berikut tidak boleh hilang.

## Public dan Auth

| Route | Actor | Tujuan |
|---|---|---|
| `/` | Semua | Landing publik; CTA session-aware menuju app sesuai role |
| `/program` | Semua | Katalog Diikuti/Tersedia/Riwayat sesuai actor |
| `/program/[programId]` | Semua | Penawaran atau aktivitas sesuai enrollment |
| `/peringkat` | Semua | Peringkat public-safe dan pemilih program |
| `/coach` | Semua | Direktori Coach approved |
| `/coach/[coachId]` | Semua | Profil publik Coach |
| `/masuk` | Guest | Login provider-first tanpa Apple |
| `/daftar` | Guest | Registrasi dan onboarding |
| `/lupa-kata-sandi` | Guest | Feature-gated sampai SMTP siap |
| `/auth/callback` | OAuth | PKCE code exchange dan redirect aman |

## Peserta

| Route | Capability |
|---|---|
| `/hari-ini` | Fokus program, hari aktif, langkah dan progres |
| `/program/[programId]/gabung` | QR Coach, preflight, payment request |
| `/pembayaran/[paymentId]` | Instruksi, upload bukti, status |
| `/program/[programId]/langkah/[stepId]` | Artikel/video/form/kuis/foto/timbang |
| `/profil` | Profil, Coach aktif, privacy, akun |
| `/profil/edit` | Nama, nomor HP, avatar |
| `/profil/ganti-coach` | Scan QR dan konfirmasi Coach |
| `/akun/hapus` | Reauthentication dan account deletion |

## Coach

| Route | Capability |
|---|---|
| `/coach-area` | Dashboard Coach |
| `/coach-area/peserta` | Roster dan perhatian |
| `/coach-area/peserta/[participantId]` | Detail privat, progres, riwayat berat |
| `/coach-area/pemeriksaan` | Queue dan filter submission |
| `/coach-area/pemeriksaan/[submissionId]` | Jawaban, answer key, approve/reject |
| `/coach-area/aktivitas` | Feed hari ini/7/30 hari tanpa berat/foto |
| `/coach-area/peringkat` | Peringkat program terkait |
| `/coach-area/qr` | QR Coach tanpa raw identifier |
| `/coach-area/profil` | Profil publik dan pengaturan |
| `/pengajuan-coach` | Eligibility/application/payment lifecycle |

## Admin

| Route | Capability |
|---|---|
| `/admin` | Dashboard, tindakan, audit ringkas |
| `/admin/pembayaran` | Queue bukti transfer program/Coach |
| `/admin/pembayaran/[paymentId]` | Viewer privat dan keputusan audited |
| `/admin/program` | Daftar/search/lifecycle program |
| `/admin/program/baru` | Draft baru |
| `/admin/program/[programId]` | Hub draft/published |
| `/admin/program/[programId]/pengaturan` | Identitas, jadwal, kapasitas, harga |
| `/admin/program/[programId]/konten` | Hari, langkah, konten, pertanyaan |
| `/admin/program/[programId]/pratinjau` | Renderer Peserta/Coach bersama |
| `/admin/orang` | Segmen Peserta/Coach/Admin |
| `/admin/orang/[userId]` | Profil dan operasi privileged |
| `/admin/konten` | Galeri poster pemenang |
| `/admin/audit` | Audit event sesuai permission |

## Role gate

- Route gate meningkatkan UX, tetapi RLS/RPC tetap authorization boundary.
- Guest yang membuka mutation diarahkan ke Login dengan pending intent aman.
- Participant tidak dapat mengaktifkan Coach dari URL atau client state.
- Coach hanya membaca participant yang authoritative ditugaskan kepadanya.
- Admin mutation selalu memerlukan operation server, reason bila diwajibkan,
  idempotency, dan audit.
- Redirect tidak boleh membocorkan apakah resource privat benar-benar ada.
