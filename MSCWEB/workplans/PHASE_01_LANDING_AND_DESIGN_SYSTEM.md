# MSCWEB W01 — Landing, design system, and app shell

Status: `Complete`
Autonomy: `A` for implementation; `C` for final visual/brand approval
Depends on: W00 exit criteria

## Objective

Turn the approved visual direction and iOS product language into a production-quality responsive landing page, reusable design system, and role-ready application shell.

## Required references

- `00_PRODUCT_SPEC.md`
- `02_UX_PARITY_AND_ROUTES.md`
- `03_DESIGN_SYSTEM.md`
- `06_PWA_HOSTING.md`
- `references/landing/README.md` and both concept PNGs
- iOS `UI_REFERENCE_SHEET.md` and current Guest/Participant simulator flows

## Deliverables

- semantic responsive landing page;
- light/dark design tokens and theme provider;
- typography, spacing, radius, motion, focus, elevation, and breakpoint primitives;
- `MSCIcon` semantic registry using Phosphor SVG;
- shared controls, state components, bottom tabs, rail/sidebar, sheets/dialogs;
- Guest/Participant/Coach/Admin shell routes without feature data;
- manifest metadata/icon links and legal/support shells;
- visual regression baselines.

## Mandatory simulator gate

- [x] Launch current iOS Guest Home and Login in `id-ID`.
- [x] Inspect current Participant compact tab bar/header/card rhythm and light/dark states.
- [x] Record screens, device, OS, scenario, and differences before web UI implementation.
- [x] Do not copy generated mobile product UI from the ImageGen mockup when it conflicts with the simulator.

## Checklist

### Design foundation

- [x] Implement primitive, semantic, and component tokens from the spec.
- [x] Implement system typography with tabular numerals and `id-ID` formatting helpers.
- [x] Implement reduced motion/transparency and increased-contrast behavior.
- [x] Implement responsive gutters/max widths and safe-area helpers.
- [x] Implement `MSCIcon`; prohibit direct feature imports from Phosphor.

### Shared UI

- [x] Buttons, icon button, fields, segmented control, cards, badges, progress, avatar fallback.
- [x] Loading, empty, error, offline, forbidden, and session-expired states.
- [x] Sheet/dialog/toast with focus management and Escape/back behavior.
- [x] Bottom navigation compact and rail/sidebar medium/wide.
- [x] Keyboard, pointer, coarse-touch, 200% zoom, and screen-reader semantics.

### Landing implementation

- [x] Header, hero, CTA, Cara kerja, program section, Coach support, manual-payment explanation, install section, footer.
- [x] Use generated concepts for composition/quality only; use approved copy/data/icons/assets.
- [x] Keep core landing copy readable without client JavaScript.
- [x] Add SEO/canonical/Open Graph/favicon/theme metadata.
- [x] Approve the separately generated production-candidate photography, or replace it with licensed/approved assets.

### App shells

- [x] Guest/Participant destinations: Beranda, Program, Peringkat, Coach, Profil.
- [x] Coach destinations: Dashboard, Program, Profil.
- [x] Admin destinations: Dashboard, Program, Orang, Konten, Pengaturan.
- [x] Route state, browser Back/Forward, deep link shell, and tab restoration tests.

## Sub-agent plan

- `msc_explorer`: current simulator UI audit and source-to-web parity notes; read-only.
- `msc_implementer`: sole writer for tokens/components/landing in sequential slices.
- `msc_reviewer`: visual quality, responsive/accessibility, direct-Phosphor import, and simulator-parity review.

Shared tokens, route root, and icon registry remain primary-agent owned integration points.

## Verification

- typecheck/lint/unit/component/production export;
- Playwright at 320/375/390/430/768/1024/1440;
- light/dark/reduced-motion/200%-zoom snapshots;
- keyboard-only landing and shell navigation;
- bundle check for full icon pack and feature chunk leakage;
- side-by-side compact comparison with current iOS simulator.

## Exit criteria

- Landing meets spec, reference quality bar, responsive and accessibility gates.
- All role shells navigate correctly without private fixture leakage.
- Design primitives are documented and reused; no Tailwind/NativeWind/div icons.
- Local PWA manifest/icon links resolve.
- User has reviewed the rendered v1; final visual sign-off may be a named checkpoint before production polish.
- The safe repository-split criteria from `08_DELIVERY_PLAN.md` are evaluated, and the user explicitly chooses either `split after W01` or `defer split to W09` before W02 begins.

