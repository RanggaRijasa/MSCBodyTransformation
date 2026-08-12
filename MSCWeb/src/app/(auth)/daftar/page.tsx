import { AuthPage } from "@/features/auth/components/auth-page";
import { safeReturnTo } from "@/features/auth/model/auth-flow";

type PageProperties = Readonly<{
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}>;

export default async function RegisterPage({ searchParams }: PageProperties) {
  const parameters = await searchParams;
  const returnTo = safeReturnTo(
    typeof parameters.returnTo === "string" ? parameters.returnTo : undefined,
  );
  return (
    <AuthPage
      description="Buat akun Peserta, lalu lengkapi profil dan tujuan Anda."
      mode="register"
      returnTo={returnTo}
      title="Buat akun Peserta"
    />
  );
}
