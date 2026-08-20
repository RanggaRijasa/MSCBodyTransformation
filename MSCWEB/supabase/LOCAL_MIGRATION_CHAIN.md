# Rantai migrasi Supabase lokal MSCWEB

Supabase lokal memakai dua sumber migrasi yang berurutan:

1. migrasi shared baseline di `../supabase/migrations` melalui `supabase db reset` dari root repository;
2. migrasi khusus web di `MSCWEB/supabase/migrations` melalui script berikut.

```sh
MSCWEB/scripts/apply-local-supabase-migrations.sh
```

Script menolak URL selain `127.0.0.1` atau `localhost`, mengambil kredensial
langsung dari `supabase status`, lalu menerapkan seluruh file web menurut urutan
nama. Hosted `main` tidak pernah menjadi target script ini.

Worker receipt cancellation lokal dijalankan dengan:

```sh
MSCWEB/scripts/run-local-provisional-cleanup.sh
```

Script tersebut juga menolak target non-lokal, menghapus objek melalui Storage
API, mencabut seluruh session, menghapus Auth identity, dan menyelesaikan receipt.
Untuk development berkelanjutan, jalankan setelah test cancellation atau dari
supervisor lokal terjadwal. Aktivasi hosted scheduler/Edge Function tetap butuh
otorisasi production terpisah.

Untuk membuktikan schema bersih tanpa memengaruhi data pengembangan utama,
gunakan stack Supabase lokal terpisah atau lakukan reset hanya setelah pengguna
secara eksplisit menyetujui penghapusan data lokal. W07.4 tidak menjalankan
`supabase db reset` secara otomatis.
