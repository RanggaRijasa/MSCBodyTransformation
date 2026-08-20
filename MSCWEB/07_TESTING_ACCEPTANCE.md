# 07 — Testing and acceptance specification

## 1. Definition of done

Satu vertical slice hanya selesai jika:

1. requirement IDs dan acceptance scenarios telah dipilih;
2. UI copy Indonesia lengkap;
3. unit/component tests untuk behavior utama ada;
4. RLS/RPC tests ada bila menyentuh backend authority;
5. Playwright happy path dan critical failure path lulus;
6. compact light/dark serta responsive state diperiksa secara visual;
7. keyboard, screen reader semantics, reduced motion, dan zoom relevan diperiksa;
8. build production berhasil;
9. tidak ada secret/private data pada bundle/log;
10. spec dan ADR diperbarui bila implementasi mengubah keputusan.

- `QA-001` Tidak boleh menandai feature complete hanya karena screenshot terlihat benar.
- `QA-002` Fixture harus deterministic dan tidak menggunakan media produksi.
- `QA-003` Production test tidak boleh merusak hosted main; backend integration berjalan local kecuali environment khusus diotorisasi.

## 2. Test layers

| Layer | Tool | Fokus |
|---|---|---|
| Domain unit | Vitest | policy, state transition, formatter, typed errors |
| Component | React Native Testing Library | rendering/state/action/accessibility |
| Database | pgTAP/SQL tests + Supabase local | RLS, grants, constraints, functions, concurrency |
| Integration | Vitest/Playwright + Supabase local | Auth adapter, upload, RPC result/cache invalidation |
| E2E | Playwright | user journeys pada browser |
| Visual | Playwright screenshots | hierarchy/regression compact/wide/light/dark |
| Manual device | Safari iPhone/iPad, Chrome Android/desktop | install, camera, picker, safe area, keyboard |
| Performance | Lighthouse/Web Vitals/bundle analysis | budgets pada PWA/landing |

## 3. Browser/device baseline

Versi final mengikuti current-1 policy saat launch. Baseline categories:

- Safari iOS current dan previous major;
- installed PWA iOS;
- Chrome Android current;
- Chrome desktop current;
- Safari macOS current;
- Edge desktop current;
- viewport 320, 375, 390, 430, 768, 1024, 1280, dan 1440 CSS px.

Firefox MAY menjadi compatibility target tambahan; jika tidak, core browsing/accessibility tetap harus tidak rusak secara sengaja.

## 4. Critical product journeys

### `QA-JRN-001` Guest ke program berbayar

Given Guest membuka program aktif berbayar  
When memilih gabung, login Google, kembali ke program, memindai QR Coach valid, membuat request, dan mengirim proof valid  
Then status `Menunggu pemeriksaan` terlihat, Participant belum enrolled, dan Admin melihat satu queue item.

### `QA-JRN-002` Participant payment approval

Given payment Participant pending review  
When Admin menyetujui  
Then transaction, entitlement, enrollment, dan audit tercipta exactly once; Participant melihat program pada `Diikuti`.

### `QA-JRN-003` Participant payment rejection/resubmit

Given proof ditolak dengan alasan  
When Participant membuka status dan mengirim proof baru  
Then attempt lama tetap tercatat, attempt baru pending, dan tidak ada enrollment.

### `QA-JRN-004` Free program

Given program gratis dan QR Coach valid  
When Participant mengonfirmasi enrollment  
Then tidak ada payment request dan enrollment tercipta atomik.

### `QA-JRN-005` Coach activation

Given applicant eligible dengan payment pending  
When Admin memilih `Setujui dan aktifkan Coach`  
Then payment/application approved, entitlement tiga bulan dan protected role aktif exactly once.

### `QA-JRN-006` Program evidence review

Given Participant mengirim bukti aktivitas  
When Coach assigned menyetujui  
Then status dan poin authoritative berubah once; Coach lain tidak dapat membuka bukti.

### `QA-JRN-007` Logout privacy

Given user telah membuka profile, weight, evidence, dan payment proof  
When logout lalu Guest/account lain membuka app  
Then private data, thumbnail, signed URL, dan query cache tidak terlihat/terakses.

### `QA-JRN-008` Installed PWA

