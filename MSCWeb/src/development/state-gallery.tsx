"use client";

import { useCallback, useState } from "react";

import { shellProgramFixture } from "@/features/app-shell/fixtures/shell-fixtures";
import { navigationByKind, ShellNavigation, type ShellKind } from "@/features/app-shell";
import { ImageAcquisition, QrScannerDialog } from "@/features/device-media";
import { ProgramGallery } from "@/development/program-gallery";
import { PaymentGallery } from "@/development/payment-gallery";
import { ParticipantGallery } from "@/development/participant-gallery";
import { CoachGallery } from "@/development/coach-gallery";
import { AdminGallery } from "@/development/admin-gallery";
import { MarketingCaptureGallery } from "@/development/marketing-capture-gallery";
import { copy } from "@/shared/i18n/id";
import {
  AppButton,
  Avatar,
  ChoiceField,
  FilterActions,
  FilterForm,
  FilterSummary,
  FormErrorSummary,
  MediaSurface,
  Metric,
  ModalDialog,
  ProgramActivityRenderer,
  SelectField,
  Skeleton,
  StateMessage,
  StatusBadge,
  Surface,
  TextareaField,
  TextField,
  ToastLiveRegion,
} from "@/shared/ui";

export function StateGallery() {
  const [isDialogOpen, setDialogOpen] = useState(false);
  const [toast, setToast] = useState<string>();
  const [isQrOpen, setQrOpen] = useState(false);
  const [mediaStatus, setMediaStatus] = useState("Belum ada media diproses.");
  const closeDialog = useCallback(() => setDialogOpen(false), []);

  return (
    <main className="state-gallery">
      <header className="state-gallery__intro">
        <p>{copy.shell.phaseLabel}</p>
        <h1>{copy.stateGallery.title}</h1>
        <p>{copy.stateGallery.summary}</p>
      </header>

      <section aria-labelledby="gallery-controls">
        <h2 id="gallery-controls">{copy.stateGallery.controls}</h2>
        <div className="state-gallery__actions">
          <AppButton onClick={() => setToast("Perubahan contoh tersimpan.")}>
            Simpan perubahan
          </AppButton>
          <AppButton onClick={() => setDialogOpen(true)} variant="secondary">
            Buka dialog
          </AppButton>
          <AppButton variant="accent">Lihat pencapaian</AppButton>
          <AppButton variant="destructive">Hapus draft</AppButton>
          <AppButton isLoading>Memproses</AppButton>
        </div>
      </section>

      <section aria-labelledby="gallery-states">
        <h2 id="gallery-states">{copy.stateGallery.states}</h2>
        <div className="state-gallery__grid">
          <Surface>
            <Skeleton />
          </Surface>
          <StateMessage
            description="Konten baru akan tampil setelah tersedia."
            title="Belum ada konten"
          />
          <StateMessage
            description="Periksa koneksi, lalu coba lagi."
            title="Konten belum dapat dimuat"
            tone="error"
          />
          <Surface elevated>
            <StatusBadge tone="success">Disetujui</StatusBadge>
            <Metric label="Total poin" value="1.250" />
          </Surface>
        </div>
      </section>

      <section aria-labelledby="gallery-forms">
        <h2 id="gallery-forms">{copy.stateGallery.forms}</h2>
        <div className="state-gallery__grid">
          <Surface className="state-gallery__stack">
            <TextField id="gallery-name" label="Nama tampilan" placeholder="Masukkan nama" />
            <SelectField id="gallery-program" label="Program">
              <option>Program kebiasaan sehat</option>
            </SelectField>
            <TextareaField id="gallery-note" label="Catatan" />
            <ChoiceField id="gallery-confirm" label="Saya sudah memeriksa data" type="checkbox" />
          </Surface>
          <Surface className="state-gallery__stack">
            <FormErrorSummary title="Periksa kembali data">
              <p>Nama tampilan perlu diisi.</p>
            </FormErrorSummary>
            <Avatar name="Avatar kosong" />
            <MediaSurface alt="Cover program placeholder" />
          </Surface>
        </div>
      </section>

      <section aria-labelledby="gallery-program">
        <h2 id="gallery-program">{copy.stateGallery.program}</h2>
        <ProgramActivityRenderer audience="participant" model={shellProgramFixture} />
      </section>

      <section aria-labelledby="gallery-media">
        <h2 id="gallery-media">Media browser</h2>
        <div className="state-gallery__grid">
          <Surface className="state-gallery__stack">
            <h3>Pemindai QR</h3>
            <p>{mediaStatus}</p>
            <AppButton onClick={() => setQrOpen(true)} variant="secondary">
              Uji pemindai QR
            </AppButton>
          </Surface>
          <Surface className="state-gallery__stack">
            <h3>Pemrosesan foto</h3>
            <ImageAcquisition
              onProcessed={(image) =>
                setMediaStatus(
                  `Foto aman siap: ${image.descriptor.width} × ${image.descriptor.height} piksel.`,
                )
              }
            />
          </Surface>
        </div>
      </section>

      <section aria-labelledby="gallery-program-catalog">
        <h2 id="gallery-program-catalog">Katalog program</h2>
        <ProgramGallery />
      </section>

      <section aria-labelledby="gallery-payments">
        <h2 id="gallery-payments">Pembayaran manual</h2>
        <PaymentGallery />
      </section>

      <section aria-labelledby="gallery-participant">
        <h2 id="gallery-participant">Pengalaman Peserta</h2>
        <ParticipantGallery />
      </section>

      <section aria-labelledby="gallery-coach">
        <h2 id="gallery-coach">Pengalaman Coach</h2>
        <CoachGallery />
      </section>

      <section aria-labelledby="gallery-admin">
        <h2 id="gallery-admin">Pengalaman Admin</h2>
        <AdminGallery />
      </section>

      <section aria-labelledby="gallery-marketing-capture">
        <h2 id="gallery-marketing-capture">Capture marketing release candidate</h2>
        <MarketingCaptureGallery />
      </section>

      <section aria-labelledby="gallery-shells">
        <h2 id="gallery-shells">Shell responsif</h2>
        <div className="state-gallery__grid">
          {(
            [
              ["participant", "Peserta", copy.shell.participantLabel],
              ["coach", "Coach", copy.shell.coachLabel],
              ["admin", "Admin", copy.shell.adminLabel],
            ] as const satisfies readonly (readonly [ShellKind, string, string])[]
          ).map(([kind, title, navigationLabel]) => (
            <Surface className={`state-gallery__shell-preview app-shell--${kind}`} key={kind}>
              <strong>{title}</strong>
              <ShellNavigation
                items={navigationByKind[kind]}
                kind={kind}
                label={`${navigationLabel} pratinjau`}
              />
            </Surface>
          ))}
        </div>
      </section>

      <section aria-labelledby="gallery-dark" data-color-scheme="dark">
        <Surface className="state-gallery__stack" elevated>
          <h2 id="gallery-dark">Mode gelap</h2>
          <p>Token semantik tetap menjaga hierarchy dan kontras.</p>
          <StatusBadge tone="warning">Perlu perhatian</StatusBadge>
        </Surface>
      </section>

      <section aria-labelledby="gallery-large" className="state-gallery__large-text">
        <Surface>
          <h2 id="gallery-large">Teks besar dan kurangi gerakan</h2>
          <p>Teks membungkus tanpa diperkecil atau dipotong.</p>
        </Surface>
      </section>

      <FilterSummary
        onClick={() => setDialogOpen(true)}
        summary="Semua program · Hari ini"
        title="Filter aktivitas"
      />
      <ModalDialog
        description="Contoh bottom sheet dengan history browser."
        isOpen={isDialogOpen}
        onClose={closeDialog}
        title="Atur filter"
        variant="sheet"
      >
        <FilterForm>
          <SelectField id="gallery-filter-program" label="Program">
            <option>Semua program</option>
          </SelectField>
          <FilterActions onApply={closeDialog} onReset={() => setToast("Filter diatur ulang.")} />
        </FilterForm>
      </ModalDialog>
      <ToastLiveRegion message={toast} />
      <QrScannerDialog
        isOpen={isQrOpen}
        onClose={() => setQrOpen(false)}
        onScan={() => setMediaStatus("QR Coach canonical diterima tanpa menampilkan identifier.")}
      />
    </main>
  );
}
