# MSCWEB W08 — PWA, Cloudflare, and production hardening

Status: `Complete — all W08 launch gates verified on production`
Autonomy: `A` local, `B` physical-device checks, `D` external preview/production changes  
Depends on: W01–W07 plus W06.5 and completed W07.4 onboarding remediation. W07.5 Sales Overview and W07.6 Admin Image Storage are explicitly deferred post-launch by ADR-0010.

## Objective

Harden MSCWEB as an installable, secure, accessible, performant PWA; prepare Cloudflare deployment configuration and runbooks without mutating production unless separately authorized.

## Required references

- `06_PWA_HOSTING.md`
- `07_TESTING_ACCEPTANCE.md`, including `QA-MED-LCH-*`
- `03_DESIGN_SYSTEM.md` app icon/accessibility/motion
- `05_DATA_SECURITY.md`
- current official Expo/Cloudflare/Supabase browser guidance

## Deliverables

- final manifest/icons/install guidance;
- service-worker cache/update/offline behavior;
- Cloudflare Workers Static Assets config and SPA routing;
- canonical/Open Graph/social-preview delivery for `/c/:handle` without leaking hidden profile data;
- minimum media launch safety: private buckets/RLS, automatic payment-proof retention/orphan cleanup, and opaque controlled public Coach-media delivery;
- CSP/security headers and permissions policy;
- code splitting/image/bundle performance compliance;
- browser/device/accessibility matrix evidence;
- privacy-redacted observability interface;
- deployment, rollback, cache, incident, and secret runbooks.

## Checklist

### PWA/install/offline

- [x] Manifest name/scope/start/theme/icons validated.
- [x] Maskable safe zone and Apple touch rendering checked.
- [x] Browser remains fully usable without installation.
- [x] iOS Add to Home Screen guidance and supported install affordance.
- [x] Public shell/assets only in precache; private API/media never precached.
- [x] Private API/media responses never enter service-worker/shared caches; deferred Sales/Image Storage routes are absent from the launch build/navigation.
- [x] Offline state is truthful and server mutations are disabled, not queued silently.
- [x] Safe service-worker update/reload behavior and account-cache cleanup.

### Cloudflare configuration

- [x] Workers Static Assets directory and SPA `not_found_handling` verified locally/dry run.
- [x] Hashed asset vs HTML/manifest/service-worker cache policies.
- [x] Canonical/404/robots/preview noindex behavior.
- [x] `/c/:handle` refresh and share crawler resolve the correct published Coach; unpublished/expired/unknown handles return safe not-found metadata.
- [x] Per-handle title/description/image use only the public profile read model; published phone/WhatsApp may render only in profile body, while every hidden contact, raw QR, auth ID, private media, phone, and WhatsApp stay out of Open Graph/SEO metadata.
- [x] Canonical URL strips tracking query parameters while ordinary browser navigation may retain them for attribution handling.
- [x] Cache invalidation covers profile publish/edit/moderation/entitlement expiry without caching a private draft as public.
- [x] Environment validation and no secret/service-role in output.
- [x] CSP report-only test, then local/preview enforcement plan.
- [x] With separate external authorization, deploy an isolated noindex preview and validate report-only CSP against real Cloudflare routing, Supabase Auth/Storage/Realtime endpoints, OAuth redirect, media, and service worker.
- [x] Enforce candidate CSP on preview and show no unexpected violations before W08 exit, or obtain an explicit documented production-blocking waiver.
- [x] `nosniff`, Referrer, frame-ancestors, Permissions-Policy, and HSTS rollout plan.

### Minimum media launch safety

- [x] Verify `question-photos` and `payment-evidence` remain private with least-privilege RLS/operations; browser output contains no service-role key, raw object path, or reusable private URL.
- [x] Verify production-shaped automatic payment-proof retention and orphan cleanup are idempotent, preserve payment/ledger/audit metadata, protect under-review/correction/dispute evidence, and have an approved schedule/operator before rollout.
- [x] Make `coach-public-media` private and migrate public profile projections to opaque media IDs; public delivery uses a controlled server gateway that validates current published reference and active Coach/media state.
- [x] Draft, hidden, pending/rejected moderation, superseded, unpublished, or entitlement-revoked Coach media fail closed; known legacy direct Storage URLs are not a fallback.
- [x] Define and verify versioned/no-store cache behavior plus invalidation for profile edit, unpublish, moderation decision, entitlement expiry/revocation, avatar replacement, and media detachment.
- [x] Verify account/provisional cleanup cannot leave public or private orphan media and does not expose object paths in audit/log/error payloads.
- [x] Do not implement `/admin/image-storage`, usage inventory, Trash, restore, manual purge, registry/backfill, or Admin deletion worker in W08.

### Performance/accessibility/devices

- [x] Route-level chunking keeps Admin/Coach out of public landing initial bundle.
- [x] AI provider code/key remains server-only and is absent from public/Coach/Admin route chunks.
- [x] Image thumbnail/lazy/full-resolution authorization behavior.
- [x] Detached/unpublished/superseded/revoked public Coach media is no longer served after the documented CDN/browser invalidation window; stale direct URLs fail safely.
- [x] Lighthouse/Web Vitals/bundle budgets.
- [x] Safari iOS current/previous, installed iOS PWA, Chrome Android, desktop Chrome/Safari/Edge.
- [x] Camera QR, picker, safe area, virtual keyboard, browser Back, rotation, and standalone external links.
- [x] Keyboard/screen reader/200% zoom/reduced motion/transparency/increased contrast.

### Observability/runbooks

- [x] Redacted event/error contract and correlation IDs; no sensitive payload.
- [x] Deployment/rollback/cache purge/environment/secret rotation/incident checklist.
- [x] Production blockers matrix updated with accountable owner.

## Sub-agent plan

- `msc_explorer`: current platform docs and browser limitation audit; read-only.
- `msc_implementer`: sole writer for service worker/config/header/performance fixes sequentially.
- `msc_reviewer`: security headers/cache privacy/secret scan/performance/accessibility/device evidence.

Do not let sub-agents deploy, change DNS, configure credentials, or accept budget waivers.

## Verification

- production export and Cloudflare-compatible local serve;
- manifest/installability/icon audit;
- offline/private-cache/account-switch suite;
- private-media cache isolation, payment-proof cleanup, and public Coach-media authorization/invalidation suite;
- CSP and security-header checks;
- Lighthouse/Web Vitals/bundle analyzer;
- full Playwright matrix plus physical-device manual record;
- social crawler/canonical/cache tests for minimum/full/unpublished/expired Coach profiles;
- dependency and secret scans.

## Exit criteria

- Local production candidate passes release gates or has explicit accepted waivers.
- An authorized preview has validated real routing/OAuth/Supabase endpoints under enforced candidate CSP, or an explicit waiver records the unverified production risk and blocks rollout until resolved.
- Private data is absent from service worker/shared caches and logs.
- Minimum media launch safety passes without claiming the deferred Admin Image Storage feature is implemented.
- Physical-device critical flows are recorded.
- Cloudflare config/runbooks are ready but no external mutation is implied.

## User input or authorization

- Physical devices or assistance for device-only checks.
- Monitoring vendor/consent decision if observability will leave the app.
- Cloudflare preview deploy is a required external authorization for the CSP/real-routing gate unless the user explicitly records a waiver. Domain/DNS, secrets, and production deploy each require separate authorization.

## Progress log

Append platform/version, device/browser evidence, budgets, cache/security results, external authorizations, files/commands, and next item.

### 21 Agustus 2026 — Slice 1: Cloudflare preview foundation

- Requirement IDs: `PWA-HST-001`, `PWA-HST-003…005`, `PWA-MAN-001…005`, `PWA-OFF-001/002/004`, `PWA-INS-003/004`, `PWA-SEC-001`, dan routing/cache portion dari W08 Cloudflare checklist.
- Authorization: owner explicitly authorized a pinned Wrangler install, Colima/local Supabase startup, Worker plus `workers.dev` subdomain creation, and a noindex preview deployment. Custom-domain DNS, hosted Supabase, production secrets, and production deployment remained out of scope and were not changed.
- Files changed: `package.json`, `package-lock.json`, `.gitignore`, `tsconfig.json`, `wrangler.jsonc`, generated `worker-configuration.d.ts`, `worker/index.ts`, `public/index.html`, `public/landing.html`, `public/register-sw.js`, `public/robots.txt`, `public/sw.js`, `tests/unit/worker-routing.test.ts`, `tests/unit/pwa-strategy.test.ts`, and this workplan.
- Cloudflare: Wrangler `4.125.0` is exact-pinned. `msc-body-transformation-web-preview` was deployed only through `--env preview` to `https://msc-body-transformation-web-preview.msc-body-transformation-web.workers.dev` with `workers_dev=true`, additional Preview URLs disabled, no route/custom domain, and only `ASSETS` plus non-secret `DEPLOYMENT_ENVIRONMENT=preview` bindings. Final verified Cloudflare version: `da229a5e-0043-4e58-835f-cac7ec637728`.
- Routing/cache/security evidence: live landing and `/app/profile` return `200`; unknown navigation returns `404`; `/robots.txt` returns `Disallow: /`; HTML, manifest, service worker, errors, and extensionless static pages use `no-store`; hashed assets use `public, max-age=31536000, immutable`. Live responses include `X-Robots-Tag: noindex, nofollow, noarchive`, CSP report-only without `unsafe-eval`, `nosniff`, `DENY` framing, strict-origin referrer policy, and restrictive permissions policy.
- Browser evidence: Codex in-app Browser loaded the live landing at its desktop viewport with meaningful semantic content and zero console warnings/errors. Interaction `Unduh aplikasi` initially exposed an extensionless static-route 404; the Worker mapping and tests were fixed, redeployed, and the same action then rendered `Cara memasang aplikasi` with zero console warnings/errors. A `390 × 844` viewport rendered the landing with `scrollWidth = innerWidth = 390` and no console warnings/errors. No iOS source or app UI was changed in this infrastructure slice.
- Local services: Docker responded through the existing local runtime; `supabase status` succeeded and local GoTrue health returned version `v2.195.0`. Colima CLI state reporting was inconsistent with the responding Docker daemon, so no shutdown/restart was forced. Supabase and Colima were left running as required.
- Commands passed: `npm run worker:types`, `npm run worker:types:check`, `npm run typecheck`, `npm run lint`, focused Vitest Worker/PWA/environment suites (`16` then `8` regression assertions), `npm test` (`149 passed`, `8 skipped` local-condition tests), `npm run build`, `npm run worker:dry-run`, `npm run verify:bundle` (`50` JavaScript files), `npm run verify:pwa`, local `wrangler dev --env preview`, live `curl` routing/header checks, and browser render/interaction checks.
- Dependency audit: `npm audit --omit=dev` still reports `15` transitive Expo-toolchain advisories (`7 moderate`, `8 high`) through `image-size` and `uuid`. The offered force remediation would downgrade Expo to `53.0.27`, so it was not applied.
- Assumption/blocker: the authorized backend remains local-only. The public preview therefore validates real Cloudflare routing, headers, cache, service-worker registration, install guidance, and static rendering, but it does not claim live Supabase Auth/Storage/Realtime, OAuth callback, private media, or enforced-CSP acceptance from the preview origin. Those checkboxes remain open; no hosted Supabase endpoint or secret was introduced.
- Next unchecked item: fresh maskable safe-zone and Apple touch rendering verification, followed by the remaining offline/update/account-cache gates.

