import Link from "next/link";

import { AuthCloseControl } from "@/features/auth/components/auth-close-control";
import { AppIcon } from "@/shared/ui/icons/app-icon";

export default function ForgotPasswordPage() {
  return (
    <main className="auth-page" id="konten-utama">
      <section aria-labelledby="forgot-title" className="auth-card auth-card--compact">
        <header className="auth-card__topbar">
          <span className="auth-route-title">Pemulihan</span>
          <AuthCloseControl />
        </header>
        <div className="auth-card__heading">
          <span aria-hidden="true" className="auth-icon">
            <AppIcon name="info" />
          </span>
          <h1 autoFocus id="forgot-title" tabIndex={-1}>
            Lupa password
          </h1>
          <p>
            Pemulihan melalui email belum diaktifkan. Jika fitur ini diaktifkan nanti, respons akan
            tetap sama untuk setiap alamat email agar keberadaan akun tidak terbuka.
          </p>
        </div>
        <footer className="auth-switch">
          <Link href="/masuk">Kembali ke masuk</Link>
        </footer>
      </section>
    </main>
  );
}
