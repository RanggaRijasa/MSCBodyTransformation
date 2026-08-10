import Link from "next/link";

export default function ForgotPasswordPage() {
  return (
    <main className="auth-page" id="konten-utama">
      <section className="auth-card">
        <p className="auth-eyebrow">Pemulihan akun</p>
        <h1>Lupa password</h1>
        <p>
          Pemulihan melalui email belum diaktifkan. Jika fitur ini diaktifkan nanti, respons akan
          tetap sama untuk setiap alamat email agar keberadaan akun tidak terbuka.
        </p>
        <Link className="app-action app-action--secondary" href="/masuk">
          Kembali ke masuk
        </Link>
      </section>
    </main>
  );
}
