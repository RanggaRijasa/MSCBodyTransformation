import { AuthPage } from "@/features/auth/components/auth-page";

export default function RegisterPage() {
  return (
    <AuthPage
      description="Buat akun Peserta, lalu lengkapi profil dan tujuan Anda."
      mode="register"
      title="Daftar"
    />
  );
}