Given PWA terpasang  
When dibuka dari Home Screen online dan kemudian offline  
Then online route/session bekerja; offline menampilkan shell/status jujur dan mutation disabled.

### `QA-JRN-009` Coach membagikan profil publik

Given Coach aktif dengan hanya foto, nama, dan badge otomatis serta beberapa field opsional kosong
When Coach memublikasikan profil dan memilih `Bagikan profil`
Then canonical `/c/:handle` dapat dibuka Guest, field kosong tidak dirender, raw QR/user UUID tidak ada pada URL/HTML, dan share fallback menyalin URL yang sama.

### `QA-JRN-010` Insight makanan tidak memblokir poin

Given pertanyaan foto dikonfigurasi untuk analisis makanan dan submission memenuhi aturan poin otomatis
When Participant mengirim foto dan provider AI lambat
Then submission/poin authoritative selesai tanpa menunggu AI, UI menampilkan `Menganalisis foto…`, lalu hasil macro/bintang muncul setelah job selesai.

### `QA-JRN-011` Provider AI gagal

Given submission foto makanan berhasil
When provider timeout, rate-limit, mengembalikan schema invalid, atau tidak tersedia
Then job retry/berakhir aman, UI menampilkan `Analisis belum tersedia`, tidak ada poin/approval yang dibatalkan, dan tidak ada key/payload privat pada browser/log.

### `QA-JRN-012` Admin melihat penjualan bersih

Given fixture memiliki penjualan program, akses Coach, order pending/rejected, dan satu reversal
When Admin membuka `Ringkasan penjualan` untuk 30 hari WITA
Then bruto hanya menjumlah verified ledger, reversal ditampilkan terpisah, net adalah bruto dikurangi reversal, pending/rejected tidak menjadi revenue, dan tidak ada double count dari commerce projection.

### `QA-JRN-013` Admin menghapus gambar pengguna dengan aman

Given satu gambar eligible, satu gambar masih protected, dan satu path dipakai lebih dari satu reference
When Admin memindahkan eligible image ke Sampah lalu mengonfirmasi purge
Then normal user segera kehilangan akses, protected/shared image tetap utuh, worker rechecks references dan mencapai satu logical purge outcome melalui Storage API dengan retry aman, serta domain record/poin/audit tetap tersedia dengan satu tombstone/audit.

### `QA-JRN-014` Google user baru menjadi Peserta

Given Google OAuth menghasilkan Auth identity dan profile provisional
When user mengisi nama/HP/level, memilih `Lanjut sebagai Peserta`, memindai QR Coach valid, dan mengonfirmasi
Then account menjadi active Participant exactly once, current Coach tersimpan authoritative, raw QR tidak terekspos, dan preserved authorized intent dilanjutkan.

### `QA-JRN-015` Google user baru mengajukan Coach

Given provisional user berlevel SC atau lebih tinggi
When memilih `Ajukan menjadi Coach`, mencentang HOM STS/ICT/terms, membuat order tiga bulan, dan mengirim proof valid
Then account menjadi active Participant, application/payment tetap menunggu Admin, role Coach belum aktif, dan approval Admin kemudian mengaktifkan Coach exactly once.

## 5. Payment acceptance matrix

| Case | Expected |
|---|---|
| file > 8 MiB setelah normalisasi | ditolak sebelum submit dengan copy actionable |
| unsupported/corrupt file | ditolak client dan server |
| upload putus | request tetap `awaiting_proof`, retry aman |
| double submit | satu proof attempt/state transition |
| two Admin approve concurrently | satu success, satu already-processed conflict |
| forged lower amount | server menggunakan amount snapshot authoritative |
| destination config berubah | request lama tetap memakai snapshot lama |
| program inactive sebelum approve | operation mengikuti policy conflict; tidak partial approve |
| duplicate enrollment exists | no duplicate entitlement/enrollment |
| reject tanpa alasan | server validation error |
| owner B reads proof A | RLS denial/not found |
| expired signed URL | download gagal dan URL baru hanya untuk authorized viewer |

## 6. Recurring product edge cases

Wajib dimasukkan pada fixtures/tests yang relevan:

