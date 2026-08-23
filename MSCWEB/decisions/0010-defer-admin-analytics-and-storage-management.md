# ADR-0010 — Tunda analytics dan pengelolaan Storage Admin sampai pascapeluncuran

Status: Accepted
Date: 21 August 2026

## Context

W07.5 Sales Overview dan W07.6 Admin Image Storage dirancang sebagai perluasan web-only setelah W07 selesai. Keduanya berguna, tetapi bukan bagian dari perjalanan utama Guest, pendaftaran Peserta/Coach, enrollment, pembayaran manual, program, review, scoring, atau approval Admin.

Pemilik produk memilih mempercepat deployment pertama. Menghapus spesifikasi kedua fitur akan membuang keputusan ledger, privacy, dan destructive-operation safety yang sudah disusun. Sebaliknya, tetap menjadikan seluruh W07.6 sebagai dependency W08 akan menunda rilis untuk UI operasional yang belum diperlukan.

Sebagian kontrak media W07.6 tetap merupakan keamanan dasar, bukan fitur Admin opsional: bucket privat/RLS, tidak adanya raw path atau service credential di browser, retensi dan orphan cleanup bukti pembayaran, serta delivery media Coach publik melalui opaque controlled gateway dengan cache invalidation yang aman.

## Decision

- W07.5 dan W07.6 berstatus `Deferred post-launch`; keduanya tidak menjadi dependency atau release gate deployment pertama.
- Spesifikasi, requirement ID, acceptance criteria, dan workplan W07.5/W07.6 dipertahankan sebagai authority saat fitur pascapeluncuran diaktifkan.
- W08 dimulai langsung setelah W07.4 dan memiliki satu slice `Minimum media launch safety`.
- Slice tersebut mengambil authority launch-critical dari `PROD-MED-011`, `ARCH-MED-007`, `UX-MED-012`, `SEC-STO-013`, bagian automatic-retention dari `SEC-STO-014`, serta baseline private-media/RLS/cache/log requirements yang sudah berlaku.
- Rilis pertama tidak menampilkan quick action atau route `/admin/sales` dan `/admin/image-storage`.
- Rilis pertama tidak menyediakan inventory, usage dashboard, Trash, restore, manual purge, managed-media registry/backfill, atau deletion worker Admin.
- Tidak adanya UI W07.6 tidak mengizinkan direct browser deletion, SQL deletion terhadap `storage.objects`, public payment proof, public raw Storage path, atau penundaan retensi bukti pembayaran.
- W09 tidak memerlukan production Sales Overview read scope maupun activation/smoke penghapusan media Admin. W09 tetap memerlukan verifikasi minimum media safety dan kebijakan retensi pembayaran sebelum production rollout.
- Setelah deployment stabil, owner dapat mengaktifkan W07.5 dan W07.6 melalui keputusan prioritas baru. Implementasinya tetap memerlukan seluruh checklist dan authorization pada workplan masing-masing.

## Consequences

Positif:

- jalur ke W08/W09 lebih pendek tanpa mengurangi keamanan data launch;
- core Participant/Coach/Admin dan pembayaran dapat dirilis lebih cepat;
- desain analytics dan media-management tetap tersedia untuk fase berikutnya.

Risiko/trade-offs:

- Admin belum memiliki analytics penjualan teragregasi dan harus memakai operational payment views yang sudah ada;
- Admin belum dapat melihat usage Storage atau menghapus gambar secara manual dari aplikasi;
- cleanup launch terbatas pada lifecycle otomatis/feature-owned yang sudah ditetapkan, bukan general-purpose Trash;
- requirement pascapeluncuran tidak boleh keliru dilaporkan sebagai selesai hanya karena deployment pertama berhasil.
