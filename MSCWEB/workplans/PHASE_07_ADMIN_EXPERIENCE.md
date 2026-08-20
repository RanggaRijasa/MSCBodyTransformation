# MSCWEB W07 — Admin experience

Status: `Completed`
Autonomy: `A` locally; `C` for ambiguous operational authority  
Depends on: stable Participant, payment, evidence, Coach, scoring, public-profile, and W06.5 food-insight contracts

## Objective

Deliver Admin parity for Dashboard, Program, People, Content, payment/application review, scoring corrections, winner locking, fallback operations, settings, and audit—optimized for both compact and wide web.

## Required references

- `00_PRODUCT_SPEC.md` Admin requirements
- `02_UX_PARITY_AND_ROUTES.md`
- `03_DESIGN_SYSTEM.md`
- `05_DATA_SECURITY.md`
- program end-to-end contract matrix
- current iOS Admin simulator flows for every implemented area

## Deliverables

- Admin Dashboard attention/metrics/quick actions;
- Program CRUD/draft/publish/archive/list/search/preview;
- People Peserta/Coach/Admin and detail/actions;
- Content authoring using shared Participant renderer;
- integrated payment and Coach application review;
- Coach public-profile content moderation and AI insight operational visibility;
- scoring adjustments, winner preview/lock/snapshot;
- approved enrollment fallback operations and audit/settings;
- compact and data-dense wide layouts.

## Mandatory simulator gate

- [x] Inspect Admin Dashboard, Program list/detail/editor, People segments/details, Content, and Settings.
- [x] Inspect attention cards, metrics, search, filters, create action, status badges, sheets/dialogs, and decision copy.
- [x] Inspect payment and Coach application states built in W05/W06.
- [x] For each slice, compare compact to iOS and design a documented wide adaptation rather than stretching cards.

## Checklist

### Navigation/dashboard

- [x] Destinations: Dashboard, Program, Orang, Konten, Pengaturan.
- [x] Attention and metrics use authoritative aggregates with loading/empty/error/stale states.
- [x] Wide layout uses table/list/two-pane where it reduces context switching.

### Program/content

- [x] Program lifecycle transitions validated server-side and audited.
- [x] Search/filter/list/detail/draft validation/publish/archive behavior.
- [x] Content authoring covers all published step types and required questions.
- [x] Preview uses the same renderer/domain definition as Participant.
- [x] Published scoring/content behavior cannot change silently.

### People/operations

- [x] Segments Peserta, Coach, Admin with protected details/actions.
- [x] No direct unsafe role write from client.
- [x] Payment/evidence/application queue integration.
- [x] Authorized fallback enrollment/scoring corrections require reason and audit.
- [x] Winner calculation preview handles ties/fewer than five; lock creates stable snapshot.
- [x] Settings never display or edit secrets in browser.
- [x] Admin Coach detail shows public-profile publication state without exposing hidden contact fields outside authorized detail.
- [x] Testimonial/before–after moderation supports approve/reject-with-reason and records actor/time/content version.
- [x] Admin can inspect AI job/result status, provider/model alias, version, and redacted error code without seeing API key, prompt, raw provider payload, or private path.
- [x] Authorized AI rating correction requires reason/audit and cannot mutate approval, points, or leaderboard ledger.

## Sub-agent plan

- `msc_explorer`: one iOS/Admin area and associated backend authority map at a time.
- `msc_implementer`: sole writer for a bounded Admin vertical slice.
- `msc_reviewer`: privilege/authority/audit, shared preview parity, responsive density, accessibility, and test coverage.

The primary agent owns shared program renderer, authority operation interfaces, navigation root, and migration order.

## Verification

- authorization/RLS/RPC tests for every mutation;
- program lifecycle/content validation/published immutability tests;
- score correction/weight gain/duplicate/tie/fewer-than-five/winner lock tests;
- Admin Playwright journeys compact and wide;
- keyboard/data-table/dialog accessibility;
- simulator parity and wide design review;
- audit record completeness and sensitive-log scan.
- public-profile moderation and hidden-contact leakage tests;
- food-insight redaction/correction/point-independence tests.

