"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";

import {
  memberLevelLabels,
  memberLevels,
  validateOnboardingDraft,
  type AccountPurpose,
  type MemberLevel,
} from "@/features/auth/model/auth-model";
import { QrScannerDialog } from "@/features/device-media";
import type { OpaqueCoachQrPayload } from "@/domain/media/qr-payload";
import { AppButton } from "@/shared/ui/controls/actions";
import { ChoiceField, SelectField, TextField } from "@/shared/ui/forms/form-controls";

type SubmissionState = "idle" | "submitting" | "success" | "error";

export function OnboardingForm({ initialName = "" }: Readonly<{ initialName?: string }>) {
  const router = useRouter();
  const [displayName, setDisplayName] = useState(initialName);
  const [phoneNumber, setPhoneNumber] = useState("");
  const [memberLevel, setMemberLevel] = useState<MemberLevel>("member");
  const [accountPurpose, setAccountPurpose] = useState<AccountPurpose>("participant");
  const [hasCompletedHomSts, setHasCompletedHomSts] = useState(false);
  const [hasCompletedIct, setHasCompletedIct] = useState(false);
  const [state, setState] = useState<SubmissionState>("idle");
  const [message, setMessage] = useState<string | null>(null);
  const [coachQrPayload, setCoachQrPayload] = useState<OpaqueCoachQrPayload | null>(null);
  const [isScannerOpen, setScannerOpen] = useState(false);

  const draft = {
    accountPurpose,
    displayName,
    hasCompletedHomSts,
    hasCompletedIct,
    memberLevel,
    phoneNumber,
  } as const;
  const errors = validateOnboardingDraft(draft);
  const needsQr = accountPurpose === "participant" && coachQrPayload === null;

  async function submit() {
    if (errors.length > 0 || needsQr) {
      setMessage(
        needsQr
          ? "Pindai QR Coach untuk menyelesaikan pendaftaran Peserta."
          : (errors[0] ?? "Periksa data profil."),
      );
      setState("error");
      return;
    }
    setState("submitting");
    setMessage(null);
    try {
      const response = await fetch("/api/onboarding", {
        body: JSON.stringify({ ...draft, coachQrPayload }),
        headers: { "Content-Type": "application/json" },
        method: "POST",
      });
      const payload = (await response.json()) as { destination?: string; code?: string };
      if (!response.ok || !payload.destination) {
        throw new Error(payload.code ?? "onboarding_failed");
      }
      setState("success");
      router.replace(payload.destination);
      router.refresh();
    } catch {
      setState("error");
      setMessage("Profil belum dapat disimpan. Periksa koneksi lalu coba lagi.");
    }
  }

  async function cancel() {
    setCoachQrPayload(null);
    setState("submitting");
    setMessage(null);
    try {
      const response = await fetch("/api/onboarding", { method: "DELETE" });
      if (!response.ok) throw new Error("cleanup_failed");
      router.replace("/masuk");
      router.refresh();
    } catch {
      setState("error");
      setMessage("Pendaftaran belum dapat dibatalkan. Coba lagi saat koneksi stabil.");
    }
  }

  return (
    <form
      className="onboarding-form"
      onSubmit={(event) => {
        event.preventDefault();
        void submit();
      }}
    >
      <section className="onboarding-section">
        <h2>Profil dasar</h2>
        <TextField
          autoComplete="name"
          id="display-name"
          label="Nama lengkap"
          maxLength={80}
          onChange={(event) => setDisplayName(event.target.value)}
          required
          value={displayName}
        />
        <TextField
          autoComplete="tel"
          id="phone-number"
          inputMode="tel"
          label="Nomor HP"
          onChange={(event) => setPhoneNumber(event.target.value)}
          placeholder="Contoh: +628123456789"
          required
          value={phoneNumber}
        />
        <SelectField
          id="member-level"
          label="Level member"
          onChange={(event) => setMemberLevel(event.target.value as MemberLevel)}
          value={memberLevel}
        >
          {memberLevels.map((level) => (
            <option key={level} value={level}>
              {memberLevelLabels[level]}
            </option>
          ))}
        </SelectField>
      </section>

      <fieldset className="onboarding-section">
        <legend>
          <h2>Tujuan akun</h2>
        </legend>
        <div className="choice-grid">
          <ChoiceField
            checked={accountPurpose === "participant"}
            description="Ikuti program dengan arahan Coach."
            id="purpose-participant"
            label="Menjadi Peserta"
            name="purpose"
            onChange={() => setAccountPurpose("participant")}
            type="radio"
          />
          <ChoiceField
            checked={accountPurpose === "coach_applicant"}
            description="Ajukan akses Coach setelah syarat dipenuhi."
            id="purpose-coach"
            label="Ajukan Coach"
            name="purpose"
            onChange={() => setAccountPurpose("coach_applicant")}
            type="radio"
          />
        </div>
      </fieldset>

      {accountPurpose === "coach_applicant" ? (
        <fieldset className="onboarding-section">
          <legend>
            <h2>Konfirmasi kelayakan Coach</h2>
          </legend>
          {memberLevel === "member" ? (
            <p className="onboarding-status">
              Level Member belum dapat mengajukan Coach. Pilih level SC atau lebih tinggi jika
              sesuai.
            </p>
          ) : null}
          <ChoiceField
            checked={hasCompletedHomSts}
            label="Saya telah menyelesaikan HOM STS"
            onChange={(event) => setHasCompletedHomSts(event.target.checked)}
            id="hom-sts"
            type="checkbox"
          />
          <ChoiceField
            checked={hasCompletedIct}
            label="Saya telah menyelesaikan ICT"
            onChange={(event) => setHasCompletedIct(event.target.checked)}
            id="ict"
            type="checkbox"
          />
        </fieldset>
      ) : (
        <section className="onboarding-section" aria-labelledby="coach-qr-title">
          <h2 id="coach-qr-title">Hubungkan Coach</h2>
          <p className="onboarding-status">
            {coachQrPayload
              ? "QR Coach siap divalidasi saat profil disimpan."
              : "Pendaftaran Peserta memerlukan pemindaian QR Coach. Tidak ada kolom kode manual."}
          </p>
          <AppButton onClick={() => setScannerOpen(true)} variant="secondary">
            {coachQrPayload ? "Pindai ulang QR Coach" : "Pindai QR Coach"}
          </AppButton>
          <QrScannerDialog
            isOpen={isScannerOpen}
            onClose={() => setScannerOpen(false)}
            onScan={(payload) => {
              setCoachQrPayload(payload);
              setMessage(null);
              setState("idle");
            }}
          />
        </section>
      )}

      {message ? (
        <p className="form-error-summary" role="alert">
          {message}
        </p>
      ) : null}
      <div className="onboarding-actions">
        <AppButton
          disabled={errors.length > 0 || needsQr}
          isLoading={state === "submitting"}
          type="submit"
        >
          Simpan dan lanjutkan
        </AppButton>
        <AppButton
          disabled={state === "submitting"}
          onClick={() => void cancel()}
          variant="secondary"
        >
          Batalkan pendaftaran
        </AppButton>
      </div>
    </form>
  );
}
