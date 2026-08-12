# Keputusan Tailwind CSS dan shadcn/ui Phase 11A

## Status

Disetujui lokal untuk Slice 11A.3. Dokumen ini membekukan fondasi
compatibility sebelum primitive visual ditambahkan pada slice berikutnya.

## Tooling dan versi

Compatibility spike memakai Node.js 24.19.0, pnpm 11.21.0, dan shadcn CLI
4.16.2 melalui command sekali pakai berikut:

```bash
pnpm dlx shadcn@4.16.2
```

CLI shadcn tidak menjadi runtime dependency. Primitive registry selalu
dipreview dengan `add --dry-run` dan `add --diff`, lalu source hasilnya direview
sebelum masuk aplikasi.

Dependency production dipin exact:

- `@base-ui/react` 1.7.0 untuk primitive interaktif Base UI.
- `class-variance-authority` 0.7.1 untuk variant primitive yang typed.
- `clsx` 2.1.1 dan `tailwind-merge` 3.6.0 untuk helper `cn` tunggal.

Dependency build dipin exact:

- `tailwindcss` 4.3.3.
- `@tailwindcss/postcss` 4.3.3.
- `postcss` 8.5.26 sebagai compiler API langsung yang sama dengan graph
  Tailwind/Vite dan dipakai oleh contract test.

Transitive package dari Base UI dan compiler Tailwind diterima hanya sebagai
dependency dari tujuh pin tersebut. `shadcn`, `lucide-react`, `tw-animate-css`,
dan Geist tidak ditambahkan. Icon tetap memakai kontrak `AppIcon`; motion
tetap scoped dan menghormati reduced motion.

## Cascade dan pemindaian class

`src/styles/tailwind-compatibility.css` mendeklarasikan urutan layer `theme`,
`base`, `components`, lalu `utilities`. File itu mengimpor hanya
`tailwindcss/theme.css` dan `tailwindcss/utilities.css`. Tailwind Preflight,
full import `tailwindcss`, stylesheet shadcn, reset global, token neutral
bawaan, serta override `html`, `body`, atau `:root` sengaja tidak dipakai.

Source scan production hanya mencakup `src`; gallery development dan test
tidak boleh memperbesar CSS route production. Auto-detection dimatikan dengan
`source(none)`, lalu allowlist `@source "../"` mengaktifkan hanya tree `src`.
Contract test memakai directive inline sentinel milik Tailwind v4 untuk
membuktikan utility literal dikompilasi dan utility dinamis/terlarang tidak
ikut dihasilkan. Nama utility harus berbentuk literal lengkap pada source.
Jangan menyusun class secara dinamis seperti `bg-${warna}-500`; gunakan map
literal atau `cn()` dengan branch class lengkap agar compiler, review, dan
bundle tetap deterministik.

Legacy CSS tetap aktif sampai route pemiliknya dimigrasikan. Utility dan
primitive baru wajib membaca semantic variable MSC. Preflight baru boleh
dipertimbangkan setelah audit seluruh raw control dan approval PM/reviewer.

## RSC, keamanan, dan deployment target

Server Component tetap default. Primitive Base UI yang memakai state, event,
portal, focus management, atau browser API menjadi Client Component pada leaf
boundary terkecil; dependency tersebut tidak boleh dipromosikan melalui
barrel yang membuat seluruh route menjadi client-side.

Tailwind dan PostCSS berjalan pada build time dan menghasilkan CSS statis.
Konfigurasi ini tidak mengubah Content Security Policy, tidak membutuhkan
`eval`, inline script, CDN font, registry call saat runtime, atau akses
backend. Base UI dapat memakai style attribute untuk positioning; policy saat
ini sudah mengizinkan inline style dan tidak perlu dilonggarkan.

Output CSS statis kompatibel dengan target Cloudflare Workers melalui
OpenNext karena compiler tidak menjadi runtime Worker. Setiap primitive baru
tetap harus melewati build, bundle budget, WebKit/Chromium, accessibility,
reduced motion/transparency, dan review Cloudflare/OpenNext sebelum diterima.

Project build gate memakai builder webpack resmi Next 16:

```bash
pnpm run build
# menjalankan: next build --webpack
```

Pilihan ini mengisolasi keterbatasan environment saat Turbopack mengevaluasi
loader PostCSS: proses tersebut mencoba membuat subprocess dan mengikat port
internal, lalu mendapat `EPERM` bahkan pada retry dengan network escalation.
Builder webpack mengompilasi konfigurasi dan route yang sama tanpa kebutuhan
port loader tersebut. Keputusan ini tidak mengubah runtime browser, CSP,
backend, cache, route, atau kontrak data.

Script `verify` memanggil `pnpm run build`, bukan menjalankan `next build`
secara langsung, agar gate agregat dan gate build tunggal selalu memakai
builder yang sama. Contract test mengunci kedua script tersebut.

TODO gate: evaluasi ulang Turbopack hanya setelah environment build mendukung
subprocess loader dan port internal. Re-evaluasi wajib menjalankan focused
Tailwind compile test serta build/regression penuh sebelum script diganti.
Keterbatasan environment Turbopack ini bukan blocker Phase 11A selama builder
webpack resmi Next tetap lulus.

## Audit dependency dan SBOM

Pada 12 Agustus 2026, `pnpm generate:phase11:sbom` menghasilkan ulang
`docs/security/PHASE_11_SPDX_SBOM.json` dengan 141 package production. SHA-256
lockfile `66131bb714b3105567cceaf04930cdf1dcc0a42cade7af2a29ceb552ab96620a`
sama dengan suffix `documentNamespace` SBOM. Inventory mencakup dependency
langsung baru serta graph Base UI, termasuk `@base-ui/utils`, keluarga
`@floating-ui`, `reselect`, dan `use-sync-external-store`.

Seluruh package memiliki `licenseDeclared`; tidak ada nilai
`licenseDeclared: NOASSERTION`. Base UI dan dependency floating memakai MIT,
`class-variance-authority` memakai Apache-2.0, sedangkan `clsx` dan
`tailwind-merge` memakai MIT. `licenseConcluded` dan `downloadLocation` tetap
`NOASSERTION` sesuai kebijakan generator SPDX existing, bukan karena metadata
lisensi package hilang. Dependency build seperti PostCSS tidak masuk inventory
production, tetapi perubahannya tetap tercakup oleh digest lockfile.

Audit production berikut lulus dengan hasil `No known vulnerabilities found`:

```bash
pnpm audit --prod --audit-level high
```

## Batas konfigurasi shadcn

`components.json` memilih preset Base UI `base-nova`, RSC, TypeScript, dan
alias ke `src/shared/ui`. File ini hanya konfigurasi registry; keberadaannya
tidak menyatakan bahwa suatu component telah terpasang. Tidak ada icon library
yang dideklarasikan sampai dependency icon terpisah mendapat approval. CLI
4.16.2 tetap menampilkan Lucide dan Geist sebagai fallback preset ketika field
tersebut dihilangkan. Karena itu setiap `add` wajib melalui dry-run/diff dan
hasil source harus mempertahankan `AppIcon` serta font MSC; dependency Lucide
atau perubahan layout/font fallback tidak boleh diterima otomatis.
