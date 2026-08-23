# ADR-0011 — Repository web sebagai deployment authority tunggal

Status: Accepted
Date: 23 August 2026

## Context

MSCWEB awalnya dikembangkan di dalam repository aplikasi native iOS. Rencana
split sebelumnya mempertahankan repository induk sebagai authority Supabase
karena backend dianggap dipakai bersama oleh iOS dan web.

Pemilik produk kemudian memutuskan menghentikan iOS sebagai release target dan
melanjutkan produk hanya sebagai web app/PWA. Mempertahankan deployable Supabase
history pada repository iOS tidak lagi memberi manfaat dan akan membuat dua
lokasi source berpotensi dianggap authoritative.

Hosted Supabase telah menggunakan canonical migration history pada
repository-root `supabase/`. Riwayat tersebut harus tetap lengkap agar linked
migration inventory, Function source, database tests, dan rollback evidence
tidak terputus saat repository dipisahkan.

## Decision

- Repository MSCWEB standalone menjadi pemilik tunggal source web/PWA,
  Cloudflare Worker/configuration, dan seluruh canonical Supabase deployment
  history.
- Seluruh repository-root `supabase/` dipindahkan ke root repository MSCWEB
  sebagai satu unit, termasuk semua migration lama, Edge Functions/shared
  modules, database tests, `config.toml`, dan runbook yang masih berlaku.
- Split tidak boleh melakukan migration squash, rebaseline, renumbering,
  selective copy, atau membuat migration chain kedua.
- Setelah cutover, hanya repository MSCWEB yang memiliki CI, credential, dan
  izin operasional untuk deployment Cloudflare maupun Supabase.
- Repository lama yang berisi iOS menjadi arsip non-deployable. iOS tidak lagi
  menjadi release gate, backend owner, atau tujuan pengembangan produk.
- Salinan sementara source MSCWEB atau `supabase/` boleh dipertahankan selama
  standalone validation dan rollback window, tetapi pipeline production dari
  repository lama harus dinonaktifkan sehingga salinan tersebut bukan authority
  kedua.
- Penghapusan salinan lama dilakukan hanya setelah standalone build/test,
  canonical migration comparison, production availability check, dan izin
  destruktif terpisah dari pemilik produk.
- Existing Cloudflare Worker, domain/DNS, hosted Supabase database, Auth,
  Storage, Functions, dan secrets tidak dibuat ulang hanya karena repository
  source berpindah. Deployment workflow yang diarahkan ke repository baru.

## Consequences

Positif:

- satu repository memiliki seluruh produk aktif dan backend deployment source;
- tidak ada ambiguity mengenai migration dan Function authority;
- CI, release evidence, rollback, serta perubahan frontend/backend dapat
  diverifikasi dalam satu fresh clone;
- repository iOS dapat disimpan sebagai arsip tanpa membebani release web.

Risiko/trade-offs:

- root `supabase/` tidak otomatis ikut dalam `git subtree split` yang hanya
  memilih prefix `MSCWEB`; transfer harus menggabungkan keduanya secara sengaja;
- test dan script yang memakai parent-relative path perlu diubah sebelum
  standalone validation;
- CI/credential lama harus benar-benar dinonaktifkan saat cutover agar safety
  copy tidak menjadi deployment authority kedua;
- pembersihan repository lama tidak boleh dilakukan bersamaan dengan transfer
  awal karena akan menghilangkan rollback source sebelum repo baru terverifikasi.
