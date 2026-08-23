# 08 — Delivery plan and checkpoints

Dokumen ini adalah delivery overview. Workplan eksekusi rinci, checklist, sub-agent plan, exit criteria, dan permission matrix berada di [`workplans/`](./workplans/README.md). Penamaan `W00–W09` digunakan untuk membedakan fase MSCWEB dari fase native iOS pada repository induk.

Active launch sequence per [`ADR-0010`](./decisions/0010-defer-admin-analytics-and-storage-management.md):

```text
W07.4 complete → W08 PWA/Cloudflare hardening → W09 authorized deployment
                                               → W10 CI/CD automation
                                      ↓ after launch by new priority
                              W07.5 Sales → W07.6 Image Storage
```

## Prinsip delivery

- Kerjakan vertical slice kecil end-to-end.
- Supabase local adalah development authority; hosted main tidak disentuh tanpa izin production eksplisit.
- iOS tidak diubah untuk membuat web lebih mudah.
- Setiap phase berakhir dengan build/test/demo evidence dan spec delta.
- Repository tetap menyatu sampai checkpoint pemisahan aman.
- Sesuai [`ADR-0011`](./decisions/0011-web-only-repository-and-supabase-authority.md), setelah W09 cutover repository MSCWEB menjadi satu-satunya authority aplikasi web, Cloudflare, dan seluruh canonical Supabase deployment history; repository iOS menjadi arsip non-deployable.

## W00 — feasibility spikes

Tujuan: membuktikan risiko platform sebelum feature work.

- scaffold Expo TypeScript strict di dalam `MSCWEB`;
- verifikasi Expo Router export ke Cloudflare Workers Static Assets;
- spike static landing + authenticated SPA route;
- spike React Native Web + StyleSheet/tokens + responsive navigation;
- spike Phosphor SVG tree-shaking;
- spike Google OAuth callback local;
- spike camera QR pada Safari iOS dan Chrome Android;
- spike image normalize/metadata removal/8 MiB;
- generate PWA icon derivatives dan mask test;
- prototype private Supabase signed image download.

Exit: keputusan rendering/export, QR library/adapter, image pipeline, dan dependency versions dikunci lewat ADR. Tidak ada production deploy.

## W01 — foundation and design system

- dependency container dan domain/repository boundaries;
- theme/tokens/light/dark;
- MSCIcon registry;
- shared controls/state components;
- public landing, legal shells, manifest, service worker baseline;
- responsive Guest/Participant app shell;
- testing/visual baseline infrastructure.

Exit: landing dan empty app shell berjalan pada compact/wide, installable locally, accessibility smoke lulus.

## W02 — Auth and public Participant shell

- Google Auth local;
- callback/preserved intent/session/logout cache clearing;
- public program/read model;
- Guest Home, program catalog/detail, leaderboard/pemenang/Coach public states;
- centralized authentication gate.

Exit: Guest tidak pernah menerima private data; auth/deep link journeys lulus.

## W03 — Participant program parity

- enrolled/available/history;
- program activity/day accordion/locks;
- article/video/form/quiz/weight step renderer;
- home focus/progress/points.

Exit: Participant dapat menjalankan program flow dan mengisi jawaban dasar terhadap Supabase local; scoring/review authority tetap server-side.

## W04 — Evidence, review, and authoritative scoring

- evidence picker/camera/normalization/private upload/status;
- Coach-scoped review queue/detail;
- approve/reject/idempotency/audit;
- authoritative step/weight points dan private media access.

Exit: `QA-JRN-006` dan negative RLS/concurrency tests lulus; pending/rejected evidence tidak memberi poin.

## W05 — Enrollment and manual payment

- scan QR Coach;
- free enrollment operation;
- manual payment destination/request/proof schema dan RLS;
- rekening/QRIS/upload/status UI;
- Participant payment Admin queue/review;
- atomic approval to entitlement/enrollment.

Exit: journeys `QA-JRN-001` sampai `004` dan payment negative/concurrency suite lulus.

## W06 — Coach experience and public profile

- Coach application/eligibility/pricing/payment;
- activation Admin operation;
- Coach dashboard/QR/participants/activity/review queue;
- evidence review approval/rejection;
- Coach program/leaderboard/profile;
- public `/c/:handle`, required Google/account identity, optional professional/contact/testimonial/before–after fields, publication controls, dan share action.

