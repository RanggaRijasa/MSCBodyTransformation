# Target Manual Commerce Contract

Dokumen ini membekukan desain logis Phase 00. Ini bukan migration SQL dan
tidak mengklaim table atau provider manual sudah tersedia pada backend.
Keputusan produk authoritative berada di
[Phase 00 Manual Commerce Decisions](../decisions/PHASE_00_MANUAL_COMMERCE_DECISIONS.md).

## Prinsip aggregate

- Application/enrollment intent, payment order, evidence, verified ledger,
  role, dan entitlement adalah state terpisah.
- Browser tidak pernah menentukan amount, destination, owner, reviewer,
  verification, capacity, role, atau entitlement authoritative.
- Setiap mutation memakai idempotency key, server clock, actor dari verified
  session, row locking, dan immutable event.
- Existing store tables tetap provider-specific. Manual transfer memakai
  aggregate baru dan tidak dimasukkan sebagai nilai palsu ke constraint
  `app_store`/`play_store`.

## `payment_destinations`

| Field logis | Aturan |
|---|---|
| `id`, `version` | UUID dan versi monotonic/unik |
| `bank_code`, `bank_name` | Nilai allowlisted untuk presentasi |
| `account_name`, `account_reference` | Data sensitif; hanya server/admin yang boleh mengubah |
| `qris_object_path` | Opsional, private/versioned; bukan credential atau dynamic QR |
| `effective_from`, `effective_until` | Effective-dated; window tidak overlap untuk destination aktif |
| `created_by`, `created_at` | Actor Admin dan server timestamp |
| `status` | `scheduled`, `active`, `retired` |

Destination tidak di-update in place setelah direferensikan order. Order lama
menyimpan snapshot aman dari version yang dipilih server.

## `payment_orders`

| Field logis | Aturan |
|---|---|
| `id`, `owner_user_id` | Owner berasal dari verified session |
| `purpose` | `program_enrollment` atau `coach_access` |
| Target | Tepat satu `program_id`/pending enrollment atau `coach_application_id` |
| `amount_minor`, `currency` | Server snapshot; currency wajib `IDR` |
| Destination snapshot | Destination ID/version dan display snapshot yang diperlukan untuk audit |
| Reservation | `reserved_at`, `reservation_expires_at`; program berbayar 24 jam |
| Review | current projection saja; history tetap di event/attempt |
| `idempotency_key`, `version` | Unik per owner/operation; optimistic conflict detection |
| Retention anchor | Program end atau Coach access period yang dihasilkan order |

Stable status target:

```text
awaiting_evidence
under_review
correction_required
approved
expired
cancelled
rejected
reversal_pending
reversed
```

`approved` berarti payment ledger verified sudah ditulis. Itu belum boleh
menyiratkan role Coach tanpa Coach decision/capability operation yang sah.
`reversal_*` adalah internal exceptional resolution, bukan fitur refund client.

## `payment_evidence_attempts`

| Field logis | Aturan |
|---|---|
| `id`, `order_id`, `attempt_number` | Unik; nomor 1 sampai 3 |
| Object references | Original/normalized/thumbnail di bucket private |
| Integrity | MIME sniffed, byte size, content hash, normalized metadata |
| Submission | `submitted_at`, uploader actor; immutable setelah submit |
| Expiry | Attempt perbaikan harus disubmit dalam 24 jam setelah rejection |

Review tidak mengubah content atau metadata submission. Outcome dicatat
sebagai event append-only yang menunjuk attempt, lalu projection order
diperbarui atomik. Attempt keempat selalu ditolak server.

## `payment_ledger` dan `payment_events`

`payment_ledger` menyimpan hasil rekonsiliasi verified/reversal yang tidak
dapat ditulis client: order, purpose, amount, currency, destination version,
verified actor/time, target projection, dan reversal reference bila ada.

`payment_events` append-only memakai event type stabil:

```text
order_created, reservation_expired, reservation_restored,
upload_intent_created, evidence_submitted, evidence_rejected,
payment_approved, order_cancelled, reversal_required,
reversal_recorded, entitlement_projected, enrollment_projected
```

Metadata event memakai allowlist dan tidak menyimpan image, signed URL,
nomor rekening penuh, nomor HP, berat, atau raw QR Coach.

## Protected operations

| Operation | Actor | Efek wajib |
|---|---|---|
| `create_payment_order` | Participant/applicant | Validasi purpose, owner, target, price, destination, capacity/eligibility; reserve atomik |
| `create_payment_evidence_upload_intent` | Owner | Generate object path server-side dan short-lived upload intent |
| `submit_payment_evidence` | Owner | Validasi object ownership/integrity/attempt/expiry; append event; hold reservation |
| `approve_payment_order` | Admin reviewer | Lock order/target, verify amount/destination/state, write ledger/event, project enrollment/access atomik |
| `reject_payment_evidence` | Admin reviewer | Wajib reason + instruction; append event; buka retry bila masih tersedia |
| `restore_expired_order` | Admin reviewer | Hanya bila late transfer dan capacity masih tersedia |
| `expire_payment_order` | Scheduler/operator | Lepas reservation yang tidak memiliki evidence tepat waktu |
| `cancel_payment_order` | Owner/Admin sesuai policy | Hanya pre-approval dan audited |
| `record_exceptional_reversal` | Admin/owner terbatas | Catat proses manual dan deadline maksimal 7 hari kerja |
| `renew_coach_access` | Applicant/Admin flow | Buat order baru; periode mengikuti server clock dan policy renewal |

Approve/reject/restore/reversal harus idempoten dan menolak keputusan terminal
atau konflik versi tanpa efek ganda.

## Storage contract

- Bucket target: `payment-evidence`, private.
- Object path: server-derived, misalnya partition opaque per order/attempt;
  client tidak mengirim arbitrary path.
- Owner dapat upload/read status miliknya; Admin reviewer yang berwenang
  mendapat short-lived signed read; actor lain tidak dapat membaca.
- Input: JPEG/JPG, PNG, WebP, HEIC/HEIF, maksimal 10 MB.
- Normalized result sekitar maksimal 5 MB; magic-byte/decode/size diverifikasi
  server dan metadata lokasi dibuang.
- Tidak boleh masuk public HTML, service worker cache, logs, analytics,
  exception payload, fixture production, atau screenshot.
- Cleanup program: 30 hari setelah program selesai. Cleanup Coach: 30 hari
  setelah access period hasil order berakhir. Ledger/event mengikuti policy
  legal/accounting terpisah.

## Authorization matrix

| Data | Owner | Coach lain | Admin reviewer | Public |
|---|---|---|---|---|
| Instruksi order sendiri | Read | No | Read bila ditugaskan | No |
| Evidence image sendiri | Short-lived read | No | Short-lived read | No |
| Status/reason sendiri | Read | No | Read/write via operation | No |
| Ledger/event | Projection terbatas | No | Read sesuai permission | No |
| Destination management | No | No | Admin allowlist saja | No |

## Required tests sebelum deployment

Mencakup capacity race, duplicate create/approve, expiry boundary, evidence
tepat sebelum expiry, late transfer full/available, attempt keempat, wrong
owner/object path, MIME spoof, oversized image, conflicting reviewer,
duplicate/excess reversal, Coach renewal sebelum/sesudah expiry, RLS matrix,
signed URL expiry, retention cleanup, dan no-cache response headers.
