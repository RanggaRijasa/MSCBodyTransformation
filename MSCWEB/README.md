# MSCWEB — paket spesifikasi

Status: `Draft 1 — baseline untuk spec-driven development`  
Tanggal baseline: `12 Agustus 2026`  
Revisi terakhir: `20 Agustus 2026 — first-login onboarding remediation, Sales Overview, dan Image Storage Admin`
Produk: `MSC Body Transformation Web App / PWA`

Folder ini berisi spesifikasi untuk memindahkan kemampuan aplikasi iPhone MSC Body Transformation ke web app/PWA yang terasa seperti aplikasi mobile, tanpa pembayaran App Store. Folder ini belum berisi implementasi aplikasi web.

## Cara menggunakan spesifikasi

Urutan otoritas keputusan:

1. Spesifikasi di folder ini untuk keputusan khusus web, PWA, autentikasi Google, pembayaran manual, dan Cloudflare.
2. Kontrak produk iOS yang dirujuk oleh dokumen ini untuk aturan program, peran, skor, bukti aktivitas, dan privasi.
3. Implementasi iOS yang berjalan sebagai referensi visual dan interaksi.
4. Jika ketiganya berbeda, pekerjaan dihentikan pada batas perbedaan tersebut dan sebuah ADR baru harus disetujui sebelum implementasi dilanjutkan.

Kata `MUST`, `MUST NOT`, `SHOULD`, dan `MAY` adalah kata normatif. Setiap perubahan produksi harus menunjuk requirement ID dan acceptance criteria yang relevan.

## Isi paket

| Dokumen | Isi |
|---|---|
| [00_PRODUCT_SPEC.md](./00_PRODUCT_SPEC.md) | visi, ruang lingkup, peran, kemampuan, dan success criteria |
| [01_ARCHITECTURE.md](./01_ARCHITECTURE.md) | stack, batas modul, routing, data flow, dan strategi migrasi |
| [02_UX_PARITY_AND_ROUTES.md](./02_UX_PARITY_AND_ROUTES.md) | inventaris layar iOS, parity matrix, navigasi, gesture, dan responsivitas |
| [03_DESIGN_SYSTEM.md](./03_DESIGN_SYSTEM.md) | StyleSheet, design tokens, Phosphor, motion, accessibility, dan App Icon |
| [04_MANUAL_PAYMENT.md](./04_MANUAL_PAYMENT.md) | pembayaran transfer/QRIS statis dan approval Admin |
| [05_DATA_SECURITY.md](./05_DATA_SECURITY.md) | model data, RLS, Storage, authorization, audit, dan privasi |
| [06_PWA_HOSTING.md](./06_PWA_HOSTING.md) | installability, offline boundary, Cloudflare, domain, dan observability |
| [07_TESTING_ACCEPTANCE.md](./07_TESTING_ACCEPTANCE.md) | definition of done, matriks pengujian, dan acceptance scenarios |
| [08_DELIVERY_PLAN.md](./08_DELIVERY_PLAN.md) | urutan implementasi, checkpoint, dan kriteria pemisahan repository |
| [09_SIMULATOR_AUDIT.md](./09_SIMULATOR_AUDIT.md) | bukti audit simulator dan detail visual yang menjadi baseline |
| [decisions/](./decisions) | architecture decision records yang sudah disepakati |
| [workplans/](./workplans) | workplan eksekusi W00–W09 termasuk W06.5 serta remediation W07.4–W07.6, delegation map, exit criteria, dan permission matrix |
| [references/landing/](./references/landing) | konsep visual landing desktop/mobile hasil ImageGen dan aturan penggunaannya |

## Sumber produk yang tetap berlaku

- `../MSCBodyTransformation/MSC_Codex_Phased_Workplan/00_START_HERE.md`
- `../MSCBodyTransformation/MSC_Codex_Phased_Workplan/UI_REFERENCE_SHEET.md`
- `../MSCBodyTransformation/MSC_Codex_Phased_Workplan/PROGRAM_END_TO_END_CONTRACT_MATRIX.md`
- aturan repository pada `../AGENTS.md`

## Batas baseline ini

Baseline ini tidak mengizinkan:

- perubahan source aplikasi iOS;
- deployment Cloudflare atau production Supabase;
- penambahan credential, secret, atau service-role key;
- pembayaran App Store/StoreKit di web;
- self-assignment role Coach atau Admin;
- implementasi Android;
- penggunaan Tailwind/NativeWind, icon dari `div`/CSS, atau campuran beberapa icon family.

Perubahan terhadap keputusan di atas harus melalui ADR baru.
