# Phase 11A performance measurement

## Decision

The Phase 11A build gate keeps the frozen clean-build route baselines from
`PHASE_11A_BASELINE.md` and permits at most `+10 KiB` gzip per representative
route and `+5 KiB` gzip for root global CSS. The existing absolute route limits
remain a second ceiling.

Next 16.3 emits `globalThis.__RSC_MANIFEST[...]={...}` and includes client-module
records from sibling route groups in each client reference manifest. For
baseline comparability, JavaScript measurement therefore intentionally retains
the conservative union of all `.js` chunks referenced by `clientModules`, which
is the same build-graph method used for the frozen baseline. It must not be
described as browser-transfer bytes for one route.

CSS measurement changes only to reflect the approved Phase 11A route scoping:

- root global CSS is the exact `src/app/layout` entry;
- route CSS is the union of root, route-group layout, route error boundary, and
  representative page entrypoints;
- sibling route-group CSS is excluded;
- duplicate paths are counted once;
- inline CSS or a missing root stylesheet fails closed until the parser is
  deliberately updated.

Before Phase 11A, every handwritten stylesheet was emitted through the root
global entry. The frozen `14.31 KiB` CSS value was therefore delivered to every
representative route, so comparing it with the new root-plus-route CSS union is
consistent with the delivery boundary while still preserving the original
conservative JavaScript baseline.

The gate must be run after the pinned production build. A future Next manifest
format change, Turbopack re-evaluation, or browser-transfer budget requires a
new auditable clean baseline rather than silently changing these numbers.