Exit: Coach access hanya aktif melalui authority path, cross-Coach RLS tests lulus, dan profil minimum dapat dipublikasikan/dibagikan tanpa membocorkan hidden contact/raw QR.

## W06.5 — Async food insight and AI stars

- question-level food analysis flag dan durable idempotent jobs;
- server-only provider interface dengan OpenRouter/OpenAI-compatible adapter awal;
- estimasi kkal/protein/karbohidrat/lemak dan insight non-diagnostik;
- favorable 1–5 rating dengan 1–2 guard;
- Participant/Coach pending/result/unavailable UI dan optional audited correction;
- privacy-minimal payload, secret, provider-failure, and point-independence tests.

Exit: insight berjalan asynchronous tanpa memengaruhi submission/approval/poin, rating rendah hanya lolos guard, dan provider compatible dapat diganti lewat config tanpa feature change.

## W07 — Admin parity

- Dashboard/metrics/attention;
- Program CRUD/publish/preview;
- People Peserta/Coach/Admin;
- Content management;
- score corrections/winner lock/fallback operations;
- Settings dan complete audit surfaces.
- moderation testimoni/before–after serta operational view AI yang ter-redact.

Exit: semua Admin iPhone capabilities memiliki parity evidence atau accepted deferral.

## W07.4 — Registration and first-login onboarding remediation

- session context membedakan provisional/onboarding/active, bukan role saja;
- profile form Nama/HP/Level Member dan tujuan Peserta/Ajukan Coach;
- Participant QR Coach finalization tanpa manual code;
- new-user Coach eligibility/manual payment/proof/pending Admin;
- proof submission mengaktifkan Participant tanpa memberi role Coach;
- provisional cancel/resume/expiry cleanup dan active-user regressions.

Exit: new Google user tidak dapat membuka private app sebelum onboarding authoritative; Participant memerlukan QR valid, applicant Coach tetap Participant sampai Admin approval, dan abandoned provisional identity dibersihkan aman.

## W07.5 — Admin Sales Overview (`Deferred post-launch`)

Tidak menjadi dependency atau release gate deployment pertama. Workplan dan requirement berikut tetap authoritative ketika fase ini diaktifkan setelah launch.

- Dashboard Quick Access `Ringkasan penjualan` dan route `/admin/sales`;
- ledger-authoritative gross/reversal/net/order metrics;
- 7/30/90/custom WITA filters dan purpose Program/Akses Coach;
- daily trend, program, purpose, customer, dan non-revenue pipeline breakdown;
- Admin-only fixed projection, privacy, query-plan/index, responsive/accessibility tests.

Exit: semua angka dapat direkonsiliasi ke payment ledger tanpa double count commerce, pending tidak menjadi revenue, dan response tidak memuat private payment/customer data.

## W07.6 — Admin Image Storage (`Deferred post-launch`)

Inventory/usage/Trash/restore/purge Admin tidak menjadi dependency deployment pertama. Private Coach-media gateway dan automatic payment-proof retention/orphan cleanup dipindahkan ke launch gate W08.

- fourth Quick Access `Penyimpanan gambar` dan route `/admin/image-storage`;
- managed usage/inventory untuk user-uploaded question, payment, dan Coach-profile images;
- private media registry/reference reconciliation dan opaque browser IDs;
- Sampah, restore, permanent-purge intent, protected-state matrix, tombstones;
- leased server worker dengan last-moment reference recheck dan Supabase Storage API delete;
- destructive/race/retry/cache/privacy/accessibility/regression tests.

Exit: Admin dapat menghapus eligible synthetic local image tanpa merusak domain history/poin/ledger, sedangkan protected/shared/unknown media fail closed dan tidak ada raw path/service key di browser.

## W08 — PWA hardening

- offline/cache/update behavior;
- install guidance;
- security headers/CSP;
- performance/code splitting/image budgets;
- full browser/device/accessibility pass;
- observability redaction;
- production runbooks dan policy blockers.
- canonical/Open Graph/cache behavior untuk profil Coach publik.
- minimum media launch safety: private evidence/RLS, payment-proof retention/orphan cleanup, opaque Coach-media gateway, dan cache invalidation.
- launch build tidak merender route/action W07.5 atau W07.6 yang masih deferred.