### 21 Agustus 2026 — Production authorization preflight; rollout held before mutation

- Owner authorization received: deploy reviewed Supabase production migrations/functions, install owner-provided production secrets, deploy the production Worker, connect `msc-body-transformation.com`, create required DNS, redirect `www` to apex, and run synthetic production smoke with cleanup; no real transfer or real-user data is allowed.
- Production mutation result: none. Preflight stopped the rollout before migration, function, secret, Worker, custom-domain, DNS, or smoke mutation because mandatory W08/W09 release gates are not yet satisfied.
- Hosted target evidence: linked project ref matches the documented hosted `main`; the project is `ACTIVE_HEALTHY`, PostgreSQL `17.6.1.155`, region `ap-southeast-1`; all `20` root migrations match remote and root `supabase db push --linked --dry-run` has no pending migration.
- Migration-authority blocker: the `10` MSCWEB migrations are maintained outside root `supabase/migrations`, so the canonical linked `db push` does not see them. The W09 decision for one authoritative migration home is still open. Applying them directly would bypass reviewed migration history and is not allowed by the current runbook.
- Minimum-media blockers: `20260813051840_w06_coach_experience.sql` still creates `coach-public-media` with `public = true`; no opaque media-ID gateway/cutover migration exists; the documented 30-day payment-proof retention path explicitly says implementation is still required. These contradict `SEC-STO-013/014` and the unchecked W08 minimum-media launch gates.
- Frontend/security blockers: production Worker environment/routes do not yet exist; the current build loads local `.env.local`; CSP remains report-only and permits local/wildcard Supabase endpoints; preview has not passed production-shaped Auth/Storage/Realtime/OAuth/media under enforced CSP; canonical social metadata/cache invalidation for `/c/:handle` remains unimplemented.
- Product/legal blockers: `public/kebijakan-privasi.html` and `public/ketentuan.html` explicitly identify themselves as development shells and say final production text/contact/retention/dispute details are unapproved. Publishing them on the apex would violate the W09 legal/privacy/support gate.
- Secret readiness: hosted secret-name inventory does not include `PAYMENT_CLEANUP_JOB_SECRET`, `PROVISIONAL_CLEANUP_JOB_SECRET`, `FOOD_AI_WORKER_SECRET`, or the real AI provider configuration. The workspace only exposes a Google provider secret name plus local public Expo configuration; no owner-supplied production web/worker secret file is available. No value was printed or copied.
- Domain evidence: `msc-body-transformation.com` is delegated to Cloudflare nameservers, while apex and `www` currently have no public address/CNAME response. No DNS record was created because the production Worker candidate is not safe to expose yet.
- Smoke blocker: there is no approved exact synthetic identity/role/operation inventory or MSCWEB production cleanup script proving zero residual Auth/profile/enrollment/payment/media rows. The broad smoke authorization is recorded, but the W09 exact-scope and cleanup evidence remains absent.
- Required next action: complete and review the W08 minimum-media migration/functions, move the reviewed web migration chain into the single canonical deployment authority, provide approved final legal/support copy and production secret source, then pass an enforced production-shaped preview before retrying production rollout.

### 21 Agustus 2026 — Root authority integration dan W08 launch-safety candidate

- Authorization: owner menetapkan repository-root `supabase/` sebagai satu-satunya
  deployment authority, mengizinkan integrasi migration/function MSCWEB, file
  production lokal ignored, generated job secrets, draft legal, dan synthetic
  smoke `@example.invalid`. Google OAuth production smoke dipilih `DEFERRED`
  sampai akun Gmail test khusus ditetapkan.
- Authority: sepuluh migration W05–W07.4 dan tiga Edge Function web dipindahkan
  ke root. Script rantai migration kedua dihapus; dry-run hosted sekarang melihat
  tepat 14 migration root pending W05–W08. Tidak ada hosted migration, Function,
  secret, Auth, Storage, DNS, route, Worker production, atau smoke mutation.
- Media safety: `coach-public-media` sekarang private; public profile hanya
  memproyeksikan opaque asset UUID. `public-coach-media` me-resolve UUID melalui
  service-only RPC, memeriksa profile published/public, approval, entitlement,
  dan current avatar/approved item reference, lalu mengirim image `no-store`.
  Coach/Admin preview memakai signed URL 60 detik. Direct Storage URL dan asset
  setelah entitlement expiry gagal tertutup.
- Payment retention: kandidat final berumur 30 hari mengecualikan
  `under_review`, `correction_required`, dan `reversal_pending`. Worker dry-run
  tetap default; mode delete memakai claim `deleting`, release saat Storage gagal,
  stale-claim recovery 15 menit, final status `deleted`, dan event/audit aggregate
  tanpa object path. Metadata order/ledger/audit tidak dihapus.
- Functions/secrets: job auth memakai digest comparison; seluruh Edge Function
  berhasil dibundle dan diserve pada Supabase lokal. Dua file production-local
  mode `0600` terkonfirmasi ignored. Tiga job secret 64-hex dibuat tanpa dicetak;
  `FOOD_AI_API_KEY` sengaja kosong. Candidate model config adalah
  `openrouter/free` dan tetap memerlukan owner/legal review sebelum aktivasi AI.
- Build/Worker: production export mematikan Expo dotenv auto-load dan hanya
  menerima tiga public key dari `.env.production.local`; verifier membuktikan
  development URL/key dan job/provider secret tidak masuk bundle. Production CSP
  enforced memakai exact hosted Supabase HTTPS/WSS origin; preview tetap
  report-only/noindex dan secara eksplisit memiliki `routes: []`. Top-level
  Worker candidate menyiapkan apex custom domain serta redirect `www` → apex,
  tetapi belum dideploy.
- Review artifacts: `legal/WEB_LEGAL_DRAFT.md` berisi adaptasi Google Auth,
  Supabase, manual payment, OpenRouter, dan retensi 30 hari dengan placeholder
  owner/support; `production/SYNTHETIC_SMOKE_AND_CLEANUP_MANIFEST.md` membatasi
  data/operasi/cleanup dan melarang transfer nyata serta data pengguna nyata.
- Commands passed: root `supabase migration up --local`; `supabase db lint
  --local --level warning`; local migration history through four W08 files;
  hosted `supabase db push --linked --dry-run`; local Edge Function serve and
  HTTP checks (`404` unknown asset, `401` unauthorized jobs, `200` payment cleanup
  dry-run); focused integration tests for Coach media and payment retention;
  `npm run typecheck`; `npm run lint`; `npm test` (`155 passed`, `8 skipped`);
  production `npm run build`; `verify:production-env`; `verify:bundle` (`50`
  JavaScript files); `verify:pwa`; Worker types/check; preview and production
  Wrangler dry-runs. Final focused W08 tests: `35` plus `11` assertions passed.
- Remaining blockers: owner/legal must fill and approve operator/support,
  refund/dispute/SLA/yurisdiction/AI terms; `FOOD_AI_API_KEY` must be filled
  locally; production AI model/router must be accepted; exact cleanup procedure
  and non-billable smoke fixture require review; live production-shaped preview
  must pass enforced CSP/Auth/Storage/media; social crawler metadata/cache,
  offline/account cache, device/accessibility, observability, rollback, cron
  activation, and production destination configuration remain open.
- Next unchecked item: review/finalize the legal and synthetic-smoke drafts, then
  deploy an enforced production-shaped noindex preview before any production
  mutation.

### 21 Agustus 2026 — Production rollout dan synthetic cleanup selesai

- Authorization: owner menyetujui root `supabase/` sebagai satu-satunya deployment
  authority, migration/Function/secrets production, Worker production, apex dan
  `www`, DNS, legal final, `openrouter/free`, synthetic `@example.invalid`, serta
  fixture non-billable. Google OAuth smoke tetap `DEFERRED`; tidak ada transfer,
  data pengguna nyata, payment verification, atau production enforcement ZDR.
- Files changed in this slice: `worker/index.ts`, `wrangler.jsonc`, `.gitignore`,
  `scripts/run-production-synthetic-smoke.mjs`, legal/public pages,
  `tests/unit/worker-routing.test.ts`, `tests/unit/w08-launch-safety-contract.test.ts`,
  root Supabase migrations/Functions, dan workplan ini. File production-local dan
  manifest smoke tetap ignored serta mode `0600`.
- Supabase production: backup schema-only dibuat sebelum mutation; migration root
  sinkron sampai `20260821002617`; empat Edge Functions W08 serta tiga Function
  web sebelumnya berstatus `ACTIVE`; tujuh secret Function dan tiga secret Vault
  job dipasang tanpa mencetak nilainya. Final `supabase db push --linked --dry-run`
  melaporkan `upToDate=true`.
- Cron production: `w08-food-insight-worker` dan
  `w08-provisional-cancellation-cleanup` aktif dan respons HTTP terakhir `200`;
  cleanup payment aktif pada jadwal harian dalam mode `dryRun:true`, dan invocation
  manual dry-run mengembalikan nol kandidat/kegagalan/penghapusan. Job lama
  `phase13-apple-commerce-reconciliation` teramati menghasilkan HTTP `500` pada
  menit 22/37 dan dicatat sebagai blocker terpisah di luar mutation W08.
- Cloudflare: candidate noindex final version
  `ae543b31-9243-49db-9c9e-82c24486c70e`; production Worker version
  `58f9bc22-84e7-444e-bf94-c590d85f556c` aktif pada
  `msc-body-transformation.com` dan `www.msc-body-transformation.com`. Apex, deep
  link, legal, robots production, CSP, cache, synthetic unknown `404`, TLS, dan
  redirect `www` `308` lulus. Resolver lokal sempat menyimpan negative DNS cache
  untuk `www`; DNS publik sudah mengembalikan Cloudflare A records dan TLS/redirect
  diverifikasi melalui alamat tersebut.
- Social metadata: `/c/:handle` mengambil read model publik server-side, hanya
  me-render nama/headline/biografi/area dan opaque media UUID, membuang tracking
  query dari canonical, menggunakan `no-store`, serta tidak memasukkan phone,
  WhatsApp, auth ID, raw path, atau private draft. Candidate unknown handle
  mengembalikan `404`; production synthetic profile dan gateway/invalidation
  lulus.
