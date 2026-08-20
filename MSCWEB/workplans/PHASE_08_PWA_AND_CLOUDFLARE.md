# MSCWEB W08 — PWA, Cloudflare, and production hardening

Status: `Not started`  
Autonomy: `A` local, `B` physical-device checks, `D` external preview/production changes  
Depends on: W01–W07.6 capability completion, including W06.5, Sales Overview, and Image Storage

## Objective

Harden MSCWEB as an installable, secure, accessible, performant PWA; prepare Cloudflare deployment configuration and runbooks without mutating production unless separately authorized.

## Required references

- `06_PWA_HOSTING.md`
- `07_TESTING_ACCEPTANCE.md`
- `03_DESIGN_SYSTEM.md` app icon/accessibility/motion
- `05_DATA_SECURITY.md`
- current official Expo/Cloudflare/Supabase browser guidance

## Deliverables

- final manifest/icons/install guidance;
- service-worker cache/update/offline behavior;
- Cloudflare Workers Static Assets config and SPA routing;
- canonical/Open Graph/social-preview delivery for `/c/:handle` without leaking hidden profile data;
- CSP/security headers and permissions policy;
- code splitting/image/bundle performance compliance;
- browser/device/accessibility matrix evidence;
- privacy-redacted observability interface;
- deployment, rollback, cache, incident, and secret runbooks.

## Checklist

### PWA/install/offline

- [ ] Manifest name/scope/start/theme/icons validated.
- [ ] Maskable safe zone and Apple touch rendering checked.
- [ ] Browser remains fully usable without installation.
- [ ] iOS Add to Home Screen guidance and supported install affordance.
- [ ] Public shell/assets only in precache; private API/media never precached.
- [ ] Sales responses and Image Storage inventory/thumbnail/Trash responses never enter service-worker/shared caches.
- [ ] Offline state is truthful and server mutations are disabled, not queued silently.
- [ ] Safe service-worker update/reload behavior and account-cache cleanup.

### Cloudflare configuration

- [ ] Workers Static Assets directory and SPA `not_found_handling` verified locally/dry run.
- [ ] Hashed asset vs HTML/manifest/service-worker cache policies.
- [ ] Canonical/404/robots/preview noindex behavior.
- [ ] `/c/:handle` refresh and share crawler resolve the correct published Coach; unpublished/expired/unknown handles return safe not-found metadata.
- [ ] Per-handle title/description/image use only the public profile read model; published phone/WhatsApp may render only in profile body, while every hidden contact, raw QR, auth ID, private media, phone, and WhatsApp stay out of Open Graph/SEO metadata.
- [ ] Canonical URL strips tracking query parameters while ordinary browser navigation may retain them for attribution handling.
- [ ] Cache invalidation covers profile publish/edit/moderation/entitlement expiry without caching a private draft as public.
- [ ] Environment validation and no secret/service-role in output.
- [ ] CSP report-only test, then local/preview enforcement plan.
- [ ] With separate external authorization, deploy an isolated noindex preview and validate report-only CSP against real Cloudflare routing, Supabase Auth/Storage/Realtime endpoints, OAuth redirect, media, and service worker.
- [ ] Enforce candidate CSP on preview and show no unexpected violations before W08 exit, or obtain an explicit documented production-blocking waiver.
- [ ] `nosniff`, Referrer, frame-ancestors, Permissions-Policy, and HSTS rollout plan.

### Performance/accessibility/devices

- [ ] Route-level chunking keeps Admin/Coach out of public landing initial bundle.
- [ ] AI provider code/key remains server-only and is absent from public/Coach/Admin route chunks.
- [ ] Image thumbnail/lazy/full-resolution authorization behavior.
- [ ] Purged/detached public Coach media is no longer served after documented CDN/browser invalidation window; stale direct URLs fail safely.
- [ ] Lighthouse/Web Vitals/bundle budgets.
- [ ] Safari iOS current/previous, installed iOS PWA, Chrome Android, desktop Chrome/Safari/Edge.
- [ ] Camera QR, picker, safe area, virtual keyboard, browser Back, rotation, and standalone external links.
- [ ] Keyboard/screen reader/200% zoom/reduced motion/transparency/increased contrast.

### Observability/runbooks

- [ ] Redacted event/error contract and correlation IDs; no sensitive payload.
- [ ] Deployment/rollback/cache purge/environment/secret rotation/incident checklist.
- [ ] Production blockers matrix updated with accountable owner.

## Sub-agent plan

- `msc_explorer`: current platform docs and browser limitation audit; read-only.
- `msc_implementer`: sole writer for service worker/config/header/performance fixes sequentially.
- `msc_reviewer`: security headers/cache privacy/secret scan/performance/accessibility/device evidence.

Do not let sub-agents deploy, change DNS, configure credentials, or accept budget waivers.

## Verification

- production export and Cloudflare-compatible local serve;
- manifest/installability/icon audit;
- offline/private-cache/account-switch suite;
- sales/private inventory cache isolation and public-media purge invalidation suite;
- CSP and security-header checks;
- Lighthouse/Web Vitals/bundle analyzer;
- full Playwright matrix plus physical-device manual record;
- social crawler/canonical/cache tests for minimum/full/unpublished/expired Coach profiles;
- dependency and secret scans.

## Exit criteria

- Local production candidate passes release gates or has explicit accepted waivers.
- An authorized preview has validated real routing/OAuth/Supabase endpoints under enforced candidate CSP, or an explicit waiver records the unverified production risk and blocks rollout until resolved.
- Private data is absent from service worker/shared caches and logs.
- Physical-device critical flows are recorded.
- Cloudflare config/runbooks are ready but no external mutation is implied.

## User input or authorization

- Physical devices or assistance for device-only checks.
- Monitoring vendor/consent decision if observability will leave the app.
- Cloudflare preview deploy is a required external authorization for the CSP/real-routing gate unless the user explicitly records a waiver. Domain/DNS, secrets, and production deploy each require separate authorization.

## Progress log

Append platform/version, device/browser evidence, budgets, cache/security results, external authorizations, files/commands, and next item.