Exit: release gates pada QA spec lulus; production deploy masih memerlukan izin eksplisit.

## W09 — Release and repository split

- requirement-to-evidence traceability dan unresolved-risk register;
- authorized production Supabase/AI provider/Cloudflare rollout bila diminta;
- controlled production smoke scope;
- safe repository split yang membawa seluruh canonical root `supabase/` ke repository MSCWEB;
- cutover Cloudflare dan Supabase deployment authority hanya ke repository MSCWEB;
- repository iOS dibekukan sebagai arsip tanpa deployment authority.

Exit: release/split dilakukan dan diverifikasi hanya dalam authorization yang tepat, atau tetap jelas belum dilakukan dengan blocker terdokumentasi.

## W10 — CI/CD and production release automation

- local/`feature/*` development menggunakan Supabase lokal;
- pull request ke `main` menjalankan full CI, rebuild/test canonical migrations, dan Cloudflare dry run tanpa production secret;
- protected `main` menjadi satu-satunya production source;
- GitHub Environment approval atau fallback `workflow_dispatch` menjadi release gate;
- production deploy berurutan migration → Functions → Worker → synthetic smoke;
- GitHub Actions menggantikan deployment rutin melalui GPT/MCP;
- baseline tidak membuat hosted staging, branch `develop`, atau automatic PR Worker yang memakai Supabase production.

Exit: workflow production fail-closed, terserialisasi, menjaga secret, memiliki evidence/rollback runbook, dan telah menjalankan satu release yang diotorisasi; atau tetap incomplete dengan external blocker yang tepat.

## Safe repository split checkpoint

Pindahkan `MSCWEB` ke repository sendiri pada W09 setelah W08 menghasilkan production candidate, hanya bila semua kondisi ini benar:

- Expo project dapat install, lint, typecheck, test, export, dan serve sendiri dari folder `MSCWEB`;
- tidak mengimpor source Swift atau path runtime dari parent;
- App Icon dan shared visual assets sudah disalin dengan provenance/license note;
- specs/ADRs ikut terbawa;
- environment examples tidak memuat secret;
- CI commands dan lockfile berada di folder;
- seluruh root `supabase/`—migration history, Functions/shared modules, tests, config, dan runbook—masuk transfer inventory tanpa squash, rebaseline, renumber, atau selective copy;
- test/script yang masih memakai `../supabase/` atau parent-only path sudah memakai path root repository standalone;
- repository iOS ditetapkan sebagai arsip dan tidak memiliki pipeline/credential deployment web atau backend aktif;
- moving-folder dry run menunjukkan tidak ada broken relative path.

Pilihan yang direkomendasikan setelah split:

- repository MSCWEB memiliki source frontend, tests, specs, Cloudflare config, dan satu root `supabase/` yang memuat seluruh canonical deployment history;
- hanya repository MSCWEB yang dapat deploy Cloudflare dan Supabase setelah cutover;
- salinan sementara pada repository lama hanya menjadi safety backup non-deployable selama validation/rollback window;
- repository iOS tetap utuh sebagai arsip sampai owner memberi izin destruktif terpisah untuk menghapus salinan lama.

## Spec-driven workflow per slice

1. Pilih requirement IDs.
2. Tulis/update acceptance scenario terlebih dahulu.
3. Tetapkan data contract/RLS dan visual reference.
4. Implement domain/use case/repository/UI.
5. Jalankan unit → database → component → E2E → visual.
6. Catat divergence; buat ADR jika architectural.
7. Demo terhadap iOS reference dan acceptance result.

## Blockers yang harus diputuskan sebelum production

- domain/subdomain final;
- rekening dan QRIS production, owner, serta rotasi config;
- SLA review pembayaran dan notification channel;
- expiry, resubmission, dispute/refund, reconciliation SOP;
- retention/deletion policy untuk bukti program dan pembayaran;
- payment-proof retention/orphan-cleanup schedule dan responsible operator;
- private/opaque Coach public-media delivery serta cache invalidation/rollback runbook;
- daftar Admin/reviewer production dan least-privilege process;
- privacy policy/terms/support contact;
- exact Supabase hosted project authorization dan Google OAuth credentials;
- monitoring/analytics vendor dan consent basis.
