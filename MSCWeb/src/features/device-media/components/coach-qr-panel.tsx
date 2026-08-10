import Image from "next/image";

import { SafeImageShareButton } from "@/features/device-media/components/safe-image-share-button";

export function CoachQrPanel({ coachName }: Readonly<{ coachName: string }>) {
  return (
    <section aria-labelledby="coach-qr-heading" className="coach-qr-panel">
      <header>
        <p className="auth-eyebrow">Pendaftaran Peserta</p>
        <h1 id="coach-qr-heading">QR Coach</h1>
        <p>
          Minta Peserta memindai QR ini dari aplikasi MSC. Identifier tidak ditampilkan dan tidak
          dapat disalin sebagai teks.
        </p>
      </header>
      <div className="coach-qr-panel__image">
        <Image
          alt={`QR pendaftaran milik ${coachName}`}
          height={320}
          priority
          src="/api/coach/qr-image"
          unoptimized
          width={320}
        />
      </div>
      <SafeImageShareButton fileName="qr-coach-msc.svg" sourceUrl="/api/coach/qr-image" />
      <p className="coach-qr-panel__privacy">
        Bagikan hanya gambar QR kepada Peserta yang akan kamu dampingi. QR akan divalidasi lagi oleh
        server saat pendaftaran.
      </p>
    </section>
  );
}
