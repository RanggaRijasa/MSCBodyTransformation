# Landing image provenance

## Unsplash editorial landing set

The redesigned public landing uses four downloaded photographs stored under
`images/landing/`. Each source page identifies the image as free to use under
the Unsplash License. The files are served locally so the landing does not
depend on a third-party image request at runtime.

- `modest-gym.jpg` — Asso Myron, “A woman in a hijab exercises in the gym.”
  https://unsplash.com/photos/Ivu2SWRyFxQ
- `modest-recovery.jpg` — fanya mediani, “Woman in athletic wear taking a
  selfie outdoors.” https://unsplash.com/photos/-k9eSW5berI
- `modest-running.jpg` — nobleseed nobleseed, “Woman in hijab running on a
  city street.” https://unsplash.com/photos/FyQBh0feV60
- `modest-volleyball.jpg` — shot ed, “Woman in white hijab and black pants
  standing on gray concrete floor.” https://unsplash.com/photos/fms0BB94ItY

License: https://unsplash.com/license

## 2026-08-23 mixed modest fitness revision

The public landing now keeps `modest-gym.jpg` as its only visible photograph
of a woman wearing hijab. The other visible fitness photography is a mix of
non-hijab women and men in covered athletic clothing.

- `man-gym-coach.jpg` — Vitaly Gariev, “Man in gym wearing grey t-shirt
  looking at camera.” https://unsplash.com/photos/esdi104xmkc
- `man-gym-pullup.jpg` — Gordon Cowie, “Man in white crew neck t-shirt and
  black pants holding black exercise equipment.”
  https://unsplash.com/photos/kVX6MBa2uNk
- `woman-gym-generated.jpg` — generated specifically for the MSC landing with
  OpenAI ImageGen on 2026-08-23. It depicts a fictional adult Southeast Asian
  woman in a long-sleeve athletic top and full-length loose athletic pants.
  It contains no real participant, Coach, testimonial, logo, or result claim.

The final ImageGen prompt requested a photorealistic editorial gym photograph,
a non-hijab adult Southeast Asian woman, opaque long sleeves, full-length loose
athletic pants, no exposed midriff, no logos, and no sexualized pose.

The photographs illustrate an active lifestyle only. They are not MSC
participants, Coaches, testimonials, or evidence of program results.

The two landing photographs were generated specifically for MSC Body
Transformation with OpenAI ImageGen on 2026-08-12. They contain no real Coach,
participant, logo, testimonial, body-transformation claim, or before/after
comparison.

- `landing-hero.jpg`: adult Indonesian participants training in a contemporary
  gym with an adult Indonesian Coach. Cropped for a dark editorial hero.
- `coach-support.jpg`: an adult Indonesian Coach supporting adult participants
  during a small-group training session.

These files are production candidates, not evidence of real people or results.
Final visual approval remains a W01 user checkpoint. If a real Coach identity is
introduced later, replace these assets only after the subject and usage rights
are explicitly approved.

`sign-in-with-google-light-pill.png` is the unmodified Android + Web light pill
button from Google's pre-approved Sign in with Google branding asset archive,
downloaded from `developers.google.com/static/identity/images/signin-assets.zip`
on 2026-08-21. It remains an image-only presentation layer over the existing
Supabase PKCE OAuth action; no Google credential or client secret is embedded.
