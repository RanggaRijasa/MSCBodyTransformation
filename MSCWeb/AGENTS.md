# MSC Web/PWA Project Guidelines

Instruksi ini menambah, bukan mengganti, `../AGENTS.md`. Aturan root tetap
berlaku. Jika ada konflik, gunakan aturan yang lebih ketat dan requirement
produk terbaru di workplan web.

## Konteks produk

MSC Web adalah PWA Bahasa Indonesia dengan Guest dan tiga role terautentikasi:
Peserta, Coach, dan Admin. Peserta serta Coach memakai shell yang terasa
seperti aplikasi mobile. Admin memakai layout responsif yang mengutamakan
desktop.

PWA menggantikan distribusi App Store. Sign in with Apple dan StoreKit tidak
menjadi bagian runtime web. Pembayaran program serta akses Coach menggunakan
transfer manual, bukti pembayaran privat, pemeriksaan Admin, dan aktivasi
server-authoritative.

## Batas direktori kerja

- Seluruh file baru dan perubahan untuk implementasi Web/PWA wajib berada di
  dalam direktori `MSCWeb/` ini.
- Jangan membuat source, konfigurasi, dokumentasi hasil konversi, fixture,
  test, script, atau artefak Web/PWA baru di root repository maupun di folder
  proyek iOS.
- File dan folder di luar `MSCWeb/` hanya boleh dibaca sebagai referensi,
  kecuali pengguna secara eksplisit meminta perubahan pada path tertentu.
- Instruksi goal yang menyebut Phase Web/PWA tidak memperluas write scope:
  write scope tetap hanya `MSCWeb/`, meskipun penyelesaian goal memerlukan
  audit read-only terhadap source iOS, `Contracts`, atau `supabase` existing.
- Jika suatu phase membutuhkan perubahan pada shared backend, `Contracts`,
  hosted Supabase, DNS, domain, OAuth production, atau deployment, hentikan di
  gate tersebut dan minta persetujuan eksplisit pengguna sebelum melakukan
  perubahan.
- Jangan memindahkan, menghapus, atau mengarsipkan source iOS secara otomatis.
  Pemindahan `MSCWeb/` ke repository baru tetap merupakan tindakan manual yang
  diputuskan pengguna setelah parity dan cutover dinyatakan aman.

## Bacaan wajib sebelum mengubah source web

1. `MSCWeb_Codex_Phased_Workplan/00_START_HERE.md`.
2. Satu file phase yang sedang ditugaskan.
3. `docs/architecture/ARCHITECTURE.md`.
4. `docs/architecture/TARGET_FOLDER_STRUCTURE.md`.
5. `docs/architecture/BACKEND_AND_COMMERCE_MIGRATION.md` bila menyentuh
   Supabase, Auth, Storage, pembayaran, role, atau enrollment.
6. `../MSCBodyTransformation/MSC_Codex_Phased_Workplan/UI_REFERENCE_SHEET.md`
   sebelum membuat atau mengubah UI.
7. Implementasi dan test iOS terdekat sebagai referensi perilaku, bukan
   sebagai source yang harus diterjemahkan baris demi baris.

## Batas platform

- Jangan mengubah source iOS kecuali pengguna secara eksplisit meminta.
- Jangan mengedit `project.pbxproj`.
- Jangan menghapus adapter Apple atau StoreKit selama masa parity.
- Selama transisi, `../supabase` dan `../Contracts` tetap satu-satunya source
  backend dan kontrak. Jangan membuat salinan aktif yang kemudian berkembang
  terpisah.
- Pemindahan backend ke dalam `MSCWeb` hanya dilakukan melalui cutover
  terverifikasi di Phase 13.
- Hosted Supabase `main`, DNS, domain, OAuth production, dan deployment
  production memerlukan persetujuan eksplisit pengguna pada phase terkait.

## Arah dependensi

```text
Route/Page
  -> feature component/state
  -> use case/domain service
  -> repository interface
  -> Supabase/browser/server adapter
  -> Postgres/RPC/Edge Function/Storage
```

- Route hanya menyusun layout, boundary, dan feature entry point.
- Komponen tidak menjalankan query Supabase langsung.
- Domain tidak mengimpor React, Next.js, Supabase, browser API, atau library UI.
- Otorisasi, scoring, enrollment, pembayaran verified, dan role tidak pernah
  authoritative di browser.
- Gunakan Server Component sebagai default bila interaktivitas browser tidak
  diperlukan. Tambahkan `use client` pada boundary sekecil mungkin.
- Jangan mengimpor file internal feature lain. Gunakan public feature entry
  point atau shared domain contract.

