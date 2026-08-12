# W03 Participant program parity sign-off

Date: 2026-08-12  
Device: iPhone 17 Pro Simulator  
Runtime: iOS 26.4  
Native build: `MSCBodyTransformation`, Debug/local demo  
Web build: production export at `http://127.0.0.1:4173`

The native application was built and launched fresh. No native source,
project, scheme, capability, or signing setting was changed. The web comparison
used the same Participant information hierarchy with deterministic local
Supabase data; fixture identifiers and private account data are not retained in
this evidence.

## Participant Home

Feature / requirement IDs: `UX-HOME-001`–`UX-HOME-004`, `PROD-PTC-005`,
`PROD-LDB-001`–`PROD-LDB-003`  
iOS screens and states inspected: `participant_active`; profile summary,
horizontal Program cards, Fokus hari ini with 2/4 progress, Leaderboard Top 5,
Pemenang, Coach, selected Beranda tab, long vertical scroll  
Web compact states inspected: authenticated Participant Home, server profile
and neutral avatar fallback, joined-program carousel, focus/progress, Top 5,
winner empty/populated handling, assigned Coach, loading/error/offline/
forbidden/session-expired boundaries  
Web wide states inspected: same section order in the wide content column with
navigation rail  
Behavior differences: web provides explicit previous/next carousel controls
in addition to touch/pointer scrolling  
Accepted adaptive differences: bottom tabs become a rail at wider breakpoints  
Accessibility result: heading order is stable; numeric content uses tabular
formatting; current leaderboard row is labeled `Kamu` and has a noncolor
indicator  
Visual result: pass; bold black/red/yellow identity and neutral data surfaces
match the approved native hierarchy  
Reviewer/date: Codex primary, 2026-08-12

## Program catalog

Feature / requirement IDs: `PROD-PRG-001`, `UX-PRG-001`, `UX-PRG-002`  
iOS screens and states inspected: `participant_mid_program`; Diikuti,
Tersedia, Riwayat, selected segment, vertical program cards, selected Program
tab, compact scroll  
Web compact states inspected: all three URL-backed segments, empty/private
gate states, retained per-segment scroll, card primary target, Back restoration  
Web wide states inspected: tablist and responsive card grid with unchanged
authority/filter semantics  
Behavior differences: web persists the segment in `?segment=` and uses browser
Back/Forward  
Accepted adaptive differences: wider view uses a card grid rather than a
single vertical stack  
Accessibility result: semantic tablist/tab roles, `aria-selected`, keyboard
activation, and one unambiguous link per program card pass  
Visual result: pass  
Reviewer/date: Codex primary, 2026-08-12

## Program offer/detail

Feature / requirement IDs: `PROD-PRG-002`, `UX-PRG-002`  
iOS screens and states inspected: available-program offer; poster, schedule,
duration, activity count, price, wellness copy, Coach/QR entry context, red
primary CTA, Back  
Web compact states inspected: poster, date, timezone, price, activity count,
state-aware CTA, Coach context for Participant, safe login intent for Guest,
320/390/430 in light and dark  
Web wide states inspected: constrained content width, expanded metadata grid,
navigation rail  
Behavior differences: W03 stops at a read-only `Program dipilih` handoff;
actual QR enrollment/payment is W05  
Accepted adaptive differences: web metadata wraps into an adaptive grid  
Accessibility result: poster has an image label, CTA is a single primary
action, copy remains readable without horizontal overflow  
Visual result: pass  
Reviewer/date: Codex primary, 2026-08-12

## Activity accordion

Feature / requirement IDs: `PROD-PTC-005`, `PROD-PRG-003`, `PROD-PRG-004`,
`UX-PRG-003`  
iOS screens and states inspected: active detail, compact progress header,
current day expanded, previous/future days, locked state, status rows, vertical
scroll  
Web compact states inspected: server progress/poin/rank, available/locked/
hidden/read-only access, pending/rejected/approved submissions, current day
opened and positioned without animation  
Web wide states inspected: same accordion contract within the centered content
column  
Behavior differences: browser deep-links steps with `?step=` and returns with
native history  
Accepted adaptive differences: hidden days are omitted rather than rendered as
disabled cards, matching the server visibility contract  
Accessibility result: day buttons expose expanded state and descriptive
current/locked labels; status is never color-only  
Visual result: pass  
Reviewer/date: Codex primary, 2026-08-12

## Step renderers

Feature / requirement IDs: `PROD-PRG-003`, `UX-PRG-004`  
iOS screens and states inspected: initial weigh-in renderer, private-weight
copy, numeric entry, disabled/submission CTA, sticky action above compact nav  
Web compact states inspected: article, video, form text/choice/photo, one-attempt
quiz, initial/daily/final weight, locked/read-only/pending/approved/rejected;
sticky CTA above bottom navigation and safe area  
Web wide states inspected: the same shared published definition with sticky
action near the viewport edge and rail navigation  
Behavior differences: W03 renders and validates interaction affordances but
does not submit answers, weights, or photos; private mutations are W04  
Accepted adaptive differences: browser video is a published-content frame and
browser Back replaces the iOS edge gesture  
Accessibility result: labels, roles, disabled state, required/one-attempt copy,
privacy copy, and virtual-keyboard-safe scrolling pass  
Visual result: pass  
Reviewer/date: Codex primary, 2026-08-12

## Verification note

The existing native UI test
`testParticipantSelectsProgramBeforeOpeningDetail` traversed catalog segments,
offer/join, Back, active detail, and opened day 4. It then failed at the
native-only static-text lookup on line 968 (`Hari ini`). This is recorded as a
native test-harness follow-up, not a web pass. Fresh runtime inspection still
confirmed the corresponding visible current-day hierarchy. The web W03 path is
covered in both compact and desktop Chromium and passed in the final 54-test
Playwright run.
