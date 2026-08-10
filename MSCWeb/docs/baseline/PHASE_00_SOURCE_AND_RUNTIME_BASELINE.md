# Phase 00 Source and Runtime Baseline

> Snapshot: 10 Agustus 2026, Asia/Jakarta
>
> Sifat audit: read-only terhadap source iOS, `Contracts`, `supabase`, dan
> hosted deployment record. Tidak ada hosted query atau mutation.

## Klasifikasi bukti

| Klasifikasi | Bukti | Kesimpulan |
|---|---|---|
| Fakta source | Working tree pada commit `25415c4dcae6b9816bf6f6821e385db98503b38c` | 20 migration, 9 Edge Function entrypoint, 14 pgTAP file, OpenAPI 3.1 |
| Fakta local runtime | Database Supabase lokal yang sedang berjalan | 20 migration terpasang, schema terakhir `20260809092112` |
| Fakta hosted | [Deployment record 9 Agustus 2026](../../../Documentation/Release/HOSTED_MAIN_DEPLOYMENT_2026-08-09.md) | Hosted `main` menerima 20 migration, 9 Edge Functions, 5 recurring jobs, legal endpoint, Google dan Apple provider |
| Deferred manual gate | Hosted console, DNS, domain, production OAuth, deployment web | Tidak diperiksa atau diubah pada Phase 00 |

Empat klasifikasi di atas tidak boleh digabung menjadi status tunggal. Source
menjelaskan apa yang tersedia untuk dibangun, local runtime menjelaskan apa
yang benar-benar dimuat lokal, dan deployment record adalah bukti hosted
terbaru yang diizinkan untuk audit ini.

## Git dan user changes

- Branch saat snapshot: `port/phase_00`.
- Working tree sudah kotor sebelum implementasi Phase 00.
- Perubahan yang sudah ada: `AGENTS.md` dan `MSCWeb/AGENTS.md`.
- Kedua perubahan tersebut dipertahankan; Phase 00 tidak mengubah source iOS,
  `Contracts`, `supabase`, project Xcode, atau file root lain.
- Hash source yang menjadi baseline dicatat di
  [Backend and Contract Hash Manifest](./BACKEND_CONTRACT_HASH_MANIFEST.md).

## Inventaris source iOS

Hitungan berikut berasal dari file `.swift` dan tidak memasukkan workplan.

| Area | File Swift | Baris |
|---|---:|---:|
| App | 10 | 1.861 |
| Core | 10 | 533 |
| Domain | 24 | 5.610 |
| Feature Admin | 11 | 7.971 |
| Feature AppShell | 3 | 1.189 |
| Feature Auth | 4 | 3.022 |
| Feature Coach | 21 | 8.339 |
| Feature Commerce | 1 | 496 |
| Feature Media | 3 | 954 |
| Feature Participant | 21 | 7.532 |
| Infrastructure | 19 | 7.113 |
| LocalData | 3 | 1.905 |
| SharedUI | 15 | 2.827 |
| **Total** | **145** | **49.352** |

Test source terdiri dari 18 file Swift Testing dengan 194 deklarasi test dan
3 file XCUI dengan 52 metode test. Angka ini adalah inventory source, bukan
klaim bahwa test dijalankan ulang pada Phase 00. Pemetaan target web berada di
[iOS to Web Test Mapping](../testing/IOS_TO_WEB_TEST_MAPPING.md).

## Inventaris backend source

### Migration dan contract

- 20 migration SQL, dari `20260802000000_program_end_to_end.sql` sampai
  `20260809092112_phase13_recurring_operations_url_validation_fix.sql`.
- 14 file pgTAP dan 13 file integration `.mjs`.
- OpenAPI 3.1.0 valid secara YAML: 48 path dan 36 schema.
- Contract OpenAPI masih membawa status Coach application lama; resolution
  tercatat di [Contract Reconciliation](./PHASE_00_CONTRACT_RECONCILIATION.md).

### Edge Functions

