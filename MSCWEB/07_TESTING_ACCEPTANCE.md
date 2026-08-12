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
- Admin Dashboard, Program, People, payment/Coach review;
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
- SOP pembayaran/retention/dispute telah diputuskan;
- production Supabase/Cloudflare deployment mendapat authorization eksplisit.