- Synthetic smoke final: run
  `w08-prod-smoke-20260821-010116759-37fe08d0` berstatus `PASS`. Dua identity
  `@example.invalid`, Coach asset, program `NON-BILLABLE`, enrollment, order tanpa
  transfer/approval, dan JPEG 1×1 tanpa metadata dibuat sementara. Opaque gateway,
  direct private Storage denial, publication invalidation, social metadata,
  signed payment-evidence URL, dan private bucket lulus. Cleanup seluruh object,
  application/entitlement, program/enrollment/payment, profile, dan Auth identity
  lulus; residual public/private/Auth semuanya `0`. File API-key reveal temporary
  dan bootstrap config telah dihapus.
- Browser evidence: candidate dan production `/app/profile` merender shell Tamu
  Bahasa Indonesia tanpa horizontal overflow atau console warning/error. OAuth
  tidak dipicu. Email/password production juga tidak diaktifkan hanya demi smoke;
  hasilnya dicatat `DEFERRED_PROVIDER_DISABLED`.
- Verification passed: `npm test` (`161` passed, `8` skipped), `npm run typecheck`,
  `npm run lint`, `npm run worker:types:check`, `npm run verify:bundle` (`50`
  JavaScript files), `npm run verify:pwa`, production build/deploy, Supabase
  migration dry-run, production Function authorization checks, cron/pg_net
  metadata, database/security/performance advisors, curl routing/header checks,
  dan in-app Browser QA.
- Remaining blockers: physical-device/install/offline/account-cache/accessibility
  matrix, Lighthouse/Web Vitals, HSTS/observability/incident-runbook completion,
  dan diagnosis job Apple commerce lama yang menghasilkan `500`.
- Next unchecked item: maskable safe-zone dan Apple touch rendering verification,
  lalu offline/update/account-cache gates.

### 21 Agustus 2026 — Hosted Google callback dan login branding diperbaiki

- Evidence: Android Chrome dan iOS Safari milik owner kembali ke
  `localhost:3000` setelah pemilihan akun Google. Hosted Auth config terbukti
  masih memakai Site URL `http://localhost:3000` dan hanya mengizinkan deep link
  iOS, meskipun bundle production sudah meminta callback apex.
- Hosted Auth fix: Site URL diubah menjadi `https://msc-body-transformation.com`;
  allow-list sekarang memuat callback apex exact dan tetap mempertahankan
  `mscbodytransformation://auth/callback`. Google provider tetap aktif. OAuth
  initiation sesudah perubahan mempertahankan callback apex beserta return intent
  internal dan mengarah ke `accounts.google.com` melalui callback Supabase hosted.
- UI fix: `src/app/login.tsx` sekarang memakai `/icons/icon-192.png`, bukan kotak
  teks `MSC`. Tombol merah custom diganti dengan aset Android + Web light-pill
  resmi dan tidak dimodifikasi dari paket branding Google, dibungkus touch target
  aksesibel tanpa mengubah alur Supabase PKCE.
- Deploy: candidate version `88f88912-2f60-4f2e-a666-65c0ff8146b3` dan production
  version `454f41eb-452d-4778-b056-3d9f6253f12a`.
- Browser QA: candidate dan production pada mobile `390 × 844` serta desktop
  menampilkan ikon/tombol baru, tidak overflow, tidak memiliki framework overlay
  atau console warning/error; interaction `/app/profile` → login dan production
  login → `accounts.google.com` lulus tanpa memilih akun.
- Verification: `npm test` (`161` passed, `8` skipped), `npm run typecheck`,
  `npm run lint`, `verify:production-env`, `verify:bundle`, dan `verify:pwa`
  lulus. `BOOTSTRAP_ADMIN_EMAIL` hadir pada file ignored tanpa dicetak. Identity
  exact sudah ada sebagai `participant/provisional`; belum dipromosikan karena
  role Admin memerlukan authorization production eksplisit setelah login sukses.
- Next action: owner mengulang login Google production. Setelah callback sukses,
  owner dapat mengizinkan bootstrap Admin exact; jangan membuat Admin dari
  self-registration atau metadata Google.

### 21 Agustus 2026 — Bootstrap Admin selesai; Coach menunggu identity

- Authorization: owner mengizinkan promosi exact `BOOTSTRAP_ADMIN_EMAIL` dan
  bootstrap satu kali exact `BOOTSTRAP_COACH_EMAIL` sebagai Coach aktif tanpa
  pembayaran nyata, dengan entitlement tiga bulan dan audit.
- Preflight production: kedua variabel lokal terisi dan file tetap ignored.
  Admin cocok tepat satu Auth identity/profile `participant/provisional`. Coach
  belum memiliki Auth identity maupun profile production, sehingga tidak dibuat
  secara artifisial dan tidak ada mutasi Coach yang dijalankan.
- Admin production: profile exact diubah server-side menjadi `admin/active`;
  provisional expiry dibersihkan, finalization dan onboarding version diperbarui,
  serta satu audit `production_admin_bootstrap` ditulis tanpa email di payload.
- Verification query: role `admin`, onboarding `active`, dan tepat satu audit
  bootstrap. Percobaan SQL pertama gagal sebelum mutasi karena aggregate UUID
  yang tidak didukung; transaksi terkoreksi kemudian berhasil dan diverifikasi.
- Remaining action: owner login Google sekali menggunakan akun
  `BOOTSTRAP_COACH_EMAIL`, mengisi profil serta menyatakan level/HOM STS/ICT dan
  ketentuan Coach sampai layar pembayaran. Setelah itu operator dapat menerbitkan
  waiver tanpa transfer/ledger verified, QR acak, status publik/approved, audit,
  dan entitlement tiga bulan secara atomik.

### 21 Agustus 2026 — Bootstrap Coach pertama selesai

- Evidence owner: akun exact `BOOTSTRAP_COACH_EMAIL` login dengan Google,
  melengkapi profil Coach, memilih level yang memenuhi syarat, dan menyatakan HOM
  STS, ICT, serta ketentuan Coach. UI berhenti dengan pesan generik setelah tombol
  `Lanjut ke pembayaran Coach`.
- Diagnosis production: handoff, application draft, dan submission seluruhnya
  berhasil. Profile berada pada `coach_handoff_pending`, application `submitted`,
  dan belum ada order. Kegagalan terakhir adalah
  `payment_destination_unavailable` karena tidak ada tujuan pembayaran aktif.
- Waiver bootstrap: tujuan pembayaran tidak dibuat dan flow transfer tidak
  dipalsukan. Transaksi server-side mengaktifkan application/profile Coach,
  menerbitkan QR acak dan entitlement tiga bulan, serta memakai payment record
  referensial `not_started` tanpa provider reference, verification timestamp,
  commerce transaction, payment order, atau ledger.
- Audit dan verifikasi: satu `production_first_coach_bootstrap` dicatat oleh Admin
  tanpa email; profile `coach/active`, approved dan public; QR cocok pola opaque
  dan diterima oleh lookup onboarding Peserta; entitlement aktif; payment order
  `0`; ledger `0`; audit tidak memuat email.
- Browser QA production: landing dan shell aplikasi merender tanpa warning/error;
  navigasi landing → aplikasi berhasil; Coach baru tampil pada direktori publik
  dan profil publiknya dapat dibuka tanpa framework overlay.
- Owner next action: reload atau logout/login ulang pada akun Coach, lalu buka
  dashboard Coach dan halaman QR. Peserta pertama dapat memindai QR tersebut.

### 21 Agustus 2026 — RPC dashboard dan profil Coach production diperbaiki

- Evidence owner: shell mengenali akun sebagai Coach, tetapi `/coach` menampilkan
  `Akses Coach tidak aktif` dan aggregate dashboard tidak muncul.
- Root cause: `get_my_coach_workspace()` dan
  `get_my_coach_public_profile_draft()` merujuk
  `profiles.profile_avatar_path`, sedangkan kolom tersebut tidak pernah menjadi
  bagian schema authority production. RPC gagal dengan PostgreSQL `42703`
  sebelum payload dibentuk; entitlement bootstrap bukan penyebabnya.
- Repair: migration root
  `20260821022337_w08_coach_workspace_profile_avatar_fix.sql` mengganti kedua
  projection dan mempertahankan field kompatibilitas sebagai JSON `null`. Tidak
  ditambahkan kolom raw private-media path baru ke tabel yang terekspos.
- Production deployment: dry-run hanya memuat migration repair tersebut; push
  berhasil; final linked dry-run `upToDate=true`.
- Exact-account verification: kedua RPC berhasil di bawah konteks Auth Coach;
  workspace, profile draft, participants/programs/leaderboard arrays, dan QR
  payload memiliki shape valid; field private path bernilai null. Tidak ada nama,
  avatar, QR mentah, atau data Peserta yang dicetak dalam bukti verifikasi.
- Verification commands: focused W08 unit `8 passed`, `npm run typecheck`,
  `npm run lint`, full `npm test` (`162 passed`, `8 skipped`), local migration
  apply, local `supabase db lint --level warning` tanpa schema error, production
  security advisor tanpa error (warning authority yang sudah dikenal tetap ada),
  dan final hosted function query lulus. Coach integration suite terdeteksi
  skipped karena fixture local-test tidak tersedia pada proses tersebut.
- Browser note: browser QA terisolasi tidak memiliki sesi Coach dan diarahkan ke
  Login; koneksi langsung ke tab Chrome owner tidak tersedia. Exact authenticated
  behavior dibuktikan melalui fungsi production dengan konteks Auth Coach. Owner
  dapat menekan `Coba lagi` atau reload pada tab yang sudah login.

### 21 Agustus 2026 — QR Coach dan pemindai iPhone diperbaiki

- Evidence owner: rekaman layar iPhone menunjukkan izin dan preview kamera
  berhasil, tetapi QR tetap berada di frame tanpa callback pemindaian.
- Root cause pertama: renderer Coach membalik polaritas matrix QR dengan
  menggambar nilai `0` sebagai modul hitam. Uji decoder langsung membuktikan
  output lama tidak valid, sedangkan polaritas nonzero-as-dark menghasilkan
  payload opaque yang tepat.
- Root cause kedua: fallback iOS WebKit memuat ZXing WASM dari CDN default,
  sementara CSP production hanya mengizinkan origin sendiri; error scanner dari
  adapter Expo tidak tampil ke pengguna.
- Repair: SVG dan PNG QR memakai helper polaritas bersama. Pemindai iOS WebKit
  memiliki loop fallback canvas, decoder ZXing self-hosted, dan deduplikasi
  callback. Build menyalin binary versi `3.1.1` hanya setelah SHA-256 cocok;
  Worker mengirim MIME/cache immutable dan CSP `wasm-unsafe-eval` tanpa
  JavaScript `unsafe-eval`.
