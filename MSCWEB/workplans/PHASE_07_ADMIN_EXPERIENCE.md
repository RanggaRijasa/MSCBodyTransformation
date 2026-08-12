# MSCWEB W07 — Admin experience

Status: `Not started`  
Autonomy: `A` locally; `C` for ambiguous operational authority  
Depends on: stable Participant, payment, evidence, Coach, and scoring contracts

## Objective

Deliver Admin parity for Dashboard, Program, People, Content, payment/application review, scoring corrections, winner locking, fallback operations, settings, and audit—optimized for both compact and wide web.

## Required references

- `00_PRODUCT_SPEC.md` Admin requirements
- `02_UX_PARITY_AND_ROUTES.md`
- `03_DESIGN_SYSTEM.md`
- `05_DATA_SECURITY.md`
- program end-to-end contract matrix
- current iOS Admin simulator flows for every implemented area

## Deliverables

- Admin Dashboard attention/metrics/quick actions;
- Program CRUD/draft/publish/archive/list/search/preview;
- People Peserta/Coach/Admin and detail/actions;
- Content authoring using shared Participant renderer;
- integrated payment and Coach application review;
- scoring adjustments, winner preview/lock/snapshot;
- approved enrollment fallback operations and audit/settings;
- compact and data-dense wide layouts.

## Mandatory simulator gate

- [ ] Inspect Admin Dashboard, Program list/detail/editor, People segments/details, Content, and Settings.
- [ ] Inspect attention cards, metrics, search, filters, create action, status badges, sheets/dialogs, and decision copy.
- [ ] Inspect payment and Coach application states built in W05/W06.
- [ ] For each slice, compare compact to iOS and design a documented wide adaptation rather than stretching cards.

## Checklist

### Navigation/dashboard

- [ ] Destinations: Dashboard, Program, Orang, Konten, Pengaturan.
- [ ] Attention and metrics use authoritative aggregates with loading/empty/error/stale states.
- [ ] Wide layout uses table/list/two-pane where it reduces context switching.

### Program/content

- [ ] Program lifecycle transitions validated server-side and audited.
- [ ] Search/filter/list/detail/draft validation/publish/archive behavior.
- [ ] Content authoring covers all published step types and required questions.
- [ ] Preview uses the same renderer/domain definition as Participant.
- [ ] Published scoring/content behavior cannot change silently.

### People/operations

- [ ] Segments Peserta, Coach, Admin with protected details/actions.
- [ ] No direct unsafe role write from client.
- [ ] Payment/evidence/application queue integration.
- [ ] Authorized fallback enrollment/scoring corrections require reason and audit.
- [ ] Winner calculation preview handles ties/fewer than five; lock creates stable snapshot.
- [ ] Settings never display or edit secrets in browser.

## Sub-agent plan

- `msc_explorer`: one iOS/Admin area and associated backend authority map at a time.
- `msc_implementer`: sole writer for a bounded Admin vertical slice.
- `msc_reviewer`: privilege/authority/audit, shared preview parity, responsive density, accessibility, and test coverage.

The primary agent owns shared program renderer, authority operation interfaces, navigation root, and migration order.

## Verification

- authorization/RLS/RPC tests for every mutation;
- program lifecycle/content validation/published immutability tests;
- score correction/weight gain/duplicate/tie/fewer-than-five/winner lock tests;
- Admin Playwright journeys compact and wide;
- keyboard/data-table/dialog accessibility;
- simulator parity and wide design review;
- audit record completeness and sensitive-log scan.

## Exit criteria

- All in-scope iPhone Admin capabilities have implementation and parity evidence or explicit accepted deferral.
- Browser cannot bypass authority functions through direct writes.
- Program preview and Participant renderer do not diverge.
- Winner lock and adjustments are stable, audited, and private-weight safe.

## User input or authorization

- Product decision for any fallback/correction action not settled by existing contracts.
- Explicit acceptance of any deferred iPhone Admin capability.
- Production Admin roster/configuration is not part of local completion.

## Progress log

Append simulator area, compact/wide behavior, operations/tests, audit evidence, decisions/deferrals, files/commands, and next item.

