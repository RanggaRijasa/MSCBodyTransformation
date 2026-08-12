# W01 native simulator reference

Captured on 2026-08-12 from the current native iOS build on iPhone 17 Pro,
iOS 26.4, locale `id-ID`:

- `guest-home-light.png`: Guest Home, light appearance;
- `login-light.png`: Login presented from Guest Home, light appearance;
- `participant-home-dark.png`: authenticated Participant Home, dark appearance.

Parity notes used by the web implementation:

- retain large title-first hierarchy, neutral content surfaces, red primary
  actions, and a compact five-destination Participant bar;
- keep selected navigation visible through icon, label, and surface—not color
  alone;
- preserve dark/light readability and the neutral blank-person avatar;
- do not copy the native fixture data, native-only Apple login, or decorative
  Liquid Glass treatment into the web shell.
