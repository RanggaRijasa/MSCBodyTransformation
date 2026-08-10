# Workplan Manifest

Status awal seluruh implementation phase adalah `BELUM DIMULAI`.

| Urutan | Phase | File | Prasyarat | Status |
|---:|---|---|---|---|
| 1 | 00 | `01_PHASE_00_BASELINE_AND_CONTRACT_FREEZE.md` | — | Selesai |
| 2 | 01 | `02_PHASE_01_WEB_FOUNDATION.md` | 00 | Belum dimulai |
| 3 | 02 | `03_PHASE_02_DESIGN_SYSTEM_AND_SHELLS.md` | 01 | Belum dimulai |
| 4 | 02A | `03A_PHASE_02A_PUBLIC_LANDING_AND_INSTALL_CTA.md` | 02 | Belum dimulai |
| 5 | 03 | `04_PHASE_03_GUEST_AUTH_AND_ONBOARDING.md` | 02A | Belum dimulai |
| 6 | 04 | `05_PHASE_04_BROWSER_MEDIA_QR_AND_VIDEO.md` | 02–03 | Belum dimulai |
| 7 | 05 | `06_PHASE_05_PROGRAM_CATALOG_AND_ENROLLMENT.md` | 03–04 | Belum dimulai |
| 8 | 06 | `07_PHASE_06_MANUAL_PAYMENTS_AND_ADMIN_VERIFICATION.md` | 05 | Belum dimulai |
| 9 | 07 | `08_PHASE_07_PARTICIPANT_EXPERIENCE.md` | 03–06 | Belum dimulai |
| 10 | 08 | `09_PHASE_08_COACH_EXPERIENCE.md` | 03–07 | Belum dimulai |
| 11 | 09 | `10_PHASE_09_ADMIN_CMS_AND_OPERATIONS.md` | 03–08 | Belum dimulai |
| 12 | 10 | `11_PHASE_10_SCORING_LEADERBOARD_AND_CLOSURE.md` | 07–09 | Belum dimulai |
| 13 | 11 | `12_PHASE_11_PWA_QUALITY_SECURITY_AND_RELIABILITY.md` | 02A–10 | Belum dimulai |
| 14 | 12 | `13_PHASE_12_HOSTING_DOMAIN_AND_PRODUCTION.md` | 11 | Belum dimulai |
| 15 | 13 | `14_PHASE_13_PARITY_UAT_AND_CUTOVER.md` | 12 | Belum dimulai |

## Status vocabulary

- `BELUM DIMULAI`: belum ada implementation yang dapat diverifikasi.
- `SEDANG BERJALAN`: minimal satu slice aktif, phase belum memenuhi DoD.
- `TERBLOKIR`: blocker konkret dicatat dan tidak ada safe in-scope progress.
- `SELESAI LOKAL`: seluruh local gate lulus; external production gate belum.
- `SELESAI`: seluruh gate phase termasuk external/manual gate yang diwajibkan
  benar-benar lulus.

## Supporting documents

- `DECISION_REGISTER.md`
- `../docs/architecture/ARCHITECTURE.md`
- `../docs/architecture/TARGET_FOLDER_STRUCTURE.md`
- `../docs/architecture/ROUTES_AND_ROLES.md`
- `../docs/architecture/IOS_TO_WEB_PARITY.md`
- `../docs/architecture/BACKEND_AND_COMMERCE_MIGRATION.md`
- `../docs/decisions/PHASE_00_MANUAL_COMMERCE_DECISIONS.md`
- `../docs/design/LANDING_PAGE_DESIGN_AND_CONTENT.md`
- `../docs/operations/HOSTING_DOMAIN_AND_ENVIRONMENTS.md`
