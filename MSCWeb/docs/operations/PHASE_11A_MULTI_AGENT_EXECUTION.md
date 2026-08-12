# Phase 11A Multi-Agent Execution Protocol

## Tujuan

Redesign besar dijalankan dengan pemisahan peran agar keputusan visual,
implementasi, dan acceptance tidak diperiksa oleh satu agent yang sama.
Dokumen ini adalah konfigurasi kerja project untuk Codex; jangan menciptakan
file konfigurasi agent proprietary yang belum didukung runtime.

## Formasi maksimum

Dengan empat slot agent termasuk coordinator:

```text
Orchestrator / PM
├── Implementer A — active vertical slice
├── Implementer B — tests/evidence atau non-overlapping slice
└── Reviewer — independent review dan regression audit
```

Tidak semua slot harus selalu dipakai. Gunakan subagent hanya untuk task yang
bounded, memiliki file ownership jelas, dan dapat berjalan independen.

## Orchestrator / PM

Tanggung jawab:

- membaca phase, companion docs, AGENTS, current diff, dan progress log;
- memilih satu coherent slice serta menetapkan acceptance criteria;
- menjaga route/function/backend freeze dan dependency direction;
- membagi file ownership tanpa overlap;
- mengelola iOS reference, concept approval, parity ledger, dan decision gate;
- mengintegrasikan hasil serta menjalankan final verification;
- menghentikan kerja pada production/backend/external approval gate.

PM tidak boleh menandai checklist selesai hanya dari laporan subagent. Ia harus
memeriksa diff dan evidence akhir pada shared workspace.

## Implementer

Tanggung jawab:

- hanya mengubah file yang diberikan PM di dalam `MSCWeb/`;
- membaca nearby implementation dan test sebelum patch;
- mempertahankan function/state/repository boundary;
- memakai approved tokens/primitives, bukan membuat design system paralel;
- membuat focused tests dan screenshot evidence bersama production change;
- melaporkan file, assumption, command, result, dan blocker.

Implementer dilarang:

- mengedit file milik implementer lain pada waktu bersamaan;
- mengubah snapshot tanpa inspeksi visual;
- menambah dependency di luar approved compatibility slice;
- mengubah root backend/iOS/shared contract;
- memperluas slice sendiri hanya karena menemukan UI lain yang belum bagus.

## Reviewer

Reviewer harus independen dari implementation utama slice yang dinilai.

Tanggung jawab:

- membaca requirement dan diff, bukan hanya screenshot akhir;
- membandingkan iOS reference, accepted concept, dan PWA rendered output;
- menguji functional preservation, responsive behavior, accessibility,
  privacy/security, React performance, dan component architecture;
- memeriksa snapshot pada original detail dan interaction path;
- memberi finding dengan severity, path, evidence, dan reproduction;
- menjalankan focused verification yang proporsional;
- menyatakan `accepted` hanya bila tidak ada unresolved Critical/High.

Reviewer bekerja read-only. Temuan dikembalikan kepada implementer pemilik;
reviewer tidak memperbaiki slice yang sedang ia nilai karena itu menghilangkan
independensi acceptance.

Reviewer tidak mengubah acceptance criteria setelah melihat implementation dan
tidak menurunkan severity hanya karena regression sulit diperbaiki.

## Work packet wajib

Setiap delegation message memuat:

```text
Phase/slice:
Objective:
Files owned:
Read-only references:
Functions/states that must remain:
Accepted visual reference:
Tests/evidence required:
Commands allowed:
Explicit prohibitions:
Expected handoff:
```

Task tanpa file ownership atau acceptance reference belum siap didelegasikan.

## Ownership dan concurrency

- Satu file hanya memiliki satu writer pada satu waktu.
- Shared tokens, primitives, global CSS, lockfile, package config, app layout,
  navigation shell, dan snapshot index adalah serialized ownership.
- Feature implementation dapat paralel hanya setelah shared contract stabil.
- Reviewer boleh membaca workspace saat implementation berlangsung, tetapi
  final review dimulai pada immutable handoff point yang dicatat PM.