| Function | Boundary saat ini | Disposisi web |
|---|---|---|
| `delete-account` | User session | Pertahankan dan adaptasi web session |
| `cleanup-orphan-question-photos` | Admin/session atau scheduler | Pertahankan |
| `commerce` | Store purchase verification | Legacy iOS selama transisi |
| `commerce-apple-notifications` | Apple signed webhook | Legacy iOS selama transisi |
| `apple-identity-lifecycle` | Apple identity user flow | Legacy iOS selama transisi |
| `apple-account-events` | Apple signed event | Legacy iOS selama transisi |
| `apple-identity-reconciliation` | Internal scheduler | Legacy sampai decommission gate |
| `apple-commerce-reconciliation` | Internal scheduler | Legacy sampai decommission gate |
| `legal` | Public GET/HEAD | Pertahankan sampai legal surface web menggantikannya secara terverifikasi |

## Inventaris local runtime

Colima dan Docker daemon tersedia. `supabase status` melaporkan core stack dan
database dapat diakses; image proxy dan pooler berstatus stopped. Phase 00
tidak mengklaim kedua service opsional itu sehat.

| Item | Hasil read-only |
|---|---|
| Migration terpasang | 20; min `20260802000000`, max `20260809092112` |
| Tabel schema `public` | 29 |
| Tabel public dengan RLS | 29 dari 29 |
| Policy `public` + `storage` | 50 |
| Function `public` | 67 termasuk overload/helper |
| Function `private` | 22 |
| Grant tabel `private` ke `anon`/`authenticated` | 0 |
| SECURITY DEFINER tanpa fixed search path | 0 |
| Bucket | `public-media` public; `question-photos` private; limit 8 MiB |

Grant tabel langsung hanya memberikan `SELECT` pada 22 tabel kepada
`authenticated`; akses tetap dibatasi RLS. Lima function dapat dieksekusi
`anon` untuk public-safe read dan 53 function dapat dieksekusi
`authenticated` sesuai explicit grants.

### Tabel authoritative saat ini

```text
apple_notification_inbox, audit_events, coach_access_entitlements,
coach_applications, coach_payment_records, coach_store_products,
commerce_purchase_intents, commerce_transaction_events,
commerce_transactions, profiles, program_answer_keys, program_days,
program_enrollments, program_entitlement_events, program_entitlements,
program_question_options, program_questions, program_scores, program_steps,
program_store_products, program_winners, programs, quiz_attempt_results,
score_adjustments, step_submission_answers, step_submissions, weigh_ins,
winner_posters, winner_snapshots
```

### Recurring jobs lokal

| Job | Jadwal UTC | Aktif |
|---|---|---|
| `phase10-expired-provisional-cleanup` | menit 17 setiap jam | Ya |
| `phase12-expire-commerce-state` | setiap 5 menit | Ya |
| `phase13-apple-identity-reconciliation` | menit 2 lalu setiap 15 menit | Ya |
| `phase13-apple-commerce-reconciliation` | menit 7 lalu setiap 15 menit | Ya |
| `phase13-orphan-question-photo-cleanup` | 03.12 harian | Ya |

Local config mengaktifkan Google dan Apple provider untuk development. Tidak
ada credential, key, URL privat, atau token yang disalin ke dokumen ini.

## Inventaris hosted berdasarkan deployment record

- 20 migration diterapkan forward-only; tidak ada reset atau seed.
- 9 Edge Functions aktif, semuanya memakai handler-level authentication
  boundary sesuai fungsi masing-masing.
- SSL database dipaksa aktif.
- RLS/grant/security-definer audit pada deployment record bersih.
- Bucket hosted: `public-media` public dan `question-photos` private.
- Lima cron yang sama dengan local runtime tercatat aktif.
- Google dan Apple Auth provider aktif; Email provider nonaktif.
- Commerce Apple gagal tertutup bila environment store belum lengkap.
- Store product mapping production belum tersedia.

Hosted state tidak di-query ulang. Bukti ini berlaku sesuai deployment record
9 Agustus 2026 dan harus diverifikasi lagi pada production gate Phase 12/13.

## Kesimpulan baseline

Backend saat ini adalah production-evolved system, bukan prototype. Web harus
mempertahankan schema/RLS/RPC yang benar, menambah manual commerce secara
forward-only, dan menjaga Apple/StoreKit objects sampai decommission gate.
Phase 01 boleh membuat scaffold, tetapi tidak boleh melakukan codegen dari
OpenAPI lama atau mengasumsikan provider `manual` sudah ada.