- Files: `src/shared/qr/qr-matrix.ts`, `src/shared/qr/web-qr-decoder.ts`,
  `src/shared/qr/QRScanner.tsx`,
  `src/features/coach/CoachWorkspaceComponents.tsx`,
  `scripts/prepare-production-output.mjs`, `worker/index.ts`, focused unit tests,
  dan `06_PWA_HOSTING.md`.
- Verification: focused unit (`26` passed), full `npm test` (`165` passed,
  `8` skipped), `npm run typecheck`, `npm run lint`, production build,
  environment/bundle/PWA verification, Wrangler dry-run, dan browser QA kandidat
  serta production tanpa console error semuanya lulus.
- Production deployment: Worker version
  `b3629e2e-75ca-4258-b7ed-8ad61feb6187`. Custom domain mengembalikan WASM
  `application/wasm`, cache immutable, dan SHA-256
  `6a858c01e076bab3a1bd413e4f2cf5e5e45f819a0d9441d83c66993bc48ed38f`.
- Remaining device gate: owner menutup lalu membuka ulang PWA/Safari, membuka QR
  Coach yang dirender ulang, dan mengulang pemindaian pada iPhone fisik. Screenshot
  QR lama tidak digunakan karena tetap memuat gambar dengan polaritas terbalik.

### 21 Agustus 2026 — Infinite loading Peringkat diperbaiki

- Evidence owner dan browser: `/app/leaderboard` berhenti pada spinner `Memuat`
  tanpa error console. Reproduksi production guest menghasilkan state yang sama.
- Production diagnosis: database memiliki satu program berstatus `draft`, nol
  program dengan status publik, dan RPC `list_public_programs` mengembalikan nol
  row. Tidak ada data atau status program yang diubah.
- Root cause frontend: React Query mempertahankan `isPending=true` untuk query
  leaderboard yang dinonaktifkan karena tidak ada program terpilih. Komponen
  menghitung flag tersebut sebagai loading aktif sehingga empty state tidak pernah
  dirender.
- Repair: loading leaderboard kini hanya dihitung setelah program terpilih;
  loading program route dan prerequisite Coach tetap dipertahankan. Helper state
  bersama melindungi halaman Peserta dan Coach dari kasus tanpa program publik.
- Files: `src/features/leaderboard/LeaderboardExperience.tsx`,
  `src/features/leaderboard/leaderboard-state.ts`, dan
  `tests/unit/leaderboard-state.test.ts`.
- Verification: focused unit `17 passed`, full `npm test` `168 passed` dan
  `8 skipped`, `npm run typecheck`, `npm run lint`, candidate/production build dan
  Wrangler dry-run lulus. Candidate version
  `9a445418-c584-4d02-aa0d-ddfe5dd21331` dan production version
  `88117741-14d3-491d-9596-ca33b818f814`.
- Browser QA: kandidat dan production fresh navigation menampilkan
  `Belum ada konten` setelah request selesai, tanpa framework overlay atau
  warning/error console. Interaction Program → Peringkat kembali ke empty state.
  Tab production lama yang masih memegang runtime sebelumnya perlu refresh atau
  ditutup dan dibuka ulang.

### 21 Agustus 2026 — Date picker Admin desktop diperbaiki

- Evidence owner: input `Mulai`, `Selesai`, dan `Batas pendaftaran` pada
  `Jadwal dan peserta` membuka picker di mobile tetapi tidak merespons pada
  desktop Chrome.
- Root cause frontend: input native `date`/`datetime-local` dibuat transparan
  di atas pill format Indonesia dan hanya mengandalkan perilaku klik bawaan.
  Mobile membuka picker saat fokus, sedangkan desktop tidak konsisten membuka
  popup dari input transparan tersebut.
- Repair: klik input web sekarang memanggil `HTMLInputElement.showPicker()`
  secara eksplisit saat tersedia. Browser tanpa API tersebut atau yang menolak
  panggilan tetap memakai fallback native dan tidak menghasilkan error.
- Files: `src/features/admin/AdminProgramEditorFlow.tsx`,
  `src/features/admin/web-native-picker.ts`,
  `tests/unit/web-native-picker.test.ts`, dan focused assertion pada
  `tests/e2e/admin-experience.spec.ts`.
- Verification: focused unit `11 passed`; full `npm test` `171 passed` dan
  `8 skipped`; typecheck, lint, build, candidate/production dry-run, dan
  `git diff --check` lulus. Harness browser desktop dengan CSS overlay yang sama
  berubah dari `Belum dibuka` menjadi `Picker desktop berhasil diminta` setelah
  klik, tanpa warning/error console.
- E2E note: skenario Admin lokal berhenti di Login sebelum halaman target karena
  fixture session lama tidak lagi terhidrasi; kondisi yang sama terulang dua kali
  sebelum interaksi date picker dan dicatat sebagai blocker test terpisah. Tidak
  ada Supabase production mutation.
- Deployment: candidate version `59b68db9-f07e-4bca-bdd3-34de72e94b1d` dan
  production version `45d66982-6895-47d1-9969-638d3e6ebdae`. Bundle production
  terverifikasi memuat pemanggilan picker dan public-shell smoke tidak memiliki
  framework overlay atau warning/error console.

### 21 Agustus 2026 — Persistensi pertanyaan kuis Admin diperbaiki

- Evidence owner: pertanyaan terlihat setelah disimpan di layar Pertanyaan,
  tetapi kembali menjadi `0 pertanyaan` setelah kembali melalui editor langkah,
  hari, dan Konten.
- Read-only production diagnosis: draft terbaru memiliki tiga hari dan tiga
  langkah, tetapi tabel pertanyaan sudah berjumlah nol. Tidak ada data production
  yang dimutasi dan pertanyaan yang telah terhapus tidak dapat direkonstruksi.
- Root cause pertama: setiap layar bertingkat menyimpan salinan graph program
  sendiri. Layar lama yang masih mounted dapat menyimpan graph stale dan
  menggantikan graph terbaru setelah pertanyaan dibuat.
- Root cause kedua: PostgREST mengembalikan relasi satu-ke-satu
  `program_answer_keys` sebagai objek, sedangkan normalizer hanya menerima array.
  Kunci jawaban hilang setelah refetch dan penyimpanan berikutnya menghapusnya.
- Repair: cache program diperbarui sinkron saat save, seluruh content flow
  diremount berdasarkan revisi server `updated_at`, dan normalizer menerima
  bentuk objek maupun array untuk relasi kunci jawaban.
- Files: `src/features/admin/AdminProgramEditorFlow.tsx`,
  `src/features/admin/admin-queries.ts`,
  `src/features/admin/admin-repository.ts`, unit regressions untuk cache dan
  normalisasi, contract assertion, serta E2E Admin.
- Verification: focused unit `15 passed`; full `npm test` `175 passed` dan
  `8 skipped`; `npm run typecheck`; `npm run lint`; local integration save RPC;
  dan browser E2E desktop penuh dari pembuatan kuis sampai publikasi semuanya
  lulus. E2E memastikan satu pertanyaan dan kunci jawaban tetap ada di database
  setelah setiap navigasi balik.
- Deployment: candidate version `42579e4f-42c8-4097-960d-91338d52ca16` dan
  production version `0096c234-409e-4321-b155-f25de6635e8c`. Candidate dan
  production mengembalikan HTTP 200 dengan bundle hash yang sama; candidate
  tetap `noindex` dan production tetap `no-store`.

### 21 Agustus 2026 — Video jawaban dan media panduan pertanyaan

- Admin sekarang dapat memilih tipe pertanyaan `Unggah video` pada langkah
  Form. Gambar atau video panduan opsional dapat ditempatkan di bawah prompt
  semua tipe pertanyaan dan wajib memiliki deskripsi aksesibilitas sebelum
  program dapat dipublikasikan.
- `Insight makanan` diperjelas menjadi toggle `Aktifkan analisis AI makanan` dan
  hanya tersedia untuk `Unggah foto`. Jawaban video tidak membuat job AI dan
  tidak memengaruhi poin maupun keputusan Coach.
- Storage dipisahkan berdasarkan exposure: `program-question-media` bersifat
  publik untuk media program terbit, sedangkan `question-videos` privat dan
  hanya dapat dibaca melalui signed URL oleh Peserta pemilik serta Coach yang
  berwenang. Video dibatasi 50 MB dan MIME MP4, QuickTime, atau WebM.
- Backend authority: migration root
  `20260821055430_w08_question_video_and_prompt_media.sql` menambahkan metadata
  media prompt, path jawaban video, validasi/RLS Storage, RPC submit atomik,
  public hydration, Coach hydration, audit orphan, serta cleanup untuk foto dan
  video. Edge Function `cleanup-orphan-question-photos` dideploy ulang dari
  root `supabase/`.
- Local verification: migration apply dan `supabase db lint --level warning`
  tanpa schema error; integration membuktikan media panduan publik, video
  jawaban privat, `text_value` tetap null, dan tidak ada Food Insight job untuk
  video. `npm run typecheck`, `npm run lint`, full `npm test` (`176 passed`,
  `9 skipped`), focused tests setelah final read-only guard (`18 passed`,
  `1 skipped`), serta Admin Chromium E2E lulus.
- Production verification: kolom, RPC, dan dua bucket baru terdeteksi. Advisor
  menandai RPC `SECURITY DEFINER` yang memang disengaja; fungsi publik membatasi
  hasil ke program terbit dan fungsi Coach memeriksa otorisasi relasi di dalam
  RPC. Tidak ada fixture, transaksi, atau data pengguna production yang dibuat.
- Deployment final: candidate version `fb157d32-a3e0-470e-82ab-100ac28549dd`
  mengembalikan HTTP 200 dengan `noindex`; production Worker version
  `9ae7944d-6f58-4edb-9e85-cc987b6c9f2c` aktif pada apex dan `www` tetap 308 ke
  apex. CSP `media-src` mengizinkan origin HTTPS Supabase secara spesifik agar
  video Storage dapat diputar tanpa memperluas origin lain. Browser smoke
  production merender public shell tanpa warning/error.

### 21 Agustus 2026 — Persistensi lampiran pertanyaan diperbaiki

- Evidence production read-only: enam upload terbaru berhasil masuk ke bucket
  `program-question-media`, tetapi semuanya orphan dan belum ada
  `program_questions.media_path` yang tersimpan.
- Root cause: constraint database mewajibkan `media_alt_text` ketika media
  tersedia. Editor membiarkannya kosong dan tidak merender error mutation,
  sehingga transaksi save rollback sementara Admin hanya melihat tombol Simpan
  tetap tersedia.
