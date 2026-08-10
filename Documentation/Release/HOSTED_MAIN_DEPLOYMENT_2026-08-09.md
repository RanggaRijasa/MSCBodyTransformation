# Hosted Main Deployment Record — 9 Agustus 2026

## Target dan approval

- Target: hosted Supabase `main`.
- Project ref: `uoymesmgsitdoxouvgca`.
- Source branch lokal: `features/phase_13`.
- Owner mengizinkan migration push, deployment delapan Edge Functions, hosted
  verification, dan database SSL enforcement.
- Tidak ada `db reset`, seed, Git commit/push/merge, Auth provider mutation,
  cron mutation, product mapping, atau App Store Connect mutation dalam window
  ini.

## Source snapshot sebelum mutation

- Worktree berisi perubahan Phase 13.1 yang belum di-commit atau dipush.
- Combined SHA-256 manifest untuk 18 migration, delapan function entrypoint,
  shared Edge modules, dan `supabase/config.toml`:
  `aa007e3654d5becc509beb5921d76a385447b09d0b856c5cfc7e374131353e40`.
- Local verification: 385 pgTAP tests, commerce 31 assertions, orphan cleanup
  3 checks, Auth lifecycle 22 checks, database lint bersih, dan schema diff
  kosong.
- Hosted migration dry-run memuat tepat 18 migration dan tidak memuat seed.

## Hasil deployment

- Seluruh 18 migration berhasil diterapkan tanpa reset atau seed.
- Remote migration history cocok dengan lokal.
- Remote lint schema `extensions`, `private`, dan `public` bersih.
- Database SSL enforcement berhasil diaktifkan dan diverifikasi
  `database=true`.
- Deployment awal delapan Functions ditahan sebelum mutation karena
  `--no-verify-jwt` memerlukan approval keamanan khusus. Setelah owner memberi
  approval tersebut, seluruh delapan Functions berhasil dideploy sebagai
  versi 1, status `ACTIVE`, dan `verify_jwt=false`.
- Smoke tanpa credential menghasilkan boundary yang diharapkan:
  `delete-account`/orphan cleanup `401`; Apple webhooks menolak payload invalid;
  commerce dan Apple lifecycle/reconciliation gagal tertutup karena secrets
  sandbox belum dipasang.
- Auth provider, cron, product mapping, secrets, network restriction, dan App
  Store Connect belum dimutasi.

## Post-deploy read-only verification

- Hosted migration list cocok dengan seluruh 18 migration lokal.
- Database lint `public,private` lulus tanpa warning.
- Schema diff hanya memuat helper platform-managed
  `public.rls_auto_enable()` yang memang tidak dibuat migration lokal. Audit
  membuktikan helper memakai fixed `search_path` dan execute pseudo-role
  `PUBLIC` sudah dicabut.
- Audit agregat tidak menemukan tabel `public` tanpa RLS, grant tabel
  `private` ke `anon`/`authenticated`, ordinary view tanpa
  `security_invoker`, atau `SECURITY DEFINER` application yang kehilangan
  fixed `search_path`/terbuka ke PUBLIC.
- Bucket `public-media` tetap public secara sengaja dan `question-photos`
  private. Tidak ada product mapping hosted dan hosted Auth belum mempunyai
  user ketika audit dijalankan.
- SQL cron aktif untuk provisional identity cleanup dan commerce expiry.
  Reconciliation Edge workers serta orphan cleanup belum dijadwalkan.
- Google dan Apple provider kemudian dikonfigurasi manual oleh owner. Public
  Auth settings membuktikan keduanya aktif, Email provider nonaktif, serta
  signup global tetap aktif untuk registrasi OAuth. OAuth Google authorization
  smoke juga membuktikan redirect ke domain Google. Credential provider tidak
  dibaca atau dicetak saat verifikasi.

## Recurring operations deployment

Migration ke-19 `phase13_recurring_operations` dan update orphan cleanup
kemudian mendapat approval terpisah. Dry-run membuktikan hanya migration itu
yang pending; migration berhasil diterapkan, history lokal/remote cocok, dan
`cleanup-orphan-question-photos` aktif sebagai versi 3 dengan
`verify_jwt=false`.