## Exit criteria

- All in-scope iPhone Admin capabilities have implementation and parity evidence or explicit accepted deferral.
- Browser cannot bypass authority functions through direct writes.
- Program preview and Participant renderer do not diverge.
- Winner lock and adjustments are stable, audited, and private-weight safe.
- Public Coach media is moderated without reusing private evidence, and AI operational tools reveal no provider secret/raw payload.

## User input or authorization

- Product decision for any fallback/correction action not settled by existing contracts.
- Explicit acceptance of any deferred iPhone Admin capability.
- Production Admin roster/configuration is not part of local completion.

## Progress log

Append simulator area, compact/wide behavior, operations/tests, audit evidence, decisions/deferrals, files/commands, and next item.

### 2026-08-17 — W07 completed locally

- Requirement IDs: `PROD-001/002/004/006/007`, `PROD-ADM-001…004`, `PROD-OPS-003…005`, `PROD-LDB-001…003`, `SEC-001…006`, `SEC-DATA-004…008`, `SEC-AUTHZ-001…003`, `SEC-OP-001…004`, `UX-001…003`, `UX-NAV-001…004`, `UX-RSP-001…005`, `QA-001…003`, `QA-JRN-002/005`, `QA-CPR-003/004`, dan acceptance Admin/AI terkait.
- iOS Simulator: build/run current source lulus pada iPhone 17, iOS 26.5, locale `id_ID`, skenario `admin_draft_editor` dan `admin_winner_lock`. Fresh runtime inspection mencakup Dashboard, Program list/filter/create, draft hub tiga tahap, published/read-only hub, People Peserta/Coach/Admin, detail profil per role, applicant Coach (level, HOM STS, ICT, harga, pembayaran, periode, approve/reject), Content poster gallery/editor, Settings, transfer Coach, enrollment manual, closure, dan winner lock. Tidak ada source iOS/Xcode yang diubah.
- Compact fidelity: hierarchy, copy, tab order, semantic colors, grouped rows, two-column poster gallery, stage cards, read-only lock copy, status badges, chevron, minimum touch target, dan bottom navigation dibandingkan dengan runtime serta design references `Design/AdminDashboard` dan `Design/AdminProgramFlow`. Drift yang diperbaiki: label tab terpotong, dots menggantikan chevron, primary quick-action surface terlalu merah, dan dialog poster tidak dapat digulir.
- Wide adaptation: bottom navigation berubah menjadi sidebar; Dashboard memakai grouped operational rows/metrics, Program memakai data-dense list rows, dan People/Content memakai bounded wide lists/panels. Detail tetap route terpisah agar browser history, deep link, dan focus restoration stabil; card tidak sekadar diregangkan memenuhi desktop.
- Intentional web deviations: `Pembayaran manual` ditambahkan ke attention karena StoreKit iOS diganti transfer/QRIS web; People menambah pencarian; Content menambah segment `Moderasi` dan `Insight AI`; wide memakai sidebar/list. Dashboard tetap hanya mempunyai dua quick action iOS yang unik (`Buat program`, `Tambah poster`) dan tidak mengulang `Kelola program/orang`.
- Program/content: server-authoritative save/publish/duplicate/archive, food-analysis configuration preservation, semua 7 content kinds, semua 9 question kinds, answer key, copy-day multi-target dengan nested ID baru, shared Participant preview renderer, published immutability, closure preflight, deterministic winner preview, stable lock, dan real poster upload/publish selesai.
- People/operations: protected role segments/detail, Coach application/payment review, evidence monitoring, manual enrollment cutoff fallback, Coach transfer, score adjustment, private weigh-in detail, public-profile publication state, moderation v2, redacted AI operations, Admin AI correction, audit list, dan secret-free settings selesai. People list memakai projection minimal; email/nomor HP/biografi hanya diambil melalui authorized detail RPC.
- Authority/audit evidence: non-Admin RPC ditolak; Admin direct table write ke program/score ditolak; every mutation memakai narrow RPC, server role check, safe `search_path`, reason/idempotency/version where applicable, dan audit before/after. Integration proves equal-score deterministic tie-break, fewer-than-five winners, immutable snapshot, moderation conflict/idempotency, hidden-contact redaction, AI path/rubric redaction, dan AI correction point independence.
- Verification passed: `npm run typecheck`; `npm run lint -- --no-cache`; `npm test` (`136` passed, `7` local-environment skipped); explicit `admin-experience.local.test.ts` (`1` passed); `npm run build` (`43` JS bundles); Admin Playwright compact+desktop (`8` passed); W05 payment Playwright serial compact+desktop (`4` passed); Coach/evidence/AI regression (`10` passed); `npm run verify:bundle`; `npm run verify:pwa`; local Supabase security and performance advisors (`No issues found`). Browser plugin verified unauthorized Admin shell/navigations fail closed with no console warning/error; authenticated journeys used project Playwright because Browser sessions were not injected with local auth tokens.
- Visual QA/fidelity ledger: Dashboard content order and quick actions match; Program search/create/filter/list and draft/published hubs match; People segments/rows/detail hierarchy match; Content poster hierarchy/gallery match; Settings grouped values match; compact nav labels/icons fit; light/dark compact and wide screenshots inspected with `view_image`. No remaining material visual mismatch was accepted silently.
- External state: migration `20260817014822_w07_admin_experience.sql` applied only to Supabase local. Colima, Supabase, preview server `127.0.0.1:4173`, and the iOS Simulator were left running. No hosted Supabase/Cloudflare deployment, production roster/configuration, Git mutation, credential, or secret mutation was performed.
- Remaining W07 blockers: none. Next unchecked phase: W08 PWA and Cloudflare hardening.