- Repair frontend: upload baru otomatis memperoleh deskripsi aksesibilitas dari
  jenis media dan teks pertanyaan; serializer graph mengisi default yang sama
  sebagai pertahanan kedua; deskripsi manual tetap dipertahankan; kegagalan save
  sekarang tampil sebagai pesan yang dapat ditindaklanjuti.
- Files: `src/features/admin/admin-question-media.ts`,
  `src/features/admin/AdminProgramContentFlow.tsx`,
  `src/features/admin/admin-repository.ts`, unit regression, dan Admin E2E.
- Verification: focused unit `16 passed`; full `npm test` `179 passed` dan
  `9 skipped`; typecheck, lint, dan `git diff --check` lulus. Chromium desktop
  E2E mengunggah gambar sintetis lokal, memastikan deskripsi otomatis, menyimpan,
  membuka ulang editor, memverifikasi gambar masih tampil, lalu membersihkan
  fixture.
- Browser availability: in-app Browser tidak memiliki sesi Admin dan Chrome
  extension tidak tersedia, sehingga exact authenticated interaction memakai
  Playwright fixture lokal. Candidate dan production public-shell smoke tetap
  dijalankan lewat in-app Browser tanpa overlay atau console error.
- Deployment: candidate version `850e55d5-4b5c-48bf-a35a-0c5113f7a384`
  tetap HTTP 200 dan `noindex`; production version
  `86251607-c5dc-410e-8f8a-f2bdc7c34bbd` aktif pada apex, sedangkan `www` tetap
  308 ke apex. Tidak ada migration atau mutasi data pengguna production.

### 21 Agustus 2026 — Publish program berbayar dan feedback Admin diperbaiki

- Evidence production read-only: `TEST 3 HARI` tetap `draft`; tiga permintaan
  `publish_program` mengembalikan HTTP `400`. Seluruh tiga hari, 11 langkah, 10
  pertanyaan, kunci kuis, dan pasangan timbang valid. Penyebabnya adalah guard
  historis `phase12_payment_handoff` pada RPC, sementara production belum memiliki
  satu pun tujuan pembayaran aktif.
- Backend repair: migration authority root
  `20260821072405_w08_paid_program_publish_handoff.sql` menghapus handoff Phase 11.
  Program berbayar sekarang dapat diterbitkan setelah harga positif dan
  `private.current_payment_destination()` tersedia; tanpa destination transaksi
  gagal tertutup dengan `program_paid_not_ready` dan status tetap draft.
- Frontend repair: halaman Tinjau memeriksa destination melalui RLS Admin,
  menonaktifkan publish berbayar yang belum aman, menampilkan pesan yang dapat
  ditindaklanjuti, menangkap rejection mutation, serta menginvalidasi katalog
  publik setelah publish berhasil. Program gratis tetap tidak bergantung pada
  pemeriksaan pembayaran.
- Files: migration dan pgtap regression root, `admin-repository.ts`,
  `admin-queries.ts`, `AdminProgramEditorFlow.tsx`, dan contract unit test.
- Verification: migration apply lokal, `supabase db lint --local --level warning`
  tanpa error, focused pgtap `5 passed`, focused unit `14 passed`, full
  `npm test` `180 passed` dan `9 skipped`, typecheck, lint, production build,
  environment/bundle/PWA verification, Worker type check, kandidat/production
  dry-run, serta browser E2E publish gratis `1 passed`. Suite pgtap historis
  penuh tidak dipakai sebagai final gate karena database lokal berisi fixture
  lama yang membuat closure/winner count global tidak terisolasi; regression baru
  berjalan dalam transaksi dan rollback.
- Production: migration root tersinkron (`upToDate=true`), candidate noindex
  version `5004c01f-6229-4b2b-a9f8-1b2f2dab3be8`, dan Worker production version
  `84196cd3-2ddd-44ff-9757-cdd57739b164`. Apex/deep link mengembalikan HTTP 200,
  `www` tetap 308, Browser production tidak overflow atau menampilkan framework
  error. Tidak ada program, destination, transaksi, payment order, atau data
  pengguna production yang dimutasi.
- Remaining action: owner mengisi rekening bank dan/atau aset QRIS production.
  Setelah destination dibuat oleh Admin, `TEST 3 HARI` dapat diterbitkan dan akan
  muncul di tab Tersedia; jangan memakai tujuan pembayaran sintetis.

### 21 Agustus 2026 — Destination lokal asli dipromosikan dan program diterbitkan

- Owner mengoreksi bahwa rekening dan QRIS asli sudah tersimpan lokal. Audit
  menemukan satu destination non-fixture versi 8 beserta JPEG QRIS 1.098×1.098
  (93.920 byte). Kesimpulan sebelumnya keliru karena pemeriksaan hanya mencakup
  file env dan production, sementara destination asli berada di database/Storage
  Supabase lokal dalam status `retired` setelah fixture test menjadi aktif.
- Fixture aktif lokal ditolak sebagai sumber: bank `TST`, account/instruction
  fixture, serta path QRIS tanpa object. Hanya destination non-fixture yang
  memiliki object Storage digunakan.
- QRIS asli disalin dari bucket lokal ke path yang sama pada bucket private
  `payment-destination-assets` production. Destination production versi 1 dibuat
  lewat `create_payment_destination` dengan konteks Admin; petunjuk pratinjau
  lokal diganti menjadi instruksi transfer/QRIS production yang meminta bukti
  untuk diperiksa Admin.
- `TEST 3 HARI` diterbitkan lewat `publish_program` dengan idempotency key
  production dan berubah menjadi `scheduled` untuk 22–24 Agustus 2026. Satu audit
  `program_published` tercatat. Tidak ada payment order, enrollment, transfer,
  ledger, atau data peserta yang dibuat.
- Verification production: satu destination aktif, satu QRIS object 93.920 byte,
  satu row katalog publik, satu audit publish, dan nol payment order. Browser
  fresh navigation menampilkan `TEST 3 HARI` pada tab Tersedia tanpa empty state
  atau horizontal overflow.
- Process correction: sebelum menyatakan material payment belum tersedia,
  pemeriksaan berikutnya wajib mencakup ignored files, database lokal, dan object
  Storage lokal serta harus membedakan fixture dari source non-fixture.

### 22 Agustus 2026 — Status timbang dan pemilih sumber media Peserta diperbaiki

- Evidence owner: rekaman iPhone menunjukkan timbang yang sudah berhasil dicatat
  tetap berlabel `Belum dimulai`; pengiriman ulang kemudian ditolak dengan konflik
  status. Rekaman kedua menunjukkan tombol unggah foto langsung membuka kamera
  tanpa menawarkan pustaka foto atau file.
- Root cause status: RPC timbang menyimpan authoritative row di `weigh_ins`, tetapi
  read model Peserta hanya mengambil `step_submissions`. UI karena itu tidak pernah
  melihat penyelesaian timbang dan tetap menawarkan form kosong. Repository sekarang
  mengambil kedua sumber secara paralel dan memproyeksikan row timbang menjadi status
  aktivitas `approved` tanpa mengambil atau mengekspos nilai berat.
- UI: timbang tersimpan menampilkan `Berat badan sudah dicatat`, status `Selesai`,
  serta menghilangkan input dan tombol kirim. Submission foto/form yang pending atau
  approved juga menampilkan pesan tercatat yang eksplisit dan tidak merender form
  kosong yang seolah belum diisi.
- Media picker: atribut HTML `capture="environment"` dihapus dari jawaban foto dan
  video. Tombol `Pilih sumber foto` dan `Pilih sumber video` sekarang membuka chooser
  native perangkat yang dapat menawarkan pustaka, file, atau kamera; input di-reset
  setelah pemilihan agar file yang sama dapat dipilih kembali saat koreksi.
- Files changed: `src/features/participant/ParticipantSubmissionForm.tsx`,
  `participant-models.ts`, `participant-program-policy.ts`,
  `participant-repository.ts`, focused unit tests, serta E2E Peserta/review.
- Verification: typecheck dan lint lulus; focused unit `21 passed`; full Vitest
  `181 passed`, `9 skipped`; compact authenticated E2E Peserta `4 passed` dan
  evidence/review `2 passed`. Regression timbang membuktikan status selesai langsung
  setelah submit dan tetap selesai setelah reload. Production build, environment,
  bundle (`50` JavaScript files), PWA, Wrangler types, candidate/production dry-run,
  CSP/header checks, dan browser QA tanpa overlay atau warning/error semuanya lulus.
- Deployment: candidate noindex version
  `f1694963-c023-43ca-99cf-ed042acf6279`; production Worker version
  `24ad0330-a108-4213-a3c4-9852736f9696`. Apex melayani bundle baru dengan
  `no-store`, CSP tetap enforced, dan `www` tetap redirect `308` ke apex. Tidak ada
  migration, secret, DNS, payment, transfer, atau data production yang dimutasi.
- Remaining physical-device check: tutup/buka ulang PWA iPhone, pastikan langkah
  timbang lama tampil selesai, lalu tekan pemilih foto dan video untuk memastikan
  action sheet iOS menawarkan pustaka/file/kamera sesuai kemampuan perangkat.

### 22 Agustus 2026 — Insight makanan dibuat opt-in secara fail-closed

- Evidence production read-only menemukan pertanyaan foto timbang awal sudah
  `analysis_mode=none`, tetapi pertanyaan berlabel upload video pada langkah yang
  sama masih tersimpan `food`. Satu job dari pertanyaan kedua telah selesai sebelum
  perbaikan; tidak ada job nonaktif yang masih queued, processing, atau retry.
- Frontend sekarang memakai satu policy eksplisit: kartu dan query Insight makanan
  hanya dirender bila langkah memiliki pertanyaan `photo_upload` dengan
  `analysis_mode=food`. Enqueue sekunder di repository memakai syarat yang sama.
  Serializer Admin juga membersihkan rubric dan versi rubric ketika toggle mati
  atau jenis pertanyaan bukan upload foto.
- Backend root migration `20260822022849_w08_food_insight_opt_in_guard.sql`
  menutup race konfigurasi: reconciliation menandai job queued/retry yang sudah
  dinonaktifkan sebagai unavailable/configuration_invalid, sedangkan claim hanya
  mengambil pertanyaan foto yang masih opt-in dan masih memiliki private photo.
  Karena claim mengembalikan null, worker tidak mengunduh foto dan tidak memanggil
  provider AI untuk konfigurasi nonaktif.
- Production data correction hanya mengubah dua pertanyaan timbang berlabel upload
  video dari `food` menjadi `none`; tiga pertanyaan makanan Hari 2 tetap opt-in.
  Hasil AI lama dipertahankan sebagai audit historis tetapi tidak lagi dirender.
- Files changed: `src/features/admin/admin-question-media.ts`, policy/form/repository
  Peserta, focused unit/integration regression, migration root, dan progress log ini.
