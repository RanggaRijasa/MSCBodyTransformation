# Phase 11A Visual Acceptance Matrix

## Tujuan

Matriks ini menentukan reference yang harus dicapture dan evidence yang harus
dibandingkan selama redesign. Ia melengkapi test perilaku Phase 03–11; visual
test tidak menggantikan functional, RLS, privacy, atau integration test.

## Aturan capture iOS

Aplikasi iOS boleh dijalankan pada Simulator untuk keperluan reference Phase
11A. Izin ini read-only terhadap source iOS dan Xcode project.

- Gunakan scheme/project existing yang ditemukan melalui inspection.
- Wajib override environment menjadi `MSC_APP_MODE=local_demo`. Shared scheme
  saat ini memasang `debug_local_supabase`; jangan mengandalkannya untuk
  capture reference.
- Gunakan Debug fixture dan launch argument deterministik yang telah tersedia.
- Gunakan locale Indonesia; tambahkan non-Indonesia pass untuk mendeteksi key
  localization yang terlihat bila reference UI diubah di masa lain.
- Jangan login ke production atau memasukkan data orang nyata.
- Screenshot disimpan hanya di `MSCWeb/docs/design/references/phase-11a/`.
- Catat device, OS, appearance, content size, role, scenario, dan screen.
- Crop hanya untuk menghapus chrome Simulator; jangan mengubah isi UI.
- Source iOS, asset catalog, scheme, signing, dan `project.pbxproj` tidak boleh
  diubah untuk mempermudah capture.

Future executor boleh memakai simulator runner/debugger tooling yang tersedia,
`xcodebuild`, dan `xcrun simctl` untuk build, launch, serta screenshot. Jika
launch gagal, perbaikan source iOS bukan bagian Phase 11A tanpa approval baru.

Launch argument canonical:

```text
-AppleLanguages (id)
-AppleLocale id_ID
-DemoRole guest|participant|coach|admin
-DemoScenario <scenario>
-SkipDemoLanding
```

Gunakan iPhone dengan iOS 26 sebagai baseline Liquid Glass dan iOS 18 sebagai
pembanding fallback native. Device/UDID harus ditemukan ulang pada hari
capture; jangan pin identifier simulator dari mesin/sesi lama ke workplan.

## Reference set minimum

| Actor | iOS scenario/reference | PWA surface minimum |
|---|---|---|
| Guest | `guest_home`, `guest_program_catalog` | `/hari-ini`, `/program`, detail publik |
| Auth | `auth_login`, `auth_register`, `auth_forgot_password`, `auth_profile_onboarding` | `/masuk`, `/daftar`, `/lupa-password`, `/onboarding` |
| Coach applicant | eligible, ineligible, payment success, pending approval | Coach application dan payment lifecycle |
| Peserta | onboarding, no program, active, day 1, mid, final weigh-in, final leaderboard | seluruh tab dan step state terkait |
| Coach | identifier, active participants, review queue | dashboard, roster/detail, review, QR, profile |
| Admin | dashboard, draft CMS, active program, winner lock | dashboard, payments, CMS, people, content, settings |
| Global | loading, offline, permission denied, repository error, logged out | state yang relevan pada setiap shell |

Reference set diperluas bila audit menemukan surface web atau iOS lain yang
memiliki action/state unik.

Transfer manual program/Coach, upload bukti, Admin payment queue/detail, serta
QRIS statis adalah flow web-native karena iOS lama memakai StoreKit. Gunakan
design system dan interaction hierarchy yang sama, tetapi jangan mengklaim
pixel parity iOS atau menghidupkan kembali StoreKit.

## Route reconciliation gate

Sebelum concept dikunci, PM menetapkan setiap gap sebagai route aktual,
modal/overlay yang disengaja, atau alias redirect. Audit awal menemukan:

- belum ada `/coach/[coachId]`;
- belum ada `/profil/edit`, `/profil/ganti-coach`, `/akun/hapus`;
- belum ada `/coach-area/aktivitas`, `/coach-area/peringkat`, dan detail route
  pemeriksaan terpisah;
- belum ada `/admin/orang/[userId]`, `/admin/audit`, atau route granular
  settings/content/preview program;
- dokumentasi memakai `/lupa-kata-sandi`, implementation `/lupa-password`;
- dokumentasi memakai `/pengajuan-coach`, implementation memakai
  `/akses-coach/[applicationId]`.

Gate ini tidak memberi izin menambah fungsi. Ia mendokumentasikan presentation
dan navigation contract yang memang sudah ada sebelum screenshot baseline
diterima.

## Surface matrix

### Landing dan public

- Header/menu mobile dan desktop.
- Hero serta install CTA untuk ready, iPhone guidance, standalone,
  unsupported, dismissed, dan not-ready.
- Program teaser/catalog/detail public-safe.
- Cara kerja, Peserta/Coach, FAQ, legal/footer.
- Placeholder screenshot dan replacement release capture.
- Light/dark, 320 px large text, tablet, desktop.

### Guest/Auth

- Guest shell dan personal-action authentication gate.
- Login, register, forgot password, onboarding.
- Google action, pending, validation, provider error, callback/retry.
- Keyboard mobile, password manager/autofill, focus, back/close behavior.

### Peserta

- Hari ini: no program, active day, progress, locked/completed.
- Program: available/followed/history, detail, join, QR scanning states.
- Payment: instruction, QRIS image, upload, pending, rejected/correction,
  approved, expired/late/conflict.
- Step: article, video, typed form, quiz, photo, initial/daily/final weigh-in.
- Peringkat: active selector, tie, fewer winners, history/final snapshot.
- Coach directory/profile serta Participant profile/account lifecycle.

