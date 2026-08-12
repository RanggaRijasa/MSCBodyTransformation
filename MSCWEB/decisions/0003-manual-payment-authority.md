# ADR-0003 — Manual bank/QRIS payment with Admin authority

Status: Accepted  
Date: 12 August 2026

## Context

Web menghindari komisi App Store dan tidak memakai StoreKit. Bisnis menerima pemeriksaan visual bukti transfer. Payment gateway/automatic reconciliation belum diinginkan.

## Decision

- Participant/Coach melihat destination rekening dan QRIS statis yang dikonfigurasi server.
- Pengguna mengunggah proof image privat dan secara eksplisit submit untuk review.
- Status menggunakan state machine `awaiting_proof → pending_review → approved/rejected/...`.
- Admin memeriksa secara visual dan menjalankan operation authoritative yang idempotent/audited.
- Participant approval atomically menghasilkan transaction/entitlement/enrollment.
- Coach approval mempertahankan state eligibility/payment/application terpisah, tetapi satu CTA Admin dapat atomically menyetujui dan mengaktifkan Coach bila semua prasyarat valid.
- Proof history append-only; resubmission tidak menimpa bukti lama.
- Tidak ada service-role/direct authority write dari browser.

## Consequences

Positif:

- sesuai proses bisnis yang diinginkan tanpa App Store payment;
- alur dan bukti tercatat dalam sistem;
- approval, enrollment, dan role tetap server-authoritative.

Risiko/trade-offs:

- visual proof dapat dipalsukan dan membutuhkan SOP rekonsiliasi manusia;
- aktivasi tidak instan;
- retention, dispute/refund, expiry, SLA, dan reviewer responsibility wajib diputuskan sebelum production;
- volume besar kelak mungkin membutuhkan payment gateway/automated reconciliation ADR baru.

