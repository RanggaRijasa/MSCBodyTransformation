# W00 feasibility and compatibility report

Date: 12 August 2026  
Status: Proven; W00 complete

## Baseline compatibility

The project is pinned to Node `22.23.2` through `.nvmrc` and `.node-version`, with package engines `>=22.13.0 <23`. All recorded web commands were run with Homebrew Node 22 on Apple silicon.

| Layer | Pinned version | Result |
| --- | ---: | --- |
| Expo | `57.0.12` | Export passed |
| React Native | `0.86.2` | Typecheck and web rendering passed |
| React / React DOM | `19.2.3` | Browser and unit tests passed |
| React Native Web | `0.21.2` | Compact and wide layouts passed |
| Expo Router | `57.0.12` | Deep link, refresh, history, and 404 tests passed |
| TypeScript | `6.0.3` | Strict typecheck passed |
| Supabase JS | `2.112.3` | PKCE adapter tests and local Storage integration passed |
| Playwright | `1.62.1` | 14 production-output checks passed |

`npx expo install --check` reported compatible versions. `npm audit --omit=dev` was reviewed and reported 23 transitive advisories (7 moderate and 16 high) under the Expo toolchain: `image-size@1.2.1` through Metro and `uuid@7.0.3` through Expo config plugins/Xcode tooling. The only automated npm remediation offered would downgrade Expo across the accepted baseline, so no forced downgrade was applied. Recheck these upstream packages before release.

## Export and hosting decision

ADR-0004 selects Expo `web.output: single`, then deterministically produces two artifacts:

- `dist/index.html`: semantic public landing page without an application JavaScript bundle;
- `dist/app.html`: Expo Router SPA shell for `/app`, nested application routes, and `/auth/callback`.

The local production server and Cloudflare Worker use the same route allowlist. Missing assets and unknown top-level or `/app/*` navigation return HTTP 404. Known application routes resolve to the SPA shell; later phases must extend the route allowlist alongside new route tests.

Evidence:

- `/`, `/app`, `/app/profile`, refresh, Back, Forward, unknown top-level and `/app/*` navigation, and missing-asset tests pass in desktop and compact Chromium projects;
- three focused tests execute the actual Cloudflare Worker handler for the two-artifact routing and 404/405 contract;
- the bundle verifier finds 12 route-split JavaScript files and rejects known unused Phosphor glyph names;
- the public landing HTML contains no Expo application script reference;
- the output scan finds no service-role or Google provider-secret marker.

## UI and PWA findings

- One shared route model renders bottom navigation below 768 px, a medium rail from 768–1199 px, and the wide class at 1200 px. Breakpoints are centralized tokens.
- The production-output matrix covers 320 px width, horizontal overflow, keyboard focus visibility, dark mode, and reduced motion.
- The compact W00 shell was inspected in Safari on an iPhone 17 Pro simulator running iOS 26.4.
- The current native Participant `participant_active` home screen was freshly built and launched on the same simulator. The web shell follows its title-first hierarchy, neutral surfaces, red primary emphasis, and bottom-navigation model without copying native pixels.
- `MSCIcon` exposes only the semantic `home`, `program`, and `profile` mappings through direct Phosphor icon imports.
- Generated PWA assets include `192`, `512`, maskable `192`/`512`, Apple touch, and favicon sizes. Source and maskable output were visually inspected: the source is square without baked rounded corners, and maskable artwork is inset inside the central safe region.
- The service worker precaches only the public shell, manifest, and offline page. It does not cache Auth, private media, API responses, mutation queues, or application bundles.

## Image pipeline

The browser adapter:

1. rejects unsupported MIME types, but permits a large valid source to be resized before enforcing the 8 MiB output limit;
2. decodes with `createImageBitmap(..., { imageOrientation: 'from-image' })`;
3. contains the image within 2048 × 2048;
4. renders to a new canvas and exports JPEG, which removes source metadata;
5. closes the decoded bitmap and returns typed Indonesian errors.

Unit tests cover source/output validation, orientation request, containment, JPEG output, metadata-isolating re-encode behavior, close behavior, and error mapping. A real browser probe creates a 3200 × 2400 JPEG with EXIF orientation 6 plus a GPS date marker, verifies upright 1536 × 2048 output, and verifies the output no longer contains the EXIF/GPS marker in desktop and compact Chromium.

## Local OAuth findings

