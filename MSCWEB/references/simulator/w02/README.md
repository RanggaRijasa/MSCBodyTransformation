# W02 iOS simulator parity evidence

Date: 2026-08-12  
Device: iPhone 17 Pro simulator  
Runtime: iOS 26.4  
Build: `MSCBodyTransformation`, Debug/local demo

## Captured surfaces

- `guest-home.jpg`: Guest Home and public program presentation.
- `login.jpg`: native login presentation and authentication gate.
- `program-catalog.jpg`: public Program catalog and segmented information hierarchy.
- `leaderboard.jpg`: public ranking presentation without private weight data.

The simulator was also launched with `-AppleLanguages (en) -AppleLocale en_US`
and the Debug scenarios `loading`, `offline`, `repository_error`,
`participant_no_program`, and `participant_active`. Runtime snapshots confirmed
Indonesian product copy, empty/no-program treatment,
actionable retry/error controls, the Guest public shell, and the transition to
the authenticated Participant shell.

## Intentional web adaptations

- Google authentication uses a full-page browser redirect and PKCE callback,
  rather than the native presentation sheet.
- The callback preserves only an allowlisted internal route and then uses
  normal browser history/back behavior.
- Compact web retains the five Guest/Participant destinations; medium and wide
  layouts may use a rail while preserving labels and destination authority.
- Personal actions route Guest users through the centralized login gate.

Fixtures shown in these references are deterministic local demo data, not
production data or a production backend contract.