- Verification: migration apply dan lint lokal tanpa schema error; integration
  membuktikan disabled claim menghasilkan null lalu job ditutup tanpa provider;
  focused unit `20 passed`; full Vitest `185 passed`, `9 skipped`; typecheck, lint,
  production build, environment/bundle/PWA verification, Wrangler types, serta
  candidate/production dry-run lulus. Production aggregate: `0` pertanyaan timbang
  AI aktif, `3` pertanyaan makanan AI aktif, dan `0` active job untuk mode nonaktif.
- Deployment: Supabase production migration `20260822022849`; candidate Worker
  `3f6f5d40-a3dd-4b8f-b083-e47e61cb3bf0`; production Worker
  `880311da-7697-4f22-9777-967b194655a4`. Browser production membuka katalog tanpa
  console error. Advisor tidak menemukan temuan baru yang berasal dari migration;
  warning/info historis tetap berada di backlog lint database.
- Remaining physical-device check: tutup penuh lalu buka kembali PWA iPhone agar
  service worker mengambil bundle baru; halaman timbang yang toggle AI-nya mati
  tidak boleh lagi menampilkan kartu Insight makanan.

### 22 Agustus 2026 — Progres timbang pada detail peserta Coach diselaraskan

- Evidence owner memperlihatkan detail peserta Coach memiliki riwayat `Timbang awal`
  dan langkah upload yang sudah disetujui, tetapi langkah timbang tetap berstatus
  `Belum dimulai`, ringkasan hari `1/2 langkah`, dan total `1 dari 11 langkah selesai`.
- Root cause: read model Coach hanya menghitung `step_submissions`, sedangkan timbang
  disimpan secara authoritative di `weigh_ins`. Ini kelas masalah yang sama dengan
  status Peserta, tetapi berada pada RPC direktori/detail Coach yang terpisah.
- Migration root `20260822024334_w08_coach_weigh_in_progress_read_model.sql`
  mempertahankan authorization function lama sebagai private base, lalu menormalkan
  completed-step, active-day, last-activity, dan status langkah timbang dari
  `weigh_ins`. Nilai berat tidak dipakai untuk ringkasan dan tidak diekspos ke
  direktori.
- Regression lokal membuat langkah `initial_weigh_in` dengan row `weigh_ins` tanpa
  `step_submission`; direktori dan detail sama-sama menghitungnya selesai dan status
  langkah menjadi `approved`. Cross-Coach denial tetap lulus.
- Verification: focused integration `1 passed`, focused contract unit `11 passed`,
  full Vitest `185 passed` dan `9 skipped`, typecheck, lint, production build, serta
  `supabase db lint --local --level warning` tanpa schema error. History migration
  lokal dan production sama-sama berakhir di `20260822024334`.
- Production: project sehat; wrapper direktori/detail dan helper metrics tersedia,
  role `authenticated` memiliki execute sedangkan `anon` ditolak. Aggregate privat
  tanpa ID atau nilai berat menemukan tepat satu langkah timbang authoritative tanpa
  submission—kasus tersebut kini tercakup. Tidak ada data peserta, payment, secret,
  DNS, atau Worker yang diubah; Worker tidak perlu redeploy karena kontrak frontend
  tetap sama.
- Remaining physical-device check: muat ulang detail peserta pada akun Coach. Hari
  pertama harus tampil `2/2 langkah`, `Timbang awal` berstatus selesai/disetujui, dan
  ringkasan menjadi `2 dari 11 langkah selesai`.

### 22 Agustus 2026 — Status program Peringkat mengikuti tanggal program

- Evidence owner: `TEST 3 HARI` bertanggal 22–24 Agustus tampil `Selesai` dan
  `Program selesai` pada 22 Agustus, serta masih menampilkan disclaimer privasi di
  bawah podium.
- Diagnosis production read-only: row program masih berstatus lifecycle `scheduled`,
  tetapi tanggal lokal `Asia/Makassar` sudah 22 Agustus sehingga state efektifnya
  `running`. Komponen lama menganggap setiap status selain `active` sebagai selesai.
- Repair: state Peringkat sekarang menggabungkan lifecycle server dengan tanggal
  mulai/selesai dalam timezone program. Program scheduled pada tanggal aktif tampil
  `Berlangsung` dan `Peringkat sementara`; state sebelum mulai, lewat tanggal akhir,
  dan completed/archived tetap dibedakan. Disclaimer di halaman Peringkat dan sheet
  Rincian poin dihapus.
- Files: `src/features/leaderboard/LeaderboardExperience.tsx`,
  `src/features/leaderboard/leaderboard-state.ts`, focused unit regression,
  assertion E2E Coach, dan progress log ini.
- Verification: focused unit `5 passed`; full Vitest `187 passed`, `9 skipped`;
  typecheck, lint, production build, environment/bundle/PWA verification, Wrangler
  types, candidate dan production dry-run lulus. Kandidat noindex serta production
  fresh navigation Program → Peringkat sama-sama menampilkan `Berlangsung` dan
  `Peringkat sementara`, tidak memuat disclaimer, dan tidak memiliki warning/error
  console.
- Deployment: candidate version `dfdfda25-56b6-4128-8eeb-6a6b8d77bf73` dan
  production Worker version `aac982bf-ea9c-4e6d-9da8-cbaa3ad14e5e`. Tidak ada
  migration, perubahan status/data program, payment, secret, atau DNS.
- Remaining physical-device check: tutup lalu buka kembali PWA iPhone atau lakukan
  refresh agar service worker mengambil bundle baru; Peringkat harus menampilkan
  `Berlangsung` tanpa disclaimer.

### 22 Agustus 2026 — Status Perlu perhatian mengikuti langkah jatuh tempo

- Evidence owner: direktori `Peserta saya` menandai satu peserta `Perlu perhatian`
  walaupun Hari 1 sudah `2/2 langkah`; progres keseluruhan tetap `2 dari 11` karena
  sembilan langkah berikutnya belum jatuh tempo.
- Root cause: helper UI memakai `progress_percentage < 50` terhadap seluruh program.
  Ini melanggar kontrak expected progress karena langkah masa depan ikut membuat
  peserta terlihat tertinggal.
- Backend repair: migration root
  `20260822040354_w08_coach_due_progress_attention.sql` menambahkan
  `due_step_count` dan `completed_due_step_count` pada read model direktori Coach.
  Program terjadwal memakai tanggal program pada timezone authoritative; program
  mandiri memakai offset hari dari tanggal enrollment. Submission pending/approved
  dan timbang authoritative sama-sama dihitung sebagai tindakan peserta yang selesai.
- Frontend repair: policy `needsCoachAttention` hanya benar bila enrollment belum
  selesai dan `completed_due_step_count < due_step_count`. Filter, jumlah ringkasan,
  dan badge baris memakai policy yang sama; persentase keseluruhan tetap ditampilkan
  sebagai kemajuan program.
- Verification: focused unit `14 passed`; focused integration `1 passed` dengan
  `3/3` langkah jatuh tempo selesai dan satu langkah masa depan belum selesai; full
  Vitest `190 passed`, `9 skipped`; typecheck, lint, production build,
  `git diff --check`, local database lint, environment/bundle/PWA verification,
  Wrangler types, serta candidate/production dry-run lulus. Production read model
  menghasilkan `2` langkah jatuh tempo, `2` selesai, dan `0` enrollment perhatian.
- Security: RPC direktori tetap hanya executable oleh `authenticated`; `anon` ditolak
  dan helper privat tidak executable oleh `public`. Advisor hanya mengulang warning
  intentional untuk RPC `SECURITY DEFINER` authenticated yang memeriksa authorization
  Coach pada base function; tidak ada temuan performance baru terkait migration.
- Deployment: Supabase production migration `20260822040354`; candidate noindex
  Worker `6d812684-0a21-4b3e-8114-78cfcd55cb7b`; production Worker
  `26855a3d-c738-4e5b-93dd-2de398263502`. Apex/deep link melayani HTTP 200 dengan
  `no-store`, `www` tetap 308 ke apex, dan Browser production tidak memiliki
  framework overlay atau warning/error console.
- Tidak ada data peserta, nilai berat, payment, secret, DNS, transfer, atau fixture
  production yang dibuat atau diubah. Remaining physical-device check: refresh atau
  tutup/buka ulang PWA Coach; ringkasan harus menampilkan `0 perlu perhatian` dan
  badge peserta tidak lagi muncul selama seluruh langkah jatuh tempo selesai.

### 23 Agustus 2026 — Router AI makanan dan kartu status diperbaiki

- Diagnosis aggregate production tanpa membaca identitas, foto, prompt, atau hasil
  peserta menemukan tiga job gagal dengan `invalid_output`; cron dan Edge Function
  tetap sehat. Reproduksi memakai fixture non-user menunjukkan router
  `openrouter/free` sempat memilih model content-safety yang tidak mengembalikan
  structured JSON sesuai kontrak.
- Backend repair menambahkan `provider.require_parameters = true`, menjadikan
  keluaran provider yang malformed sebagai kegagalan retryable, dan mempertahankan
  bounded retry. Migration root
  `20260823031218_w08_retry_invalid_food_insight_jobs.sql` hanya menjadwalkan ulang
  job `invalid_output` yang masih memiliki jatah percobaan.
- UI repair menghapus teks penjelas pada kartu `Aktivitas sudah selesai`, `Analisis
  sedang diproses`, dan `Analisis belum berhasil`, serta menghapus kartu informasi
  `Bukti foto diperlukan` tanpa menghapus pemilih sumber foto.
- Verification: focused unit `31 passed`; full Vitest `191 passed`, `9 skipped`;
  authenticated local E2E Chromium desktop/compact `4 passed`; typecheck, lint,
  production build, environment/bundle/PWA verification, database lint,
  `git diff --check`, Wrangler types, serta candidate/production dry-run lulus.
- Deployment: Supabase Edge Function `process-food-insight` version `2` (ACTIVE),
  production migration `20260823031218`, candidate Worker
  `7fea3874-6297-49d8-be24-f3f2c7fa39fb`, dan production Worker
  `2c0f86b1-9cd4-4227-b496-c567d5df88da`. Apex dan `www` tetap memakai route/DNS
  yang sama.
- Scheduler production yang sudah ada memulihkan dua dari tiga job lama pada
  percobaan kedua. Satu job tersisa gagal `provider_unavailable` pada percobaan
  kedua. Job itu tidak dipanggil atau dijadwalkan ulang secara manual karena akan
  mengirim ulang foto production ke OpenRouter dan membutuhkan izin eksplisit baru.
  Tidak ada payment, transfer, secret, DNS, atau data peserta yang dibaca/diubah
  manual selama verifikasi ini.
