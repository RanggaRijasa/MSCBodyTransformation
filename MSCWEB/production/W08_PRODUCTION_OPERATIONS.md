# W08 production operations runbook

Status: launch runbook for the MSCWEB Cloudflare Worker and hosted Supabase production project.

## Accountable roles

| Area | Accountable owner | Execution owner |
| --- | --- | --- |
| Launch approval, legal copy, payment destination, incident severity | Product owner | Product owner |
| Web build, Worker deployment, rollback, headers, cache and logs | Technical operator | Codex or appointed operator |
| Supabase migrations, functions, schedules and Storage policy | Technical operator | Codex or appointed operator |
| Payment review and correction | Admin | Assigned Admin |
| Participant evidence review | Coach operations | Assigned Coach |
| Cloudflare, Supabase, Google OAuth or OpenRouter outage | Technical operator | Platform vendor plus operator |

Never place access tokens, private media paths, OAuth credentials, payment proof, body weight, raw Coach QR values, or user email in an incident ticket or log excerpt.
Cloudflare automatic invocation logs remain disabled because they include raw URL and network metadata. Use only the custom structured `http_response` event for routine application monitoring.
Cloudflare Web Analytics/RUM is not approved for launch. HTML and update-sensitive
responses must retain `Cache-Control: no-store, no-transform` so Cloudflare cannot
auto-inject a browser beacon. Do not remove `no-transform` or allow
`static.cloudflareinsights.com` in CSP without a new product-owner consent and
privacy review.

## Deployment preflight

1. Confirm the intended Git diff and stop if unrelated files would be included.
2. Confirm `.env.production.local` and `supabase/.env.production.local` remain ignored and mode `0600`.
3. Run from `MSCWEB/`:

   ```sh
   npm run typecheck
   npm run lint
   npm test
   npm run build
   npm run verify:production-env
   npm run verify:bundle
   npm run verify:performance
   npm run verify:pwa
   npm run worker:types:check
   npm run worker:production:dry-run
   ```

4. Verify the dry-run bindings contain only `ASSETS`, `DEPLOYMENT_ENVIRONMENT`, `SUPABASE_ORIGIN`, and the configured public Supabase key. Stop if a secret or local endpoint appears.
5. Confirm the synthetic manifest uses only `@example.invalid`, `NON-BILLABLE`, and its cleanup `finally` block. Do not create a real transfer.
6. Record the current Worker version with `npx wrangler versions list` before deployment.

## Candidate and production rollout

1. Deploy and smoke the noindex candidate first with `npm run deploy:candidate`.
2. Check `/`, `/app/home`, `/login`, one published `/c/:handle`, one unknown route, `robots.txt`, manifest and service worker.
3. Confirm candidate responses enforce CSP and return `X-Robots-Tag: noindex, nofollow, noarchive`.
4. Deploy production only after candidate acceptance:

   ```sh
   npx wrangler deploy
   ```

5. Confirm apex is `200`, `www` redirects `308` to apex, app routes refresh, and unknown navigation returns `404`.
6. Confirm production responses include CSP, `nosniff`, strict referrer policy, denied framing, permissions policy, one UUID `X-Request-ID`, and `Strict-Transport-Security: max-age=31536000; includeSubDomains`.
7. Do not add the HSTS `preload` directive until every current and future subdomain has an explicit HTTPS ownership review.

## Rollback and cache

1. Freeze new deploys and record the failing `X-Request-ID`, UTC timestamp, route group and HTTP status only.
2. List versions with `npx wrangler versions list` and roll back to the last accepted version with `npx wrangler rollback VERSION_ID`.
3. Repeat the apex, `www`, app refresh, published Coach and `404` probes.
4. Normal rollback needs no manual asset purge: immutable assets are content hashed, while HTML, app shell, service worker, manifest and error responses use `no-store`.
5. Use a Cloudflare zone purge only for a confirmed cache-policy defect. Record scope and reason; avoid “purge everything” when a specific URL is sufficient.
6. Revoked or replaced private media must be invalidated at the authorization/source record first. Never rely on browser or CDN purge as the authorization boundary.

## Environment validation and secret rotation

1. Public browser variables are limited to Supabase URL, publishable key and OAuth redirect URL.
2. Server-only secrets remain in Supabase Function secrets or the reviewed Vault-backed schedule path. Never copy values into Worker variables, source, fixtures or chat.
3. Rotate one secret at a time. Update the target platform, run a synthetic non-billable probe, then revoke the previous value.
4. For a job secret, verify both the schedule and Edge Function before revocation. For `FOOD_AI_API_KEY`, verify an AI-enabled synthetic photo path and confirm disabled insight questions make no provider call.
5. After rotation, run `npm run verify:production-env` and inspect redacted logs for status and correlation ID only.

## Incident checklist

1. Classify: Sev-1 privacy/auth/payment authorization; Sev-2 login, enrollment, program or upload outage; Sev-3 degraded AI, display or performance.
2. Contain: disable the affected feature or roll back. Do not delete production records during triage.
3. Preserve only redacted evidence: UTC time, deployment version, safe route group, status, correlation ID and vendor incident reference.
4. Verify whether private media, payment state, points or role authorization were affected.
5. Communicate user impact in Bahasa Indonesia without raw backend errors or personal data.
6. Recover with the smallest reviewed change, run smoke tests and monitor error-rate recovery.
7. Document cause, affected window, remediation and follow-up owner. Rotate secrets if exposure is plausible.

## W08 blocker matrix

| Gate | State | Accountable owner | Evidence or next action |
| --- | --- | --- | --- |
| Physical iPhone and Android PWA flows | Accepted | Product owner | Owner completed install, icon, offline, QR, media picker, keyboard, rotation, Back and logout/login checks. |
| Security headers and HSTS | Verified in production | Technical operator | Live apex/app/404 responses return the complete policy, UUID request ID and one-year HSTS without preload. |
| Private media lazy/full view | Verified locally | Technical operator | Signed media is requested only after explicit Coach action; compact image can expand; video loads metadata only after authorization. |
| Browser and accessibility matrix | Verified automatically plus owner device evidence | Technical operator | Chromium desktop/compact, Edge profile and WebKit desktop; semantic landmarks, keyboard, 200% zoom, reduced motion and forced colors. |
| Redacted observability | Verified in production | Technical operator | Safe route group, method, status, environment and UUID correlation ID only; automatic raw invocation logging disabled. |
| Deployment and incident operations | Ready | Technical operator | This runbook. |
| Lighthouse/Web Vitals trace | Verified in production | Technical operator | Desktop/mobile Lighthouse 53/53 with Accessibility, Best Practices and SEO 100; desktop LCP 123 ms/CLS 0,00; Fast 4G + CPU 4× mobile FCP 336 ms, LCP 333 ms, TBT 0 ms, CLS 0,00 and menu INP 69 ms. |
| Legacy iOS-only operations | Not a W08 web launch blocker | Product owner | Native iOS work is discontinued; archive/disable legacy-only automation during its dedicated retirement task. |

W08 is formally complete. No product-owner device check needs to be repeated.
