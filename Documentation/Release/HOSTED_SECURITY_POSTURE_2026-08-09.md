# Hosted Security Posture — 9 Agustus 2026

Dokumen ini hanya berisi hasil read-only dan tidak menyimpan token, API key,
credential provider, data akun, atau private object path.

## Terverifikasi

- Supabase Dashboard Project Overview menampilkan **Advisor found no issues**
  dan **No security or performance issues found** pada saat audit.
- Database SSL enforcement aktif (`database=true`).
- Enam physical backup harian terakhir berstatus `COMPLETED`; WAL-G aktif dan
  PITR tidak aktif.
- Google dan Apple provider aktif. Email/password tidak diaktifkan sebagai
  metode produk dan signup OAuth tetap tersedia.
- Legacy API keys telah dinonaktifkan/revoke oleh owner; Release memakai
  publishable key modern dan server worker memakai secret key modern melalui
  Vault/header.
- 20 migration lokal/hosted cocok dan sembilan Edge Function berstatus
  `ACTIVE` dengan handler-side authentication boundary.
- Hosted database lint bersih; audit RLS, grants, private schema,
  `security_invoker`, fixed `search_path`, dan revoked `PUBLIC` tidak
  menemukan blocker.

## Keputusan atau verifikasi manual yang masih terbuka

- Koneksi database langsung masih mengizinkan IPv4 `0.0.0.0/0` dan IPv6
  `::/0`. Jangan memperketatnya sebelum alamat operator/CI yang stabil
  tersedia; perubahan ini memerlukan approval production terpisah.
- Status MFA untuk akun operator Supabase, CAPTCHA/rate-limit Auth, Storage
  quota, spend cap/alert, dan organisasi billing tidak dipublikasikan oleh
  endpoint Auth settings dan harus diperiksa melalui Dashboard oleh owner.
- PITR belum aktif. Physical backup harian cukup untuk gate testing awal,
  tetapi keputusan mengaktifkan PITR harus mempertimbangkan plan dan biaya.

## Accepted testing posture

Untuk exploratory testing owner sebelum TestFlight, database connection CIDR
yang masih terbuka dicatat sebagai risiko operasional sementara. Data API dan
aplikasi tetap dibatasi RLS; database password tidak berada di client. Risiko
ini tidak boleh dianggap keputusan final production launch dan harus ditinjau
kembali sebelum Phase 13.3/App Review.
