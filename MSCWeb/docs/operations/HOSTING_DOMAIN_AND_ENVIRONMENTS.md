# Hosting, Domain, and Environments

Dokumen ini merekam rekomendasi per 10 Agustus 2026. Harga, limit, dan API
provider harus diverifikasi ulang tepat sebelum pembelian atau deployment.

## Rekomendasi default

```text
Domain registrar : IDCloudHost untuk `.id`; Cloudflare Registrar untuk `.com`
DNS              : Cloudflare DNS
Web hosting      : Cloudflare Workers Paid melalui OpenNext
Backend          : Supabase Pro
Web origin       : https://domain-pilihan.tld
Admin            : https://domain-pilihan.tld/admin
Supabase API     : project.supabase.co pada awal release
Optional API     : https://api.domain-pilihan.tld melalui Supabase Custom Domain
```

Alasan:

- Workers Paid memberi baseline production berbiaya rendah. Static assets
  tidak dikenai biaya request/egress dan kuota berbayar mencakup 10 juta
  request serta 30 juta CPU-ms per bulan sebelum overage.
- Next.js App Router full-stack dijalankan melalui `@opennextjs/cloudflare`.
  Compatibility test wajib mencakup SSR, cookies Auth, middleware/proxy,
  Server Actions, image handling, PWA, dan preview sebelum cutover.
- IDCloudHost tercantum sebagai registrar PANDI dan menjadi default praktis
  untuk domain `.id`; harga promo dan renewal wajib dicek lagi saat membeli.
- Cloudflare Registrar mengenakan harga registry tanpa markup, menyediakan
  DNSSEC, serta mewajibkan Cloudflare nameserver. Daftar TLD resminya saat
  riset belum mencantumkan `.id`.
- Vercel Pro tetap fallback bila OpenNext/runtime compatibility gate gagal;
  keputusan fallback harus berbasis bukti test, bukan kenyamanan semata.

## Perkiraan baseline saat ini

| Layanan | Baseline | Catatan |
|---|---:|---|
| Cloudflare Workers Paid | minimum USD 5/bulan | 10 juta request dan 30 juta CPU-ms termasuk; overage berlaku |
| Supabase Pro | USD 25/bulan | Termasuk compute credit untuk satu Micro |
| Supabase custom domain | USD 10/bulan | Opsional, perlu paid plan |
| Domain `.id` IDCloudHost | Rp225.000 registrasi; Rp250.000 renewal saat riset | Verifikasi availability, promo, pajak, dan renewal |
| Domain global | harga registry/tahun | Bergantung TLD dan status premium |

Nilai belum termasuk pajak, kurs, seat tambahan, bandwidth/compute berlebih,
email provider, observability, atau layanan pemrosesan gambar tambahan.
Aktifkan budget alert, limit, dan notifikasi sebelum production.

Baseline production cost-first adalah sekitar USD 30/bulan ditambah domain:
Workers Paid USD 5 dan Supabase Pro USD 25. Ini menghemat sekitar USD 15/bulan
dibanding baseline Vercel Pro, sebelum pajak dan overage.

Workers Free dan Supabase Free dapat dipakai untuk prototype/prelaunch dengan
biaya hosting nol, tetapi bukan baseline production aplikasi ini. Workers Free
hanya memberi 10 ms CPU per invocation, sedangkan data privat, bukti transfer,
dan kebutuhan backup membuat Supabase Pro tetap pilihan production yang lebih
bertanggung jawab.

## Pilihan domain

### `.com` atau TLD global yang didukung

Cloudflare Registrar adalah pilihan default karena renewal pada list price
registry, auto-renew, WHOIS redaction bila registry mengizinkan, dan DNSSEC.
Konsekuensinya, domain harus tetap memakai Cloudflare nameserver selama berada
di registrar tersebut. Ketersediaan dan harga final harus diperiksa di
Registrar search/check tepat sebelum pembelian.

### `.id`

Rekomendasi default adalah IDCloudHost, yang tercantum sebagai registrar
terakreditasi PANDI. Tetap bandingkan harga renewal normal, bukan promo tahun
pertama, dukungan DNSSEC, kemudahan transfer, ownership atas akun, metode
pembayaran, dan support. Alternatif harus berasal dari daftar registrar PANDI.
Setelah membeli, arahkan nameserver ke Cloudflare; tidak perlu membeli paket
shared hosting dari registrar.

Jangan membeli domain sebelum memeriksa:

- ejaan brand dan kemungkinan salah ketik;
- harga renewal dan status premium;
- kepemilikan atas nama badan usaha/pemilik yang benar;
- akses MFA dan recovery codes;
- ketersediaan akun sosial/brand bila relevan;
- konflik merek dan kebijakan nama domain.

## Topologi domain

Untuk release pertama, gunakan satu origin:

```text
domain.tld          -> PWA dan public pages
www.domain.tld      -> redirect permanen ke domain.tld
domain.tld/admin    -> Admin role-gated
api.domain.tld      -> opsional Supabase custom domain
```

