# Phase 11A concept decisions

Status: **accepted for local production implementation**  
Decision date: 2026-08-11 (Asia/Jakarta)  
Decision owners: orchestrator/PM and independent reviewer

This record closes Slice 11A.2. The accepted images are layout and visual-language
constraints, not authorization to add routes, fields, data, or capabilities. The
functional inventory and route reconciliation in
`docs/design/PHASE_11A_PARITY_LEDGER.md` remain authoritative.

## Accepted references

- iOS representative packet: `docs/design/references/phase-11a/` (12 Simulator
  captures; hashes and privacy review passed).
- Mobile shells: `docs/design/concepts/phase-11a/mobile-shell-v1.png`.
- Auth and state components:
  `docs/design/concepts/phase-11a/auth-components-v2.png`.
- Web glass and shared components:
  `docs/design/concepts/phase-11a/web-glass-v1.png`.
- Admin responsive system:
  `docs/design/concepts/phase-11a/admin-responsive-v2.png`.
- Landing: `docs/design/concepts/phase-11a/landing-phase11a-v1.png`.

The superseded `auth-components-v1.png` and `admin-responsive-v1.png` remain as
review provenance only. `landing-page-concept-v3.png` remains an earlier mood
reference; it is not a production screenshot specification.

## Locked visual direction

- Use the canonical brand red `#D92D20`, pressed red `#B42318`, yellow
  `#F5C542`, near-black identity surfaces, neutral content surfaces, and semantic
  success/warning/error/info colors.
- Use the system UI stack for application surfaces. Preserve the existing
  marketing font only where the final landing implementation deliberately needs
  it and does not impose it on authenticated routes.
- Use compact 8-point spacing, 12–16 px content radii, 20–24 px prominent
  radii, restrained elevation, and 44 px minimum interactive targets.
- Glass is selective: navigation, compact overlays, and interactive floating
  surfaces only. Long content and forms stay opaque. Reduced-transparency and
  high-contrast modes receive opaque, clearly bordered fallbacks.
- Participant and Guest use five mobile tabs; Coach uses three. Admin uses five
  mobile tabs and a six-destination desktop sidebar. The payment queue remains
  discoverable on mobile from the Dashboard action row.
- Icons use the existing `AppIcon` vocabulary. No new icon package is approved.

## Functional and route conditions

- Auth is Google-only on the web. The component board does not authorize Apple
  sign-in or new credential fields. Loading, empty, error, offline, and denied
  remain distinct states even when shown together in the concept board.
- Mobile Admin `Pembayaran menunggu` and desktop `Pembayaran` both resolve to
  `/admin/pembayaran`; payment detail remains `/admin/pembayaran/[paymentId]`.
  `Lihat audit` resolves to `/admin/pengaturan#audit`. Concept counts and names
  are deterministic fixtures, not production data. The phone bezel is not UI.
- The first Admin pending-action row maps to the authoritative program-closure
  queue at `/admin/program?status=completed`, followed by Coach applications and
  Payments. Activity review remains Coach-owned, so the Admin implementation
  must not invent a review count or destination merely to copy fixture wording.
- Landing `Program` and `Lihat program` resolve to `/program`; `Masuk` resolves
  to `/masuk`; section links target existing sections only.
- Landing keeps the frozen install-state labels and outcomes: `Unduh MSC`,
  `Cara memasang di iPhone`, `Cara memasang`, `Buka aplikasi`, and
  `Gunakan di browser`. Concept copy such as `Mulai transformasi` and
  `Pasang aplikasi` is hierarchy guidance, not a replacement state machine.
- Only one primary install CTA may be visible per viewport and scroll state.
- Until final redesigned PWA captures exist, every generic product preview must
  remain visibly and accessibly labelled `Pratinjau aplikasi`. It must not be an
  Open Graph asset or final product evidence. iOS captures must never be
  presented as PWA product screenshots.
- Browser modal and sheet implementations must preserve URL/history behavior,
  Escape, focus trapping and restoration, WebKit behavior, and accessible modal
  semantics. Auth `Tutup` retains the browser back/close contract and
  `/lupa-password` remains canonical.
- Locked-day and gated actions must not appear actionable merely to match a
  concept. Existing access and authorization outcomes remain authoritative.
- `/coach/[coachId]` and `/admin/orang/[userId]` remain absent.

## Intentional web adaptations

- Desktop/tablet Admin expands the same mobile hierarchy into a sidebar and
  denser tables; it does not gain desktop-only capability.
- Manual payment and PWA install surfaces are web-native adaptations with their
  existing route and state contracts.
- Browser back/deep-link, password-manager, camera permission, file picker,
  share/download, and focus behavior may use native web patterns while preserving
  the same outcome and privacy boundary.

## Image provenance and privacy

The five concept images were produced with the built-in OpenAI ImageGen workflow
from Phase 11A prompts and, where applicable, local reference-image edits. They
contain only generic fixture or skeleton content. Independent review found no
tokens, real email, raw Coach QR, body weight, transfer evidence, signed/private
URL, or private photo. Final product imagery must come from the rendered local
PWA after review.

## Review result

The independent reviewer accepted all five final concept assets and the 12-image
iOS representative packet. There are no open Critical or High Slice 11A.2
findings. Remaining Medium/Low conditions above are implementation acceptance
criteria, not permission to alter frozen behavior.
