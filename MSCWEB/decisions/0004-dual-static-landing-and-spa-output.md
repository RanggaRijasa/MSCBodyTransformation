# ADR-0004 — Landing statis dan shell SPA dalam satu build

Status: Accepted  
Date: 12 August 2026

## Context

Landing publik harus dapat dibaca tanpa JavaScript. Route aplikasi memakai opaque ID yang tidak dapat diketahui saat build dan harus tetap mendukung refresh, browser history, serta fallback Cloudflare Static Assets.

Expo SDK 57 menawarkan `single`, `static`, atau `server` untuk seluruh project. Mode `static` memerlukan `generateStaticParams` untuk setiap dynamic route, sedangkan mode `single` tidak menghasilkan landing HTML per route. Mode `server` masih alpha dan menambahkan runtime server yang tidak diperlukan untuk hosting static.

## Decision

- Gunakan Expo `web.output: single` untuk shell aplikasi dan route dinamis.
- Setelah export, simpan shell Expo sebagai `dist/app.html`.
- Salin landing HTML semantik tanpa JavaScript menjadi `dist/index.html`.
- Cloudflare Worker Static Assets dan local production server melayani `/` dari `index.html`, route aplikasi/callback dari `app.html`, asset yang hilang sebagai HTTP 404, dan unknown navigation dari app shell dengan HTTP 404 agar `+not-found` tetap dapat dirender.
- Landing dan app memakai manifest/icon/tokens warna yang sama, tetapi landing tidak mengimpor Auth, Supabase, Coach, atau Admin module.

## Consequences

- Landing utama tetap indexable dan terbaca tanpa JavaScript.
- App mempertahankan arbitrary opaque route dan browser history.
- Build memiliki satu langkah post-export deterministik dan perlu test routing dua artefak.
- Jika Expo kelak mendukung mixed static/SPA output secara stabil, keputusan ini dapat ditinjau ulang.