- tidak ada program aktif;
- step list kosong;
- evidence/answer wajib belum ada;
- hari terkunci;
- pending/rejected evidence;
- final weight belum ada;
- berat naik;
- skor leaderboard seri;
- pemenang kurang dari lima;
- QR Coach invalid/mismatch;
- duplicate enrollment;
- program capacity reached;
- camera permission denied;
- offline/timeout/repository failure;
- session expiry;
- application Coach tidak eligible;
- payment pending/rejected/expired/concurrent review.
- profil Coach hanya berisi field wajib, semua field opsional, kontak sebagian publik, handle tidak ditemukan, entitlement kedaluwarsa, dan media menunggu moderation;
- food, drink, shake, not-food, foto buram/ambigu, provider timeout/rate-limit/schema invalid, duplicate job, correction conflict, dan low-confidence request untuk rating 1–2.
- sales zero/reversal-only/pending-only, WITA boundary, partial/full reversal, approved-without-ledger, purpose program/Coach, missing display name, dan equal top totals;
- media orphan/shared reference/protected/unknown, pending review, active AI job, published Coach media, trash/restore/purge, concurrent reference, worker retry, missing object, dan partial batch failure.
- first-login existing/new Google identity, provisional/expired/cleanup state, incomplete profile, Member Coach choice, invalid/denied QR, camera denied, two tabs, duplicate callback/finalize, preserved unauthorized intent, pre-proof cancel, tab close/resume, Coach proof correction/rejection/approval.

## 6.1 Coach public profile acceptance

- `QA-CPR-001` Foto awal Google diimpor/ditransformasi tanpa hotlink; Coach dapat mengganti avatar dan media lama mengikuti cleanup policy.
- `QA-CPR-002` Nama dan badge berasal dari authority; Coach tidak dapat memalsukan badge atau mempertahankannya setelah entitlement berakhir.
- `QA-CPR-003` Setiap kontak yang toggle publikasinya off tidak muncul pada public API, HTML, metadata, maupun cache Guest.
- `QA-CPR-004` Semua testimoni/before–after memerlukan moderation state; attestation izin pihak ketiga hanya wajib ketika orang lain ditampilkan/dikutip. Konten diri sendiri memiliki publication path tanpa attestation pihak ketiga, dan bucket bukti privat tidak dapat dipakai sebagai sumber.
- `QA-CPR-005` Web Share, copy fallback, canonical URL, unknown handle, unlisted profile, keyboard, screen reader, compact, dan wide states lulus.

## 6.2 Food insight and favorable-rating acceptance

- `QA-AI-001` Hanya question dengan analysis mode `food` membuat job; submission foto lain menghasilkan nol provider call.
- `QA-AI-002` Browser/network bundle tidak mengandung provider API key, system prompt, raw Storage path, atau signed URL provider input.
- `QA-AI-003` Provider adapter menerima fixture food/drink/shake/not-food dan menolak output di luar schema/range.
- `QA-AI-004` Rating validator menetapkan: 4 default untuk food yang plausible tanpa pelanggaran jelas; 5 untuk match kuat; 3 untuk ambigu; rating 1 hanya untuk `not_food_for_required_food` dan rating 2 hanya untuk `severe_explicit_rubric_mismatch`, keduanya dengan rubric eksplisit serta confidence `>= 0.90` menurut `food_rating_policy_v1`.
- `QA-AI-005` Property/table tests MUST membuktikan setiap no-rubric, confidence `< 0.90`, unknown-reason, atau rating/reason mismatch 1–2 disimpan minimal sebagai 3 atau `uncertain`; policy version berasal dari server, bukan provider.
- `QA-AI-006` Crash setelah submission commit tetapi sebelum enqueue MUST dipulihkan oleh reconciliation scan menjadi tepat satu job untuk analysis version tersebut tanpa mengubah poin/approval.
- `QA-AI-007` Duplicate delivery/retry menghasilkan satu result untuk submission + analysis version; correction beralasan diaudit dan tidak mengubah poin.
- `QA-AI-008` Provider timeout/rate-limit/invalid JSON/invalid macro tidak mengubah submission, approval, ledger poin, atau Coach role.
- `QA-AI-009` Mengganti konfigurasi ke fake OpenAI-compatible provider tidak memerlukan perubahan feature/domain code. Adapter noncompatible diuji melalui contract suite yang sama.
- `QA-AI-010` Disclosure AI dan anjuran menghindari wajah/dokumen terlihat sebelum submit, tetapi tidak ada checkbox consent terpisah pada baseline.
- `QA-AI-011` Insight dan alasan rating menggunakan Bahasa Indonesia yang natural dan non-diagnostik, label `Perkiraan dari foto`, icon bintang Phosphor, dan tidak memberi klaim keamanan/medis dari foto.
- `QA-AI-012` Output provider berbahasa Inggris, campuran yang tidak layak, raw JSON, atau istilah teknis provider MUST tidak dirender langsung; validator menggunakan retry terbatas atau fallback Bahasa Indonesia deterministic.
- `QA-AI-013` Structured output MUST berisi satu atau dua `insightSentences`; setiap item maksimal 80 karakter dan total maksimal 160 karakter. Output kosong, tiga kalimat, overlong, atau kalimat terpotong MUST gagal validasi dan menggunakan fallback valid.
- `QA-AI-014` Request OpenRouter memakai `FOOD_AI_MODEL=google/gemma-4-31b-it:free` sebagai default, `reasoning.effort=none`, `reasoning.exclude=true`, dan output-token cap. Reasoning response tidak disimpan.
- `QA-AI-015` Mengganti `FOOD_AI_MODEL` ke compatible OpenRouter fixture/model tidak memerlukan perubahan feature/domain/adapter; model tanpa image, structured response, atau reasoning-off gagal aman tanpa memengaruhi submission, approval, atau poin.

