import type { AdminProgramDraft } from "@/domain/admin/admin-program";
import { SelectField, TextareaField, TextField } from "@/shared/ui/forms/form-controls";

export function ProgramSettingsEditor({
  draft,
  onChange,
}: Readonly<{ draft: AdminProgramDraft; onChange: (draft: AdminProgramDraft) => void }>) {
  const update = <Key extends keyof AdminProgramDraft>(key: Key, value: AdminProgramDraft[Key]) =>
    onChange({ ...draft, [key]: value });
  return (
    <div className="admin-editor-grid">
      <TextField
        id="program-title"
        label="Judul"
        onChange={(event) => update("title", event.target.value)}
        required
        value={draft.title}
      />
      <TextField
        id="program-category"
        label="Kategori"
        onChange={(event) => update("category", event.target.value || null)}
        value={draft.category ?? ""}
      />
      <TextareaField
        id="program-summary"
        label="Ringkasan"
        onChange={(event) => update("summary", event.target.value)}
        value={draft.summary}
      />
      <TextField
        id="program-cover-path"
        label="Path sampul"
        onChange={(event) => update("coverPath", event.target.value || null)}
        value={draft.coverPath ?? ""}
      />
      <TextField
        id="program-cover-alt"
        label="Teks alternatif sampul"
        onChange={(event) => update("coverAlternativeText", event.target.value || null)}
        value={draft.coverAlternativeText ?? ""}
      />
      <TextField
        id="program-start"
        label="Tanggal mulai"
        onChange={(event) => update("startsOn", event.target.value)}
        type="date"
        value={draft.startsOn}
      />
      <TextField
        id="program-end"
        label="Tanggal selesai"
        onChange={(event) => update("endsOn", event.target.value)}
        type="date"
        value={draft.endsOn}
      />
      <SelectField
        id="program-timezone"
        label="Zona waktu"
        onChange={(event) => update("timezone", event.target.value)}
        value={draft.timezone}
      >
        <option value="Asia/Jakarta">WIB</option>
        <option value="Asia/Makassar">WITA</option>
        <option value="Asia/Jayapura">WIT</option>
      </SelectField>
      <TextField
        id="program-capacity"
        label="Kapasitas"
        min="1"
        onChange={(event) =>
          update("participantLimit", event.target.value ? Number(event.target.value) : null)
        }
        type="number"
        value={draft.participantLimit ?? ""}
      />
      <TextField
        id="program-cutoff"
        label="Batas pendaftaran"
        onChange={(event) =>
          update(
            "registrationClosesAt",
            event.target.value ? new Date(event.target.value).toISOString() : null,
          )
        }
        type="datetime-local"
        value={draft.registrationClosesAt?.slice(0, 16) ?? ""}
      />
      <SelectField
        id="program-past-policy"
        label="Hari lampau"
        onChange={(event) =>
          update("pastStepPolicy", event.target.value as AdminProgramDraft["pastStepPolicy"])
        }
        value={draft.pastStepPolicy}
      >
        <option value="available">Tersedia</option>
        <option value="read_only">Hanya baca</option>
        <option value="hidden">Disembunyikan</option>
        <option value="locked">Dikunci</option>
      </SelectField>
      <SelectField
        id="program-future-policy"
        label="Hari mendatang"
        onChange={(event) =>
          update("futureStepPolicy", event.target.value as AdminProgramDraft["futureStepPolicy"])
        }
        value={draft.futureStepPolicy}
      >
        <option value="locked">Dikunci</option>
        <option value="hidden">Disembunyikan</option>
        <option value="available">Tersedia</option>
        <option value="read_only">Hanya baca</option>
      </SelectField>
      <TextField
        id="program-activity-points"
        label="Poin per aktivitas"
        min="0"
        onChange={(event) => update("pointsPerActivity", Number(event.target.value))}
        type="number"
        value={draft.pointsPerActivity}
      />
      <TextField
        id="program-weight-points"
        label="Poin per kilogram"
        min="0"
        onChange={(event) => update("pointsPerWeightKilogram", event.target.value)}
        step="0.01"
        type="number"
        value={draft.pointsPerWeightKilogram}
      />
      <TextField
        id="program-quiz-threshold"
        label="Ambang lulus kuis (%)"
        max="100"
        min="0"
        onChange={(event) => update("quizPassingPercentage", Number(event.target.value))}
        type="number"
        value={draft.quizPassingPercentage}
      />
      <SelectField
        id="program-pricing"
        label="Akses"
        onChange={(event) =>
          update("pricingMode", event.target.value as AdminProgramDraft["pricingMode"])
        }
        value={draft.pricingMode}
      >
        <option value="free">Gratis</option>
        <option value="paid">Berbayar</option>
      </SelectField>
      {draft.pricingMode === "paid" ? (
        <TextField
          id="program-price"
          label="Harga (IDR)"
          min="1"
          onChange={(event) => update("desiredPrice", event.target.value)}
          type="number"
          value={draft.desiredPrice ?? ""}
        />
      ) : null}
      <TextareaField
        id="program-disclaimer"
        label="Pernyataan wellness"
        onChange={(event) => update("wellnessDisclaimer", event.target.value)}
        value={draft.wellnessDisclaimer}
      />
    </div>
  );
}
