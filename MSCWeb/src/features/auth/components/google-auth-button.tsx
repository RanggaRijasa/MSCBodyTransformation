type GoogleAuthButtonProperties = Readonly<{
  mode: "login" | "register" | "reauthenticate";
  returnTo?: string | undefined;
}>;

export function GoogleAuthButton({ mode, returnTo }: GoogleAuthButtonProperties) {
  const parameters = new URLSearchParams({ mode });
  if (returnTo) parameters.set("returnTo", returnTo);
  const label = mode === "register" ? "Daftar dengan Google" : "Lanjutkan dengan Google";

  return (
    <a className="google-auth-button" href={`/auth/google/start?${parameters.toString()}`}>
      <span aria-hidden="true" className="google-auth-button__brand" />
      <span>{label}</span>
    </a>
  );
}
