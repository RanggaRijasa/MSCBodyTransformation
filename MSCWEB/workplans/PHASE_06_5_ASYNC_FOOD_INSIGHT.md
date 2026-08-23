# MSCWEB W06.5 — Async food insight and AI star rating

Status: `Completed`  
Autonomy: `A` with deterministic local/fake provider; `B` for a real OpenRouter smoke key; `D` for production secret/deployment  
Depends on: W04 submission/scoring authority and W06 Coach review/profile foundation

## Objective

Add asynchronous food-photo analysis that estimates macro values, writes supportive 1–5 star feedback, and never blocks or changes submission, Coach approval, or authoritative points. Keep the provider replaceable through a narrow server-side adapter.

## Required references

- `00_PRODUCT_SPEC.md` `PROD-AI-*`
- `01_ARCHITECTURE.md` food vision boundary
- `02_UX_PARITY_AND_ROUTES.md` insight states
- `03_DESIGN_SYSTEM.md` `FoodInsightCard` and Phosphor stars
- `05_DATA_SECURITY.md` AI minimization and job/result data
- `07_TESTING_ACCEPTANCE.md` `QA-AI-*`, `QA-JRN-010`, and `QA-JRN-011`
- [`ADR-0006`](../decisions/0006-async-food-insight-and-ai-rating.md)
- current iOS evidence review/rating runtime for the behavior being replaced

## Deliverables

- question-level `food` analysis configuration;
- durable/idempotent analysis job and result contract in local Supabase;
- server-side `FoodVisionProvider` plus OpenRouter/OpenAI-compatible adapter dengan default `google/gemma-4-31b-it:free`;
- schema/range/favorable-rating validator;
- Participant and Coach insight UI with pending/available/unavailable/error states;
- required audited correction operation plus secondary Coach correction path for clearly incorrect rating; W07 adds the Admin UI;
- provider contract, privacy, concurrency, failure, calibration, component, and E2E tests;
- environment examples containing names/placeholders only, never a real API key.

## Mandatory simulator gate

- [x] Launch the current iOS Participant photo-submission and Coach evidence detail/rating flows.
- [x] Record where manual stars appear, state order, labels, and whether rating changes approval/poin in the native prototype.
- [x] Record the intentional web divergence: AI replaces routine manual star entry while approval and points keep their existing authority paths.

## Checklist

### Contract and migration

- [x] Add explicit analysis mode only to eligible photo questions; default remains `none`.
- [x] Add one durable job/result per `submission_id + analysis_version`, status transitions, attempts, retry schedule, and typed terminal errors.
- [x] Best-effort enqueue only after a valid submission commit; enqueue failure cannot roll back submission/poin.
- [x] Add an idempotent reconciliation scan that finds every eligible committed submission without its analysis-version job and creates the missing job.
- [x] Store only validated result/version metadata, never raw provider request/response.
- [x] RLS allows Participant owner, assigned Coach, and authorized Admin scope only; Guest and unrelated Coach denied.

### Provider boundary

- [x] Define `FoodVisionProvider` in server/domain boundary without provider SDK types.
- [x] Implement OpenRouter through `fetch` using server-only `FOOD_AI_PROVIDER`, `BASE_URL`, `API_KEY`, `MODEL`, and version config.
- [x] Read prioritized OpenRouter slugs from `FOOD_AI_MODELS`, with `FOOD_AI_MODEL` as single-model compatibility fallback; changing compatible models requires environment change and restart/redeploy, not feature/domain edits.
- [x] Omit the optional reasoning parameter so every configured fallback remains compatible; never store/forward reasoning content that a provider may still return.
- [x] Add preflight/health validation for image input, text output, structured response, and optional/off reasoning; incompatible model fails only the secondary insight job.
- [x] Keep actual key out of repository, browser bundle, logs, fixtures, screenshots, and local committed env files.
- [x] Prove another fake OpenAI-compatible provider works by environment/config change only.
- [x] Document that noncompatible endpoint/schema needs a new adapter; do not claim universal API-key-only portability.

### Result and favorable rating

