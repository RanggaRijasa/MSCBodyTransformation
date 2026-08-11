import Link from "next/link";

import { GoogleAuthButton } from "@/features/auth/components/google-auth-button";

type AuthPageProperties = Readonly<{
  description: string;
  mode: "login" | "register";
  notice?: string | undefined;
  returnTo?: string | undefined;
  title: string;
}>;

export function AuthPage({ description, mode, notice, returnTo, title }: AuthPageProperties) {
  const isLogin = mode === "login";
  return (
    <main className="auth-page" id="konten-utama">
      <section aria-labelledby="auth-title" className="auth-card">
        <Link className="auth-wordmark" href="/">
          MSC <span>Body Transformation</span>
        </Link>
        <div className="auth-card__heading">
          <p className="auth-eyebrow">Akun Peserta</p>
          <h1 id="auth-title">{title}</h1>
          <p>{description}</p>
        </div>
        {notice ? (
          <p className="auth-notice" role="status">
            {notice}
          </p>
        ) : null}
        <GoogleAuthButton mode={mode} returnTo={returnTo} />
        <p className="auth-provider-note">
          Akun baru selalu dibuat sebagai Peserta. Pengajuan Coach dilakukan setelah profil selesai.
        </p>
        <div aria-label="Metode lain" className="auth-divider">
          <span>atau</span>
        </div>
        <p className="auth-feature-gate">
          Masuk dengan email dan pemulihan password belum diaktifkan pada lingkungan ini.
        </p>
        <p className="auth-switch">
          {isLogin ? "Belum punya akun?" : "Sudah punya akun?"}{" "}
          <Link href={isLogin ? "/daftar" : "/masuk"}>{isLogin ? "Daftar" : "Masuk"}</Link>
        </p>
      </section>
    </main>
  );
}