Local Supabase Google provider configuration is present through environment-only values. The registered web callback is exactly `http://127.0.0.1:4173/auth/callback`; the provider redirect remains the local Supabase Auth callback. No provider secret is present in MSCWEB source or output.

Proven:

- PKCE client options, callback-origin/path validation, session exchange, cancellation/error mapping, one-time return-route storage, and safe internal route allowlisting pass focused tests;
- the live feasibility action reaches the real Google sign-in page with the local Supabase callback and expected application return redirect;
- Chrome Android completed signed-in Google authorization, returned through the exact `http://127.0.0.1:4173/auth/callback`, exchanged the PKCE code through local Supabase Auth, and navigated to the sanitized `/app/feasibility` return route;
- read-only aggregate local Auth checks confirmed a Google identity and a newly created session at the acceptance time. No token, browser storage, email, or user identifier was inspected or recorded.

The first consent attempt expired while awaiting user action and demonstrated Supabase's `bad_oauth_state` rejection. A fresh authorization completed immediately after consent, so the successful session handoff—not the expired attempt—is the acceptance evidence.

## QR camera matrix

| Target | Observation | W00 conclusion |
| --- | --- | --- |
| Safari, iPhone 17 Pro simulator, iOS 26.4 | The local page renders correctly. Opening the scanner returns the Indonesian `Kamera tidak tersedia` state because the simulator exposes no camera. Close remains available and no manual Coach-code field is offered. | Fallback proven; actual QR scan not proven. |
| Safari, physical iPhone 17 (`iPhone18,3`), iOS 26.6 | The production output was opened through a temporary trusted HTTPS Quick Tunnel. Safari received real camera input and decoded the deterministic test QR. The UI rendered `QR terdeteksi. Payload diteruskan ke boundary validasi tanpa ditampilkan.` while retaining the close action and showing no manual-code field or raw payload. A user-supplied 1206 × 2622 HEVC screen recording confirms the live camera frame and success state. | Actual physical Safari scan proven. |
| Chrome Android, Pixel 8 API 36/37 emulator image | Chrome Terms were accepted by the user. The local production output requested origin and Android app camera permission, opened the real camera path, and decoded a deterministic fake Coach QR delivered through the emulator's documented fixed-image back-camera source. The UI reported `QR terdeteksi` without displaying the payload. | Actual Android emulator scan proven. |
| Adapter tests | QR-only configuration, permission loading/denied/unavailable/error states, retry, and duplicate-scan suppression pass. Raw payload is never logged or rendered. | Boundary plus both target browser categories proven. |

Both required target browser/device categories are now proven. The temporary Quick Tunnel was terminated after acceptance; it created no Cloudflare project, DNS change, or production deployment.

## Private signed media

The W00 browser adapter exposes only the locally provisioned private `question-photos` bucket, requires an authenticated session, uses non-upsert upload with `cacheControl: 0`, uses no-store download, and always requests a 60-second signed URL. It does not log paths or persist signed URLs.

The adapter itself passed a focused local Supabase upload/download/signed-download integration. The existing local private-media suite also passed 16 assertions for authenticated owner/assigned-Coach/Admin authorization and unrelated-user denial.

Limitation: the 60-second duration is an adapter contract, not a server-authoritative ceiling. An authorized user who bypasses the adapter can call the Storage signing endpoint directly with a longer duration while they retain Storage `SELECT`. If maximum signed-URL lifetime becomes an authorization invariant, a later backend hardening slice must route private delivery through a narrow server operation and remove direct signing authority. W00 does not represent the client guard as server enforcement.

## Verification record

Passed:

```text
npx expo install --check
npm run typecheck
npm run lint
npm test                              # 36 passed; local-only integration skipped without env
npx vitest run tests/integration/private-media-adapter.local.test.ts  # 1 passed with local env
npm run build
npm run verify:bundle
npm run verify:pwa
npm run e2e                           # 14 tests
node supabase/tests/integration/private_media_storage.mjs  # 16 assertions
```

Also passed through XcodeBuildMCP: `build_run_sim` for scheme `MSCBodyTransformation`, Debug, iPhone 17 Pro/iOS 26.4, launch arguments `-DemoRole participant -DemoScenario participant_active -SkipDemoLanding`.

No Cloudflare deployment, hosted Supabase mutation, Git mutation, or iOS source change was performed.
