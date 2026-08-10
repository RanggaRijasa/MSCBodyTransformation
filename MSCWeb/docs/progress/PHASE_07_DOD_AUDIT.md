# Audit Definition of Done Phase 07

> Tanggal audit: 10 Agustus 2026
>
> Status: SELESAI LOKAL — seluruh gate Phase 07 lulus.

## Batas eksekusi

- Semua source, migration additive, fixture, test, snapshot, dan dokumen hasil
  konversi berada di `MSCWeb/`.
- Proyek iOS, `Contracts/`, root `supabase/`, dan dokumentasi root hanya dibaca
  sebagai referensi; tidak ada file di luar `MSCWeb/` yang diubah.
- Migration `20260810100000_phase07_participant_experience.sql` hanya diterapkan
  ke Supabase lokal. Hosted `main`, secrets, OAuth, DNS, dan deployment tidak
  disentuh.
- Tidak ada operasi Git mutating.

## Bukti parity perjalanan Peserta

| Requirement | Bukti lokal |
| --- | --- |
| Home public-safe dan Participant | `ParticipantHome`, server use case, serta component/gallery matrix |
| Multi-program terisolasi | program dipilih per enrollment; draft dan idempotency key di-scope program/enrollment/step |
| Hari aktif authoritative | `program_day_access` dari server menjadi satu sumber fokus, label Hari ini, lock, dan read-only |
| Typed renderer | article, video, heading/text, short/long, number, pilihan, image choice, foto, dan tiga weigh-in |
| Shared preview | `ProgramContentPreview` dipakai Participant dan gallery konteks Coach; siap dipakai Admin/Coach tanpa fork renderer |
| Submission lifecycle | draft server, typed validation, automatic/Coach review, pending/approved/rejected, retry, correction/reopen projection |
| Leaderboard dan pemenang | selector program, Top 5, current-user emphasis, deterministic order, fewer-than-five, dan locked snapshot |
| Coach dan profil | directory public-safe, Coach-mu, edit avatar/name/phone, email read-only, legal, logout/delete, perubahan Coach QR-only |

## Privacy dan authority

- Jawaban API diparse sebagai payload typed: UUID, decimal terbatas, panjang
  teks, pilihan unik, dan path foto server-derived tervalidasi sebelum RPC.
- Foto pertanyaan berada di bucket privat `question-photos`; Participant hanya
  dapat mengakses miliknya, Coach hanya yang ditugaskan, dan URL bertanda
  tangan bersifat singkat. Object tidak dapat diubah setelah review.
- Nilai berat memakai string decimal canonical dan `numeric` Postgres, tidak
  pernah menjadi otoritas binary float. Berat tidak muncul di public Home,
  feed, pemenang, atau leaderboard dan tidak masuk log/cache/analytics.
- Answer key tidak masuk kontrak publik. Hasil kuis dihitung server-side,
  private, hanya satu attempt kecuali operasi reopen berotorisasi.
- Perubahan Coach mengunci state, memeriksa QR opaque dan entitlement aktif,
  memperbarui profil serta enrollment atomik, idempoten, dan diaudit tanpa raw
  QR.

## Bukti edge case dan race

- Unit/component mencakup locale decimal, malformed answer payload, Guest
  public-safe, server-day, typed question variants, offline/repository failure,
  dan tidak mengaku sukses sebelum server berhasil.
- pgTAP mencakup QR Coach invalid, replay perubahan Coach, private idempotency
  rows, avatar object invalid, final-before-initial, uniqueness/retry timbang
  awal dan harian, weight gain bernilai nol, failed quiz, dan one-attempt.
- Integration existing read-only mencakup 15 assertion submit/review race dan
  idempotensi serta 16 assertion Storage API untuk owner/Coach/unrelated actor,
  signed URL, MIME, upsert, delete, dan immutability setelah review.
- E2E Chromium memakai satu Participant/program yang sama untuk urutan scan QR
  Coach, paid order, upload bukti, verifikasi Admin, enrollment aktif, timbang
  awal, aktivitas subjektif, review Coach, timbang akhir, dan leaderboard tanpa
  kebocoran nilai berat.

## UI dan accessibility

- Gallery Phase 07 mencakup Home Peserta mobile dark mode, Reduce Motion,
  zoom 125%, axe, Chromium, dan WebKit.
- Full gallery terakhir lulus 16 check. Baseline mobile Chromium dan WebKit
  telah diperiksa visual; tidak ada clipping, key mentah, kontras status, atau
  overflow yang menghalangi penggunaan.
- Semantic heading, region, label, status text, focus, minimum target, locale
  `id-ID`, dark mode, dan reduced motion mengikuti shared shell/design system.

## Perintah verifikasi terakhir

```bash
PATH="/opt/homebrew/opt/node@24/bin:$PATH" corepack pnpm test:phase07:local
PATH="/opt/homebrew/opt/node@24/bin:$PATH" corepack pnpm verify
PATH="/opt/homebrew/opt/node@24/bin:$PATH" corepack pnpm test:gallery
```

Hasil:

- database lint: PASS tanpa schema error;
- pgTAP: 31 PASS;
- submission/review race: 15 assertion PASS;
- private-media Storage API: 16 assertion PASS;
- Chromium critical journey: 1 PASS;
- full gallery Chromium/WebKit + axe: 16 PASS;
- architecture, file-size, secret, localization, dan contract checks: PASS;
- Vitest: 28 file, 124 test PASS;
- typecheck, production build 41 halaman, dan media bundle gate: PASS.

## Kesimpulan

Seluruh checklist dan Definition of Done Phase 07 terpenuhi untuk environment
lokal. Tidak ada blocker lokal. Gate perangkat fisik/PWA quality berada di
Phase 11; migration hosted dan deployment tetap Phase 12 dengan approval
eksplisit.
