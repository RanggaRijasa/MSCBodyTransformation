import Link from "next/link";

import type { CoachContext } from "@/domain/coach/coach-experience";
import { createProgramDateTimeFormatter } from "@/shared/formatting/indonesian-formatters";
import { StatusBadge, Surface } from "@/shared/ui";

const stateCopy = {
  expired: [
    "Akses Coach berakhir",
    "Perpanjang akses melalui pembayaran manual untuk membuka kembali fitur Coach.",
  ],
  inactive: ["Akses Coach belum aktif", "Selesaikan pengajuan dan pembayaran yang diperlukan."],
  pending: ["Akses Coach sedang diproses", "Pantau status pengajuan atau pembayaranmu."],
  rejected: [
    "Pengajuan Coach tidak disetujui",
    "Akun Peserta tetap aktif. Lihat alasan pada status pengajuan.",
  ],
} as const;

export function CoachAccessState({ context }: Readonly<{ context: CoachContext }>) {
  if (context.accessState === "active") return null;
  const [title, description] = stateCopy[context.accessState];
  return (
    <Surface className="coach-locked-state">
      <StatusBadge tone="warning">Fitur Coach terkunci</StatusBadge>
      <h1>{title}</h1>
      <p>{description}</p>
      {context.accessEndsAt ? (
        <p>
          Periode terakhir berakhir{" "}
          {createProgramDateTimeFormatter("Asia/Jakarta").format(new Date(context.accessEndsAt))}{" "}
          WIB.
        </p>
      ) : null}
      <div className="coach-actions">
        {context.paymentOrderId ? (
          <Link
            className="app-action app-action--primary"
            href={`/pembayaran/${context.paymentOrderId}`}
          >
            Lihat pembayaran
          </Link>
        ) : context.applicationId ? (
          <Link
            className="app-action app-action--primary"
            href={`/akses-coach/${context.applicationId}`}
          >
            Lihat status pengajuan
          </Link>
        ) : null}
        <Link className="app-action app-action--secondary" href="/hari-ini">
          Lanjut sebagai Peserta
        </Link>
      </div>
    </Surface>
  );
}
