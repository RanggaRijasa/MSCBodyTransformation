type LegalPage = {
  slug: "privacy" | "terms";
  title: string;
  introduction: string;
  sections: Array<{ title: string; body: string }>;
};

const updatedAt = "9 Agustus 2026";

const pages: Record<LegalPage["slug"], LegalPage> = {
  privacy: {
    slug: "privacy",
    title: "Kebijakan Privasi MSC Body Transformation",
    introduction:
      "Kebijakan ini menjelaskan data yang diproses ketika Anda menggunakan aplikasi MSC Body Transformation.",
    sections: [
      {
        title: "Data yang diproses",
        body:
          "Kami memproses nama, email, nomor HP, ID akun, peran, profil, keikutsertaan program, jawaban, berat badan, foto atau video bukti, skor, riwayat pembelian, serta data operasional yang diperlukan untuk menjalankan layanan.",
      },
      {
        title: "Tujuan penggunaan",
        body:
          "Data digunakan untuk autentikasi, membuat profil, menghubungkan Participant dengan Coach, menjalankan program, menilai kiriman, menghitung skor, menampilkan peringkat, memproses akses berbayar, mencegah penyalahgunaan, dan memenuhi kewajiban keamanan.",
      },
      {
        title: "Penyedia layanan",
        body:
          "Autentikasi dapat melibatkan Google atau Apple. Data aplikasi disimpan melalui Supabase. Pembelian diproses oleh Apple melalui StoreKit. MSC Body Transformation tidak menerima nomor kartu atau detail rekening pembayaran Anda.",
      },
      {
        title: "Foto, video, dan data wellness",
        body:
          "Foto atau video bukti dan berat badan merupakan data pribadi yang sensitif. Media diproses untuk kebutuhan program, metadata yang tidak diperlukan dihapus sebelum unggah, dan akses dibatasi sesuai peran. Aplikasi ini tidak memberikan diagnosis atau saran medis.",
      },
      {
        title: "Penyimpanan dan penghapusan",
        body:
          "Data disimpan selama akun atau kewajiban program, keamanan, audit, dan transaksi masih memerlukannya. Saat akun dihapus, akses dicabut dan data pribadi serta media dihapus. Catatan pemenang, audit, atau transaksi yang wajib dipertahankan dapat disimpan tanpa identitas pribadi.",
      },
      {
        title: "Pelacakan dan iklan",
        body:
          "Aplikasi tidak menggunakan data untuk pelacakan lintas aplikasi atau situs dan tidak menjual data pribadi untuk periklanan.",
      },
      {
        title: "Kontrol dan kontak",
        body:
          "Anda dapat memperbarui profil, keluar, atau meminta penghapusan akun dari layar Profil. Pertanyaan privasi dapat dikirim melalui kanal dukungan yang tercantum pada halaman aplikasi di App Store.",
      },
    ],
  },
  terms: {
    slug: "terms",
    title: "Ketentuan Penggunaan MSC Body Transformation",
    introduction:
      "Ketentuan ini mengatur penggunaan aplikasi dan program MSC Body Transformation.",
    sections: [
      {
        title: "Penggunaan layanan",
        body:
          "Gunakan aplikasi secara jujur, aman, dan sesuai program. Anda bertanggung jawab atas ketepatan data, jawaban, berat badan, dan media yang dikirim serta dilarang mengunggah konten milik orang lain tanpa izin.",
      },
      {
        title: "Informasi wellness",
        body:
          "Program berfokus pada kebiasaan dan wellness, bukan layanan medis, diagnosis, atau pengganti konsultasi profesional. Hentikan aktivitas dan cari bantuan profesional bila Anda merasa tidak aman atau mengalami keluhan kesehatan.",
      },
      {
        title: "Program dan Coach",
        body:
          "Pendaftaran Participant memerlukan QR Coach yang aktif. Kapasitas, jadwal, cutoff, langkah, bukti, penilaian, dan aturan skor mengikuti program yang dipublikasikan. Akses Coach berlaku tiga bulan setelah pembayaran terverifikasi dan menjadi nonaktif saat masa akses berakhir.",
      },
      {
        title: "Pembelian dan pengembalian dana",
        body:
          "Program berbayar dan akses Coach dibeli melalui Apple. Tidak tersedia pengembalian dana sukarela setelah pembelian. Hak pengembalian dana, pembatalan, atau pencabutan oleh Apple tetap berlaku dan dapat menyebabkan akses terkait dihentikan.",
      },
      {
        title: "Pengajuan Coach",
        body:
          "Pengajuan Coach pertama harus memenuhi kelayakan dan diterima Admin sebelum pembayaran. Renewal dilakukan manual dan tidak memerlukan persetujuan ulang selama approval belum dicabut. Coach dengan Participant aktif tidak dapat menghapus akun sebelum pengalihan diselesaikan oleh Admin.",
      },
      {
        title: "Peringkat dan pemenang",
        body:
          "Skor authoritative dihitung server dari kiriman yang disetujui, berat badan, dan penyesuaian yang teraudit. Keputusan pemenang mengikuti snapshot final yang dikunci Admin. Jika hadiah diumumkan untuk suatu program, syarat hadiah tersebut akan dicantumkan pada detail program.",
      },
      {
        title: "Akun dan penegakan",
        body:
          "Jaga keamanan akun dan jangan membagikan akses. Kami dapat membatasi akun atau kiriman yang melanggar aturan, memalsukan bukti, menyalahgunakan pembayaran, mengganggu layanan, atau membahayakan pengguna lain.",
      },
      {
        title: "Perubahan ketentuan",
        body:
          "Perubahan penting akan dicantumkan pada versi terbaru dokumen. Penggunaan layanan setelah perubahan berlaku berarti Anda menerima ketentuan terbaru.",
      },
    ],
  },
};

