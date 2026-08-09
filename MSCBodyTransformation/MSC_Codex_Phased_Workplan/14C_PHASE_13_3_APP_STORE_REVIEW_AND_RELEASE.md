# Phase 13.3: App Store Metadata, Review Submission, and Release

> Status: **blocked sampai Phase 13.2 TestFlight release candidate lulus dan
> owner menyetujui lanjut**.
>
> Mengisi metadata dapat dilakukan bertahap. Menekan `Submit for Review`,
> merilis versi yang sudah disetujui, atau mengubah release mode selalu meminta
> persetujuan eksplisit terpisah dari owner.

## Tujuan

- Melengkapi metadata App Store, screenshot, privacy responses, dan review
  notes berdasarkan behavior build TestFlight yang benar-benar lulus.
- Menyediakan reviewer path yang dapat dipakai untuk semua role dan IAP.
- Mengaitkan IAP yang benar ke app version.
- Menjalankan pre-submission audit terakhir.
- Submit ke App Review hanya setelah approval eksplisit.
- Menangani review dan release tanpa mengubah behavior yang sudah divalidasi.

## Prasyarat wajib

- [ ] Seluruh exit criteria `14B_PHASE_13_2_ARCHIVE_AND_TESTFLIGHT.md` lulus.
- [ ] Version/build TestFlight RC final sudah dipilih.
- [ ] Tidak ada unresolved critical/high defect.
- [ ] Privacy Policy, Terms, support URL, dan reviewer URLs hidup tanpa login.
- [ ] Review accounts Participant, Coach, dan Admin tersedia dengan data aman.
- [ ] QR Coach aktif dan reviewer instructions telah dibuktikan oleh tester lain.
- [ ] IAP products sudah ready dan sesuai mapping server/build.

## Input manual

- [ ] Konfirmasi final app name dan subtitle.
- [ ] Pilih primary/secondary category.
- [ ] Konfirmasi age rating questionnaire berdasarkan content aktual.
- [ ] Sediakan support URL dan marketing URL bila digunakan.
- [ ] Konfirmasi App Review contact yang dapat dihubungi.
- [ ] Konfirmasi copyright/rights holder.
- [ ] Konfirmasi apakah leaderboard mempunyai hadiah/contest dan rules final.
- [ ] Konfirmasi DSA trader status bila distribusi mencakup wilayah terkait.
- [ ] Pilih release mode: manual atau automatic setelah approval.

## Approval boundary

Approval terpisah diperlukan sebelum:

1. Menyimpan metadata yang mempunyai konsekuensi hukum/komersial bila nilainya
   belum pernah dikonfirmasi owner.
2. Menambahkan IAP ke app-version submission.
3. Menekan `Submit for Review`.
4. Menjawab reviewer dengan perubahan material atau membuat build baru.
5. Merilis versi yang sudah approved bila release mode manual.

Tidak ada approval sebelumnya yang otomatis mengizinkan App Review submission
atau public release.

## Urutan implementasi

### Slice 13.3.0 — Metadata inventory

- [ ] Rekonsiliasi metadata terhadap TestFlight RC, bukan mock/roadmap.
- [ ] Catat app name, subtitle, description, keywords, promotional text,
  categories, age rating, support/marketing/privacy URLs, copyright,
  availability, pricing, dan release mode.
- [ ] Pastikan claim tetap wellness/non-diagnostic; jangan mengklaim diagnosis,
  treatment, medical device, atau hasil yang dijamin.
- [ ] Pastikan Bahasa Indonesia konsisten dengan UI dan legal documents.
- [ ] Pastikan tidak ada placeholder, unsupported feature, atau misleading copy.

**Gate 13.3.0:** metadata source-of-truth lengkap dan dikonfirmasi owner.

### Slice 13.3.1 — Screenshot dan preview assets

- [ ] Tentukan required screenshot sizes berdasarkan device family yang benar-
  benar didukung oleh build final.
- [ ] Ambil screenshot dari release/TestFlight-equivalent build dengan data
  aman dan tanpa Debug badge, test email, private relay address, token, raw QR,
  phone, weight, private media, atau personal notification.
- [ ] Tampilkan Guest/public catalog, Participant journey, Coach experience,
  leaderboard, dan program value secara jujur tanpa menyiratkan feature palsu.
- [ ] Jangan menampilkan price hard-coded bila actual StoreKit price berbeda.
- [ ] Pastikan screenshot tidak membuat medical/weight-loss guarantee.
- [ ] Verifikasi crop, safe area, status bar, legibility, dan urutan storytelling.
- [ ] Buat App Preview hanya bila memang diperlukan dan dapat dipelihara.

**Gate 13.3.1:** seluruh screenshot valid, aman, konsisten, dan siap upload.

### Slice 13.3.2 — App Privacy dan compliance responses

- [ ] Isi App Privacy berdasarkan data app dan seluruh dependency yang benar-
  benar ada pada RC.
- [ ] Rekonsiliasi responses dengan `PrivacyInfo.xcprivacy`, Privacy Policy,
  retention, account deletion, dan server logging.
- [ ] Cakup nama, email, phone, user ID, foto/user content, weight/fitness,
  purchase history, diagnostics, serta linkage/purpose aktual.
- [ ] Jangan menyatakan tracking bila tidak ada tracking; jangan menyembunyikan
  collection/linkage yang memang terjadi.
- [ ] Lengkapi export compliance secara akurat.
- [ ] Lengkapi content rights, age rating, regulated-medical, advertising,
  gambling/contest, dan encryption responses sesuai behavior aktual.
- [ ] Lengkapi DSA trader status bila diwajibkan untuk wilayah distribusi.
- [ ] Bila contest/hadiah digunakan, cantumkan rules dan pernyataan bahwa Apple
  bukan sponsor bila diwajibkan oleh rules/guideline.