## User input or authorization

- Final visual approval and any requested creative changes.
- Approved production photography/Coach identity and final legal/support copy may be deferred with explicit placeholders.
- Repository checkpoint decision: authorize a split after W01 or explicitly defer it. Exact Git/repository operations still require their own later authorization.
- iOS Simulator inspection is already authorized.

## Progress log

Append dated entries with simulator evidence, reference comparison, files, commands/results, accessibility status, user decision, and next item.

### 2026-08-12 — W01 implementation and verification

- Requirement IDs: `UX-002`, `UX-003`, `UX-NAV-001`–`003`, `UX-RSP-001`, `UX-RSP-002`, `UX-RSP-005`; `DS-001`–`005`, `DS-TKN-001`–`003`, `DS-TYPE-001`–`005`, `DS-ICO-001`–`007`, `DS-CMP-001`–`005`, `DS-MOT-001`–`005`, `DS-GLS-001`–`004`, `DS-APPICON-001`–`005`; `PWA-HST-003`, `PWA-MAN-001`–`005`, `PWA-INS-001`, `PWA-INS-004`, `PWA-INS-005`, `PWA-LND-001`–`005`, `PWA-PERF-002`, `PWA-PERF-003`.
- Simulator evidence: iPhone 17 Pro, iOS 26.4, `id-ID`; Guest Home light, Login light, Participant Home dark. Durable captures and parity notes are under `references/simulator/w01/`.
- Reference comparison: kept the approved concept's black/white section rhythm, red primary CTA, yellow accents, and editorial gym imagery; removed invented program names, participant counts, named Coach/chat identity, phone mockups, and fake progress metrics. The shell follows native hierarchy/navigation while remaining browser-native.
- Files: landing/static legal shells and generated-image provenance under `public/`; design tokens/theme/formatters/icons/shared primitives under `src/shared/`; role shell routes under `src/app/app`, `src/app/coach`, and `src/app/admin`; route handlers, tests, visual baselines, PWA icon source/provenance, and this workplan.
- Assumptions: legal/support content remains an explicit local placeholder; generated landing photography represents no real Coach or result and still requires user visual approval; no private fixtures are allowed in role shells.
- Native build: `xcodebuild -project MSCBodyTransformation.xcodeproj -scheme MSCBodyTransformation -destination 'platform=iOS Simulator,id=0EA61A6F-1BC3-4AB0-8DE5-AA8FDDBE7136' -derivedDataPath /private/tmp/mscweb-w01-derived build` — passed. No Xcode project or native source changed.
- Web checks: `npm run typecheck` — passed; `npm run lint` — passed; `npm test -- --run` — 43 passed, 1 environment-skipped; `npm run build` — passed with 24 web JavaScript bundles; `npm run verify:bundle` — passed; `npm run verify:pwa` — passed; `npm run e2e` — 30 passed across desktop and compact Chromium; `git diff --check` — clean.
- Accessibility evidence: semantic no-JS landing; keyboard skip link; focus-visible; exact route navigation labels with `aria-current`; 320–1440 px overflow matrix; 200% zoom; dark/reduced-motion checks; neutral avatar and explicit empty/privacy states. In-app browser QA found no console errors at 390 or 1440 px.
- Split evaluation: standalone source-copy dry run under `/private/tmp/mscweb-split-dry-run.X9EF2m` passed typecheck, 43 tests, export, bundle, and PWA verification while reusing the already installed dependency folder. App icon/photography provenance, specs, ADRs, environment example, commands, and lockfile are contained in `MSCWEB`; migration authority remains the parent repository during transition.
- Sub-agents: none used; implementation and review were completed sequentially in the primary task.
- Manual inputs remaining: user visual sign-off on rendered v1 and explicit `split after W01` or `defer split to W09` decision. Final legal/support copy and any real Coach identity remain future production inputs.
- Next unchecked item: the two user-owned W01 checkpoints above; W02 must not start until both are recorded.

### 2026-08-12 — User sign-off, bold palette, and install CTA revision