const securityHeaders = {
  "Cache-Control": "public, max-age=300, stale-while-revalidate=3600",
  "Content-Security-Policy":
    "default-src 'none'; style-src 'unsafe-inline'; img-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'",
  "Cross-Origin-Opener-Policy": "same-origin",
  "Cross-Origin-Resource-Policy": "same-origin",
  "Referrer-Policy": "no-referrer",
  "X-Content-Type-Options": "nosniff",
  "X-Frame-Options": "DENY",
};

export default {
  fetch(request: Request): Response {
    if (request.method !== "GET" && request.method !== "HEAD") {
      return new Response("Metode tidak diizinkan.", {
        status: 405,
        headers: {
          ...securityHeaders,
          "Allow": "GET, HEAD",
          "Content-Type": "text/plain; charset=utf-8",
        },
      });
    }

    const slug = pageSlug(new URL(request.url).pathname);
    if (!slug) {
      return new Response("Dokumen tidak ditemukan.", {
        status: 404,
        headers: {
          ...securityHeaders,
          "Content-Type": "text/plain; charset=utf-8",
        },
      });
    }

    const html = renderPage(pages[slug]);
    return new Response(request.method === "HEAD" ? null : html, {
      status: 200,
      headers: {
        ...securityHeaders,
        "Content-Language": "id-ID",
        "Content-Type": "text/html; charset=utf-8",
      },
    });
  },
};

function pageSlug(pathname: string): LegalPage["slug"] | null {
  const lastComponent = pathname.split("/").filter(Boolean).at(-1);
  return lastComponent === "privacy" || lastComponent === "terms"
    ? lastComponent
    : null;
}

function renderPage(page: LegalPage): string {
  const sections = page.sections.map((section) => `
      <section>
        <h2>${escapeHTML(section.title)}</h2>
        <p>${escapeHTML(section.body)}</p>
      </section>`).join("");
  return `<!doctype html>
<html lang="id">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="light dark">
  <title>${escapeHTML(page.title)}</title>
  <style>
    :root { font-family: -apple-system, BlinkMacSystemFont, sans-serif; color-scheme: light dark; }
    body { margin: 0; background: Canvas; color: CanvasText; }
    main { width: min(760px, calc(100% - 40px)); margin: 0 auto; padding: 48px 0 72px; }
    .brand { color: #d6261f; font-weight: 700; letter-spacing: .02em; }
    h1 { font-size: clamp(2rem, 7vw, 3.5rem); line-height: 1.05; margin: 20px 0 12px; }
    h2 { font-size: 1.25rem; margin: 32px 0 8px; }
    p { font-size: 1.05rem; line-height: 1.65; margin: 0; }
    .meta { color: GrayText; margin-top: 10px; }
    footer { border-top: 1px solid color-mix(in srgb, CanvasText 18%, transparent); margin-top: 40px; padding-top: 20px; color: GrayText; }
  </style>
</head>
<body>
  <main>
    <div class="brand">MSC BODY TRANSFORMATION</div>
    <h1>${escapeHTML(page.title)}</h1>
    <p>${escapeHTML(page.introduction)}</p>
    <p class="meta">Diperbarui ${updatedAt}</p>
    ${sections}
    <footer><p>Dokumen resmi aplikasi MSC Body Transformation.</p></footer>
  </main>
</body>
</html>`;
}

function escapeHTML(value: string): string {
  return value.replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}
