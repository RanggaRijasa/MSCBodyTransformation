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

### `coach_profile_drafts` dan `coach_public_profiles`

```text
draft: coach_user_id, requested_handle, avatar_source_path?,
       headline?, biography?, service_area?,
       instagram_url?, tiktok_url?, website_url?,
       whatsapp_number?, phone_number?,
       publish_instagram, publish_tiktok, publish_website,
       publish_whatsapp, publish_phone, publication_status,
       created_at, updated_at
public snapshot: public_handle, display_name, avatar_public_path,
                 verified_status, headline?, biography?, service_area?,
                 published_instagram_url?, published_tiktok_url?,
                 published_website_url?, published_whatsapp_number?,
                 published_phone_number?, publication_version,
                 published_at, updated_at
```

Draft menyimpan input Coach secara privat. Public snapshot hanya menerima nilai kontak yang toggle-nya aktif melalui operation tervalidasi; nilai tersembunyi MUST menjadi `null`/absen, bukan sekadar disembunyikan client. Testimoni dan before–after menggunakan child records dengan `publication_status`, urutan, caption/alt text, optional third-party permission attestation, dan audit moderation. Attestation wajib hanya ketika orang lain ditampilkan/dikutip. Media publik memakai asset khusus profil; object bukti program privat tidak boleh direferensikan.

### `food_insight_jobs` dan `food_insights`

```text
job: submission_id, analysis_version, status, attempt_count,
     next_attempt_at?, last_error_code?, created_at, updated_at
result: submission_id, analysis_version, detected_kind,
        energy_kcal?, protein_grams?, carbohydrate_grams?, fat_grams?,
        star_rating, confidence, reason_code, insight_text,
        provider_alias, model_alias, prompt_version, rubric_version,
        corrected_rating?, correction_reason?, corrected_by?,
        completed_at
```

### Revenue reversal dan exceptional cash adjustment

```text
payment_ledger verified: one per order, recognized amount, verified_at
payment_ledger reversal: many per verified entry, amount, reason,
                         idempotency_key, verified_at, related_ledger_id
exceptional_cash_adjustments: order_id?, adjustment_kind,
                              amount_minor, resolution_status,
                              reason, idempotency_key, recorded_at
payment_customer_reporting_keys: reporting_key, user_id?, created_at
payment_orders: customer_reporting_key snapshot
```

`exceptional_cash_adjustments` mencatat pengembalian dana yang tidak pernah menjadi recognized revenue; row tersebut tidak masuk gross/reversal/net Sales Overview. Mapping reporting key ke user berada di private schema dan tidak dikembalikan ke browser; key/order snapshot dipertahankan sebagai pseudonymous financial grouping setelah profile deletion.

### `managed_media_assets`, `managed_media_references`, dan `media_deletion_jobs`

```text
asset: id, bucket_id, object_path, object_path_hash, owner_user_id?,
       media_category, byte_size, mime_type, lifecycle_status,
       version, discovered_at, updated_at
reference: asset_id, reference_kind, reference_id, reference_status,
           is_protected, protection_reason?, observed_at
deletion job: id, asset_id, requested_by, reason, status,
              expected_asset_version, reference_fingerprint,
              not_before, lease_token?, lease_expires_at?, attempt_count,
              impact_snapshot_json, idempotency_key,
              requested_at, completed_at?
```

Nama/schema final MAY memakai private tables/views, tetapi raw `object_path` MUST berada di unexposed/private projection. Browser hanya menerima opaque asset ID dan metadata aman.

Nama final dapat diselaraskan dengan existing `commerce_purchase_intents`, `commerce_transactions`, transaction events, program entitlements, `coach_payment_records`, dan Coach entitlements. Yang wajib dipertahankan adalah invariants, bukan nama tabel konseptual di atas.

