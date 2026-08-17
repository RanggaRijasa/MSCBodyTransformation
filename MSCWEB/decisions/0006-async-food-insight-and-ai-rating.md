# ADR-0006 — Insight makanan asynchronous dan rating AI favorable

Status: Accepted  
Date: 13 August 2026

## Context

Foto makanan/minuman pada pertanyaan tertentu perlu menghasilkan estimasi macro, insight singkat, dan bintang otomatis. Hasil tersebut bersifat sekunder: submission, pemeriksaan, dan poin tidak boleh menunggu model. Rating bintang Coach yang ada pada prototype native masih lokal dan belum termasuk kontrak server, sehingga MSCWEB dapat memperkenalkan contract web tanpa menimpa authority poin.

OpenRouter dengan model vision `google/gemma-4-31b-it:free` menjadi provider/model awal. Produk menginginkan non-reasoning request, pergantian model semudah mungkin, insight Bahasa Indonesia yang sangat singkat, dan tidak menginginkan baseline consent/DPIA/ZDR/withdrawal flow yang berat untuk foto makanan.

## Decision

- Tambahkan W06.5 setelah W06 dan sebelum W07 untuk job, provider adapter, hasil, UI, dan tests.
- Hanya pertanyaan foto dengan mode `food` yang dianalisis. Submission/poin/approval selesai pada authority path yang sudah ada; job AI berjalan durable dan asynchronous setelahnya.
- Enqueue setelah commit bersifat best-effort dan didampingi reconciliation scan idempotent agar crash di antara commit/enqueue tidak kehilangan analisis permanen atau mengganggu poin.
- Provider dipanggil server-side melalui `FoodVisionProvider`. Adapter awal memakai transport OpenAI-compatible dengan konfigurasi provider, base URL, API key, model, prompt version, dan rubric version.
- Model default berasal dari `FOOD_AI_MODEL=google/gemma-4-31b-it:free`; request selalu memakai `reasoning.effort=none`, mengecualikan reasoning response, dan membatasi output. Model OpenRouter kompatibel dapat diganti lewat environment dan restart/redeploy saja.
- Provider OpenAI-compatible dapat diganti melalui environment saja. Provider dengan endpoint/schema berbeda membutuhkan adapter baru yang memenuhi contract test yang sama; perubahan key saja tidak dapat menjamin kompatibilitas universal.
- Result tervalidasi berisi jenis foto, estimasi kkal/protein/karbohidrat/lemak, rating 1–5, confidence, reason code, insight non-diagnostik, dan version metadata.
- Insight dan alasan rating wajib dalam Bahasa Indonesia. Structured schema meminta satu atau dua `insightSentences`, masing-masing maksimal 80 karakter dan maksimal 160 karakter gabungan; output invalid/non-Indonesia tidak diteruskan mentah dan diganti melalui retry terbatas atau fallback Indonesia tervalidasi.
- Kalibrasi favorable memakai policy server versioned `food_rating_policy_v1`: 4 adalah default untuk makanan yang plausible tanpa masalah jelas, 5 untuk match kuat, 3 untuk ambigu/campuran, rating 1 hanya untuk `not_food_for_required_food`, dan rating 2 hanya untuk `severe_explicit_rubric_mismatch`. Rating 1–2 memerlukan rubric published serta confidence `>= 0.90`; validator menaikkan outcome lain menjadi minimal 3/`uncertain`.
- AI menjadi pemberi bintang utama; Coach tidak mengisi rating pada alur normal. Coach/Admin boleh mengoreksi hasil jelas salah dengan alasan/audit, tanpa dampak pada poin.
- Baseline privacy dibuat minimal: satu disclosure sebelum submit, anjuran menghindari wajah/dokumen, metadata stripping, payload minim, credential server-side, dan akses hasil mengikuti scope submission. Tidak ada checkbox consent terpisah, ZDR khusus, DPIA terpisah, atau tombol withdraw khusus.
- Raw provider request/response tidak disimpan. Retention foto dan insight mengikuti lifecycle submission yang sama.

## Consequences

Positif:

- poin dan pengalaman utama tidak bergantung pada latency/availability LLM;
- rating cenderung suportif dan ambiguity tidak menghukum Participant;
- OpenRouter dapat diganti tanpa mengubah feature/domain code ketika provider berikutnya kompatibel;
- privacy UI tetap ringkas dengan safeguard teknis minimum.

Risiko/trade-offs:

- macro dari satu foto hanyalah perkiraan dan harus selalu dilabeli demikian;
- model gratis dapat berubah, rate-limit, atau hilang sehingga fallback/error state wajib;
- foto makanan tetap data pengguna ketika terhubung ke akun dan dapat tanpa sengaja memuat orang/dokumen; klaim "bukan data pribadi" tidak boleh digunakan sebagai security assumption;
- favorable calibration perlu fixture/regression test agar model/prompt baru tidak menggeser distribusi rating secara diam-diam.
