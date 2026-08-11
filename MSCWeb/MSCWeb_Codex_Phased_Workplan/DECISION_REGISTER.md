# Decision Register

## Diputuskan

| ID | Keputusan | Status |
|---|---|---|
| WEB-001 | Replatform total menjadi PWA/web | Final |
| WEB-002 | Source iOS menjadi referensi sampai parity aman | Final |
| WEB-003 | Implementasi sementara berada di `MSCWeb/` | Final |
| WEB-004 | Supabase tetap backend authoritative | Final |
| WEB-005 | Participant/Coach mobile-first; Admin desktop-first responsive | Final |
| WEB-006 | Sign in with Apple tidak diport | Final |
| WEB-007 | StoreKit diganti transfer manual dan review Admin | Final |
| WEB-008 | Role/payment/approval/entitlement tetap state terpisah | Final |
| WEB-009 | Next.js + TypeScript sebagai target frontend | Disetujui untuk workplan; versi dipin Phase 01 |
| WEB-010 | Vercel Pro sebagai hosting production default | Rekomendasi; purchase di Phase 12 |
| WEB-011 | Supabase hosted main tetap production | Final |
| WEB-012 | Hosted main dimigrasikan forward-only | Final |
| WEB-013 | Cloudflare Workers Paid menjadi hosting production cost-first | Final; menggantikan rekomendasi WEB-010 |
| WEB-014 | Landing dan aplikasi tetap satu repo/origin; `/` landing, `/hari-ini` app | Final |
| WEB-015 | Preview aplikasi landing memakai placeholder dulu, lalu screenshot PWA final | Final |
| WEB-016 | Destination pembayaran berversi menampilkan rekening dan optional gambar QRIS statis | Final |
| WEB-017 | Harga normal IDR tanpa nominal unik; amount/destination disnapshot per order | Final |
| WEB-018 | Kursi paid program direservasi 24 jam; bukti tepat waktu menahan kursi selama review | Final |
| WEB-019 | Koreksi pembayaran dikendalikan alasan Admin; tiga immutable evidence attempts | Final |
| WEB-020 | Tidak ada refund yang dapat diajukan client setelah approval; exceptional resolution internal only | Final bersyarat legal dan klarifikasi rejection |
| WEB-021 | Bukti pembayaran program dihapus 30 hari setelah program selesai | Final untuk program; Coach belum diputuskan |
| WEB-022 | Tidak ada SLA review tetap; order program terjadwal diputuskan sebelum program mulai | Final |
| WEB-023 | Coach eligibility sebelum bayar; akses tiga bulan, manual renewal, tanpa grace | Final |
| WEB-024 | Late transfer dipulihkan hanya bila kursi ada; jika penuh ditolak dan dana dikembalikan | Final |
| WEB-025 | Exceptional reversal untuk rejected funds/duplicate/excess/provider failure selesai ≤7 hari kerja | Final |
| WEB-026 | Bukti pembayaran Coach dihapus 30 hari setelah access period berakhir | Final |

## Gate yang belum diputuskan

| ID | Keputusan yang diperlukan | Deadline |
|---|---|---|
| GATE-001 | Nama domain final dan `.id`/`.com` | Sebelum Phase 12 purchase |
| GATE-002 | Registrar final | Sebelum Phase 12 purchase |
| GATE-003 | Rekening tujuan, owner, effective date, dan perubahan | Phase 00/06 |
| GATE-004 | Reservation TTL untuk peserta yang belum transfer | Phase 00 |
| GATE-005 | Transfer terlambat ketika kapasitas habis | Phase 00 |
| GATE-006 | Refund/cancellation/salah transfer/program batal | Phase 00 |
| GATE-007 | Limit file, retention, dan deletion bukti transfer | Phase 00/06 |
| GATE-008 | SLA pemeriksaan pembayaran Admin | Phase 00/06 |
| GATE-009 | Periode dan renewal akses Coach | Phase 00/06 |
| GATE-010 | Email/password tetap skipped atau diaktifkan | Phase 03/12 |
| GATE-011 | Push notification masuk MVP atau ditunda | Phase 11 |
| GATE-012 | Supabase custom domain `api.*` dibeli atau tidak | Phase 12 |
| GATE-013 | Preview memakai mock saja atau environment backend baru | Phase 12 |
| GATE-014 | Jadwal decommission Apple identity/commerce legacy | Phase 13 |
| GATE-015 | Final wordmark/logo dan hero production asset | Phase 02A |
| GATE-016 | Install analytics dipasang atau tidak | Phase 02A/11 |
| GATE-017 | Pilihan screenshot PWA final untuk mengganti placeholder | Phase 11 |

## Cara merekam keputusan

- Jangan mengubah baris lama agar audit history tidak hilang.
- Tambahkan amendment bertanggal dengan alasan, opsi yang ditolak, dampak
  schema/API/UI/test, dan owner keputusan.
- Keputusan yang menyentuh hosted main, biaya, domain, provider, atau data
  retention memerlukan konfirmasi eksplisit pengguna.