### Coach

- Dashboard metrics/attention/quick action.
- Program hub, roster, empty/search/filter, participant detail.
- Review queue/detail, answer key, private photo, approve/reject reason.
- Activity/ranking bila route tersedia, QR display, profile/settings.
- Access/application renewal states dan denied/expired boundary.

### Admin

- Dashboard action queue, metrics, audit summary.
- Payment queue/detail/evidence/decision/reason/history.
- Program list, create/edit, draft hub, settings, content, preview, publish,
  close/reopen, duplicate, winner lock.
- People segments, detail, Coach approval/rejection, transfer with reason.
- Content gallery/poster operations, settings, audit, debug-only exclusions.
- Mobile iPhone parity dan desktop responsive expansion untuk setiap workflow
  yang kritis.

## Viewport evidence

| Target | Baseline viewport | Evidence |
|---|---:|---|
| Small mobile | 320 x 900 | Large text, no horizontal overflow |
| iPhone compact | 375 x 812 | Shell/navigation/forms |
| iPhone current | 390 x 844 | Primary mobile visual baseline |
| Large mobile | 430 x 932 | Safe area and content expansion |
| Tablet portrait | 768 x 1024 | Adaptive shell/editor/list |
| Laptop | 1280 x 800 | Admin and landing |
| Desktop | 1440 x 1000 | Admin density and landing |
| Wide desktop | 1920 x 1080 | Max-width, no stretched content |

Gunakan device scale factor yang dipin untuk snapshot. Viewport tambahan wajib
ditambah bila layout memiliki breakpoint di luar matriks.

## Appearance dan accessibility matrix

Setiap critical journey diperiksa pada kombinasi yang relevan:

- light dan dark;
- reduced motion;
- reduced transparency/fallback glass;
- high contrast/forced colors;
- zoom 200% dan relevant 400%;
- keyboard-only dan visible focus;
- screen reader semantics, live status, modal focus/restore;
- Bahasa Indonesia panjang, angka locale, timezone, dan safe-area;
- online, offline, reconnect, slow loading, timeout, dan retry.

## Parity ledger template

| ID | Role/surface/state | iOS reference | PWA evidence | Exact/adapted | Alasan adaptasi | Function test | Reviewer | Status |
|---|---|---|---|---|---|---|---|---|
| EX-001 | Peserta / Hari ini / aktif | path PNG | path PNG | Exact | — | test/spec | nama | Open |

Rules:

- Satu row mewakili satu state material, bukan seluruh role.
- `Adapted` wajib memiliki alasan platform/accessibility/responsive yang nyata.
- Screenshot tanpa interaction test tidak menutup row action-oriented.
- Reviewer tidak boleh menjadi implementer utama row yang sama.
- Status hanya `Open`, `Needs decision`, `Needs fix`, atau `Accepted`.

Reference folder memiliki manifest machine-readable atau Markdown dengan
source Swift/test recipe, OS/device, role, scenario, launch args,
accessibility identifier, target web route, appearance, viewport, dan tanggal.
Nama file memakai pola stabil, misalnya
`ios26-iphone-participant-hari_ini-active-light.png`.

## Visual review workflow

1. Capture accepted iOS/concept reference.
2. Render PWA melalui local dev/build menggunakan deterministic fixture.
3. Ambil screenshot target dengan browser testing tooling.
4. Buka reference dan rendered screenshot pada detail asli.
5. Bandingkan hierarchy, content, spacing, typography, color, component shape,
   state, navigation, safe area, responsiveness, dan polish.
6. Perbaiki implementation, bukan reference, bila gap tidak disengaja.
7. Update snapshot hanya setelah reviewer menerima perubahannya.
8. Jalankan ulang snapshot tanpa update flag untuk membuktikan stabilitas.

## Functional preservation gate

Untuk setiap slice, audit sebelum/sesudah harus membuktikan:

- route dan deep link tetap tersedia;
- semua action memanggil boundary/use case yang sama;
- loading/empty/error/offline/denied/conflict/retry tetap ada;
- form validation, reason, confirmation, idempotency, dan status tetap benar;
- Auth/role/privacy/cache/service-worker boundary tidak melemah;
- keyboard, focus, screen reader, touch, dan browser back tetap bekerja;
- tidak ada fixture/mock baru yang tampil sebagai data production.

Acceptance visual wajib dijalankan pada actual production routes dengan
deterministic local data. Gallery membantu coverage dan capture, tetapi tidak
boleh menjadi satu-satunya evidence Guest/Peserta/Coach/Admin.

Target accessibility adalah WCAG 2.2 AA, zero serious/critical axe finding,
serta manual semantics/focus pass pada actual authenticated route. Periksa
skip link, `aria-current`, heading/landmark, label-error association, dialog
focus trap/restore/Escape, route focus, dan live status/error.

## Closure regression

Phase 11A tidak selesai sampai command pada phase utama lulus, seluruh visual
role memiliki evidence Chromium dan WebKit yang relevan, accessibility serta
performance gate diperbarui, dan full `test:phase11:local` dijalankan ulang.

Selain Phase 11, jalankan suite lokal Phase 03–10 dan full gallery karena
redesign shared shell tidak tervalidasi cukup oleh Phase 11 runner saja.

Owner secara eksplisit menunda physical installed-PWA/iPhone/Android checks
dan menetapkannya non-blocking untuk status `SELESAI LOKAL` Phase 11A. Gate
perangkat ini tidak dianggap lulus dan tetap wajib sebelum production cutover;
Chromium/WebKit desktop/mobile emulation serta Admin responsive evidence tidak
boleh disebut sebagai pengganti validasi perangkat fisik.
