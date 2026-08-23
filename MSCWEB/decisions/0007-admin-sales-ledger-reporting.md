# ADR-0007 — Ringkasan penjualan dari payment ledger

Status: Accepted  
Date: 20 August 2026

Scheduling amendment: implementation is deferred post-launch by [`ADR-0010`](./0010-defer-admin-analytics-and-storage-management.md). The reporting contract remains accepted; only its release order changed.

## Context

Admin membutuhkan analytics penjualan yang dapat dibuka dari `Akses cepat`. MSCWEB memiliki beberapa projection commerce: order manual, append-only payment ledger, dan commerce transaction lintas platform. Menjumlahkan order `approved` atau ledger bersama commerce transaction dapat menghasilkan revenue yang salah/dobel.

Screenshot referensi menunjukkan hierarchy top item/source/customer, tetapi kategori `source` tidak authoritative pada alur MSCWEB karena rekening dan QRIS tampil bersamaan dan `declared_method` bukan bukti cara transfer aktual.

## Decision

- W07.5 is the implementation phase for this contract. Its original pre-W08 placement is superseded by ADR-0010; it now runs after the first deployment when reprioritized.
- Route Admin adalah `/admin/sales`, dibuka dari quick action `Ringkasan penjualan`; lima destination utama Admin tidak berubah.
- Baseline hanya melaporkan manual web sales untuk program dan akses Coach.
- `payment_ledger` adalah recognized-revenue authority: satu `verified` entry per order membentuk gross; beberapa idempotent `reversal` entry MAY mengurangi verified amount secara kumulatif sampai nol. Setiap reversal terkait ke verified entry dan diakui pada timestamp reversal.
- Existing `unique(order_id, entry_kind)` harus diremediasi agar multiple partial reversal aman, dengan constraint cumulative reversal `<= verified amount`.
- Late/rejected-but-paid, duplicate transfer, dan overpayment difference yang tidak pernah diakui sebagai revenue menggunakan exceptional cash-adjustment authority terpisah; refund tersebut tidak mengurangi sales net. Approved voluntary cancellation yang non-refundable tidak membuat reversal.
- Payment order menyimpan privacy-safe customer reporting key agar historical financial grouping bertahan setelah profile deletion tanpa menyimpan contact snapshot. Public/Admin report memakai opaque group ID dan nullable Person ID; legacy null-owner order yang tidak dapat direkonstruksi dipisah per order.
- `payment_orders` hanya memberi purpose/program/order-pipeline dimensions. Status `approved` tanpa verified ledger bukan revenue.
- `commerce_transactions` tidak dijumlahkan bersama ledger dan cross-channel StoreKit/Google Play tidak masuk baseline.
- Default periode 30 hari WITA (`Asia/Makassar`), inclusive start/exclusive end; filter 7/30/90/rentang khusus maksimum 366 hari dan purpose tersedia.
- Overview hanya menampilkan aggregate serta display name aman untuk pelanggan teratas; tidak ada bank, reconciliation reference, bukti, contact, member level, atau private media.
- Live Admin-only RPC adalah baseline. Optimasi index mengikuti measured query plan; tidak ada warehouse/materialized view/analytics vendor/chart dependency baru.
- Chart memakai primitives/SVG yang sudah approved serta exact accessible table/list equivalent.

## Consequences

Positif:

- angka dapat direkonsiliasi langsung ke ledger uang;
- reversal/pending tidak disamarkan sebagai penjualan;
- tidak ada double counting dengan commerce projection;
- implementasi ringan dan tidak mengirim financial analytics ke vendor lain.

Risiko/trade-offs:

- overview tidak mencakup App Store/Google Play sampai contract lintas-channel diputuskan;
- program lama memakai current published title karena order belum menyimpan title snapshot;
- missing reversal migration/type drift harus diremediasi sebelum net-sales exit gate;
- live aggregate perlu ditinjau ulang jika volume ledger membesar.
- workplan bertambah karena reversal/cash-adjustment authority harus reproducible sebelum analytics dapat dipercaya.
