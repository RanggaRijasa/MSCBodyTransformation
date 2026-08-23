# ADR-0012 — GitHub Actions sebagai authority deployment production rutin

Status: Accepted
Date: 23 August 2026

## Context

Setelah W09, repository MSCWEB standalone menjadi pemilik tunggal aplikasi web,
Cloudflare, dan canonical Supabase deployment history. Deployment berulang lewat
GPT/MCP memerlukan banyak interaksi, lebih lambat, sulit direproduksi, dan
memperbesar risiko perintah production berbeda antar-run.

Produk memerlukan alur sederhana: semua development memakai Supabase lokal,
pull request membuktikan build dan migration secara deterministik, dan hanya
source yang sudah masuk protected `main` dapat mencapai production.

Project belum memerlukan hosted staging. Cloudflare candidate/preview yang
menunjuk Supabase production tidak memberikan isolasi staging dan tidak boleh
menjadi automatic PR environment.

## Decision

- GitHub Actions menjadi satu-satunya authority deployment production rutin
  setelah W10 diaktifkan.
- GPT, Codex, Supabase MCP, Cloudflare MCP, dashboard, dan laptop developer tidak
  digunakan untuk deployment rutin. Semuanya hanya boleh menjadi break-glass
  path dengan izin eksplisit dan incident record.
- `feature/*` dan checkout lokal memakai Supabase lokal.
- Pull request menuju `main` menjalankan CI dengan disposable local Supabase dan
  Cloudflare dry run tanpa production secret atau external mutation.
- Protected `main` adalah satu-satunya production source.
- Production memakai GitHub Environment `production` dengan required reviewer
  bila didukung paket/visibility repository. Jika tidak didukung, fallback-nya
  adalah `workflow_dispatch` untuk exact current `main` SHA.
- Fully automatic deployment tanpa approval tidak digunakan.
- Production deployment berurutan: canonical migration → Edge Functions →
  Cloudflare Worker → synthetic smoke. Kegagalan backend menghentikan Worker.
- Deployment production diserialkan dan run aktif tidak dibatalkan oleh commit
  yang lebih baru.
- Script repository menjadi implementasi tunggal perintah verifikasi/deployment;
  workflow hanya mengorkestrasi script yang sama.
- CLI, dependencies, dan GitHub Actions dipin dan direview.
- Routine release tidak mengunggah ulang atau merotasi OpenRouter/Function/
  Worker secrets.
- Database migration bersifat forward-only dan backward-compatible. Tidak ada
  automatic down migration atau database rollback.
- Baseline hanya memiliki local development dan production. Hosted staging,
  branch `develop`, atau Supabase preview branch memerlukan ADR baru.

## Consequences

Positif:

- deployment dapat diulang, diaudit, dan direview tanpa bergantung pada konteks GPT;
- PR tidak dapat menyentuh production;
- migration dan frontend dirilis dalam urutan fail-stop yang konsisten;
- production secrets baru tersedia setelah release gate;
- biaya dan kompleksitas hosted staging ditunda sampai benar-benar diperlukan.

Risiko/trade-offs:

- tidak ada URL staging end-to-end dengan database terisolasi;
- migration harus diuji kuat secara lokal dan dirancang backward-compatible;
- branch protection, GitHub Environment, secrets, dan approval owner memerlukan
  setup eksternal setelah repository baru tersedia;
- bila repository plan tidak mendukung required reviewers, owner harus memakai
  tombol manual `Run workflow` sebagai release gate;
- database tidak dapat dipulihkan hanya dengan rollback Worker sehingga
  destructive schema contract harus dibagi menjadi beberapa release.

