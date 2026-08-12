# Web design primitives

W01 centralizes reusable visual decisions in this folder:

- `tokens.ts` owns primitive, semantic, component, typography, motion, safe-area,
  and responsive values;
- `ThemeProvider.tsx` follows the system light/dark preference and allows an
  explicit test override;
- `formatters.ts` owns `id-ID` product formatting;
- `responsive-layout.ts` maps compact, medium, and wide layouts to the approved
  768 px and 1200 px boundaries.

Feature routes consume semantic tokens and shared primitives. Phosphor glyphs
must be requested through `MSCIcon`; direct feature imports are rejected by the
bundle verifier.