- [x] Validate `food | drink | shake | not_food | uncertain`, optional macro values, 1–5 rating, confidence, allowlisted reason, and concise Indonesian insight.
- [x] Prompt/schema requires `insightSentences` with one or two complete Bahasa Indonesia sentences, each at most 80 characters and at most 160 characters combined.
- [x] Reject or replace overlong/non-Indonesian insight with a deterministic Indonesian fallback instead of truncating or exposing raw provider text.
- [x] Derive rating from image classification only: food/drink/shake `4`, uncertain `3`, and not-food `1`; model-supplied rating/reason is not accepted.
- [x] Use server-owned versioned policy `food_rating_policy_v2_image_only` and output policy `food_insight_output_v2_image_only`.
- [x] Normalize every detected shake/protein shake to the approved estimate: protein `10 g`, carbohydrate `3 g`, fat `1 g`, and energy `100 kkal`.
- [x] Reject provider copy that compares the image with a question, step, task, program, guide, rubric, target, or need.
- [x] Never infer discipline, character, body shape, diagnosis, allergens, spoilage, or food safety from the image.
- [x] Keep AI/corrected rating separate from step points, approval state, and leaderboard ledger.

### Privacy-minimal flow

- [x] Reuse W04 orientation/resize/metadata-removal pipeline before provider delivery.
- [x] Send image bytes only; do not send question/step/program/rubric content, identifiers, identity, weight, free-form profile data, object path, or signed URL.
- [x] Show one disclosure before food-photo submission and ask users to avoid faces/documents; no separate consent checkbox.
- [x] Follow existing submission retention/deletion lifecycle; no separate ZDR/DPIA/withdrawal feature is required for baseline.
- [x] Reassess provider terms/data-use before production or when provider changes materially.

### UI and operations

- [x] Submission/poin state renders before AI and never shows a blocking AI spinner.
- [x] `FoodInsightCard` handles pending, result, not-food/uncertain, retry-safe failure, and unavailable states.
- [x] Macro uses `Perkiraan dari foto`; rating uses Phosphor `Star` plus accessible `n dari 5 bintang`.
- [x] Coach has no star input in normal review; correction is a secondary action for assigned Coach, reason-required, and audited. W06.5 owns the operation/Coach path; W07 adds equivalent authorized Admin UI.
- [x] Provider outage/rate-limit/invalid output has no effect on upload, approval, points, or other Coach actions.

## Sub-agent plan

- `msc_explorer`: map current iOS rating UI, W04 authority path, and existing Supabase submission events without editing.
- `msc_implementer`: sole writer, sequentially migration/job → adapter/validator → UI/tests.
- `msc_reviewer`: provider-secret boundary, payload minimization, RLS, idempotency, favorable-rating calibration, point independence, accessibility, and failure states.

The primary agent owns schema/authority decisions, provider interface, prompt/rubric versioning, and final calibration acceptance.

## Verification

- unit/property/table tests for image-only schema/ranges, contextual-copy rejection, deterministic kind/rating mapping, and shake normalization;
- crash-between-commit-and-enqueue recovery test proving reconciliation creates exactly one missing job;
- provider contract tests with deterministic food/drink/shake/not-food/ambiguous/invalid fixtures;
- language-contract tests for Indonesian output, mixed-language output, English-only output, and deterministic Indonesian fallback;
- request-shape test proving model comes from environment, reasoning effort is `none`, and output-token cap is applied;
- model-swap test proving a second compatible OpenRouter slug needs configuration change only, plus incompatible-model safe failure;
- local Supabase job idempotency/retry/RLS/concurrent correction tests;
- `QA-JRN-010`, `QA-JRN-011`, and all `QA-AI-*` checks;
- Playwright pending → result and provider-failure journeys on compact/wide;
- bundle/log/env scan proving no provider credential or private media reference;
- optional real OpenRouter smoke only with a user-provided secret and a synthetic/non-user fixture.

## Exit criteria

- Eligible food submissions receive asynchronous macro/rating feedback locally.
- Submission, approval, points, and leaderboard are independent of AI latency/failure.
- Rating/reason cannot be supplied by the provider and is derived from image classification only.
- Browser/private logs contain no provider key or raw private media reference.
- Provider contract can switch between OpenAI-compatible adapters via environment without feature/domain changes.

## User input or authorization

- No user input is required for implementation/testing with deterministic fake provider fixtures.
- A real OpenRouter API key is optional for smoke testing and must be supplied as a runtime secret, never pasted into tracked files or chat output.
- Hosted Supabase function/migration deployment and production provider secret each require explicit authorization in W09.

## Progress log

Append simulator evidence, migration/job versions, provider/model alias, prompt/rubric version, rating distribution fixtures, privacy/security tests, commands/results, external authorizations, and next item.

### 2026-08-14 — W06.5 completed locally