- User decision: visual v1 and generated production-candidate photography approved. Repository split explicitly deferred to W09; migration authority remains in the parent repository.
- Requested revision: landing and PWA webapp now use solid, high-contrast black/red/yellow fields instead of softened neutral accents. Brand primitives are locked to red `#D71920`, yellow `#FFD400`, and true black/white; selected app navigation uses a full red surface with white icon/label.
- CTA contract: hero primary action changed from `Mulai program` to `Unduh aplikasi` and routes to `/cara-memasang`. `Masuk` remains the application entry and `Lihat program` remains the public catalog entry. The install page explains Safari and Chrome installation because a PWA is installed through browser/platform UI rather than a universal downloadable package.
- Cache correction: landing/legal stylesheet references include a version query so the new palette is not masked by the existing one-hour static asset cache.
- Files: `public/landing.html`, `public/landing.css`, manifest/static/legal/offline metadata, `src/global.css`, design tokens, app-shell selected navigation, unit/E2E tests, visual baselines, and this workplan.
- Checks: `npm run typecheck` — passed; `npm run lint` — passed; `npm test -- --run` — 45 passed, 1 environment-skipped; `npm run build` — passed with 24 JavaScript bundles; `npm run verify:bundle` — passed; `npm run verify:pwa` — passed; final `npm run e2e` — 34 passed across desktop and compact Chromium.
- Browser evidence: in-app browser verified `/` identity, bold computed colors, no overflow/errors, and `Unduh aplikasi` → `/cara-memasang`. It could not retain a compact viewport across the React Native Web app-route tab refresh, so the compact `/app/home` screenshot was captured with the already configured Playwright Chromium workflow; route semantics and color assertions still passed in both E2E projects.
- Final comparison: concepts and latest 1440/390 browser renders were inspected together. Preserved composition, imagery, type hierarchy, section order, and responsive flow; intentional deviations are the user-requested install CTA and stronger solid color bands. No material visual mismatch remains.
- Manual Xcode step: none. No native project/source, deployment, production Supabase, or Git mutation performed.
- Next unchecked item: W02 Auth and public Participant shell.

### 2026-08-12 — Progressive install, marketing program story, and compact navigation

- User revision: compact app navigation now explicitly stacks each icon over its label. The 320 px render shows all five Participant destinations without horizontal overflow or overlapping labels.
- Install behavior: `Unduh aplikasi` and `Pasang aplikasi` capture the Chromium `beforeinstallprompt` event only after a user click. Browsers without that event—including Safari iPhone—continue to `/cara-memasang` for platform-specific guidance; the landing remains fully usable without installation. This advances `PWA-INS-002`/`003`, while the final cross-browser and physical-device install matrix remains assigned to W08.
- Program story: removed the mock `Diikuti`/`Tersedia`/`Riwayat` preview and `Lihat semua program` link from the landing section. Replaced them with approved, non-diagnostic marketing copy explaining clear goals, structured steps, and connected Coach support; the separate hero `Lihat program` canonical entry remains.
- Files: `public/landing.html`, `public/landing.css`, new `public/install-pwa.js`, `src/shared/navigation/AppShell.tsx`, landing unit/E2E tests, refreshed 1440/390 visual baselines, and this workplan.
- Checks: `npm run typecheck` — passed; `npm run lint` — passed; `npm test -- --run` — 46 passed, 1 environment-skipped; `npm run build` — passed with 25 JavaScript files; `npm run verify:bundle` — passed; `npm run verify:pwa` — passed; `npm run e2e` — 36 passed across desktop and compact Chromium; `git diff --check` for the revised files — clean.
- Browser evidence: in-app browser verified the 1440 and 390 landing, the new marketing section, the non-support fallback to `/cara-memasang`, 320 px stacked navigation, zero horizontal overflow, and no console warnings/errors. Playwright additionally injected the supported Chromium install event and proved one native-prompt call without navigation.
- Visual comparison: accepted desktop/mobile concept and refreshed 1440/390 renders were inspected together. Hero rhythm, bold palette, editorial photography, section alternation, typography, and install emphasis remain coherent; removing the invented program catalog is an intentional user-approved deviation.
- Manual Xcode step: none. No native source/project, deployment, production Supabase, package manifest, or Git operation changed.
- Next unchecked item: W02 Auth and public Participant shell; final real-browser PWA install/device matrix remains W08.