## 6.3 Sales overview acceptance

- `QA-SLS-001` Admin-only RPC accepts inclusive `from_at`, exclusive `to_at`, allowlisted timezone, and rejects invalid or range over 366 days; Guest/Participant/Coach fail closed.
- `QA-SLS-002` Gross = sum verified ledger, reversal = sum reversal ledger, net = gross − reversal, order count is distinct verified order, dan average memakai gross verified/order count dengan zero-safe behavior.
- `QA-SLS-003` `approved` order without verified ledger, pending/correction/rejected/expired/cancelled order, proof, event, entitlement, and `commerce_transactions` MUST not increase sales totals.
- `QA-SLS-004` Daily buckets and 7/30/90/custom ranges are deterministic across WITA midnight/DST-independent boundaries; formatter uses `id-ID`, IDR, and tabular numerals.
- `QA-SLS-005` Purpose/program/top-customer breakdown reconciles to totals. Customer projection contains opaque `person_id`, display name, order count, gross/reversal/net only; no email/phone/member/bank/proof/reconciliation/path.
- `QA-SLS-006` Multiple partial/full revenue reversals relate to one verified entry, are idempotent, cumulative `<= verified`, and are recognized on each reversal timestamp; period net can be zero/negative without UI hiding it.
- `QA-SLS-007` Late/rejected-but-paid, duplicate transfer, and overpayment-difference returns use exceptional cash-adjustment fixtures and do not alter gross/reversal/net sales; unmatched/refused adjustments fail closed.
- `QA-SLS-008` Query plan on representative fixture uses appropriate reporting indexes; Supabase security/performance advisors pass and no materialized view is added without evidence.
- `QA-SLS-009` W07.5 Quick Access preserves first two native-derived actions, adds the third Sales action with intentional wrapping, reaches `/admin/sales`, and remains usable compact/wide, keyboard, screen reader, dark mode, and 200% zoom.
- `QA-SLS-010` Chart has exact accessible table/list equivalent; zero/loading/error/stale/reversal-only states do not depend on color or animation.
- `QA-SLS-011` Program/customer top lists each return at most five rows, group by immutable ID, and tie-break by net desc, gross desc, verified-order count desc, stable ID asc. Duplicate names remain distinct; null/deleted owner is `Pengguna dihapus` with safe/non-navigable behavior when needed.
- `QA-SLS-012` Two customers with multiple orders retain distinct `customer_group_id` after both profiles are deleted; `person_id` becomes null and no contact snapshot remains. Legacy pre-key null-owner orders are separate per-order unknown groups and never merge.

## 6.4 Image storage management acceptance

