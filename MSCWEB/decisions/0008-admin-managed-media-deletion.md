# ADR-0008 — Penghapusan media melalui Sampah dan worker server

Status: Accepted  
Date: 20 August 2026

Scheduling amendment: Admin inventory/Trash/restore/purge is deferred post-launch by [`ADR-0010`](./0010-defer-admin-analytics-and-storage-management.md). Private Coach-media delivery and automatic payment-proof retention remain first-launch safety work in W08.

## Context

Admin membutuhkan inventory penggunaan gambar dan kemampuan menghapus gambar yang diunggah pengguna. Byte file berada di Supabase Storage; database hanya menyimpan metadata/reference. Direct delete dari browser atau SQL dapat meninggalkan domain reference rusak, menghapus shared asset, melewati audit, atau membuat Storage object yatim.

Current user-uploaded inventory scope adalah `question-photos`, `payment-evidence`, dan `coach-public-media`. Masing-masing memiliki reference/protected state berbeda dan beberapa media dapat memengaruhi submission, poin, payment review, AI job, atau profil publik. Existing payment contract menetapkan proof deletion otomatis dan melarang Admin cleanup button.

## Decision

- W07.6 remains the implementation phase for Admin media management after W07.5, but its original pre-W08 placement is superseded by ADR-0010.
- Route Admin `/admin/image-storage` dibuka dari quick action `Penyimpanan gambar`; video dan Admin/system-owned assets berada di luar baseline.
- `payment-evidence` tetap inventory-only dengan label automatic 30-day retention. ADR ini tidak mengganti larangan Admin proof-cleanup button; manual Trash/restore/purge hanya untuk eligible `question-photos` dan `coach-public-media`.
- `coach-public-media` dimigrasikan menjadi private. Public profile memakai opaque asset ID melalui controlled gateway yang memverifikasi current published reference dan active state; raw path/direct public bucket URL dihentikan.
- Introduce private managed-media registry/reference inventory dan opaque media ID. Raw bucket/path tidak diberikan ke browser.
- Deletion memakai dua tahap: `Pindahkan ke Sampah` menutup akses normal dan dapat dipulihkan; `Hapus permanen` membuat durable server job setelah confirmation/reason.
- Worker memakai leased table-job pattern yang sudah dipakai food insight, rechecks seluruh reference/protected state, lalu menghapus melalui Supabase Storage API. Remote remove MAY dipanggil at-least-once setelah crash, tetapi hanya satu logical tombstone/audit/final outcome yang boleh tercipta. SQL delete pada `storage.objects` dilarang.
- Unknown, shared, under-review, active-correction/dispute, active AI, account-cleanup, dan published media yang belum didetach fail closed.
- Purge mempertahankan domain record, authoritative point/transaction/decision, dan audit dengan deletion tombstone; hanya bytes media yang hilang.
- Batch purge hanya untuk Trash atau safe orphan/superseded assets, maksimum 100 per request, dengan impact snapshot dan idempotency.
- Usage berasal dari Storage metadata untuk managed user-image buckets. Quota hanya tampil jika trusted server config tersedia; nilai 50 GB pada screenshot bukan contract.
- Existing automatic cleanup tetap server/operator controlled. Admin UI tidak memanggil cleanup function atau memakai service-role key; ia hanya membuat audited media deletion intent.

## Consequences

Positif:

- Admin dapat membebaskan ruang tanpa merusak poin/transaction/audit;
- accidental deletion dapat dipulihkan dari Sampah sebelum purge;
- races/shared references diperiksa kembali tepat sebelum deletion;
- private paths dan service credentials tidak keluar ke browser.

Risiko/trade-offs:

- byte belum bebas selama item masih di Sampah;
- registry/backfill serta policy changes menyentuh shared media contract dan membutuhkan regression iOS/web;
- public Coach media memerlukan detach/unpublish dan cache invalidation;
- program/system media tetap harus dikelola melalui feature-specific flow atau ADR terpisah.
