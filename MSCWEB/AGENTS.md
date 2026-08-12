# MSCWEB agent instructions

These instructions apply to all files under `MSCWEB/` and refine the repository-level `AGENTS.md` for the web/PWA project.

## Required reading

Before changing MSCWEB implementation:

1. Read `MSCWEB/README.md`.
2. Read the relevant product/architecture spec files.
3. Read `MSCWEB/workplans/README.md` and the single active phase file.
4. Inspect nearby implementation and tests.
5. For every compact/mobile UI slice, inspect the corresponding iOS source and build/launch the current iOS app in Simulator for the exact role, screen, and state. Existing audit screenshots never replace this fresh runtime check.

The user has explicitly authorized non-destructive iOS Simulator build, launch, navigation, screenshot, and UI inspection for MSCWEB parity work. Do not ask again for that in-scope inspection. Log device, OS, scenario/role, screens, and states for every applicable slice. Never modify iOS source as part of a web phase unless the user separately requests it.

## Web phase authority

The web phases are defined in `MSCWEB/workplans/`. iOS phase numbering and the iOS-only rule that defers Supabase until later native phases do not block the web phases. MSCWEB may integrate Supabase only at the web phase specified by its workplan and only against local Supabase until production authorization is given.

## Approved baseline dependencies

The user has approved the architectural stack recorded in `01_ARCHITECTURE.md`, including Expo, React Native Web, Expo Router, React Native StyleSheet/tokens, Phosphor SVG, Supabase, TanStack Query, React Hook Form/Zod, Reanimated, Gesture Handler, and the listed testing/PWA tooling. Before Phase W00 modifies `package.json`/lockfiles or installs these packages, obtain one explicit implementation/install authorization from the user. Lock compatible versions after that authorization. Any dependency outside this baseline requires a new ADR and separate explicit approval.

## Sub-agent orchestration

Sub-agent delegation is authorized for independent, bounded work in these workplans.

- Project defaults are `gpt-5.6-sol` with `high` reasoning.
- Maximum spawned concurrency is three sub-agents in addition to the primary agent.
- Prefer `msc_explorer` for read-only mapping and `msc_reviewer` for independent gates.
- Use at most one `msc_implementer` writer at a time in the shared checkout.
- The primary agent owns scope, sequencing, integration, final validation, and user communication.
- Do not delegate reading or interpretation of a skill's `SKILL.md`; the primary agent must do that itself.
- Do not spawn agents merely to restate the workplan. Each sub-agent must have a concrete deliverable and bounded files or questions.
- Wait for required sub-agent results before claiming the phase or slice complete.

## Implementation rules

- Production-facing copy is Bahasa Indonesia and uses `id-ID` formatting.
- Styling uses React Native `StyleSheet.create` and centralized design tokens. Do not add Tailwind or NativeWind.
- Icons use the semantic `MSCIcon` wrapper backed by Phosphor SVG. Do not draw icons with `div`, CSS, emoji, or text glyphs.
- Mobile PWA UI must use current iOS runtime behavior as the reference for hierarchy, flow, navigation, gesture outcome, states, and menus. Adapt browser semantics rather than blindly copying iOS pixels.
- Views do not query Supabase directly and do not own authoritative business rules.
- Never expose service-role keys, private media paths, signed URLs, raw Coach QR values, weights, tokens, or payment proof data in source, logs, fixtures, screenshots, or analytics.
- Use local Supabase for development. Do not deploy migrations, functions, Auth settings, Storage policies, or data to hosted main without explicit authorization.
- Do not deploy to Cloudflare or change DNS/domain settings without explicit authorization.
- Do not perform Git mutations unless the user explicitly requests the exact operation.

## Completion report

For every completed slice report:

1. Requirement IDs and phase checklist items completed.
2. Files added/changed.
3. Build, typecheck, lint, test, and E2E commands run with results.
4. iOS Simulator screens inspected for compact UI, when applicable.
5. Sub-agents used and the bounded result each returned.
6. Unverified behavior, manual configuration, and next unchecked item.
