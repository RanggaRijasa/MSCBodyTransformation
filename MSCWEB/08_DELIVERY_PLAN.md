# 08 — Delivery plan and checkpoints

Dokumen ini adalah delivery overview. Workplan eksekusi rinci, checklist, sub-agent plan, exit criteria, dan permission matrix berada di [`workplans/`](./workplans/README.md). Penamaan `W00–W09` digunakan untuk membedakan fase MSCWEB dari fase native iOS pada repository induk.

## Prinsip delivery

- Kerjakan vertical slice kecil end-to-end.
- Supabase local adalah development authority; hosted main tidak disentuh tanpa izin production eksplisit.
- iOS tidak diubah untuk membuat web lebih mudah.
- Setiap phase berakhir dengan build/test/demo evidence dan spec delta.
- Repository tetap menyatu sampai checkpoint pemisahan aman.

## Phase 0 — feasibility spikes

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

## Phase 1 — foundation and design system

- dependency container dan domain/repository boundaries;
- theme/tokens/light/dark;
- MSCIcon registry;
- shared controls/state components;
- public landing, legal shells, manifest, service worker baseline;
- responsive Guest/Participant app shell;
- testing/visual baseline infrastructure.

Exit: landing dan empty app shell berjalan pada compact/wide, installable locally, accessibility smoke lulus.

## Phase 2 — Auth and public Participant shell

- Google Auth local;
- callback/preserved intent/session/logout cache clearing;
- public program/read model;
- Guest Home, program catalog/detail, leaderboard/pemenang/Coach public states;
- centralized authentication gate.

Exit: Guest tidak pernah menerima private data; auth/deep link journeys lulus.

## Phase 3 — Participant program parity

- enrolled/available/history;
- program activity/day accordion/locks;
- article/video/form/quiz/weight step renderer;
- evidence picker/camera/upload/status;
- home focus/progress/points.

Exit: Participant dapat menjalankan full program flow terhadap Supabase local; scoring/review authority tetap server-side.

## Phase 4 — enrollment and manual payment

- scan QR Coach;
- free enrollment operation;
- manual payment destination/request/proof schema dan RLS;
- rekening/QRIS/upload/status UI;
- Participant payment Admin queue/review;
- atomic approval to entitlement/enrollment.

Exit: journeys `QA-JRN-001` sampai `004` dan payment negative/concurrency suite lulus.

## Phase 5 — Coach parity

- Coach application/eligibility/pricing/payment;
- activation Admin operation;
- Coach dashboard/QR/participants/activity/review queue;
- evidence review approval/rejection;
- Coach program/leaderboard/profile.

Exit: Coach access hanya aktif melalui authority path dan cross-Coach RLS tests lulus.

## Phase 6 — Admin parity

- Dashboard/metrics/attention;
- Program CRUD/publish/preview;
- People Peserta/Coach/Admin;
- Content management;
- score corrections/winner lock/fallback operations;
- Settings dan complete audit surfaces.

Exit: semua Admin iPhone capabilities memiliki parity evidence atau accepted deferral.

## Phase 7 — PWA hardening

- offline/cache/update behavior;
- install guidance;
- security headers/CSP;
- performance/code splitting/image budgets;
- full browser/device/accessibility pass;
- observability redaction;
- production runbooks dan policy blockers.

Exit: release gates pada QA spec lulus; production deploy masih memerlukan izin eksplisit.

## Safe repository split checkpoint

Pindahkan `MSCWEB` ke repository sendiri setelah Phase 1, hanya bila semua kondisi ini benar:

- Expo project dapat install, lint, typecheck, test, export, dan serve sendiri dari folder `MSCWEB`;
- tidak mengimpor source Swift atau path runtime dari parent;
- App Icon dan shared visual assets sudah disalin dengan provenance/license note;
- specs/ADRs ikut terbawa;
- environment examples tidak memuat secret;
- CI commands dan lockfile berada di folder;
- kebutuhan shared Supabase migration ownership sudah diputuskan;
- parent iOS tetap build tanpa dependency ke `MSCWEB`;
- moving-folder dry run menunjukkan tidak ada broken relative path.

Pilihan yang direkomendasikan setelah split:

- repository web memiliki source frontend, tests, specs, dan Cloudflare config;
- satu repository harus menjadi authority migration Supabase. Selama transisi, authority tetap repo induk; jangan menduplikasi migration history di dua repo yang dapat deploy;
- kontrak backend bersama dipublikasikan sebagai versioned schema/types/artifact, bukan symlink filesystem.

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
- daftar Admin/reviewer production dan least-privilege process;
- privacy policy/terms/support contact;
- exact Supabase hosted project authorization dan Google OAuth credentials;
- monitoring/analytics vendor dan consent basis.