### 2026-08-17 — Koreksi parity editor Program Admin

- Requirement IDs: `PROD-ADM-001`, `PROD-004`, `PROD-006`, `UX-001…003`, `UX-RSP-001…005`, `QA-001…003`, dan kontrak Admin → published program pada `PROGRAM_END_TO_END_CONTRACT_MATRIX.md`.
- Referensi authoritative: simulator/screenshot iPhone 17 iOS 26.5 dan source SwiftUI `AdminProgramEditorView.swift`, `AdminProgramSettingsViews.swift`, `AdminProgramContentPlannerView.swift`, serta `AdminStepContentEditorView.swift`. Tidak ada source iOS atau project Xcode yang diubah.
- Hub program: header draft, progress merah, status draft, dan tiga tahap memakai hierarchy, icon, status, grouped surface, serta navigasi inline seperti iOS. Header AppShell besar disembunyikan hanya pada detail Program Admin; bottom navigation tetap dipertahankan.
- Pengaturan program: form panjang tunggal dipecah menjadi hub `Info program`, `Jadwal dan peserta`, serta `Aturan dan poin`. `Gratis/Berbayar` dipulihkan di section `Pembayaran` pada Info program; mode berbayar menampilkan harga IDR. Cover memakai pratinjau 16:9, picker asli browser, ganti/hapus, dan teks alternatif.
- Konten program: accordion editor tunggal diganti dengan daftar jadwal dan hari, sinkronisasi schedule, mode Edit untuk urutan/hapus, tambah hari, detail hari, salin isi multi-target, dialog tujuh jenis langkah, editor langkah per jenis, pertanyaan typed, opsi/kunci jawaban, gambar pilihan, serta konfigurasi insight makanan. Mutasi draft tetap melalui RPC repository yang sama.
- Tinjau & terbitkan: kembali menjadi grouped flow `Pratinjau`, `Validasi`, `Ringkasan`, dan primary publish. Pratinjau Peserta/Coach berada di destination terpisah dan tetap memakai shared Participant renderer.
- Files: `src/features/admin/AdminProgramEditorShared.tsx`, `AdminProgramEditorFlow.tsx`, `AdminProgramContentFlow.tsx`, `AdminProgramComponents.tsx`, `src/app/admin/programs/[programId].tsx`, `src/shared/navigation/AppShell.tsx`, `tests/unit/admin-experience-contract.test.ts`, dan `tests/e2e/admin-experience.spec.ts`.
- Verification passed: `npm run typecheck`; `npm run lint -- --no-cache`; `npm test` (`136` passed, `7` environment-skipped); `npm run build` (`43` JS bundles); `npm run verify:bundle`; `npm run verify:pwa`; Admin Playwright compact+desktop (`8` passed). Android Chrome emulator memverifikasi hub, Info/Gratis-Bayar, Konten/day/type picker, preview, dan review/publish pada build produksi terbaru.
- Visual fidelity ledger: grouped background/surface, inline title/back/action, progress/status, three-stage cards, payment segment, cover framing, schedule/day rows, `Edit`, validation list, summary rows, and bottom navigation dibandingkan langsung melalui `view_image`. Perbedaan platform yang dipertahankan hanya Chrome toolbar dan native browser file picker; tidak ada perbedaan produk yang disengaja.
- External state: perubahan hanya source web dan data/test lokal. Tidak ada migration baru, hosted Supabase/Cloudflare deployment, production mutation, Git mutation, credential change, atau Xcode project change. Server lokal, Supabase lokal, dan Android emulator tetap berjalan.
- Remaining W07 blockers: none. Next unchecked phase remains W08 PWA and Cloudflare hardening.

