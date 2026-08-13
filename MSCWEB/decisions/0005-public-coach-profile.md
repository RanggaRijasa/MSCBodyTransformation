# ADR-0005 — Profil Coach publik yang dapat dibagikan

Status: Accepted  
Date: 13 August 2026

## Context

Coach membutuhkan profil profesional yang dapat dibagikan seperti halaman profil karier/sosial, termasuk ke Instagram atau WhatsApp. Profil harus tetap berguna ketika hanya data otomatis tersedia, tetapi Coach boleh menambahkan identitas profesional, kontak, testimoni, dan before–after secara opsional.

Raw QR Coach dan identifier enrollment sudah ditetapkan privat. Kontak, testimoni, dan foto orang lain juga tidak boleh menjadi publik hanya karena berada pada row profil privat.

## Decision

- Profil publik memakai canonical route `/c/:handle` dengan handle stabil server-managed; raw QR, auth user ID, dan enrollment identifier tidak menjadi URL.
- Foto, nama, dan badge `Coach terverifikasi` adalah identitas minimum. Foto awal diimpor dari Google dan dapat diganti Coach; bila Google tidak menyediakan foto, Coach wajib mengunggah satu sebelum publikasi. Nama mengikuti profil akun berwenang; badge mengikuti entitlement Coach aktif dan tidak dapat diedit.
- Headline, biografi, kota/area layanan, Instagram, TikTok, website, WhatsApp, nomor telepon, testimoni, dan before–after bersifat opsional.
- Setiap kontak memiliki pilihan publikasi sendiri. Public read model hanya memuat field yang benar-benar dipublikasikan.
- Profil dibuat sebagai draft dan baru menjadi publik melalui aksi Coach. Entitlement kedaluwarsa/dicabut menutup profil dan menghapus badge sampai dipulihkan.
- Semua testimoni/before–after melewati moderation state. Pernyataan izin pihak ketiga hanya wajib bila orang lain ditampilkan atau dikutip; konten diri sendiri tidak membutuhkannya. Media berasal dari upload publik khusus profil, bukan bukti program privat.
- Tombol `Bagikan profil` memakai Web Share API dan fallback copy canonical URL.
- W06 membangun contract/editor/public route. W07 menyediakan moderation Admin. W08 menyelesaikan canonical metadata, Open Graph/social preview, cache, dan Cloudflare behavior.

## Consequences

Positif:

- profil minimum tetap terlihat profesional tanpa memaksa Coach mengisi banyak field;
- Coach memilih kontak mana yang benar-benar publik;
- URL aman dibagikan dan tidak membocorkan jalur enrollment;
- profil dapat berkembang tanpa mencampur data privat Participant.

Risiko/trade-offs:

- testimoni dan before–after membutuhkan moderation serta proses permission sederhana;
- metadata sosial per handle membutuhkan rendering/cache strategy pada W08, bukan hanya SPA fallback generik;
- perubahan handle di masa depan membutuhkan redirect agar link lama tidak rusak.
