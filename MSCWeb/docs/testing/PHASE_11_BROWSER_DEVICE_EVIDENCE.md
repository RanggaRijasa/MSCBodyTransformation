# Evidence browser dan perangkat Phase 11

## Evidence otomatis kandidat rilis

- Chromium dan WebKit: manifest, screenshot final, security headers, axe Guest/Peserta/Coach, light/dark, contrast, reduced motion, zoom 400%.
- Chromium: install controller/service worker, allowlisted cache, logout/account-state clear, offline navigation, offline mutation failure, mobile throttled Web Vitals.
- Database lokal: 13 pgTAP assertion untuk push subscription RLS/operations dan rate limits.
- Existing Phase 03–10 suites: Auth, media/QR, program, pembayaran, Peserta, Coach, Admin, scoring, volume, dan cross-role.
- Visual baseline: landing desktop/mobile/light/dark/large text dan marketing fixture Peserta/Coach.

Firefox binary tidak tersedia pada runner lokal ini. Smoke Firefox desktop termasuk checklist manual owner di bawah dan bukan alasan untuk memalsukan evidence otomatis.

## Checklist owner setelah Phase 11

Pengujian manual di HP/laptop ditetapkan user sebagai follow-up non-blocking. Simpan hasil, OS/browser/version, tanggal, dan screenshot tanpa PII.

- iPhone Safari browser: landing, login, install guidance, camera/QR permission denied, upload, rotation, safe area.
- iPhone installed PWA: launch/resume/deep link, theme/status bar, logout/account switch, offline/reconnect, permission push dari pengaturan.
- Android Chrome browser dan installed PWA: custom install/dismiss/reinstall, deep link, upload/camera, offline/update, push.
- Desktop Chrome/Safari/Firefox: Admin keyboard-only, 200%/400% zoom, table/form/dialog focus, logout/account switch.
- VoiceOver/TalkBack: urutan heading, label control, status live, modal focus/restore, error announcement.
- Multi-tab: update available muncul konsisten; reload hanya setelah tombol; pekerjaan form tidak hilang sebelum pilihan reload.

Kegagalan Critical/High yang ditemukan pada follow-up harus menghentikan Phase 12 production deployment sampai diperbaiki, walaupun completion engineering Phase 11 tidak menunggu jadwal perangkat owner.