- Jika dua slice perlu file yang sama, urutkan slice; jangan menyelesaikan
  conflict dengan overwrite atau destructive Git command.
- Capability lintas role seperti payments, programs, device-media, app-shell,
  dan PWA runtime memiliki satu owner khusus; jangan membaginya sekaligus ke
  owner Peserta, Coach, dan Admin.
- Transfer ownership hanya sah setelah writer lama idle dan ledger PM
  diperbarui.

## Gelombang execution

### Wave 0 — PM dan reference

- Freeze function inventory dan current test baseline.
- Capture iOS reference dan buat parity ledger.
- Hasilkan concept, dapatkan owner approval, tetapkan design contract.

### Wave 1 — Foundation

- Implementer A: compatibility/config Tailwind dan shadcn.
- Implementer B: visual/test harness dan reference gallery.
- Reviewer: dependency, architecture, accessibility, performance review.

### Wave 2 — Shell dan public

- Shared shell/design primitives diserialkan lebih dahulu.
- Guest/Auth menjadi pilot setelah primitive stabil.
- Reviewer menutup Wave 2 sebelum role-heavy work meluas.

### Wave 3 — Role surfaces

- Peserta dan Coach dapat paralel bila ownership tidak overlap.
- Admin berjalan setelah shared responsive pattern stabil atau pada file set
  terpisah yang disetujui PM.
- Payment/media shared component changes diserialkan.
- Landing dimigrasikan setelah system/role pattern stabil karena CSS existing
  besar dan global; dekorasi khusus boleh tetap scoped CSS yang terpecah.

### Wave 4 — Hardening dan closure

- Satu agent fokus visual/accessibility/performance fixes.
- Reviewer menjalankan parity ledger dan independent acceptance.
- PM menjalankan full Phase 10/11 regression serta menutup progress log.

## Handoff format

Implementer menyerahkan:

- ringkasan outcome, bukan rencana;
- daftar file yang diubah;
- screenshot/evidence path dan viewport;
- function/state checklist yang dipertahankan;
- command exact beserta hasil;
- test/snapshot yang sengaja diperbarui;
- known gap, manual check, dan external blocker.

Reviewer menyerahkan:

- findings berurutan severity;
- parity ledger row yang accepted/needs fix;
- command dan environment yang dipakai;
- verdict `accepted`, `accepted with documented low risk`, atau `rejected`.

Orchestrator memverifikasi `git diff --name-only` terhadap allowlist work
packet sebelum menerima handoff. Snapshot memiliki satu custodian setelah
reviewer menyetujui perubahan yang memang dimaksudkan.

## Quality gates antar-wave

Wave berikutnya tidak dimulai bila:

- accepted concept belum ada;
- shared component contract masih berubah tanpa versioned decision;
- unresolved Critical/High functional, accessibility, privacy, atau visual gap;
- focused lint/typecheck/test/build slice gagal;
- snapshot belum diperiksa manusia/agent reviewer secara visual;
- file ownership overlap belum diselesaikan.

## Git, backend, dan external state

- Semua Git restriction root tetap berlaku; subagent tidak mendapat izin Git
  tambahan dari delegation.
- Local Supabase dinyalakan hanya saat regression/integration memerlukannya dan
  tidak dihentikan otomatis.
- Hosted main, DNS, domain, deployment, provider, dan secret tetap dilarang
  tanpa approval terpisah.
- iOS Simulator adalah reference tool; source iOS tetap read-only.

## Recommended task prompt

```text
Kerjakan hanya Phase 11A Slice <ID> di MSCWeb. Ikuti AGENTS.md, phase utama,
design parity contract, acceptance matrix, dan multi-agent protocol. Bekukan
semua fungsi/backend. Gunakan file ownership yang diberikan, jalankan focused
tests, buat evidence, dan jangan melakukan Git/deploy/hosted mutation.
```

PM menambahkan file ownership, accepted reference, dan command spesifik untuk
setiap task. Prompt generik di atas tidak cukup untuk memulai implementation.
