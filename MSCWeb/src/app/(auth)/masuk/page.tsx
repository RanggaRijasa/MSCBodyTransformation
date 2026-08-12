import { AuthPage } from "@/features/auth/components/auth-page";
import { safeReturnTo } from "@/features/auth/model/auth-flow";

type PageProperties = Readonly<{
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}>;

const errorMessages: Readonly<Record<string, string>> = {
  callback: "Tautan masuk tidak valid atau sudah tidak berlaku. Mulai lagi dari halaman ini.",
  cancelled: "Proses masuk dibatalkan. Tidak ada perubahan pada akun Anda.",
  configuration: "Layanan masuk lokal belum dikonfigurasi. Coba lagi setelah konfigurasi tersedia.",
  exchange: "Sesi belum dapat dibuat. Mulai lagi dan pastikan koneksi stabil.",
  provider: "Google belum dapat dihubungi. Periksa koneksi lalu coba lagi.",
  state: "Permintaan masuk tidak cocok atau sudah kedaluwarsa. Mulai lagi untuk keamanan akun.",
};

export default async function LoginPage({ searchParams }: PageProperties) {
  const parameters = await searchParams;
  const error = typeof parameters.error === "string" ? parameters.error : undefined;
  const status = typeof parameters.status === "string" ? parameters.status : undefined;
  const returnTo = safeReturnTo(
    typeof parameters.returnTo === "string" ? parameters.returnTo : undefined,
  );
  const selectedNotice =
    status === "keluar"
      ? ({ copy: "Anda sudah keluar dengan aman.", tone: "status" } as const)
      : error
        ? ({
            copy:
              errorMessages[error] ??
              "Proses masuk belum dapat diselesaikan. Mulai lagi dari halaman ini.",
            tone: "error",
          } as const)
        : undefined;

  return (
    <AuthPage
      description="Gunakan akun Google Anda untuk melanjutkan dengan aman."
      mode="login"
      notice={selectedNotice?.copy}
      noticeTone={selectedNotice?.tone}
      returnTo={returnTo}
      title="Selamat datang kembali"
    />
  );
}