## Amendment 10 Agustus 2026 — WEB-013

- Owner keputusan: pengguna.
- Alasan: biaya bulanan minimum menjadi prioritas hosting.
- Keputusan: gunakan Cloudflare Workers Paid melalui OpenNext sebagai target
  production; Cloudflare DNS digunakan pada semua TLD.
- Registrar: Cloudflare Registrar bila TLD didukung; `.id` tetap melalui
  registrar PANDI karena `.id` belum tercantum pada daftar TLD Cloudflare.
- Opsi yang digantikan: WEB-010 Vercel Pro sebagai default. Vercel Pro tetap
  fallback hanya bila compatibility test Next.js/OpenNext gagal.
- Dampak: tidak mengubah schema, RLS, RPC, Storage, atau hosted Supabase main.
  Phase 01 menyiapkan runtime-portable code dan Phase 12 menguji adapter,
  environment, OAuth callback, custom domain, observability, serta rollback.

## Amendment 10 Agustus 2026 — Phase 00 manual commerce

- Owner keputusan: pengguna.
- Detail authoritative:
  `../docs/decisions/PHASE_00_MANUAL_COMMERCE_DECISIONS.md`.
- GATE-003, GATE-004, GATE-008, dan GATE-009 telah dijawab.
- GATE-006 terjawab untuk kebijakan no-refund setelah approval, tetapi
  exceptional Admin rejection/received funds masih perlu klarifikasi.
- GATE-007 terjawab untuk file dan retention pembayaran program; retention
  bukti Coach masih perlu klarifikasi.
- GATE-005 tentang late transfer/capacity full belum dijawab.
- Nomor rekening dan gambar QRIS asli tidak dicatat di workplan/repository.

## Amendment 10 Agustus 2026 — Phase 00 gate closure

- Owner menyetujui tiga klarifikasi terakhir.
- GATE-005 ditutup oleh WEB-024.
- GATE-006 ditutup untuk product contract oleh WEB-020 dan WEB-025; review
  legal/consumer terms tetap production gate, bukan perubahan product answer.
- GATE-007 ditutup oleh WEB-021 dan WEB-026.
- Semua keputusan produk GATE-003 sampai GATE-009 telah memiliki jawaban.
- Phase 00 belum selesai: inventory, hash, parity, contract reconciliation,
  forward-only migration plan, dan verification masih harus dilaksanakan.

## Amendment 10 Agustus 2026 — Phase 00 baseline closure

- Approver: pengguna, melalui keputusan manual commerce terdokumentasi dan
  instruksi eksplisit untuk menyelesaikan Phase 00 pada 10 Agustus 2026.
- Inventory source/local/hosted, hash manifest, parity matrix, test mapping,
  target manual commerce contract, dan forward-only plan telah dibuat.
- GATE-003 sampai GATE-009 tetap closed oleh amendment sebelumnya; keputusan
  uang, expiry, late transfer, reversal, retention, dan Coach renewal sudah
  melalui human approval.
- OpenAPI valid secara sintaks tetapi memiliki drift Coach application terhadap
  constraint SQL terbaru. Resolution mengikat: codegen dilarang sampai
  shared OpenAPI dan schema manual commerce diperbarui dalam authorized slice.
- Phase 00 tidak mengubah `Contracts`, `supabase`, source iOS, hosted resource,
  provider, cron, DNS, domain, package, atau executable source.

## Amendment 11 Agustus 2026 — Phase 11 PWA MVP gates

- Owner keputusan GATE-011: pengguna, melalui instruksi eksplisit bahwa push
  notification masuk MVP.
- GATE-011 ditutup: Web Push menjadi bagian MVP dengan permission hanya setelah
  tindakan pengguna pada Pengaturan. Payload wajib generik dan tidak memuat
  PII; subscription owner/RLS, outbox, retry, serta revoke endpoint menjadi
  kontrak kandidat lokal. VAPID secret, deployment function, dan scheduler
  production tetap memerlukan approval Phase 12.
- GATE-016 ditutup untuk MVP tanpa analytics vendor. Kandidat rilis memakai
  event operasional first-party yang allowlisted dan correlation ID acak tanpa
  PII. Pemasangan vendor observability/analytics kelak wajib mendapat approval
  privacy, dependency, biaya, retention, dan consent terpisah.
- GATE-017 ditutup: screenshot final yang dipilih adalah fixture kandidat rilis
  Peserta dan Coach dari Phase 10. Keduanya deterministic, metadata-stripped,
  diperiksa bebas PII/private URL, dipakai pada landing/manifest, dan dijaga
  oleh visual serta security regression test.
- Opsi yang ditolak: placeholder landing dipertahankan; permission push saat
  page load; payload notifikasi berisi detail aktivitas/pembayaran; analytics
  vendor ditambahkan tanpa approval.
- Dampak hanya berada di `MSCWeb/`; hosted Supabase, DNS, domain, Contracts,
  source iOS, dan backend root tidak diubah.