### 2026-08-17 — Koreksi kontrol Jadwal dan peserta

- Input teks tanggal dan zona waktu diganti dengan kontrol browser native yang sebenarnya. Mode `Tanggal tertentu` menampilkan date picker Mulai/Selesai; mode `Durasi tetap` menampilkan date picker Tanggal acuan dan stepper 1–365 hari yang menghitung tanggal selesai.
- `Jenis durasi` menjadi picker `Durasi tetap`/`Tanggal tertentu`. `Zona waktu` menjadi picker allowlisted `WITA · Makassar`, `WIB · Jakarta`, dan `WIT · Jayapura`. Batas pendaftaran opsional memakai `datetime-local` picker dan menyimpan offset sesuai zona program.
- Date control menampilkan nilai terformat `id-ID` pada surface aplikasi, sementara dialog kalender tetap surface native browser/OS. Android Chrome membuktikan dialog kalender, picker durasi, picker zona waktu, dan stepper durasi tampil serta dapat digunakan.
- Verification passed: typecheck, lint, `136` unit tests, production build, dan focused Admin Playwright compact+desktop (`2` passed), termasuk persistence `fixed_duration` dan `Asia/Jakarta` melalui Supabase lokal.

### 2026-08-17 — Koreksi Aturan dan poin

- `Nilai lulus kuis` diganti dari input angka bebas menjadi stepper 0–100%. `Pemeriksaan default` menjadi picker `Otomatis`/`Pemeriksaan Coach` yang tersimpan sebagai authoring default program dan diterapkan ke langkah non-kuis/non-timbang baru.
- `Langkah lampau` menjadi picker `Tetap tersedia`/`Hanya baca`/`Disembunyikan`; `Langkah mendatang` menjadi picker `Tersedia lebih awal`/`Terkunci`/`Disembunyikan`. Copy footer menjelaskan bahwa kebijakan mengatur buka, baca-saja, kunci, atau sembunyi di luar hari aktif.
- Migration web-only `20260817090704_w07_admin_program_default_verification.sql` menambahkan `programs.default_verification_mode` dengan check constraint, memperluas narrow Admin save/duplicate RPC, mempertahankan role check, safe `search_path`, dan grant hanya untuk authenticated callers. Migration diterapkan hanya ke Supabase lokal; hosted `main` tidak disentuh.
- E2E juga menemukan dan memperbaiki mapping legacy `completion_policy` untuk langkah baru: Video → `watch_video`, Kuis → `automatic_quiz`, dan timbang → `submit_weigh_in`, sesuai kontrak backend.
- Verification passed: typecheck, lint, `137` unit tests, production build, explicit Admin integration (`1` passed), focused Admin Playwright compact+desktop (`2` passed), persistence default/policy melalui RPC, langkah Video baru memakai `automatic`, duplikasi mempertahankan default, non-Admin ditolak, dan Supabase advisors `No issues found`. Android Chrome memverifikasi stepper serta ketiga native select sheet.