**Gate 13.3.2:** privacy/compliance responses konsisten dengan binary, server,
legal documents, dan behavior nyata.

### Slice 13.3.3 — Reviewer access dan review notes

- [ ] Siapkan review accounts Participant, Coach, dan Admin tanpa data nyata.
- [ ] Pastikan reviewer dapat mengakses tiap role tanpa menunggu koordinasi
  manual yang tidak dijelaskan.
- [ ] Sediakan QR Coach aktif dan instruksi scan yang dapat direproduksi.
- [ ] Review notes menjelaskan:
  - Google/Apple login dan private relay;
  - Guest/public access;
  - free dan paid program;
  - QR Coach enrollment tanpa typed-code fallback;
  - Coach application → Admin approval → payment → activation;
  - manual three-month renewal dan no voluntary refund;
  - camera/photo purpose dan wellness context;
  - cara mengakses Participant, Coach, dan Admin;
  - account deletion flow;
  - sandbox IAP behavior yang perlu reviewer ketahui.
- [ ] Pastikan contact person siap merespons selama review.
- [ ] Jangan menaruh password/credential reviewer dalam repository atau log.

**Gate 13.3.3:** reviewer path diuji oleh orang selain pembuat instruksi.

### Slice 13.3.4 — IAP submission association

- [ ] Sediakan IAP review screenshot yang akurat untuk setiap product.
- [ ] Pastikan localized product metadata, price, availability, tax category,
  dan review notes lengkap.
- [ ] Kaitkan hanya product ID yang digunakan oleh app version/server mapping.
- [ ] Pastikan non-consumable cohort dan tiga non-renewing Coach products
  mempunyai type yang benar.
- [ ] Pastikan product yang baru dibuat selesai propagasi; jangan mengubah app
  logic untuk menyiasati status App Store Connect.
- [ ] Minta approval sebelum menyertakan IAP pada submission.

**Gate 13.3.4:** IAP metadata dan association cocok dengan RC dan backend.

### Slice 13.3.5 — Final pre-submission audit

- [ ] Jalankan final diff antara RC/TestFlight build dan source yang disebutkan
  pada release notes; tidak boleh ada untested binary change.
- [ ] Ulangi critical hosted health, login, QR, purchase/restore, deletion,
  reviewer-account, privacy/legal URL, dan IAP availability smoke.
- [ ] Pastikan semua App Store required fields hijau/complete.
- [ ] Pastikan version/build yang dipilih adalah TestFlight RC yang lulus.
- [ ] Pastikan tidak ada placeholder, dead CTA, demo outcome, Mac/local
  dependency, atau expired reviewer credential/QR.
- [ ] Catat known issue dan accepted exception untuk keputusan owner.
- [ ] Presentasikan submission summary dan minta approval eksplisit.

**Gate 13.3.5:** seluruh material siap, tetapi belum disubmit.

### Slice 13.3.6 — Submit for App Review

- [ ] Terima approval eksplisit owner yang menyebut version/build yang akan
  disubmit.
- [ ] Pilih build dan IAP yang sudah disetujui.
- [ ] Tekan `Submit for Review` hanya setelah approval.
- [ ] Catat waktu, version/build, submission ID/status, dan release mode.
- [ ] Monitor status tanpa membuat mutation yang tidak diperlukan.
- [ ] Bila reviewer meminta informasi, jawab berdasarkan behavior yang ada;
  minta approval untuk material legal/product change.
- [ ] Bila perubahan binary diperlukan, kembali ke Phase 13.1/13.2 sesuai
  dampak, buat build number baru, dan ulangi gate yang relevan.

**Gate 13.3.6:** submission diterima App Store Connect dan sedang direview.

### Slice 13.3.7 — Approval dan public release

- [ ] Setelah Apple approval, verifikasi availability, pricing, IAP, legal URL,
  dan hosted health sekali lagi.
- [ ] Jika manual release dipilih, minta approval eksplisit sebelum merilis.
- [ ] Jika automatic release dipilih, pastikan owner sudah menyetujui mode itu
  sebelum submission.
- [ ] Monitor phased/manual release, crash, Auth, webhook, commerce, cron,
  support, dan security signals.
- [ ] Jalankan rollback/forward-fix runbook bila ada critical production issue.
- [ ] Dokumentasikan live version/build dan closeout Phase 13.

**Gate 13.3.7:** aplikasi live sesuai release mode yang disetujui dan initial
production monitoring sehat.

## Exit criteria Phase 13.3

- [ ] Metadata, screenshot, privacy/compliance responses, reviewer access,
  review notes, dan IAP association lengkap.
- [ ] Owner memberi approval eksplisit untuk version/build submission.
- [ ] App Review submission selesai dan status terdokumentasi.
- [ ] Jika approved, public release mengikuti mode yang disetujui owner.
- [ ] Tidak ada unresolved critical/high App Review, privacy, legal, security,
  commerce, atau reliability blocker.
- [ ] Workplan, implementation status, OpenAPI, runbook, dan progress log
  direkonsiliasi dengan hasil final.

## Referensi

- App Review Guidelines:
  https://developer.apple.com/app-store/review/guidelines/
- Submit an app for review:
  https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app-for-review
- App information:
  https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-app-information
- App Privacy:
  https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy
- Upload app previews and screenshots:
  https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots

## Progress log

### 9 Agustus 2026 — Workplan dipisah

- Memindahkan App Store metadata, screenshots, privacy/compliance responses,
  review notes, IAP submission association, App Review submission, dan public
  release ke Phase 13.3.
- Menetapkan approval terpisah untuk submit dan manual public release.
