# Audit Definition of Done Phase 08

> Tanggal audit: 10 Agustus 2026
>
> Status: SELESAI LOKAL — seluruh gate Phase 08 lulus.

## Batas eksekusi

- Semua source, migration additive, fixture, test, snapshot, dan dokumen hasil
  konversi berada di `MSCWeb/`.
- Proyek iOS, `Contracts/`, root `supabase/`, dan dokumentasi root hanya dibaca
  sebagai referensi; tidak ada file di luar `MSCWeb/` yang diubah.
- Migration `20260810110000_phase08_coach_experience.sql` hanya diterapkan ke
  Supabase lokal. Hosted `main`, secrets, OAuth, DNS, dan deployment tidak
  disentuh.
- Tidak ada operasi Git mutating.

## Bukti capability Coach

| Requirement | Bukti lokal |
| --- | --- |
| Dashboard | identitas, periode aktif, metrik, program, attention, activity, leaderboard publik, QR, dan mode Peserta |
| Roster | search/filter/sort stabil; assigned-only; status tekstual; tanpa berat/foto |
| Detail privat | identitas, program switch, progres, skor, submissions, jawaban, foto berotorisasi, dan riwayat timbang kronologis |
| Review | filter program/type/time, answer key via RLS, approve/reject, alasan wajib, idempotensi, audit, dan rekonsiliasi exactly-once |
| Program hub | rentang hari ini/7/30 berdasarkan timezone, feed aman, leaderboard program-scoped |
| Profil dan QR | bio/visibility/profile lifecycle, QR opaque, share/download fallback, no raw identifier |
| Coach-as-Participant | shared Participant renderer dan explicit owner filter; enrollment Peserta dampingan tidak bercampur |

## Privacy dan authority

- `private.can_coach_participant` dan entitlement aktif menjadi boundary RLS;
  Guest, Participant, Coach lain, Coach kedaluwarsa, serta Coach historis
  setelah transfer tidak memperoleh detail privat.
- Weight dan evidence tidak dipilih oleh feed/roster; scanner source menjaga
  field privat dan larangan log. Nilai berat hanya tampil pada detail privat.
- Foto jawaban dialirkan lewat session-authenticated Storage RLS dengan header
  `private, no-store`, `Pragma: no-cache`, dan `Vary: Cookie`; object actor lain
  ditolak oleh integration suite existing.
- Answer key hanya dibaca dari `program_answer_keys` melalui policy Coach
  assigned/Admin. Negative pgTAP membuktikan Coach lain menerima nol baris.
- Mode Peserta memfilter `participant_id` eksplisit ke actor sendiri, sehingga
  capability Coach tidak mencampurkan enrollment dampingan ke progres pribadi.
- Total skor dihitung dari komponen authoritative tabel; approval replay tidak
  menggandakan poin atau audit event.

## Bukti edge case dan race

- 24 pgTAP Phase 08 mencakup Coach-as-Participant, self-Coach guard, roster,
  assigned/other Coach, answer key, approval replay, score exactly-once,
  conflict stale, Guest, Participant, expiry, dan transfer historis.
- Gate juga menjalankan 13 test operasi program Phase 07, 15 assertion race
  submit/review, dan 16 assertion private-media Storage API.
- Empat Chromium journey mencakup dashboard sampai approve/score/activity/QR/
  profil/mode Peserta, denial Coach lain, reject dengan alasan serta audit,
  expiry, dan renewal lokal.
- Unit/component mencakup status attention, stable sort/filter, timezone
  program, capability role, quick action tunggal, no roster leakage, locked
  state, rejection reason, dan idempotency key UI.

## UI dan accessibility

- Gallery Coach mencakup dashboard desktop serta roster/expiry mobile pada
  Chromium dan WebKit, axe serious/critical scan, keyboard focus, dan visual
  baseline.
- Full gallery lulus 20 test. Baseline Coach Chromium diperiksa visual setelah
  token design system canonical diterapkan; tidak ada clipping atau overflow.
- Copy produksi tetap Bahasa Indonesia, angka/tanggal mengikuti `id-ID`, status
  tidak hanya mengandalkan warna, dan target interaksi memakai shared UI.

## Perintah verifikasi terakhir

```bash
PATH="/opt/homebrew/opt/node@24/bin:$PATH" corepack pnpm test:phase08:local
PATH="/opt/homebrew/opt/node@24/bin:$PATH" corepack pnpm verify
PATH="/opt/homebrew/opt/node@24/bin:$PATH" corepack pnpm test:gallery
```

Hasil:

- database lint: PASS tanpa schema error;
- pgTAP: 37 PASS dalam gate, termasuk 24 test khusus Phase 08;
- submission/review race: 15 assertion PASS;
- private-media Storage API: 16 assertion PASS;
- Chromium Coach journeys: 4 PASS;
- full gallery Chromium/WebKit + axe: 20 PASS;
- architecture, file-size, secret, localization, contract, dan privacy checks:
  PASS;
- Vitest: 30 file, 138 test PASS;
- typecheck, production build 37 halaman, dan media bundle isolation: PASS.

## Kesimpulan

Seluruh checklist dan Definition of Done Phase 08 terpenuhi untuk environment
lokal. Tidak ada blocker lokal. Hosted migration dan deployment tetap external
gate Phase 12 dengan approval eksplisit.