- `SEC-DATA-001` Amount canonical MUST integer minor units (Rupiah) atau numeric/Decimal yang konsisten; MUST NOT binary float.
- `SEC-DATA-002` Destination snapshot MUST immutable setelah request dibuat.
- `SEC-DATA-003` Unique constraints MUST mencegah duplicate active request/enrollment/entitlement yang melanggar contract.
- `SEC-DATA-004` State transition MUST dicatat pada append-only event/audit record.
- `SEC-DATA-005` Migration MUST menyediakan rollback-safe strategy dan local integration tests sebelum production authorization diminta.
- `SEC-DATA-006` Public Coach read model MUST mengembalikan hanya field yang dipublikasikan dan status badge server-controlled; row private profile tidak boleh diekspos langsung kepada Guest.
- `SEC-DATA-007` `public_handle` MUST unik, stabil, tidak berasal dari raw QR, dan perubahan handle MUST diaudit serta mempertahankan redirect bila kelak diizinkan.
- `SEC-DATA-008` Satu submission + analysis version MUST hanya memiliki satu job/result aktif. Retry provider maupun reconciliation scan MUST tidak membuat hasil/rating ganda, dan scan MUST menemukan eligible submission yang commit tetapi belum memiliki job.
- `SEC-DATA-009` Sales report MUST memakai `payment_ledger.amount_minor`, `entry_kind`, dan `verified_at`; `payment_orders` hanya menjadi dimension/order-pipeline source. `commerce_transactions` MUST tidak dijumlahkan bersama ledger manual.
- `SEC-DATA-010` Payment ledger remediation MUST enforce one verified entry per order, multiple idempotent reversal entries related to verified entry, and cumulative reversal not exceeding verified amount. Unrecognized-fund returns live in separate exceptional cash-adjustment records and do not affect sales net.
- `SEC-DATA-011` Every payment order MUST snapshot a server-controlled privacy-safe customer reporting key. Profile/account deletion MAY null the private user mapping but MUST not null the order key; browser report gets opaque group ID and nullable authorized person ID, never mapping/contact snapshot.
- `SEC-DATA-012` Media registry/reference inventory MUST direkonsiliasi terhadap `storage.objects` dan seluruh reference tables sebelum deletion diaktifkan. Unknown object/reference MUST diklasifikasikan `protected`/`unknown`, bukan diasumsikan orphan.
- `SEC-DATA-013` `object_path_hash` dan reference fingerprint MUST digunakan untuk audit/concurrency evidence; raw object path MUST tidak masuk audit payload atau browser response.
- `SEC-DATA-014` Purged media MUST meninggalkan tombstone/status yang cukup untuk menjaga audit dan menjelaskan viewer state tanpa mempertahankan signed URL atau media bytes.

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
| Profil Coach yang dipublikasikan | read | read own published | moderate/manage through operation | read published |
| Draft profil/kontak Coach | none | own only | authorized moderation | none |
| Food insight | own submission | assigned scope | authorized review | none |
| Sales aggregate | none | none | fixed aggregate/detail projection | none |
| Media inventory | own record status only | scoped evidence status only | safe fixed projection | none |
| Media deletion job | none | none | request/restore/confirm through narrow operation | none |

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
| `coach-public-media` | private; controlled public gateway | avatar dan media profil yang secara eksplisit dipublikasikan |

W07.6 managed-image allowlist uses the actual implemented buckets `question-photos`, `payment-evidence`, and `coach-public-media`. Conceptual name `program-evidence` maps to `question-photos`; it is not a second bucket.

