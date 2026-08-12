# 09 — iOS simulator audit baseline

## Audit environment

- Project: `../MSCBodyTransformation.xcodeproj`
- Scheme: `MSCBodyTransformation`
- Simulator: iPhone 17 Pro, iOS 26.5
- Bundle: `com.ranggar.MSCBodyTransformation`
- Locale launch: Indonesian (`id-ID`)
- Result: simulator build and launch succeeded on 12 August 2026.

Audit dilakukan secara read-only terhadap source/repository dan runtime UI. Tidak ada source iOS yang diubah.

## Runtime scenarios inspected

### Guest

- debug role/scenario picker;
- Home dengan dark theme;
- hero `Siap memulai perjalananmu?` dan CTA Login;
- horizontal program cards;
- account/focus prompt;
- compact bottom tab bar;
- Login surface dengan provider actions.

### Participant

- Home: profile summary, program poster/card, focus/progress, bottom tabs;
- Program catalog dengan `Diikuti`, `Tersedia`, `Riwayat`;
- program activity menggunakan day accordions dan relevant-day positioning;
- initial weigh-in/detail form dan disabled CTA state;
- available program offer dan CTA `Gabung program`;
- join flow dengan program price dan `Pindai QR coach`.

### Coach

- Dashboard profile summary;
- 2×3 quick action grid;
- badge/action states;
- review queue dengan `Perlu tindakan` dan `Semua bukti`;
- filter card/list rows;
- proof review detail: context, evidence image, bottom `Tolak`/`Setujui`;
- routes/labels untuk Participant, activity, program, ranking, dan Coach QR.

### Admin

- Dashboard attention/quick actions/metrics;
- bottom tabs Dashboard, Program, Orang, Konten, Pengaturan;
- People Coach pending list;
- Coach application detail dengan eligibility/payment state;
- Program search/create/list/status surfaces.

## Visual characteristics to preserve

- mobile-first single-column hierarchy;
- black/near-black identity surfaces dengan red primary action dan yellow achievement accents;
- neutral long-form/list/form surfaces;
- large rounded posters/cards, tetapi bukan semua content dibungkus nested card;
- native-feeling bottom navigation dengan clear selected state;
- restrained glass pada compact interactive chrome;
- sticky action regions untuk decision/detail flow;
- segmented controls dan sheets untuk contextual tasks;
- clear state labels, badges, empty/error copy, dan disabled controls;
- comfortable 44-point-equivalent touch targets;
- typography hierarchy dan monospaced/tabular numeric display.

## Interaction characteristics to preserve/adapt

| iOS behavior | Web requirement |
|---|---|
| Tab navigation dengan independent destination context | bottom tabs compact; rail/sidebar wide; browser history tetap benar |
| Horizontal program cards | touch/pointer snap carousel + keyboard controls |
| Native sheet/detail | modal sheet compact, dialog/two-pane wide, focus managed |
| Day accordion + auto relevant day | same state/scroll outcome; accessible expanded semantics |
| Sticky bottom review actions | same on compact; action panel on wide |
| QR camera | browser camera adapter dengan permission/error states |
| Photos picker | file/camera input + privacy/normalization pipeline |
| Edge back gesture | browser/iOS history gesture; tidak ditimpa custom gesture |
| Liquid Glass | selective supported blur; opaque fallback/reduced transparency |

## Source contracts inspected

- app role/tab definitions and root navigation;
- Participant program/catalog/activity structure;
- Coach dashboard and review routes;
- Admin dashboard/program/people routes;
- commerce/entitlement concepts;
- Coach application/payment/entitlement concepts;
- private evidence media constraints;
- approved App Icon source/variants.

## Known audit limits

- Audit ini bukan exhaustive capture setiap modal/error/fixture combination.
- Debug fixture values dan simulator dates bukan production data contract.
- Web payment adalah intentional replacement sehingga tidak memiliki visual parity langsung dengan StoreKit flow.
- Sebelum setiap feature slice selesai, screen terkait MUST dibandingkan kembali dengan current iOS simulator agar perubahan iOS setelah baseline tidak terlewat.

## Parity sign-off template

```text
Feature / requirement IDs:
iOS screens and states inspected:
Web compact states inspected:
Web wide states inspected:
Behavior differences:
Accepted adaptive differences:
Accessibility result:
Visual result:
Reviewer/date:
```