- Remaining physical-device check: refresh atau tutup/buka ulang PWA. Kartu status
  harus tampil tanpa teks penjelas, kartu bukti foto tidak muncul, dan insight baru
  yang opt-in dapat beralih dari diproses ke hasil. Retry satu job production yang
  tersisa menunggu persetujuan khusus pemrosesan ulang foto tersebut.

### 23 Agustus 2026 — Gemma berbayar dengan fallback dan batas harga

- Konfigurasi OpenRouter memakai urutan tetap `google/gemma-4-26b-a4b-it` lalu
  `google/gemma-3-12b-it`, structured output `food_insight` strict dengan schema
  produksi lengkap, `provider.require_parameters = true`, `sort = price`, serta
  batas harga prompt `0.10` dan completion `0.40` per satu juta token.
- Parameter reasoning tidak dikirim karena fallback Gemma 3 12B tidak
  mendukungnya. Kedua model tetap mendukung image input dan structured output;
  model aktual yang melayani respons disimpan sebagai `model_alias` untuk audit.
- Konfigurasi mendukung `FOOD_AI_MODELS` berbentuk JSON array dan tetap membaca
  `FOOD_AI_MODEL` sebagai fallback kompatibilitas. Secret production diperbarui
  hanya untuk kedua nama tersebut; API key, worker secret, dan secret lain tidak
  diubah.
- Verification: synthetic non-user fixture lulus pada model utama dan fallback
  dengan hasil schema-valid; full Vitest `192 passed`, `9 skipped`; typecheck,
  lint, production build, environment/bundle/PWA verification, `git diff --check`,
  Wrangler types, candidate dry-run, dan production dry-run lulus.
- Deployment: Supabase Edge Function `process-food-insight` version `4` ACTIVE
  (`891a94e5a271a6de300f8d1fed39897b0b4e365c250f662aae2317dfaf25fcb0`),
  candidate Worker `13d23a96-48ee-4151-9c35-b3fabc40bfd6`, dan production Worker
  `212d3212-1ee3-4a24-aabd-bcdcb45e8d2a`. Candidate tetap noindex; apex HTTP 200
  dan `www` tetap 308 ke apex tanpa perubahan DNS.
- Halaman kebijakan privasi dan ketentuan production sekarang menyebut Gemma 4
  26B A4B sebagai model utama dan Gemma 3 12B sebagai fallback. Zero Data
  Retention tetap tidak dipaksakan sesuai keputusan owner.
- Audit read-only setelah deployment tetap menunjukkan tiga hasil lama
  `openrouter/free`, tiga job completed, dan satu job failed. Tidak ada job nyata
  yang dipanggil ulang, data/foto pengguna yang diproses untuk smoke, migration,
  payment, transfer, atau perubahan DNS.

### 23 Agustus 2026 — Pilihan leaderboard dan snapshot publik Coach diselaraskan

- Halaman Peringkat sekarang menyediakan tombol `Ganti` dan sheet `Pilih program`.
  ID program publik yang dipilih disimpan lokal dan dipakai kembali oleh Beranda,
  sehingga `Leaderboard Top 5` dan `Lihat semua` selalu membuka program yang sama.
- Beranda menampilkan Top 5 sebagai deretan avatar netral dengan border dan badge
  warna peringkat. Katalog Program menghapus teks penjelas dan deskripsi kartu;
  setiap kartu memakai lebar penuh area konten.
- Root cause profil Coach lintas role adalah direktori publik dan read model Coach
  pendamping masih membaca `profiles`, sedangkan perubahan Coach diterbitkan ke
  `coach_public_profiles`. Migration root
  `20260823050937_sync_public_coach_profile_reads.sql` mengarahkan keduanya ke
  snapshot publik yang sama dan hanya mengembalikan UUID asset media opaque.
  Foto tetap dilayani melalui gateway `public-coach-media`; kontak privat, path
  Storage, URL avatar provider, QR, dan relasi peserta tidak masuk read model publik.
- Cache direktori, detail Coach, dan Coach pendamping diinvalidasi setelah publish.
  Production Browser menunjukkan `Lingga Coach`, `Coach terverifikasi`, headline
  `Coach`, area `Manado`, bio `Test Cerita`, dan foto gateway yang sudah diperbarui.
- Verification: focused unit `30 passed`; full Vitest `195 passed`, `9 skipped`;
  integration Supabase lokal `1 passed`; typecheck, lint, production build,
  local database lint, kandidat/production dry-run, dan migration remote parity
  lulus. Browser desktop/compact menguji picker, persistensi ke Beranda, kartu
  Program, Top 5, dan direktori Coach pada local, kandidat, serta custom domain.
- Deployment: Supabase production migration `20260823050937`, candidate Worker
  `56fc55a8-ab93-4d41-a7d7-f822e879be51`, dan production Worker
  `5b49d538-d416-468a-ac8d-75fa3add03e1`. Tidak ada DNS, payment, transfer, secret,
  atau data pengguna yang diubah.
- Synthetic production smoke tidak dijalankan karena file lokal tidak memuat
  `SUPABASE_SECRET_KEY`; proses berhenti sebelum membuat fixture sehingga tidak ada
  cleanup manifest atau residual data. Remaining physical-device check: refresh
  atau tutup/buka ulang PWA agar service worker mengambil bundle production baru.

### 23 Agustus 2026 — Kontrol carousel Program Beranda disederhanakan

- Beranda Peserta menghapus tombol `Program sebelumnya`, `Program berikutnya`, dan
  indikator posisi seperti `1 dari 2`. Kartu program tetap memakai horizontal
  swipe/scroll dengan snap antarkartu dan label aksesibilitas yang sama.
- State indeks, ref imperative, dan style yang hanya dipakai kontrol tersebut ikut
  dihapus sehingga tidak ada state navigasi duplikat dengan posisi scroll native.
- Files changed: `src/app/app/home.tsx`, regression contract
  `tests/unit/home-program-carousel-contract.test.ts`, dan progress log ini.
- Verification: focused regression `1 passed`; full Vitest `196 passed`, `9 skipped`;
  typecheck, lint, production build, environment verification, `git diff --check`,
  Wrangler 4.125.0 candidate/production dry-run, serta Browser lokal, kandidat, dan
  production lulus tanpa warning/error console. Kandidat tetap HTTP 200 dengan
  `X-Robots-Tag: noindex`; apex HTTP 200 dan `www` tetap 308 ke apex.
- Deployment: candidate Worker `74d6eee0-1356-49ec-9ed3-5744e7ac5b54` dan
  production Worker `0f525b66-9ec9-46b9-be2d-c68d5f405cb5`. Tidak ada migration,
  perubahan Supabase/data pengguna, secret, DNS, payment, atau transfer. Remaining
  physical-device check: refresh atau tutup/buka ulang PWA Peserta agar service
  worker mengambil bundle terbaru, lalu geser kartu Program secara horizontal.

### 23 Agustus 2026 — Sinkronisasi profil Coach lintas role dan tema tautan publik

- Dashboard Coach serta direktori/detail Admin kini membaca nama, area layanan,
  headline, biografi, dan avatar dari snapshot `coach_public_profiles` yang sama
  dengan `/c/:handle`. Data akun privat tetap berasal dari `profiles`; avatar
  publik hanya diteruskan sebagai UUID asset opaque melalui gateway
  `public-coach-media`, tanpa membuka object path Storage.
- Publish profil menginvalidasi cache workspace Coach. UI Coach/Admin memilih
  avatar snapshot terbit sebelum fallback avatar provider lama.
- Hero profil publik memakai pasangan token `identitySurface` dan
  `onIdentitySurface`, sehingga tetap near-black dengan teks putih pada light
  maupun dark mode. Tautan share dikanonisasi ke origin + `/c/:handle` tanpa
  query sementara.
- Files changed: migration root
  `supabase/migrations/20260823084711_sync_coach_profile_all_role_reads.sql`,
  model/query/komponen Coach, model dan komponen Admin, design tokens, unit,
  integration, E2E tests, dan progress log ini.
- Verification: typecheck dan lint lulus; focused unit `37 passed`; full Vitest
  `198 passed`, `9 skipped`; integration Supabase lokal `2 passed`; Playwright
  compact/desktop `6 passed`; local database lint tanpa error; production build,
  bundle (`50` JavaScript files), PWA, Wrangler types, candidate/production
  dry-run, HTTP smoke, dan migration remote parity lulus. Browser production
  dalam dark mode mengukur hero `rgb(9, 9, 9)` dan judul `rgb(255, 255, 255)`.
- Deployment: Supabase production migration `20260823084711`, candidate Worker
  `5dc940a9-b4f6-4577-83c7-f22f4eb82121`, dan production Worker
  `e854adf6-0ab4-4408-a73b-d57bbc3a2d93`. Apex mengembalikan HTTP 200, `www`
  tetap 308 ke apex, dan kandidat tetap `noindex`. Tidak ada perubahan DNS,
  secret, payment, transfer, atau data pengguna.
- Remaining physical-device check: refresh atau tutup/buka ulang PWA Coach dan
  Admin agar service worker mengambil bundle terbaru, lalu cek avatar/area/bio
  pada Dashboard Coach dan Orang → Coach di Admin.

### 23 Agustus 2026 — Avatar profil pada leaderboard lintas role

- RPC leaderboard publik dan Coach kini mengembalikan avatar provider untuk
  Participant/Admin serta UUID asset opaque untuk avatar publik Coach. Object
  path Storage Coach tetap tidak pernah masuk read model atau HTML publik.
- Parser publik/Coach menyelesaikan UUID Coach melalui gateway media terkontrol;
  podium utama, baris peringkat, rincian Coach, dan `Leaderboard Top 5` Beranda
  semuanya meneruskan URL tersebut ke `UserAvatar`. Route publik yang sama
  melayani Tamu, Participant, dan Admin; route Coach memakai kontrak avatar yang
  sama tanpa membuka rincian poin peserta yang bukan binaannya.
- Files changed: root migration
  `supabase/migrations/20260823091215_leaderboard_profile_avatars.sql`, model dan
  repository public/Coach, komponen leaderboard dan Beranda Top 5, unit,
  integration, E2E tests, serta progress log ini.
- Verification: typecheck dan lint lulus; focused unit `15 passed`; full Vitest
  `199 passed`, `9 skipped`; integrasi Supabase lokal `1 passed`; Playwright
  Participant compact/desktop `2 passed` dan Coach compact/desktop `2 passed`;
  local database lint tanpa error; production build, environment verification,
  Wrangler types, candidate/production dry-run, HTTP smoke, dan migration remote
  parity lulus. Browser lokal, candidate, dan production membuktikan elemen
  `img` muncul di podium dan Top 5; console production kosong.
