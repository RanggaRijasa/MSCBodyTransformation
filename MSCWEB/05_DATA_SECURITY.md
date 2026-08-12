# 05 — Data and security specification

## 1. Prinsip

- `SEC-001` Semua tabel public schema MUST mengaktifkan RLS dan memiliki explicit privileges; jangan mengandalkan auto-exposure/auto-grant.
- `SEC-002` Default policy adalah deny. Policy dibuat per operation dan per ownership/scope.
- `SEC-003` Browser hanya menggunakan publishable/anon key bersama user JWT.
- `SEC-004` Operation yang mengubah authority state MUST melalui security-definer RPC atau Edge Function yang sempit, tervalidasi, dan diaudit.
- `SEC-005` Function security-definer MUST menetapkan safe `search_path`, memeriksa actor/role, dan tidak menerima authority claims dari client.
- `SEC-006` Semua ID eksternal adalah UUID/opaque; raw Coach QR identifier tetap privat.

## 2. Adaptasi schema yang ada

Repository induk sudah memiliki commerce dan Coach application concepts. Implementasi web SHOULD mengadaptasi/menambah provider `manual_transfer`/`static_qris`, bukan membuat authority system paralel tanpa migrasi.

Conceptual tables:

### `manual_payment_destinations`

```text
id, kind, bank_name, account_number, account_holder,
qris_object_path, instructions, currency, is_active,
version, created_at, updated_at, updated_by
```

### `manual_payment_requests`

```text
id, owner_user_id, subject_type, program_id?, coach_application_id?,
amount_minor, currency, declared_method,
destination_snapshot_json, pricing_policy_version,
status, version, idempotency_key,
created_at, submitted_at?, decided_at?, expires_at?
```

### `manual_payment_proofs`

```text
id, payment_request_id, attempt_number, object_path,
mime_type, byte_size, width, height, checksum?,
created_by, submitted_at
```

### `manual_payment_reviews`

```text
id, payment_request_id, reviewer_user_id, decision,
reason?, prior_status, resulting_status,
idempotency_key, created_at
```

Nama final dapat diselaraskan dengan existing `commerce_purchase_intents`, `commerce_transactions`, transaction events, program entitlements, `coach_payment_records`, dan Coach entitlements. Yang wajib dipertahankan adalah invariants, bukan nama tabel konseptual di atas.

- `SEC-DATA-001` Amount canonical MUST integer minor units (Rupiah) atau numeric/Decimal yang konsisten; MUST NOT binary float.
- `SEC-DATA-002` Destination snapshot MUST immutable setelah request dibuat.
- `SEC-DATA-003` Unique constraints MUST mencegah duplicate active request/enrollment/entitlement yang melanggar contract.
- `SEC-DATA-004` State transition MUST dicatat pada append-only event/audit record.
- `SEC-DATA-005` Migration MUST menyediakan rollback-safe strategy dan local integration tests sebelum production authorization diminta.

## 3. Authorization matrix

| Resource | Owner | Coach | Admin | Guest |
|---|---|---|---|---|
| Public program metadata | read published | read | manage | read published |
| Participant private profile | own read/update allowed fields | scoped read only | authorized manage | none |
| Weight | own read/write per state | only if explicitly required by contract | authorized review | none |
| Program evidence | own scoped upload/read status | assigned scope review | authorized review | none |
| Payment request | own read/create/submit | own only | review/manage | none |
| Payment proof | own request read/upload | own only | authorized review | none |
| Coach QR raw payload | never general read | own generation surface only | protected operation | none |
| Role/entitlement | read own | read own | mutate via authority operation | none |
| Audit log | limited own-facing decision copy | scoped when necessary | authorized read | none |

- `SEC-AUTHZ-001` Coach role alone MUST NOT grant access ke semua Participant.
- `SEC-AUTHZ-002` Admin UI visibility MUST NOT be treated as authorization.
- `SEC-AUTHZ-003` Unauthorized lookup SHOULD return not-found equivalent when disclosure of entity existence is sensitive.

## 4. Storage

Buckets minimum:

| Bucket | Visibility | Isi |
|---|---|---|
| `program-public` | public/read-controlled | poster/content yang memang public |
| `program-evidence` | private | bukti Participant |
| `payment-proofs` | private | bukti transfer/QRIS |
| `profile-media` | private atau transformed public sesuai policy | avatar |
| `payment-destinations` | read-controlled | QRIS static image |

