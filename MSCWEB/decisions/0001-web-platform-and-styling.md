# ADR-0001 — Expo, React Native Web, and StyleSheet tokens

Status: Accepted  
Date: 12 August 2026

## Context

Produk harus memindahkan aplikasi iPhone ke PWA dengan pengalaman compact yang sangat dekat dengan mobile, sekaligus tetap layak pada desktop. Tim ingin menghindari hasil yang terlihat seperti template website generik.

## Decision

- Gunakan Expo + React Native + React Native Web + Expo Router + TypeScript strict.
- Gunakan React Native `StyleSheet.create` dan three-layer design tokens sebagai styling utama.
- Landing web-only boleh memakai semantic HTML dan CSS Modules/platform stylesheet, dengan tokens yang sama.
- Gunakan Reanimated dan Gesture Handler secara selektif.
- Jangan gunakan Tailwind/NativeWind atau full UI kit pada baseline.
- Hosting export web melalui Cloudflare Workers Static Assets setelah feasibility spike mengunci output mode.

## Consequences

Positif:

- mental model/component patterns konsisten dengan mobile;
- tokens memberi visual discipline dan light/dark/accessibility control;
- lebih mudah menjaga compact parity tanpa class-string proliferation;
- Expo tooling mendukung web export dan PWA.

Trade-offs:

- semantic HTML, SEO, focus/hover, dan data-dense Admin membutuhkan adapter/platform-specific implementation;
- React Native Web tidak otomatis membuat UX native; quality tetap bergantung pada custom design system dan testing;
- package compatibility harus diuji pada Safari/iOS PWA.

## Rejected alternatives

- Tailwind/NativeWind sebagai styling utama: tidak dipilih karena product meminta token-driven RN styling dan ingin menjaga abstraction dekat React Native.
- Menulis dua app terpisah React DOM dan React Native: terlalu cepat menggandakan feature/domain UI pada baseline.
- Meniru SwiftUI/Liquid Glass dengan custom CSS pada semua surface: risiko performa, contrast, dan visual gimmick.