- `QA-MED-001` Inventory reconciles all objects/references in `question-photos`, `payment-evidence`, and `coach-public-media`; unknown objects fail closed. Out-of-scope buckets cannot be requested through forged input.
- `QA-MED-002` Usage equals sum of Storage metadata byte size for managed user-image buckets. Trash remains counted until purge; quota is absent unless trusted server config supplies it.
- `QA-MED-003` Browser receives opaque IDs and safe labels only. Raw path/signed URL/namespace/service key/image bytes/weight/reconciliation data do not appear in route, API projection, audit, console, analytics, or shared cache.
- `QA-MED-004` All `payment-evidence` Admin trash/purge attempts are rejected because cleanup is automatic; evidence pending review, active AI job, account cleanup, published Coach media not yet detached, shared reference, and unknown classification also block purge with typed reason.
- `QA-MED-005` Trash closes normal access immediately; Admin preview remains no-store; restore before purge reactivates the same reference exactly once.
- `QA-MED-006` Purge operation rechecks reference fingerprint immediately before Storage API removal. Concurrent new/changed reference causes conflict and object remains.
- `QA-MED-007` Worker claims jobs with lease/`SKIP LOCKED`, tolerates at-least-once remote remove invocation, retries Storage/finalization failure, treats already-missing object as recoverable finalization, and writes exactly one logical tombstone/audit/final outcome. A forced crash after `.remove()` success proves recovery.
- `QA-MED-008` Permanent delete uses Storage API, never SQL deletion of `storage.objects`. Direct client delete of managed referenced assets and non-Admin RPC calls are denied.
- `QA-MED-009` Deleting eligible question evidence preserves submission/review/poin/leaderboard and UI displays Indonesian deletion tombstone. Automatic payment-retention cleanup preserves transaction/ledger/audit and inventory reflects its deleted state without exposing manual controls.
- `QA-MED-010` `coach-public-media` becomes private and public RPC returns opaque media ID. Controlled gateway validates published+active state; published avatar/item detaches before trash; a previously known legacy direct URL and gateway URL both fail immediately after Trash, before physical purge.
- `QA-MED-011` Keyset pagination, filters, safe search, thumbnail lazy loading/object URL cleanup, 100-item batch cap, select-current-page semantics, and partial failure recovery pass compact/wide tests.
- `QA-MED-012` Clean migration-chain test reproduces every referenced media column/RPC/policy before deletion is enabled; generated database types match committed migrations.
- `QA-MED-013` Final W07.6 Dashboard has four Quick Access cards in 2 × 2 compact/up-to-four-wide layout; first two actions preserve order/alignment and Activity remains reachable above bottom navigation.
- `QA-MED-014` Automatic payment cleanup racing inventory reconciliation on the same proof results in one deleted/tombstoned inventory state; Image Storage never claims ownership of the delete or offers restore/purge controls.

## 6.5 Registration and first-login onboarding acceptance

