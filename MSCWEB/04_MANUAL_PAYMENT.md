# 04 — Manual payment specification

## 1. Tujuan dan batas

Web mengganti pembelian StoreKit dengan transfer bank atau QRIS statis. Pengguna mengunggah foto bukti. Admin memeriksa visual dan mengambil keputusan. Sistem tidak mengklaim dapat memverifikasi keaslian transfer secara otomatis.

Pembayaran manual berlaku untuk:

1. Participant membeli program berbayar.
2. Participant yang eligible mengajukan menjadi Coach dan membayar periode Coach tiga bulan.

Program gratis tetap tidak membuat pembayaran.

- `PAY-001` Payment approval MUST menjadi server-authoritative operation.
- `PAY-002` Screenshot/upload proof MUST NOT otomatis dianggap pembayaran valid.
- `PAY-003` Client MUST NOT langsung membuat enrollment, entitlement, role, atau commerce transaction approved.
- `PAY-004` Nominal dan destination MUST berasal dari server configuration dan disalin sebagai immutable snapshot ke request.
- `PAY-005` Semua approve/reject operation MUST idempotent dan audited.

## 2. Harga Coach

Baseline contract yang dipertahankan:

| Level | Harga 3 bulan |
|---|---:|
| SC / SB | Rp100.000 |
| Supervisor / World Team | Rp150.000 |
| TAB / GET / Millionaire / President’s Team | Rp200.000 |
| Member | tidak eligible |

Harga authoritative tetap dikonfigurasi server-side. UI hanya menampilkan hasil policy yang dikembalikan server.

## 3. Payment destination

Admin-authorized configuration menyimpan:

- nama bank;
- nomor rekening;
- nama pemilik rekening;
- image object path QRIS statis;
- label/instruksi;
- active window/status;
- currency `IDR`;
- version dan updated-by audit.

- `PAY-DST-001` Data rekening/QRIS MUST NOT hardcoded di component atau environment variable frontend.
- `PAY-DST-002` Hanya satu destination default aktif per payment method/context kecuali routing rule eksplisit ditambahkan lewat ADR.
- `PAY-DST-003` Perubahan destination MUST tidak mengubah request lama karena request menyimpan snapshot.
- `PAY-DST-004` QRIS image boleh public hanya jika secara bisnis memang poster pembayaran publik; baseline lebih aman adalah authenticated/read-controlled asset.

## 4. State machine

```text
awaiting_proof
    ├─ submit proof → pending_review
    ├─ cancel → cancelled
    └─ timeout → expired

pending_review
    ├─ approve → approved
    ├─ reject(reason) → rejected
    └─ expire by policy → expired

rejected
    └─ add new proof attempt → pending_review
```

Terminal status: `approved`, `cancelled`, `expired`. `Rejected` dapat menerima attempt baru selama subject masih eligible dan policy mengizinkan.

- `PAY-STATE-001` Transition MUST divalidasi server dan menggunakan compare-and-set/version check.
- `PAY-STATE-002` Bukti baru MUST membuat attempt baru; file/record lama tidak boleh ditimpa.
- `PAY-STATE-003` Request `approved` MUST tidak dapat kembali pending/rejected melalui client biasa. Koreksi luar biasa membutuhkan Admin operation terpisah dan audit.
- `PAY-STATE-004` UI MUST menampilkan status dari server setelah mutation, bukan mengasumsikan hasil.
- `PAY-STATE-005` Expiry duration dan retention policy adalah production decision yang MUST ditetapkan sebelum launch; dokumen ini tidak mengarang angkanya.

## 5. Participant purchase flow

```text
Pilih program
  → Login bila Guest
  → Scan QR Coach
  → server validasi program + Coach + capacity + duplicate
  → program gratis: enrollment atomik
  → program berbayar: buat payment request
  → tampilkan nominal + rekening + QRIS
  → upload dan konfirmasi bukti
  → pending review
  → Admin approve
  → atomik: transaction approved + entitlement + enrollment + audit
  → Participant masuk program
```