- Files: added migration `20260814122036_w06_5_async_food_insight.sql`, server provider/contracts/validator, local Edge Function worker, browser repository/query/card, Participant disclosure/enqueue wiring, Coach correction wiring, generated-type additions, and focused unit/integration/E2E coverage.
- Simulator evidence: built and launched the current native iOS app on iPhone 17 Simulator. Participant photo submission presents the native camera/library actions before sending. Coach evidence detail places manual 1–5 stars after the submitted evidence; approval/rejection and authoritative points remain separate actions. Intentional web divergence: routine manual stars are removed from normal Coach review, AI supplies the secondary rating, and approval/points keep their existing server-owned paths. No native source or Xcode project file was changed.
- Contract versions: analysis `food_insight_v1`; rating policy `food_rating_policy_v1`; output policy `food_insight_output_v1`; eligible rubric fixture `rubric_food_v1`; migration timestamp `20260814122036`.
- Provider boundary: deterministic local provider alias `deterministic-food-fixture-v1`; OpenAI-compatible adapter defaults to `google/gemma-4-31b-it:free` only when explicitly configured. Provider, base URL, key, model, and worker secret remain server-only environment values. Noncompatible endpoint/schema requires a new adapter.
- Rating fixtures: plausible food `4`, drink `4`, strong-rubric shake `5`, explicit-rubric/high-confidence not-food `1`, ambiguous `3`, and invalid/English/unsafe copy rejected or replaced with deterministic Indonesian fallback. Boundary tests cover confidence `0.89/0.90`, both severe reasons, missing rubric, mismatched kind/reason, unknown reason, invalid ranges, HTTP 429/503, and malformed JSON.
- Privacy and authority evidence: W04 normalization runs before upload; worker sends downloaded bytes plus the minimum rubric only. Local RLS proves Participant owner, assigned Coach, and authorized Admin access while Guest, unrelated Participant, and unrelated Coach are denied. Reconciliation creates exactly one versioned job after missed enqueue; non-food photos create zero jobs. Automatic points are awarded before AI, remain unchanged after result/correction/retry, and correction is reason-required, audited, optimistic-concurrency-safe, and idempotent.
- Commands passed: `npm run typecheck`; `npm run lint -- --no-cache`; `npm test` (`128` passed, `6` environment-skipped); explicit local `food-insight.local.test.ts` (`1` passed); `npm run build`; `npm run verify:bundle`; `npm run verify:pwa`; Playwright evidence review on `chromium-compact` and `chromium-desktop` (`4` passed). Browser inspection found no console warning/error; final bundles contain no provider credential marker or concrete private-media object path.
- Local-only operation: the migration was applied to Supabase local and Colima/Supabase were left running. No real OpenRouter key, real-provider smoke, hosted Supabase deployment, production secret mutation, Git mutation, or native project change was performed. Real-provider smoke remains optional; hosted migration/function/secret deployment remains W09 authorization work.
- Remaining W06.5 blockers: none. Next phase item: W07 Admin experience, including the authorized Admin correction UI over the W06.5 operation.

### 2026-08-23 — Image-only policy v2 deployed

- Files: updated the root-authority `process-food-insight` provider boundary, contracts, validator, worker, focused unit/integration tests, and added migration `20260823093724_food_insight_image_only_policy.sql`.
- Privacy contract: `claim_food_insight_job` no longer returns submission/question/program/rubric identifiers or rubric text. The OpenRouter request receives one generic image-only instruction plus normalized JPEG bytes; it never receives the question, step, task, program, rubric, profile, weight, or private object path.
- Output policy: model rating and reason fields were removed from the strict JSON schema. Server policy derives rating/reason from the detected image kind and replaces any contextual provider sentence with deterministic image-only Bahasa Indonesia copy.
- Shake policy: every `shake` classification is normalized after provider validation to `10 g` protein, `3 g` carbohydrate, `1 g` fat, and `100 kkal`, independent of the model's macro estimate.
- Verification passed: focused food insight tests (`34`), explicit local Supabase integration (`1`), full unit suite (`201` passed, `9` environment-skipped), `npm run typecheck`, `npm run lint -- --no-cache`, and `supabase db lint --local --level warning` with zero schema errors.
- Production: migration `20260823093724` is present locally and remotely; Edge Function `process-food-insight` is `ACTIVE`, version `5`, deployment id `df357ba3-4267-4c16-b555-a17fe19d35f5`. No secrets changed and no existing production photo/job was invoked or reprocessed.
- Remaining note: an already stored v1 result keeps its historical text and estimates until a separately authorized re-analysis or replacement flow is performed. New jobs use image-only policy v2.
