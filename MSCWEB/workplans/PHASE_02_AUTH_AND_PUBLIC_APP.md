# MSCWEB W02 — Google Auth and public app

Status: `Not started`  
Autonomy: `A` with fake/local adapters; `B` for real local Google OAuth  
Depends on: W01 exit criteria and local Supabase readiness

## Objective

Implement Guest-safe public surfaces and Google-only Supabase Auth with preserved intent, role-aware routing, and private-cache hygiene.

## Required references

- `00_PRODUCT_SPEC.md` Guest/Participant authority
- `01_ARCHITECTURE.md` authentication and routing
- `02_UX_PARITY_AND_ROUTES.md`
- `05_DATA_SECURITY.md`
- `07_TESTING_ACCEPTANCE.md`
- current iOS Guest/Login/public Participant runtime

## Deliverables

- Supabase client/auth adapter and environment validation;
- Google OAuth PKCE callback flow;
- Guest state, auth gate, preserved internal intent, logout/session expiry;
- server-controlled role/profile loader;
- public Home, program catalog/detail, leaderboard/winners, and Coach profile read models;
- RLS/grant tests proving Guest/private separation.

## Mandatory simulator gate

- [ ] Inspect Guest Home, login presentation, intended return behavior, public Program/Peringkat/Coach/Profile gates.
- [ ] Inspect loading, empty, error, and logged-in transition states.
- [ ] Record adaptive web differences, especially browser redirect/back behavior.

## Checklist

### Local backend

- [ ] Check `colima status`, `docker info`, and `supabase status`; start only when needed.
- [ ] Add local migrations/grants/RLS for public read models and protected profiles.
- [ ] Add deterministic local fixtures without production personal data.
- [ ] Generate typed DB bindings through the chosen project workflow.

### Authentication

- [ ] Environment parser allows local/production public values but rejects secret/server keys in browser config.
- [ ] Implement Google login, callback validation, internal return-route allowlist, and typed errors.
- [ ] New self-registration creates Participant authority state only.
- [ ] Load role from protected data, not editable metadata.
- [ ] Handle cancelled OAuth, provider error, expired session, cross-tab logout, and account switch.
- [ ] Purge private query/media/signed-URL cache on logout/session invalidation.

### Public experience

- [ ] Guest Home uses published/public data only.
- [ ] Program catalog/detail expose only approved fields.
- [ ] Leaderboard/winner public result excludes private weight.
- [ ] Coach public profile excludes raw QR/current private relationships.
- [ ] Personal mutation routes use centralized auth gate and return to safe intent.

## Sub-agent plan

- `msc_explorer`: map existing Supabase auth/profile/public policies and iOS Guest states.
- `msc_implementer`: sole writer for local migrations, adapter, and one UI vertical slice at a time.
- `msc_reviewer`: open-redirect, RLS negative, cache-clearing, role-authority, and UI parity review.

Migration ordering and generated types are primary-agent integration ownership.

## Verification

- local migration/RLS tests;
- unit tests for intent allowlist, role mapping, typed auth errors;
- Playwright Guest→login→return and session-expiry journeys;
- owner/account-switch cache isolation;
- compact simulator comparison and wide accessibility checks;
- production bundle secret scan.

## Exit criteria

- Real local Google login works if credentials are provided; otherwise all non-provider code is complete and the exact provider blocker is documented.
- Guest cannot query or render private account data.
- Authenticated session resolves protected role and routes correctly.
- Public surfaces match iOS product behavior with documented web adaptations.

## User input or authorization

- Local Google OAuth client/provider configuration and redirect registration for live login.
- No hosted main configuration or production credentials are authorized.

## Progress log

Append backend readiness, migrations, auth scenario, simulator evidence, commands/results, secrets check, blockers, and next item.