- `PAY-PTC-001` Selected program dan opaque QR validation intent MUST dapat dipertahankan melewati login, tetapi raw QR payload tidak boleh disimpan di URL/log.
- `PAY-PTC-002` Server MUST menolak Coach berbeda dari current-Coach/program relationship yang berlaku.
- `PAY-PTC-003` Duplicate enrollment, capacity reached, program inactive, nominal berubah sebelum request dibuat, atau QR mismatch MUST menghasilkan typed conflict/validation error.
- `PAY-PTC-004` Approval MUST membuat entitlement/enrollment exactly once dalam satu transaction authority boundary.
- `PAY-PTC-005` Bila atomic operation gagal, status tidak boleh menjadi `approved` secara parsial.
- `PAY-PTC-006` Setelah approval, query payment, entitlement, program catalog, home focus, dan Coach relationship MUST di-invalidasi/refetch.

## 6. Coach application flow

```text
Participant memilih Daftar Coach
  → isi data application + attestasi
  → server cek eligibility dan menentukan harga
  → buat payment request Coach
  → upload proof → pending review
  → Admin membuka application + eligibility + payment proof
  → Setujui dan aktifkan Coach
  → atomik: proof approved + application approved
             + Coach entitlement 3 bulan + protected role activation + audit
```

- `PAY-CCH-001` Eligibility dan payment status MUST tetap state terpisah secara data meskipun Admin memiliki satu CTA gabungan.
- `PAY-CCH-002` CTA approval MUST gagal jika eligibility tidak lengkap, application berubah, payment proof bukan pending, atau user sudah memiliki conflicting state.
- `PAY-CCH-003` Rejection MUST memiliki alasan dan MUST tidak mengaktifkan role/entitlement.
- `PAY-CCH-004` Aktivasi Coach MUST server-controlled; metadata user yang editable tidak boleh menjadi authority.
- `PAY-CCH-005` Entitlement Coach MUST memiliki start/end authoritative untuk periode manual tiga bulan dan event audit.

## 7. Proof upload

Format baseline:

- input: JPEG/PNG/HEIC yang didukung browser;
- output penyimpanan: JPEG normalized tanpa metadata yang tidak perlu;
- ukuran output maksimal: 8 MiB;
- object path privat dan tidak dapat ditebak;
- preview memakai object URL lokal sebelum submit dan harus di-revoke sesudahnya.

- `PAY-UPL-001` File signature/MIME/size/dimensi MUST divalidasi di client untuk UX dan di server/storage boundary untuk security.
- `PAY-UPL-002` EXIF location dan metadata tidak perlu MUST dihapus sebelum penyimpanan.
- `PAY-UPL-003` User MUST hanya dapat upload ke payment request miliknya dalam allowed state.
- `PAY-UPL-004` Upload MUST memakai unique path per attempt; overwrite MUST ditolak.
- `PAY-UPL-005` Failed upload MUST tidak memindahkan request ke `pending_review`.
- `PAY-UPL-006` Submit proof record dan state transition MUST terjadi setelah object valid tersedia; orphan cleanup job/process MUST ditentukan sebelum production.
- `PAY-UPL-007` UI produksi MUST tidak memiliki tombol foto demo atau bukti sample.

## 8. Admin review UI

Queue default `Perlu tindakan` berisi `pending_review`, oldest first, dengan filter subject/type/program/date.

Detail minimum:

- order/request ID;
- nama dan account identity yang aman;
- subject: program atau aplikasi Coach;
- expected amount/currency;
- destination snapshot;
- declared method;
- submitted timestamp;
- full proof dan daftar attempt sebelumnya;
- eligibility/context warnings;
- audit/decision history;
- actions `Tolak` dan `Setujui` / `Setujui dan aktifkan Coach`.

- `PAY-ADM-001` Signed URL bukti MUST short-lived dan dibuat hanya untuk authorized reviewer.
- `PAY-ADM-002` Approve action MUST menampilkan confirmation dengan subject dan nominal.
- `PAY-ADM-003` Reject dialog MUST meminta alasan; alasan disimpan ke audit dan ditampilkan dengan redaction policy yang sesuai kepada user.
- `PAY-ADM-004` Concurrent reviewer conflict MUST menghasilkan pesan bahwa request sudah diproses, lalu refetch detail.
- `PAY-ADM-005` Admin MUST dapat zoom/open full image tanpa memasukkan signed URL ke analytics/log.

## 9. Fraud and operational limitations

Visual review dapat salah dan screenshot dapat dipalsukan. Sebelum production, owner bisnis MUST menetapkan SOP rekonsiliasi mutasi rekening, reviewer responsibility, dispute/refund path, waktu layanan, expiry, serta retention/deletion period. Ini adalah launch blocker operasional, bukan fitur yang boleh diasumsikan oleh developer.

