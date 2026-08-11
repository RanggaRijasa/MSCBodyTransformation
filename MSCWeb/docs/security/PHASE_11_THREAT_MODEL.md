# Threat model Phase 11

## Batas dan aset

Browser tidak dipercaya. Otorisasi tetap berasal dari verified Supabase claims, operasi terlindungi, RLS, dan private Storage. Aset sensitif mencakup sesi, identitas, QR Coach mentah, berat badan, jawaban, bukti pembayaran, media privat, push endpoint/key, dan operasi Admin.

| Permukaan | Ancaman utama | Kontrol kandidat rilis | Risiko residual |
| --- | --- | --- | --- |
| Auth/OAuth | CSRF, state replay, open redirect, brute force | sealed state cookie singkat, exact state/environment, return path relatif, SameSite, origin gate, limiter awal OAuth, limit Supabase Auth | Rendah; edge/WAF production dikonfigurasi Phase 12 |
| Role/Admin | metadata role palsu, direct route/API access | verified claims, protected operations, route guard, RLS, Admin checks | Rendah |
| QR Coach | raw identifier bocor, brute force, mismatch | QR opaque, tidak ada input manual, payload tidak dilog, authenticated hashed rate bucket | Rendah |
| Upload/media | polyglot, oversized/decompression, EXIF, path traversal, public leak | signature/dimensi/ukuran server, re-encode JPEG, server-generated path, private bucket, no-store, cleanup orphan | Rendah |
| Pembayaran | duplicate/replay, bukti bocor, review race | idempotency, optimistic version, private media, server validation, rate bucket, audit ledger | Rendah |
| Submission/berat | duplicate points, data privat tersimpan browser | server idempotency/scoring, RLS, no-store, SW tidak cache HTML/API, account-state clear | Rendah |
| Push | permission gelap, PII di notifikasi, endpoint takeover, stale endpoint | permission hanya dari klik pengguna, fixed generic copy, owner operation, RLS, endpoint digest uniqueness, revoke 404/410, secret-protected dispatcher | Rendah; VAPID/dispatcher secret harus dipasang Phase 12 |
| Service worker | cache poisoning, stale private page, silent update | exact public allowlist, fingerprinted static only, navigation network-only, explicit activation, version cleanup, multi-tab coordination | Rendah |
| Browser injection | XSS, clickjacking, data exfiltration | per-request nonce CSP, strict-dynamic, frame-ancestors none, HSTS, nosniff, referrer/permissions policy, same-origin mutation gate | Rendah |
| Observability | PII/token masuk log/vendor | allowlisted event names, random correlation ID, numeric metric only, no vendor | Rendah |

Tidak ada risiko Critical atau High yang terbuka. Risiko Medium produksi—WAF/edge rate rules, secret injection, cron dispatcher, TLS/domain, dan retention scheduling—adalah gate deployment Phase 12, bukan perubahan hosted pada Phase 11.

## Retensi dan redaksi

- Log aplikasi tidak boleh menerima body, query sensitif, token, email, QR, berat, path media, endpoint push, atau provider error mentah.
- Event operasional yang diizinkan hanya nama tetap, UUID korelasi acak, dan angka agregat.
- Bucket rate limit lebih tua dari 24 jam, outbox `sent` lebih tua dari 30 hari, dan subscription revoked lebih tua dari 90 hari menjadi target cleanup terjadwal Phase 12.
- Cache browser hanya menyimpan offline fallback, ikon/screenshot publik, dan aset build fingerprinted.