Operator membuat dua nilai Vault tanpa mencetak nilainya:

- `phase13_project_url`: URL HTTPS project hosted `main`.
- `phase13_edge_function_secret`: modern `sb_secret_...` project key.

Post-deploy read-only verification membuktikan kedua nama tersedia dan bentuk
kedua nilainya valid tanpa mengembalikan nilainya. Run pertama Apple identity
reconciliation gagal tertutup dengan `phase13_project_url_invalid`. Root cause
bukan nilai Vault, melainkan regex migration ke-19 yang meneruskan doubled
backslash ke regex engine PostgreSQL.

Forward-fix migration ke-20
`phase13_recurring_operations_url_validation_fix` mempertahankan migration
production yang sudah diterapkan dan mengganti escape ambigu dengan character
class `[.]`. Candidate lokal ini meluluskan 400 pgTAP assertion, lint, schema
diff, dan test valid hosted URL/modern secret. Setelah approval production,
migration ke-20 berhasil dideploy. Run identity reconciliation berikutnya
berstatus sukses dan respons Edge Function `200` dengan hasil kosong yang
valid, tanpa timeout atau kebocoran credential. Run commerce reconciliation
berikutnya juga berhasil dispatch; worker menolak secara fail-closed dengan
`commerce_environment_missing` karena konfigurasi App Store Server memang
belum dipasang. Cron cleanup aktif dan menunggu run alami harian 03:12 UTC.

## Public legal endpoint

Function publik kesembilan `legal` dideploy dengan `verify_jwt=false` setelah
approval terpisah. Handler hanya menerima `GET`/`HEAD`, tidak membaca data
pengguna, dan menyediakan dokumen Bahasa Indonesia berikut:

- `https://uoymesmgsitdoxouvgca.supabase.co/functions/v1/legal/privacy`
- `https://uoymesmgsitdoxouvgca.supabase.co/functions/v1/legal/terms`

Kedua endpoint mengembalikan `200`, `Content-Language: id-ID`, CSP ketat,
`X-Frame-Options: DENY`, serta `X-Content-Type-Options: nosniff`. URL yang sama
sudah dipasang pada konfigurasi Release; build device berhasil dipasang dan
diluncurkan pada iPhone fisik.

## Edge Function authentication boundary

Semua function harus dideploy dengan platform `verify_jwt=false` karena hosted
memakai asymmetric user JWT serta publishable/secret API keys modern. Handler
menjadi security boundary yang eksplisit:

| Function | Caller | Verifikasi handler | Fail closed |
|---|---|---|---|
| `delete-account` | User terautentikasi | Bearer session diverifikasi melalui `/auth/v1/user`; operasi privileged memakai secret key modern | `401` tanpa session; `500` bila server key hilang |
| `cleanup-orphan-question-photos` | Admin terautentikasi | Bearer session diverifikasi melalui Auth; RPC database memeriksa role Admin | `401` tanpa session, `403` non-Admin |
| `commerce` | User terautentikasi | Bearer session melalui Auth, idempotency key, server RPC authorization, Apple signed transaction | `401` tanpa session; purchase tidak fulfilled bila verifikasi gagal |
| `commerce-apple-notifications` | Apple | Signed JWS Apple, app/environment/product allowlist, durable inbox/idempotency | Invalid/oversized payload ditolak |
| `apple-identity-lifecycle` | User Apple terautentikasi | Bearer session melalui Auth, Apple authorization code dan subject identity matching | `401` tanpa session; credential mismatch ditolak |
| `apple-account-events` | Apple | Signed JWS Apple account event, audience/time/JTI validation, durable inbox | Invalid/replayed event ditolak |
| `apple-identity-reconciliation` | Internal scheduler/operator | Exact secret key modern pada `apikey`; no bearer parsing | `401` tanpa secret key |
| `apple-commerce-reconciliation` | Internal scheduler/operator | Exact secret key modern pada `apikey`; Apple Server API signed history | `401` tanpa secret key |

Semua upstream fetch memakai timeout; request body dibatasi; response error
disanitasi. Boundary ini telah dimuat oleh local Edge runtime dan diuji pada
commerce, orphan cleanup, dan account deletion dengan environment key modern.
