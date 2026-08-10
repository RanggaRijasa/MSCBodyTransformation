# Target Folder Structure

Struktur ini adalah target setelah scaffold. Folder dibuat bertahap oleh phase;
jangan membuat file kosong hanya agar tree terlihat lengkap.

```text
MSCWeb/
├── AGENTS.md
├── README.md
├── package.json
├── pnpm-lock.yaml
├── next.config.ts
├── open-next.config.ts
├── wrangler.jsonc
├── tsconfig.json
├── eslint.config.mjs
├── public/
│   ├── icons/
│   └── images/
├── src/
│   ├── app/
│   │   ├── (marketing)/
│   │   ├── (public)/
│   │   ├── (auth)/
│   │   ├── (participant)/
│   │   ├── (coach)/
│   │   ├── admin/
│   │   ├── auth/callback/
│   │   ├── manifest.ts
│   │   ├── layout.tsx
│   │   ├── error.tsx
│   │   └── not-found.tsx
│   ├── features/
│   │   ├── landing/
│   │   ├── pwa-install/
│   │   ├── auth/
│   │   ├── profiles/
│   │   ├── programs/
│   │   ├── enrollment/
│   │   ├── payments/
│   │   ├── activities/
│   │   ├── submissions/
│   │   ├── weigh-ins/
│   │   ├── leaderboard/
│   │   ├── coach-dashboard/
│   │   ├── coach-review/
│   │   ├── admin-dashboard/
│   │   ├── admin-programs/
│   │   ├── admin-people/
│   │   ├── admin-payments/
│   │   └── managed-content/
│   ├── domain/
│   │   ├── models/
│   │   ├── services/
│   │   ├── repositories/
│   │   ├── validation/
│   │   └── errors/
│   ├── infrastructure/
│   │   ├── supabase/
│   │   │   ├── client/
│   │   │   ├── dto/
│   │   │   ├── mappers/
│   │   │   └── repositories/
│   │   ├── browser-media/
│   │   ├── qr/
│   │   ├── payments/
│   │   └── telemetry/
│   ├── shared/
│   │   ├── ui/
│   │   ├── layout/
│   │   ├── hooks/
│   │   ├── i18n/
│   │   ├── formatting/
│   │   ├── config/
│   │   ├── constants/
│   │   └── types/
│   ├── styles/
│   │   ├── tokens.css
│   │   └── globals.css
│   └── proxy.ts
├── tests/
│   ├── unit/
│   ├── component/
│   ├── integration/
│   ├── contract/
│   ├── e2e/
│   ├── accessibility/
│   └── fixtures/
├── scripts/
│   ├── check-file-size.mjs
│   ├── check-localization.mjs
│   └── verify-pwa.mjs
├── docs/
│   ├── architecture/
│   ├── design/
│   ├── operations/
│   └── decisions/
└── MSCWeb_Codex_Phased_Workplan/
```

## Struktur internal feature

Tidak semua feature harus memiliki semua folder. Buat hanya yang diperlukan.

```text
features/payments/
├── components/
├── state/
├── schemas/
├── use-cases/
├── server/
├── tests/
└── index.ts
```

- `components`: rendering dan interaksi lokal.
- `state`: state machine/controller UI, bukan authoritative business state.
- `schemas`: validasi input form/transport feature.
- `use-cases`: orkestrasi domain dan repository interface.
- `server`: composition khusus server; harus memakai `server-only` boundary.
- `index.ts`: public API kecil. Jangan mengekspor seluruh internal tree.

## Aturan route

Route files hanya boleh:

- mendeklarasikan metadata;
- memuat actor/role melalui server boundary;
- memilih shell/layout;
- memanggil feature entry point;
- mendefinisikan loading/error/not-found boundary.

Query, mapping DTO, validation bisnis, upload pipeline, atau mutation tidak
boleh tinggal di `page.tsx`.

## Target ukuran

| Jenis file | Target | Review wajib |
|---|---:|---:|
| Route/layout | 80 baris | 150 baris |
| React component | 180 baris | 300 baris |
| State/use case/repository | 250 baris | 400 baris |
| Unit/component test | 300 baris | 450 baris |
| Handwritten apa pun | 250 baris | 400 baris |

Di atas 500 baris adalah blocking kecuali generated artifact atau migration
yang memiliki alasan transactional untuk tetap satu file.

## Backend selama transisi dan setelah cutover

Selama implementasi di repository gabungan:

```text
../supabase    -> source backend authoritative
../Contracts   -> source contract authoritative
MSCWeb         -> source frontend dan workplan web
```

Jangan membuat symlink yang rusak ketika folder dipindahkan ke repository
baru. Phase 13 melakukan inventory hash, memindahkan satu salinan backend dan
contract yang telah diverifikasi ke repository target, lalu menetapkan owner
baru. Tidak ada periode dua salinan yang sama-sama boleh menerima perubahan.