- `SEC-STO-001` Private bucket object MUST diakses melalui authenticated download atau short-lived signed URL.
- `SEC-STO-002` Policy pada `storage.objects` MUST mengikat bucket, owner/scope, request status, dan object path convention.
- `SEC-STO-003` Signed URL MUST tidak disimpan permanen di database/domain model, analytics, local storage, atau log.
- `SEC-STO-004` Cache-Control untuk private media MUST tidak membuat shared/public cache menyimpan konten sensitif.
- `SEC-STO-005` Delete/retention job MUST mengaudit referensi database sebelum object dihapus.
- `SEC-STO-006` Foto Google yang dipakai sebagai avatar MUST diimpor melalui media pipeline dan disajikan dari media profil yang dikontrol aplikasi; UI publik MUST tidak hotlink URL provider yang dapat kedaluwarsa atau membocorkan parameter akun.
- `SEC-STO-007` Before–after/testimoni publik MUST berasal dari upload khusus profil, dinormalisasi, dibersihkan metadata, dan tidak boleh menyalin object path bucket bukti privat.
- `SEC-STO-008` Admin inventory MUST NOT grant browser-wide `SELECT`/`DELETE` on `storage.objects`; access happens through fixed Admin RPC projection and server-only worker.
- `SEC-STO-009` Direct SQL deletion from `storage.objects` MUST dilarang. Permanent removal uses Storage API so metadata dan underlying object are removed consistently.
- `SEC-STO-010` Immediately before remove, worker MUST lock/claim the job and recompute references/protected state. List-then-delete without recheck is unsafe.
- `SEC-STO-011` Trashed assets MUST be denied to normal owner/Coach/public read policies. Admin-only Trash preview must be no-store and must not create shareable signed URL.
- `SEC-STO-012` Permanent delete result MUST record count/bytes/category/path hash, not raw path. Partial/missing-object/finalization failures remain retryable and idempotent.
- `SEC-STO-013` `coach-public-media` MUST be private; RLS alone cannot revoke an object from a public bucket. Public delivery MUST use opaque asset ID and controlled server gateway that checks active published profile/item reference plus non-trashed asset state. Draft, pending/rejected moderation, superseded, and trashed media MUST not be publicly readable through current or legacy direct path.
- `SEC-STO-014` `payment-evidence` remains inventory-only in Admin Image Storage. Existing automatic orphan/30-day retention worker owns deletion; Admin media trash/purge RPC MUST reject this bucket. Inventory reconciliation and automatic cleanup must be idempotent when racing on the same object.

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
update_my_coach_profile_draft
publish_my_coach_profile
moderate_coach_profile_content
enqueue_food_insight
correct_food_insight_rating
record_revenue_reversal
record_exceptional_cash_adjustment
get_admin_sales_overview
list_admin_managed_media
request_admin_media_trash
restore_admin_media
confirm_admin_media_purge
claim_admin_media_deletion_job
finalize_admin_media_deletion_job
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
- `SEC-OP-005` Sales RPC is stable/read-only, validates Admin and bounded date range, and returns no reconciliation/bank/proof/private-media fields.
- `SEC-OP-006` Trash/restore/purge operations MUST validate Admin, expected asset version, current reference fingerprint, allowlisted category, protected state, reason, and idempotency key.
- `SEC-OP-007` Storage API calls MUST occur outside a long-running database transaction. Worker lease/finalization follows short-transaction retry-safe saga semantics.

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
- `SEC-PRV-005` Input yang dimaksud untuk AI adalah foto makanan/minuman saja, tetapi sistem MUST tetap memperlakukannya sebagai data pengguna karena terhubung ke submission dan dapat tanpa sengaja memuat wajah, dokumen, label, atau metadata.
- `SEC-PRV-006` Baseline AI minimum: disclosure singkat pada upload, hanya pertanyaan food-enabled yang diproses, metadata dihapus, credential server-side, payload diminimalkan, dan output dibatasi ke scope Participant/Coach/Admin yang sama dengan submission.
- `SEC-PRV-007` Tidak diperlukan checkbox consent AI terpisah, kontrak ZDR khusus, DPIA terpisah, atau kontrol withdraw khusus pada baseline. Pengguna tetap dapat memilih tidak mengirim foto sebelum submission; sesudah dikirim, lifecycle foto/hasil mengikuti kebijakan submission yang sama.
- `SEC-PRV-008` Request AI MUST tidak menyertakan nama, email, nomor telepon, user ID, berat, signed URL, storage path, atau metadata lokasi. Pengguna SHOULD diberi copy singkat untuk tidak memasukkan wajah atau dokumen ke foto makanan.
- `SEC-PRV-009` API key, system prompt, raw provider response, dan raw provider error MUST tidak disimpan di browser, analytics, atau log. Database hanya menyimpan hasil tervalidasi dan metadata versi minimum.
- `SEC-PRV-010` Pergantian provider atau perubahan material terms/data-use MUST menjalani security/privacy check pada fase rilis, tanpa otomatis menambah consent flow baru kecuali praktik provider atau hukum yang berlaku memang memerlukannya.

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
- logout menghilangkan data privat dari UI/cache;
- Guest hanya menerima field profil Coach yang dipublikasikan dan tidak dapat membaca draft/kontak tersembunyi;
- profile media tidak dapat menunjuk bukti program privat;
- browser bundle tidak mengandung `FOOD_AI_API_KEY` atau provider prompt;
- food-disabled submission tidak pernah membuat job AI;
- job AI idempotent, outage tidak memengaruhi submission/poin, dan rating 1–2 gagal bila favorable guard tidak terpenuhi.
- Participant/Coach/Guest tidak dapat memanggil sales overview atau memperoleh aggregate response;
- sales response tidak memuat identity/contact/bank/reconciliation/proof/path fields dan tidak double-count ledger/commerce;
- referenced/protected/unknown media gagal dipurge dan concurrent new reference wins over deletion;
- direct browser/SQL delete referenced media ditolak; Storage API worker retry menghasilkan satu tombstone/audit;
- trashed media tidak dapat diakses normal, restore bekerja sebelum purge, dan purged media tidak dapat dipulihkan;
- media audit/log/browser tidak memuat raw path, signed URL, weight, image bytes, atau service credential.

## 9. Environment

```text
Development → Supabase local melalui CLI, Docker, dan Colima
Production  → hosted Supabase main
Branching   → tidak digunakan
```

Tidak ada migration/function/config deployment ke hosted main tanpa authorization eksplisit. New Data API tables harus menerima privileges/policies secara eksplisit karena behavior exposure/grant dapat berubah antar versi platform.