Satu origin mengurangi masalah cookie, CORS, install scope PWA, OAuth redirect,
dan deployment. Gunakan `app.domain.tld` hanya bila landing/marketing site
benar-benar harus terpisah.

## Cloudflare DNS dan Workers

1. Tambahkan zone domain ke account Cloudflare pemilik.
2. Untuk domain dari registrar lain, ganti nameserver registrar ke pasangan
   Cloudflare yang diberikan untuk zone tersebut.
3. Deploy Worker hasil OpenNext ke account dan environment yang disetujui.
4. Hubungkan apex/custom domain melalui Workers custom domain/route sesuai
   hasil inspection dashboard, bukan nilai contoh statis.
5. Buat redirect permanen `www` ke apex.
6. Aktifkan DNSSEC setelah konfigurasi stabil dan verifikasi DS chain.
7. Uji apex, `www`, HTTPS, HSTS policy, OAuth callback, dan renewal contact.

Jangan membuat DNS record atau Worker route dari contoh dokumentasi tanpa
inspection karena target dan ownership zone dapat berbeda.

## Supabase dan OAuth

- `SITE_URL` production harus origin resmi, bukan localhost atau preview URL.
- Allowlist hanya localhost development, pola preview yang dibutuhkan, dan
  callback production.
- Google OAuth memakai web client dan callback Supabase yang tepat.
- Preview environment tidak boleh otomatis terhubung ke hosted production
  untuk mutation sensitif. Gunakan local/test project strategy yang disetujui
  di Phase 12.
- Supabase custom domain tidak wajib agar Auth atau PWA bekerja. Aktifkan
  `api.domain.tld` hanya untuk branding/portability setelah Pro plan aktif dan
  callback lama serta baru diuji selama transisi.

## Environment variables

Browser-visible:

```text
NEXT_PUBLIC_SITE_URL
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY
```

Server-only hanya bila ada use case yang benar-benar memerlukan:

```text
NON_PUBLIC_PROVIDER_SECRET
```

Jangan menaruh `service_role`, Supabase secret key, database password, JWT
secret, atau Google client secret dalam `NEXT_PUBLIC_*`. Default architecture
tidak membutuhkan service role di Cloudflare Workers; privileged operations
tinggal di Supabase RPC/Edge Functions.

Environment dan secret Cloudflare harus diinventarisasi per environment.
Client bundle hanya menerima site URL, Supabase URL, dan publishable key;
server-only secret tidak boleh memakai prefix `NEXT_PUBLIC_*`.

## Runtime gate dan fallback Vercel

Cloudflare Workers membutuhkan `nodejs_compat`, compatibility date yang sesuai,
dan adapter OpenNext. Node.js Middleware Next.js belum didukung penuh menurut
dokumentasi Cloudflare saat riset; desain middleware/proxy harus mengikuti
subset yang lulus build dan test. Jika blocker ini atau fitur production lain
tidak dapat diselesaikan dengan aman, fallback yang disetujui adalah Vercel Pro
tanpa mengubah domain/business architecture.

## Environment strategy

```text
Local       : Next dev + Supabase local
Preview     : Workers preview + mock/backend non-production yang disetujui
Production  : Cloudflare Workers Paid + hosted Supabase main
```

- Local Supabase tetap dijalankan melalui Colima/Docker sesuai runbook root.
- Preview tidak boleh melakukan destructive seed/reset ke hosted main.
- Production deployment dilakukan setelah migration, secrets, Auth callbacks,
  storage policy, backups, advisors, smoke test, dan rollback plan lulus.
- Jangan membuat staging/branch Supabase baru tanpa keputusan eksplisit yang
  merevisi strategi environment root.

## Sumber resmi

- Next.js PWA guide: https://nextjs.org/docs/app/guides/progressive-web-apps
- Cloudflare Workers pricing: https://developers.cloudflare.com/workers/platform/pricing/
- Cloudflare Next.js Workers: https://developers.cloudflare.com/workers/framework-guides/web-apps/nextjs/
- Cloudflare Registrar: https://developers.cloudflare.com/registrar/
- Cloudflare supported TLDs: https://developers.cloudflare.com/registrar/top-level-domains/
- Cloudflare TLD policies: https://www.cloudflare.com/tld-policies/
- Cloudflare DNSSEC: https://developers.cloudflare.com/registrar/get-started/enable-dnssec/
- Vercel pricing (fallback): https://vercel.com/pricing
- Supabase SSR: https://supabase.com/docs/guides/auth/server-side/creating-a-client?queryGroups=framework&framework=nextjs
- Supabase redirect URLs: https://supabase.com/docs/guides/auth/redirect-urls
- Supabase custom domains: https://supabase.com/docs/guides/platform/custom-domains
- PANDI: https://pandi.id/
- Daftar registrar PANDI: https://pandi.id/en/partner-registrar
- IDCloudHost: https://idcloudhost.com/domain/
