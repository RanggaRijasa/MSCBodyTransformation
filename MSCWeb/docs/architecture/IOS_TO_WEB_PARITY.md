# iOS to Web Parity Map

Peta ini mendefinisikan parity perilaku. Web tidak menerjemahkan source Swift
baris demi baris dan tidak meniru kontrol native yang tidak sesuai web.

Capability, role, state, adaptation, dan historical prohibition lengkap
dibekukan pada [Phase 00 Capability and State Parity Matrix](./PHASE_00_PARITY_MATRIX.md).
Pemetaan test berada di
[iOS to Web Test Mapping](../testing/IOS_TO_WEB_TEST_MAPPING.md).

| iOS/reference | Target web/PWA | Catatan parity |
|---|---|---|
| `App/RootView.swift` | root layouts dan role routing | Guest bukan role |
| `Features/AppShell` | mobile bottom nav + Admin sidebar | path per capability |
| `Features/Auth` | Auth routes + Supabase SSR | Apple dihapus |
| `Features/Participant` | participant features/routes | hierarchy dan copy dipertahankan |
| `Features/Coach` | coach features/routes | privacy berat/foto dipertahankan |
| `Features/Admin` | desktop-responsive Admin features | renderer preview dipakai ulang |
| `Features/Commerce` | manual payment feature | tidak memakai StoreKit |
| `Features/Media` | browser media/QR adapter | wajib device testing |
| `Domain` | TypeScript domain | port behavior, bukan syntax |
| `Infrastructure/Supabase` | TS repository adapters | server/browser dipisah |
| `SharedUI` | semantic web UI primitives | HTML semantics lebih utama |
| `Localizable.xcstrings` | Indonesian message catalog | key tidak boleh terlihat |
| Swift Testing | unit/integration/contract tests | cases dan fixtures dipetakan |
| XCUIAutomation | Playwright/device manual matrix | critical journeys dipertahankan |

## Capability native yang diganti

### Foto dan kamera

- Web file input menerima galeri dan capture hint.
- Kamera interaktif memakai browser media API hanya saat user memulai.
- Orientasi, resize, metadata removal, MIME sniffing, size limit, dan upload
  retry tetap diuji.
- Jangan menyediakan media demo sebagai shortcut upload.

### QR

- QR Coach tetap opaque; tidak ada input manual atau raw identifier.
- Scanner memakai camera permission dengan unavailable/denied state.
- Decoder library dipilih melalui compatibility spike; tidak diasumsikan
  tersedia seragam pada semua Safari/Chrome target.
- QR Coach dapat ditampilkan sebagai SVG/canvas yang dapat dipindai tanpa
  menyediakan tombol copy payload.

### Video

- HTML media player menyimpan resume server-side/per enrollment.
- Autoplay mengikuti browser policy.
- Watch threshold dan completion authoritative tidak berasal hanya dari event
  client yang dapat dipalsukan.

### Secure storage

- Keychain diganti session cookie yang sesuai SSR.
- Jangan menyimpan refresh token atau data privat di arbitrary localStorage.
- Pending intent harus opaque, scoped, expiring, dan direvalidasi server.

### PWA install

- App Store install diganti Add to Home Screen/install prompt yang sesuai
  browser.
- Safari iOS memerlukan instruction UI karena prompt tidak seragam.
- Standalone, upgrade, stale cache, logout, dan account switch diuji.

## Parity rule

Satu capability dinyatakan parity bila:

1. Copy dan terminology sesuai UI reference.
2. Happy path, loading, empty, error, offline, denied, conflict, dan retry
   state yang relevan tersedia.
3. Authorization dan privacy setara atau lebih ketat daripada iOS.
4. Unit/integration/E2E terkait lulus.
5. Perbedaan platform dicatat sebagai deliberate adaptation, bukan fitur yang
   diam-diam hilang.