### 2026-08-20 — Koreksi layout Dashboard Admin

- `Akses cepat` diselaraskan dengan iOS menjadi dua kartu seimbang dalam satu baris. Setiap kartu memakai hierarchy ikon di kiri atas, chevron di kanan atas, dan judul di bawah; aksi `Buat program` memakai tint merah tanpa full-red surface.
- `Gambaran hari ini` dipaksa menjadi tiga kolom dalam satu baris tanpa wrap. Divider hanya berada di antara Program aktif, Peserta aktif, dan Terjadwal; label dipusatkan dan angka tetap tabular.
- Tinggi halaman compact berkurang sehingga `Aktivitas terbaru` dapat digulir ke area aman di atas bottom navigation. E2E memeriksa bounding box kedua quick action, alignment ketiga metrik, dan visibilitas Aktivitas terbaru.
- Verification passed: typecheck, lint, `137` unit tests, production build, focused Admin Playwright compact+desktop (`2` passed), serta Android Chrome visual QA pada quick actions, metrics, dan activity feed.

### 2026-08-20 — Kompatibilitas order legacy pada segmen Coach

- Root cause: panel aplikasi Coach mengambil seluruh `payment_orders` dengan `purpose = coach_access`; 75 order lokal legacy tidak mempunyai `coach_application_id`, sehingga strict `coachPaymentOrderSchema` menolak seluruh response. Daftar Coach utama tetap aman karena berasal dari RPC `list_admin_people` yang terpisah.
- Repository sekarang membatasi join order aplikasi ke `coach_application_id is not null` sebelum parsing. Data legacy tidak dihapus atau dimutasi dan tetap tersedia untuk audit; hanya order yang dapat dipasangkan ke aplikasi Coach yang masuk queue Admin.
- Verification passed: typecheck, lint, `138` unit tests, production build, focused Admin Playwright compact+desktop (`2` passed), dan Android Chrome menunjukkan panel aplikasi tanpa error serta daftar Coach tetap tampil.

### 2026-08-20 — Pemisahan Direktori dan Aplikasi Coach

- Segmen Coach sekarang mempunyai secondary segmented control `Daftar Coach`/`Aplikasi Coach`. Hanya satu surface dirender pada satu waktu, sehingga queue aplikasi tidak lagi mendorong direktori Coach jauh ke bawah dan pencarian hanya tampil untuk direktori.
- Deep link `scope=coach&pending=1` meremount pengalaman Orang melalui route key dan langsung membuka Aplikasi Coach → Perlu tindakan, termasuk navigasi pada route yang sama tanpa reload penuh.
- Empty state Perlu tindakan dipadatkan menjadi inline success message. Banner pending duplikat dihapus. `Semua aplikasi` merender 20 item per batch dengan ringkasan jumlah dan tombol `Muat 20 aplikasi lagi`, sehingga histori besar tidak langsung memenuhi DOM/scroll.
- Verification passed: typecheck, lint, `139` unit tests, production build, focused Admin Playwright compact+desktop (`2` passed), dan Android Chrome visual QA untuk direktori, deep link pending, empty state, serta batch `20 dari 197` aplikasi.

### 2026-08-20 — Extension plan setelah W07

- W07 tetap `Completed`; Sales Overview dan Image Storage adalah scope web baru yang tidak mengubah exit evidence W07.
- Urutan aktif direvisi menjadi W07.4 `Registration and First-login Onboarding Remediation`, W07.5 `Admin Sales Overview`, W07.6 `Admin Image Storage Management`, lalu W08 hardening.
- Dua quick action baru adalah intentional web-only extension. Final Dashboard mempertahankan dua aksi native-derived pertama dan memakai grid 2 × 2 pada compact.
- Tidak ada source/migration/runtime W07 yang diubah oleh planning entry ini; implementasi harus mengikuti workplan baru dan fresh simulator/web gates masing-masing.