- Deployment: Supabase production migration `20260823091215`, candidate Worker
  `7853f591-38ff-40eb-9b85-02c7d8f2f04b`, dan production Worker
  `5e836a6f-9e8a-43b8-876a-f1fa7bcf69b5`. Candidate tetap HTTP 200 dengan
  `X-Robots-Tag: noindex`; apex HTTP 200 dan `www` tetap 308 ke apex. Tidak ada
  perubahan DNS, secret, payment, transfer, atau data pengguna nyata.
- Remaining physical-device check: refresh atau tutup/buka ulang PWA pada tiap
  role agar service worker mengambil bundle terbaru, lalu periksa foto pada
  Beranda Top 5 dan Peringkat.

### 23 Agustus 2026 — Lifecycle program terjadwal diselaraskan

- Root cause label `Segera hadir` pada program yang sedang berjalan adalah kartu
  publik membaca kolom status tersimpan secara langsung. Program yang diterbitkan
  sebelum tanggal mulai tetap berstatus `scheduled`, sementara halaman detail
  memakai enrollment aktif sehingga menampilkan `Aktif`.
- Helper lifecycle bersama sekarang menentukan keadaan efektif dari `starts_on`,
  `ends_on`, dan timezone program. Kartu Beranda/Program menampilkan `Aktif` saat
  tanggal lokal berada dalam periode program; leaderboard memakai sumber lifecycle
  yang sama agar label tidak kembali berbeda.
- Migration root `20260823121458_w08_program_lifecycle_activation.sql` menambahkan
  aktivasi idempotent untuk program terbit yang sudah jatuh tanggal mulai, audit
  `program_activated`, serta job pg_cron setiap lima menit. Fungsi private tidak
  dapat dipanggil oleh Public, Anon, Authenticated, atau Service Role.
- Production membuktikan `TEST 3 HARI` aktif pada 23 Agustus 2026 dan
  `TEST 3 HARI KEDUA` tetap terjadwal untuk 24 Agustus 2026. Browser production
  menampilkan masing-masing `Aktif` dan `Segera hadir` pada Beranda dan Program.
- Files changed: `src/shared/program/program-lifecycle.ts`, kartu publik,
  leaderboard state, unit test lifecycle, migration dan pgTAP root, serta progress
  log ini.
- Verification: focused unit `11 passed`; full Vitest `210 passed`, `9 skipped`;
  pgTAP `6 passed`; typecheck, lint, production build, bundle (`50` JavaScript
  files), PWA, Wrangler types, local database lint/advisor, candidate/production
  dry-run, dan migration remote parity lulus.
- Deployment: migration Supabase production `20260823121458` dan production Worker
  `c263aff7-594d-4c64-a62d-f7e588775223`. Worker dibangun ulang secara serial
  setelah QA menemukan output paralel sempat menimpa `app.html`; `/app` kini kembali
  membuka shell aplikasi. Tidak ada perubahan DNS, secret, payment, transfer, atau
  data pengguna.
- Remaining physical-device check: refresh atau tutup/buka ulang PWA agar service
  worker mengambil bundle terbaru.

### 23 Agustus 2026 — Penerimaan perangkat nyata oleh owner

- Owner melaporkan seluruh pemeriksaan manual yang diminta berhasil: refresh dan
  tutup/buka ulang PWA iPhone, hasil ikon instalasi, keadaan offline, pemindaian QR,
  unggah foto/video, keyboard virtual, rotasi, browser Back, tautan eksternal,
  logout/login, serta pemeriksaan ringkas Chrome Android.
- Bukti owner menutup gate maskable/Apple touch rendering dan interaksi kritis
  perangkat. Audit kontrak lokal juga membuktikan service worker hanya menyimpan
  shell publik, tidak menangani mutation/background sync, menunggu aktivasi update,
  dan logout/pergantian akun membersihkan query, object URL, serta signed URL privat.
- Checklist preview noindex/CSP, payment-proof retention, penundaan Admin Image
  Storage, dan invalidasi media Coach ikut diselaraskan dengan evidence production
  yang sudah tercatat sebelumnya; item-item tersebut sebelumnya tertinggal sebagai
  checkbox kosong meskipun verifikasinya sudah lulus.
- Full browser-version matrix dan accessibility matrix tetap terbuka karena laporan
  ini tidak mengklaim Safari iOS versi sebelumnya, semua browser desktop, screen
  reader, zoom 200%, reduced motion, transparency, atau increased contrast.

### 23 Agustus 2026 — Hardening final Codex; satu trace eksternal tersisa

- Security/edge: Worker production sekarang mengirim CSP enforcement, `nosniff`,
  strict referrer policy, denied framing, permissions policy, UUID `X-Request-ID`,
  dan `Strict-Transport-Security: max-age=31536000; includeSubDomains`. HSTS preload
  sengaja tidak diaktifkan sebelum seluruh subdomain ditinjau. Apex/app/404 live
  terverifikasi; `www` tetap `308` ke apex dengan query utuh.
- Observability: custom event hanya memuat environment, nama event, method, route
  group aman, status, dan correlation ID. Pemeriksaan live menemukan automatic
  Cloudflare invocation log menyertakan URL/IP mentah; `invocation_logs` kemudian
  dinonaktifkan dan versi produksi dideploy ulang agar query OAuth tidak disimpan
  sebagai log aplikasi rutin.
- Private media: daftar bukti Coach tidak lagi meminta signed URL saat render.
  Coach harus memilih `Muat bukti foto/video`; foto compact dapat diperbesar dan
  video baru memakai `preload=metadata` setelah otorisasi. Object path tidak masuk
  UI/log. Transformasi thumbnail jaringan tidak ditambahkan karena fitur transform
  Supabase berbayar; boundary otorisasi tetap download/signed URL privat yang ada.
- Performance: budget executable ditambahkan dan lulus pada build final: bootstrap
  `2,607,921 / 2,750,000` byte, total JS `2,717,865 / 3,200,000`, bundle terbesar
  `1,497,886 / 1,650,000`, landing critical `26,006 / 64,000`, hero
  `282,229 / 350,000`, dan `50 / 60` berkas JavaScript.
- Browser/accessibility: matriks final `26 passed`, `2 skipped` pada Chromium
  desktop/compact, Edge compatibility profile, dan WebKit desktop. Skip WebKit
  hanya untuk tab-to-link yang mengikuti setting full keyboard access macOS dan
  forced-colors yang merupakan emulasi Chromium; keyboard Safari perangkat nyata
  sudah diterima owner. Layout, semantic landmarks, 200% zoom, dark mode, reduced
  motion, focus-visible, forced colors Chromium, dan seluruh viewport overflow
  lulus. In-app Browser juga merender landing, CTA install, DOM semantik, dan
  console tanpa warning/error.
- Runbook/matrix: `production/W08_PRODUCTION_OPERATIONS.md` sekarang mencakup
  deployment, rollback version, cache, environment, secret rotation, incident,
  redaction, dan owner untuk setiap blocker.
- Verification: lint dan typecheck lulus; full Vitest `212 passed`, `9 skipped`;
  focused Worker setelah observability `10 passed`; build production, public-env
  scan, bundle split, performance budget, PWA audit, Wrangler types, dan production
  dry-run lulus. Supabase changelog terbaru juga ditinjau; tidak ada schema/function
  yang perlu diubah untuk slice ini.
- Deployment: versi Worker hardening pertama
  `c857c57b-f4b6-4735-8faf-cfbc18ddc25a`, lalu versi final dengan automatic raw
  invocation logs disabled `3c8ad94a-06b5-4945-9bb2-1fd8f2cfc9bd`. Rollback
  sebelum slice: `c263aff7-594d-4c64-a62d-f7e588775223`. Tidak ada perubahan DNS,
  secret, Supabase production, payment, transfer, atau data pengguna.
- Blocker tunggal: tool `performance_start_trace` dari Chrome DevTools MCP tidak
  tersedia pada sesi Codex ini. Bundle budget sudah enforced, tetapi checkbox
  Lighthouse/Web Vitals tetap terbuka sampai connector ditambahkan dan trace live
  dicapture. Tidak ada pemeriksaan perangkat owner yang perlu diulang.

### 23 Agustus 2026 — Lighthouse/Web Vitals production selesai; W08 ditutup

- Chrome DevTools MCP berhasil dimuat setelah konfigurasi global diperbaiki. Cold
  production trace desktop menghasilkan LCP `123 ms` dan CLS `0,00`. Trace mobile
  pada Fast 4G dan CPU slowdown 4× menghasilkan FCP `336 ms`, LCP `333 ms`,
  TBT `0 ms`, CLS `0,00`, dan interaksi menu INP `69 ms`. CrUX belum memiliki
  field data untuk origin ini; hasil tersebut adalah lab/observed trace.
- Audit awal menemukan canonical relatif, tujuh kegagalan kontras pada section
  pembayaran/footer, dan Cloudflare Web Analytics auto-injection yang diblokir
  CSP. Canonical menjadi absolut, warna teks diperkuat, dan seluruh HTML/update
  sensitive response memakai `Cache-Control: no-store, no-transform` sehingga
  beacon tidak lagi diinjeksi atau mengirim RUM. Upaya menonaktifkan site RUM
  melalui API mengembalikan auth `10000` tanpa mutasi; header runtime menjadi
  boundary yang telah diverifikasi dan runbook melarang penghapusannya tanpa
  keputusan consent/CSP baru.
- Lighthouse final production lulus `53/53` pada desktop dan mobile:
  Accessibility `100`, Best Practices `100`, SEO `100`, dan Agentic Browsing
  `100`. DOM snapshot memiliki landmark/heading/link/image names yang terbaca,
  console tidak memiliki warning/error/issue, dan script hanya berasal dari origin
  MSC sendiri.
- Budget executable tetap lulus: bootstrap `2.607.921 / 2.750.000` byte, total JS
  `2.717.865 / 3.200.000`, bundle terbesar `1.497.886 / 1.650.000`, landing
  critical `26.133 / 64.000`, hero `282.229 / 350.000`, dan `50 / 60` berkas JS.
- Verification: focused Vitest `18 passed`; full Vitest `213 passed`, `9 skipped`;
  typecheck, lint, production build, public-env scan, bundle split, performance
  budget, PWA verifier, Worker type check, serta candidate/production Wrangler
  dry-run lulus. Candidate noindex mendapat Accessibility/Best Practices `100`
  dan console bersih; SEO `69` hanya karena noindex yang disengaja.
- Deployment: candidate noindex dan production Worker berhasil. Versi production
  final `a3cf6d4a-bb12-4588-b6b3-e22e7d6f95e7`. Apex dan `/app` `200`, unknown
  navigation `404`, dan `www` tetap `308` ke apex dengan query utuh. Tidak ada
  perubahan DNS, Supabase, secret, payment, transfer, atau data pengguna.
- W08 selesai. Tidak ada pemeriksaan perangkat owner yang perlu diulang; pekerjaan
  berikutnya dapat berpindah ke W09.