- `QA-ONB-001` New Google Auth row bootstraps one provisional Participant profile with provider name/photo defaults, 24-hour expiry, no active/finalized status, and no role/purpose derived from `user_metadata`.
- `QA-ONB-002` Existing active Participant/Coach/Admin bypass onboarding and reaches safe intended/role route; provisional, coach-handoff, and cleanup states cannot flash/render private app content.
- `QA-ONB-003` Session context includes only safe role/onboarding/purpose/completeness/expiry projection. AuthProvider models explicit onboarding state and invalidates cached context across callback, account switch, finalization, cancellation, and session refresh.
- `QA-ONB-004` Profile form validates Indonesian copy, name, phone, all member levels, purpose, Member-disabled Coach, purpose reconciliation after level change, keyboard/scroll/200%-zoom, and no phone logging.
- `QA-ONB-005` Participant path blocks finalization for missing/invalid/expired/unapproved/non-public/inactive-entitlement QR; no manual code exists. Valid QR sets active Participant/current Coach once under double click, concurrent tab, retry, and callback refresh.
- `QA-ONB-006` Coach path blocks Member/incomplete HOM STS/ICT/terms, uses server price bands, three-month/no-auto-renew copy, manual bank/QRIS, normalized private proof, and one current application/order.
- `QA-ONB-007` `submit_coach_onboarding_payment_evidence` atomically submits prepared proof, sets order `under_review`, and finalizes Participant exactly once; forced failure cannot persist only one side. Generic proof submit rejects provisional Coach orders. Only Admin approval activates Coach.
- `QA-ONB-008` `Minta perbaikan bukti` preserves active Participant and the same application/order with append-only attempt. `Tolak pengajuan` is terminal for that pair; later explicit reapplication creates a new pair while old history remains.
- `QA-ONB-009` Provisional RLS/RPC negative suite denies private profile/enrollment/score/evidence/payment-other-user/Coach/Admin data and mutations while allowing only explicit onboarding/public operations.
- `QA-ONB-010` Explicit pre-proof cancel creates one cancellation receipt and cleanup-pending state; worker cancels artifacts/media, revokes sessions, deletes Auth/profile, and returns Guest. Response loss before/after deletion converges without authenticated prior-success lookup. Cancellation after proof preserves Participant/financial/application history.
- `QA-ONB-011` Expired cleanup enqueues the same receipt/worker path, rechecks relationships, handles stale Coach draft/order/unsubmitted upload, retries partial failure, and leaves no orphan media/identity.
- `QA-ONB-012` Preserved internal intent resumes only after active finalization and authorization. External/open-redirect, role-mismatched, stale, `/admin`, and `/coach` intents fall back safely.
- `QA-ONB-013` Compact visual flow matches current iOS hierarchy for profile choice, Coach eligibility, payment, pending status, and Participant QR confirmed/unconfirmed states; deliberate copy uses `akun MSC belum aktif` for provisional web identity.
- `QA-ONB-014` Existing active Participant can still edit profile through shared `update_my_profile`, open `/app/coach-application`, and complete W06 flow while provisional onboarding uses a separate profile-save RPC.
- `QA-ONB-015` Cancellation/expiry revokes all sessions before Auth deletion; stale access token, second tab, and delayed callback cannot recreate or access the cancelled profile.

## 7. Accessibility acceptance

- seluruh core flow dapat selesai keyboard-only pada desktop;
- focus order logis dan focus terlihat;
- bottom navigation, segments, accordion, dialog, tabs, upload, status, dan progress memiliki semantics yang tepat;
- icon-only controls memiliki accessible name;
- status tidak disampaikan hanya dengan warna;
- zoom 200% tidak menghilangkan content/action;
- target touch minimum 44 × 44;
- reduced motion/transparency dihormati;
- screen reader tidak membaca decorative icon atau raw ID;
- error terasosiasi dengan field dan diumumkan.

## 8. Visual acceptance

Core screenshot set:

- Guest Home/login;
- Participant Home, catalog, program detail, day accordion, step, payment states;
- Coach Dashboard, review queue/detail, QR;
- profil Coach publik/edit/share dengan field minimum dan lengkap;
- insight makanan pending/available/unavailable serta rating 1–5;
- Admin Dashboard, Program, People, payment/Coach review;
- Admin Ringkasan penjualan dengan zero/normal/reversal-only periods;
- Admin Penyimpanan gambar: Gambar, Sampah, protected, trash confirmation, failed job, dan purge complete;
- first-login profile purpose choice, Participant QR unconfirmed/confirmed, Coach eligibility/payment/pending/correction, cancel/resume;
- compact light/dark dan wide Admin;
- loading/empty/error/offline;
- text zoom / long Indonesian copy.

Visual regression threshold tidak boleh menyembunyikan large layout drift. Perubahan baseline memerlukan review manusia dan link requirement.

## 9. Release gates

- lint/typecheck/unit/component/database/E2E lulus;
- production export dan local static serve lulus;
- manifest/installability/icon safe-zone lulus;
- Lighthouse/Web Vitals memenuhi atau ada accepted waiver;
- CSP enforce tanpa unexpected violation;
- dependency audit ditinjau;
- no secret scan lulus;
- RLS negative tests lulus;
- sales ledger reconciliation dan media deletion race/retry/tombstone suite lulus;
- first-login provisional route/RLS/finalization/cancellation/expiry suite lulus;
- SOP pembayaran/retention/dispute telah diputuskan;
- production media deletion policy, protected-state matrix, worker schedule, dan operator/rollback procedure telah disetujui;
- production Supabase/Cloudflare deployment mendapat authorization eksplisit.
