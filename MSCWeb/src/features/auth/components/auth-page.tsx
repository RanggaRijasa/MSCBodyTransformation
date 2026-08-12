import Link from "next/link";

import { AuthCloseControl } from "@/features/auth/components/auth-close-control";
import { AuthRouteFocus } from "@/features/auth/components/auth-route-focus";
import { GoogleAuthButton } from "@/features/auth/components/google-auth-button";
import { AppIcon } from "@/shared/ui/icons/app-icon";

type AuthPageProperties = Readonly<{
  description: string;
  mode: "login" | "register";
  notice?: string | undefined;
  noticeTone?: "error" | "status" | undefined;
  returnTo?: string | undefined;
  title: string;
}>;

export function AuthPage({
  description,
  mode,
  notice,
  noticeTone = "status",
  returnTo,
  title,
}: AuthPageProperties) {
  const isLogin = mode === "login";
  const switchHref = `${isLogin ? "/daftar" : "/masuk"}${
    returnTo ? `?returnTo=${encodeURIComponent(returnTo)}` : ""
  }`;
  return (
    <main className="auth-page" id="konten-utama">
      <section aria-labelledby="auth-title" className="auth-card">
        <header className="auth-card__topbar">
          <span className="auth-route-title">{isLogin ? "Masuk" : "Daftar"}</span>
          <AuthCloseControl />
        </header>
        <div className="auth-card__heading">
          <span aria-hidden="true" className="auth-icon">
            <AppIcon name="person" />
          </span>
          <h1 id="auth-title" tabIndex={-1}>
            {title}
          </h1>
          <AuthRouteFocus focusKey={`${mode}:${title}`} headingId="auth-title" />
          <p>{description}</p>
        </div>
        {notice ? (
          <p
            className={`auth-notice auth-notice--${noticeTone}`}
            role={noticeTone === "error" ? "alert" : "status"}
          >
            {notice}
          </p>
        ) : null}
        <GoogleAuthButton mode={mode} returnTo={returnTo} />
        <footer className="auth-switch">
          {isLogin ? "Belum punya akun?" : "Sudah punya akun?"}{" "}
          <Link href={switchHref}>{isLogin ? "Daftar" : "Masuk"}</Link>
        </footer>
      </section>
    </main>
  );
}
