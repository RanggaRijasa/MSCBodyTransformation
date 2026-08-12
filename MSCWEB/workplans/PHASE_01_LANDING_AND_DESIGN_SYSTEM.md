# MSCWEB W01 — Landing, design system, and app shell

Status: `Not started`  
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

- [ ] Launch current iOS Guest Home and Login in `id-ID`.
- [ ] Inspect current Participant compact tab bar/header/card rhythm and light/dark states.
- [ ] Record screens, device, OS, scenario, and differences before web UI implementation.
- [ ] Do not copy generated mobile product UI from the ImageGen mockup when it conflicts with the simulator.

## Checklist

### Design foundation

- [ ] Implement primitive, semantic, and component tokens from the spec.
- [ ] Implement system typography with tabular numerals and `id-ID` formatting helpers.
- [ ] Implement reduced motion/transparency and increased-contrast behavior.
- [ ] Implement responsive gutters/max widths and safe-area helpers.
- [ ] Implement `MSCIcon`; prohibit direct feature imports from Phosphor.

### Shared UI

- [ ] Buttons, icon button, fields, segmented control, cards, badges, progress, avatar fallback.
- [ ] Loading, empty, error, offline, forbidden, and session-expired states.
- [ ] Sheet/dialog/toast with focus management and Escape/back behavior.
- [ ] Bottom navigation compact and rail/sidebar medium/wide.
- [ ] Keyboard, pointer, coarse-touch, 200% zoom, and screen-reader semantics.

### Landing implementation

- [ ] Header, hero, CTA, Cara kerja, program section, Coach support, manual-payment explanation, install section, footer.
- [ ] Use generated concepts for composition/quality only; use approved copy/data/icons/assets.
- [ ] Keep core landing copy readable without client JavaScript.
- [ ] Add SEO/canonical/Open Graph/favicon/theme metadata.
- [ ] Replace generated photography with licensed/approved or separately approved production assets.

### App shells

- [ ] Guest/Participant destinations: Beranda, Program, Peringkat, Coach, Profil.
- [ ] Coach destinations: Dashboard, Program, Profil.
- [ ] Admin destinations: Dashboard, Program, Orang, Konten, Pengaturan.
- [ ] Route state, browser Back/Forward, deep link shell, and tab restoration tests.

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