- `SEC-STO-001` Private bucket object MUST diakses melalui authenticated download atau short-lived signed URL.
- `SEC-STO-002` Policy pada `storage.objects` MUST mengikat bucket, owner/scope, request status, dan object path convention.
- `SEC-STO-003` Signed URL MUST tidak disimpan permanen di database/domain model, analytics, local storage, atau log.
- `SEC-STO-004` Cache-Control untuk private media MUST tidak membuat shared/public cache menyimpan konten sensitif.
- `SEC-STO-005` Delete/retention job MUST mengaudit referensi database sebelum object dihapus.

Referensi resmi: [Supabase Storage access control](https://supabase.com/docs/guides/storage/security/access-control) dan [Supabase private downloads/signed URLs](https://supabase.com/docs/guides/storage/serving/downloads).

## 5. Authoritative operations

Operation minimum:

```text
create_participant_payment_request
submit_manual_payment_proof
review_participant_payment
create_coach_payment_request
review_and_activate_coach
reject_coach_application
review_program_evidence
```

Setiap operation:

1. resolve actor dari JWT;
2. cek role/scope server-side;
3. validate current state dan version;
4. lock affected rows bila concurrency memungkinkan;
5. perform all authority writes atomically;
6. append audit/event;
7. return typed result tanpa private implementation detail.

- `SEC-OP-001` Client-provided user ID, role, amount, score, entitlement period, atau approval status MUST tidak dipercaya.
- `SEC-OP-002` Idempotency key MUST unik per actor + operation intent dan disimpan bersama result/transition.
- `SEC-OP-003` Repeated identical request MUST mengembalikan prior success atau safe conflict, bukan duplicate side effect.
- `SEC-OP-004` Transaction isolation/locking MUST diuji dengan concurrent approvals.

## 6. Authentication security

- OAuth redirect URLs harus exact dan dipisahkan local/production.
- Google provider configuration secret hanya berada di Supabase/provider configuration.
- Session persistence memakai mekanisme resmi Supabase JS; token tidak ditulis ke custom logs.
- Cross-tab logout/session refresh harus terkoordinasi.
- Auth callback dan preserved-return route harus dilindungi open redirect.
- CSP dan `frame-ancestors` harus membatasi embedding app untuk mengurangi clickjacking.

## 7. Privacy and logging

MUST NOT log:

- access/refresh token dan auth code;
- password/secret;
- raw Coach QR payload;
- berat badan;
- object path atau signed URL privat;
- isi/thumbnail bukti program dan pembayaran;
- full bank account details pada telemetry.

Operational log MAY mencatat opaque request ID, event type, redacted actor ID, status code, latency, dan correlation ID.

- `SEC-PRV-001` Browser cache/service worker MUST NOT precache private API responses atau media.
- `SEC-PRV-002` Private query cache MUST dibersihkan pada logout/account switch.
- `SEC-PRV-003` Error reporting MUST menjalankan redaction sebelum payload meninggalkan client.
- `SEC-PRV-004` Retention period untuk proof dan evidence MUST ditetapkan bersama kebijakan privasi sebelum production.

## 8. Required security tests

- owner A tidak dapat membaca/mengubah payment request atau proof owner B;
- Participant tidak dapat approve payment sendiri;
- Coach tidak dapat membaca proof payment Participant;
- Coach A tidak dapat review evidence Participant milik Coach B;
- Admin yang valid dapat review melalui operation, bukan direct unsafe write;
- service-role key tidak ditemukan pada output build;
- signed URL lama kedaluwarsa;
- concurrent approval tidak menghasilkan double entitlement/enrollment;
- forged amount/destination/role input diabaikan atau ditolak;
- storage object path traversal/collision ditolak;
- logout menghilangkan data privat dari UI/cache.

## 9. Environment

```text
Development → Supabase local melalui CLI, Docker, dan Colima
Production  → hosted Supabase main
Branching   → tidak digunakan
```

Tidak ada migration/function/config deployment ke hosted main tanpa authorization eksplisit. New Data API tables harus menerima privileges/policies secara eksplisit karena behavior exposure/grant dapat berubah antar versi platform.

