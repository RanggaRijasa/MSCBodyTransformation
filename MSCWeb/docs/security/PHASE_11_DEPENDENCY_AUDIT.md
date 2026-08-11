# Dependency audit Phase 11

Tanggal: 11 Agustus 2026

- Production vulnerability audit: `pnpm audit --prod --audit-level high` → tidak ada vulnerability yang diketahui.
- SPDX 2.3 inventory: `docs/security/PHASE_11_SPDX_SBOM.json`, 127 package termasuk optional platform variants.
- Declared license: seluruh 127 package memiliki deklarasi; tidak ada `NOASSERTION`.
- Dependency langsung baru: `web-push@3.6.7` (MIT) dan typing development `@types/web-push@3.6.4` (MIT).
- LGPL yang terdeteksi berasal dari binary libvips optional/transitif milik Sharp/Next image pipeline. Distribusi tetap memakai package upstream tanpa modifikasi atau static relink; notice/license upstream harus dipertahankan oleh build/deployment. Tidak ada AGPL, SSPL, atau GPL application dependency.
- Package production dipin lewat `pnpm-lock.yaml`; Node 24.19.0 dan pnpm 11.21.0 dipin melalui engine/packageManager.

Regenerate inventory setelah perubahan lockfile:

```bash
PATH=/opt/homebrew/opt/node@24/bin:$PATH node scripts/generate-phase11-sbom.mjs
```

Audit registry membutuhkan internet dan harus diulang pada Phase 12 tepat sebelum deployment production.