## Modularitas dan ukuran file

- Satu file handwritten memiliki satu tanggung jawab yang dapat disebutkan
  dengan jelas.
- Target normal: maksimal 250 baris untuk `.ts` dan `.tsx` handwritten.
- Review dan pemecahan wajib saat file melewati 400 baris.
- File handwritten di atas 500 baris adalah blocking defect kecuali berupa
  migration SQL yang tidak aman dipecah; pengecualian wajib didokumentasikan.
- Generated types, lockfile, fixture data, dan snapshot dikecualikan dari
  batas baris, tetapi tidak boleh diedit manual.
- `page.tsx`, `layout.tsx`, dan route handler harus tipis; pindahkan perilaku
  ke feature/use case/repository.
- Jangan membuat satu `ParticipantService`, `AdminDashboard`, repository,
  schema, constants, atau test file yang menampung seluruh produk.
- Pecah berdasarkan capability dan vertical slice, bukan sekadar mengejar
  angka baris.

## Bahasa, format, dan aksesibilitas

- Semua copy aplikasi menggunakan Bahasa Indonesia dan locale `id-ID`.
- Gunakan `Intl.NumberFormat`, `Intl.DateTimeFormat`, dan formatter bersama.
- Timezone program selalu IANA dan keputusan hari aktif berasal dari server.
- Copy reusable berada dalam katalog terpusat; key mentah tidak boleh terlihat.
- Minimum target interaksi 44 x 44 CSS pixel.
- Semantik HTML, keyboard, focus management, screen reader, contrast,
  `prefers-reduced-motion`, dark mode, dan zoom 200% adalah acceptance gate.
- Status tidak boleh disampaikan dengan warna saja.

## Supabase dan keamanan

- Browser hanya menerima Supabase URL dan publishable key.
- Jangan pernah mengekspos secret key, `service_role`, database password,
  JWT secret, atau private provider credential melalui `NEXT_PUBLIC_*`.
- Gunakan client browser dan server terpisah dengan session cookie sesuai
  dokumentasi Supabase SSR yang berlaku pada versi terpasang.
- Proteksi server memvalidasi token/claims; jangan mempercayai user object
  dari session yang belum diverifikasi.
- Role tidak berasal dari `user_metadata`.
- Semua tabel exposed wajib memiliki explicit grants dan RLS.
- `SECURITY DEFINER` hanya untuk operasi yang benar-benar memerlukannya,
  diletakkan di schema non-exposed, memeriksa actor, mengunci search path,
  membatasi execute grant, dan diuji.
- Bukti transfer, berat badan, jawaban foto, dan media privat tidak boleh
  masuk log, analytics payload, cache publik, error report, atau URL publik.
- Service worker tidak boleh menyimpan authenticated HTML, respons Supabase,
  signed URL, bukti transfer, atau media privat.

## Dependency dan versi

- Gunakan dependency minimum dan pin versi yang kompatibel di lockfile.
- Verifikasi dokumentasi/changelog sebelum menambah atau memperbarui Next.js,
  Supabase, PWA/service-worker, QR, media, atau testing packages.
- Dependency QR/PWA/media baru memerlukan spike kecil dan alasan mengapa Web
  Platform API saja tidak cukup.
- Jangan menambah library UI besar hanya untuk beberapa komponen.

## Testing dan penyelesaian phase

- Tulis production code dan test perilakunya dalam slice yang sama.
- Gunakan deterministic clock, IDs, fixtures, dan role scenarios.
- Uji unit domain, integration repository/RPC, component interaction, contract,
  dan E2E sesuai risiko perubahan.
- Uji browser minimum: Safari iOS, Chrome Android, dan satu desktop Chromium.
- Kamera, Add to Home Screen, standalone display, permission denial, upload,
  dan lifecycle PWA harus diuji pada perangkat fisik sebelum cutover.
- Jalankan command terkecil yang relevan; sebelum phase selesai jalankan lint,
  typecheck, test fokus, dan production build.
- Perbarui checklist serta progress log phase dengan file, asumsi, command,
  hasil, dan blocker.
- Jangan menandai selesai bila hanya fixture/mock yang lulus sementara phase
  mensyaratkan Supabase lokal atau hosted environment.

## Git dan deployment

- Ikuti seluruh Git Restrictions dari `../AGENTS.md`.
- Tidak ada `git add`, commit, push, branch, PR, atau deploy tanpa permintaan
  eksplisit pengguna untuk tindakan tersebut.
- Preview dan production deployment adalah perubahan eksternal; lakukan hanya
  saat phase dan pengguna memberi otorisasi.
