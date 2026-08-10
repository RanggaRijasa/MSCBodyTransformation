# Phase 00 Contract Reconciliation

> Status: CLOSED FOR PHASE 00 — blocking resolution ditetapkan; codegen tetap
> dilarang sampai shared OpenAPI diperbarui pada phase yang berwenang.

## Source of truth

Urutan otoritas selama transisi:

1. Constraint SQL terbaru dan protected operation yang benar-benar terpasang.
2. [Program contract matrix](../../../MSCBodyTransformation/MSC_Codex_Phased_Workplan/PROGRAM_END_TO_END_CONTRACT_MATRIX.md).
3. OpenAPI untuk bentuk transport yang sudah cocok dengan SQL.
4. Model Swift hanya sebagai consumer/reference, bukan pembenar drift.

OpenAPI 3.1.0 saat ini valid secara sintaks, tetapi valid YAML tidak berarti
semantik contract sudah cocok dengan migration ke-17 sampai ke-20.

## Drift Coach application

| Area | OpenAPI saat ini | SQL terbaru | Resolution |
|---|---|---|---|
| Application status | `draft`, `ineligible`, `ready_for_payment`, `payment_processing`, `payment_verified`, `pending_admin_approval`, `approved`, `rejected`, `expired` | `draft`, `ineligible`, `submitted`, `accepted_pending_payment`, `active`, `rejected`, `expired` | SQL menang; OpenAPI harus diganti sebelum codegen |
| Accepted eligibility | Tersirat oleh payment states | `accepted_pending_payment` | Menjadi state eksplisit, tetap terpisah dari payment dan role |
| Approved Coach | `approved` | `active` setelah operasi authoritative | Gunakan `active`; client tidak boleh self-promote |
| Payment state | Tidak memuat `interrupted` atau `revoked` | `not_started`, `processing`, `pending`, `verified`, `cancelled`, `failed`, `interrupted`, `refunded`, `revoked` | Contract harus memakai projection SQL atau DTO yang sengaja lebih sempit dan terdokumentasi |
| Provider | `app_store`, `play_store` | `app_store`, `play_store` | Benar untuk legacy store, belum mewakili manual transfer |

Migration `20260808084038_phase12_authoritative_commerce.sql` secara eksplisit
mengonversi lima status Phase 11 dan mengganti constraint. Karena itu enum
OpenAPI lama tidak boleh dipertahankan sebagai alias writable. Mapper read
legacy hanya boleh hidup pada migration/server boundary bila memang diperlukan.

## Enum SQL yang dibekukan sebagai baseline

| Aggregate | Field | Stable values saat ini |
|---|---|---|
| Profile | `role` | `participant`, `coach`, `admin` |
| Profile | `account_purpose` | `participant`, `coach_applicant` |
| Profile | `onboarding_status` | `provisional`, `coach_handoff_pending`, `active`, `cleanup_pending` |
| Coach application | `status` | `draft`, `ineligible`, `submitted`, `accepted_pending_payment`, `active`, `rejected`, `expired` |
| Coach payment | `state` | `not_started`, `processing`, `pending`, `verified`, `cancelled`, `failed`, `interrupted`, `refunded`, `revoked` |
| Coach access | `status` | `pending_activation`, `active`, `expired`, `revoked`, `refunded` |
| Program | `status` | `draft`, `preparing_commerce`, `scheduled`, `active`, `completed`, `archived` |
| Program | `pace` | `scheduled`, `self_paced` |
| Program | `duration_mode` | `fixed_duration`, `specific_dates` |
| Program | `past_step_policy` | `available`, `read_only`, `hidden` |
| Program | `future_step_policy` | `available`, `locked`, `hidden` |
| Program | `pricing_mode` | `free`, `paid` |
| Content | `content_kind` | `article`, `video`, `form`, `quiz`, `initial_weigh_in`, `daily_weigh_in`, `final_weigh_in` |
| Content | `completion_policy` | `mark_complete`, `answer_all_questions`, `watch_video`, `automatic_quiz`, `submit_weigh_in` |
| Content | `verification_mode` | `automatic`, `coach_review` |
| Question | `kind` | `short_answer`, `long_answer`, `number`, `single_choice`, `multiple_choice`, `image_choice`, `photo_upload`, `heading`, `text` |
| Enrollment | `status` | `initiated`, `waiting_for_payment`, `active`, `completed`, `cancelled`, `refunded` |
| Submission | `status` | `draft`, `pending`, `approved`, `rejected` |
| Weigh-in | `kind` | `initial`, `daily`, `final` |
| Store product | `platform` | `app_store`, `play_store` |
| Store environment | `environment` | `xcode`, `local_testing`, `sandbox`, `production` |
| Purchase intent | `subject_kind` | `program`, `coach_access` |
| Purchase intent | `status` | `reserved`, `purchase_pending`, `fulfilled`, `cancelled`, `expired`, `failed` |
| Transaction | `status` | `verified`, `pending`, `refunded`, `revoked`, `expired` |
| Program entitlement | `status` | `active`, `revoked`, `refunded` |

Stable values memakai `snake_case`. Nilai manual commerce baru harus additive
dan tidak boleh memakai provider `manual` pada kolom store yang constraint-nya
hanya menerima App Store/Play Store.

## Blocking resolution sebelum codegen

Phase 00 tidak berwenang mengubah `Contracts/` atau migration root. Resolution
yang mengikat Phase 01 dan Phase 06 adalah:

1. Phase 01 boleh membuat domain TypeScript manual dari matrix yang dibekukan,
   tetapi **tidak boleh** generate DTO/client dari `CoachApplication` lama.
2. Phase 06, setelah izin eksplisit untuk shared backend/contract, membuat
   migration additive manual commerce dan mengubah OpenAPI dalam slice yang
   sama.
3. OpenAPI baru harus memisahkan `applicationStatus`, `paymentOrderStatus`,
   `paymentEvidenceStatus`, role, dan entitlement; tidak ada boolean `isPaid`.
4. Parser OpenAPI, enum parity test terhadap catalog SQL, dan compatibility
   test untuk DTO read lama wajib lulus sebelum codegen diaktifkan.
5. Bila izin shared path belum diberikan, Phase 06 berhenti di gate dan tidak
   membuat type lokal palsu yang menyimpang dari source authoritative.

Dengan resolution ini, drift tidak disembunyikan dan tidak dapat masuk ke
scaffold Phase 01 sebagai generated contract.
