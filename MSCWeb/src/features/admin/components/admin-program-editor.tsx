"use client";

import { useMemo, useState } from "react";

import { saveProgramDraftAction } from "@/application/admin/admin-mutations";
import type { AdminProgramDraft } from "@/domain/admin/admin-program";
import { copyDayContent, validateProgramDraft } from "@/domain/admin/admin-program";
import { ProgramContentEditor } from "@/features/admin/components/program-content-editor";
import { ProgramSettingsEditor } from "@/features/admin/components/program-settings-editor";
import { AppButton, FormErrorSummary, Surface } from "@/shared/ui";

export function AdminProgramEditor({
  initialDraft,
}: Readonly<{ initialDraft: AdminProgramDraft }>) {
  const [draft, setDraft] = useState(initialDraft);
  const [tab, setTab] = useState<"content" | "settings">("settings");
  const [sourceDayId, setSourceDayId] = useState(initialDraft.days[0]?.id ?? "");
  const issues = useMemo(() => validateProgramDraft(draft), [draft]);
  const makeId = () => crypto.randomUUID();
  const copyToOtherDays = () => {
    const source = draft.days.find((day) => day.id === sourceDayId);
    if (!source || !window.confirm("Konten target akan ditimpa dengan ID baru. Lanjutkan?")) return;
    const targets = draft.days.filter((day) => day.id !== source.id);
    const copied = copyDayContent(source, targets, makeId);
    setDraft({
      ...draft,
      days: draft.days.map((day) => copied.find((item) => item.id === day.id) ?? day),
    });
  };
  return (
    <div className="admin-page admin-editor">
      <header className="admin-page__header">
        <p className="admin-eyebrow">Editor draft</p>
        <h1>{draft.title}</h1>
        <p>
          Pengaturan dan konten disimpan sebagai satu kontrak typed yang divalidasi kembali oleh
          server.
        </p>
      </header>
      <div className="admin-segmented" role="tablist" aria-label="Bagian editor">
        <button
          aria-selected={tab === "settings"}
          onClick={() => setTab("settings")}
          role="tab"
          type="button"
        >
          Pengaturan
        </button>
        <button
          aria-selected={tab === "content"}
          onClick={() => setTab("content")}
          role="tab"
          type="button"
        >
          Hari dan konten
        </button>
      </div>
      {tab === "settings" ? (
        <Surface>
          <ProgramSettingsEditor draft={draft} onChange={setDraft} />
        </Surface>
      ) : (
        <>
          <Surface className="admin-copy-day">
            <label>
              Salin dari hari
              <select onChange={(event) => setSourceDayId(event.target.value)} value={sourceDayId}>
                {draft.days.map((day) => (
                  <option key={day.id} value={day.id}>
                    Hari {day.dayNumber}
                  </option>
                ))}
              </select>
            </label>
            <AppButton
              disabled={draft.days.length < 2}
              onClick={copyToOtherDays}
              variant="secondary"
            >
              Salin ke semua hari lain
            </AppButton>
          </Surface>
          <ProgramContentEditor draft={draft} makeId={makeId} onChange={setDraft} />
        </>
      )}
      {issues.length ? (
        <FormErrorSummary title="Periksa draft sebelum menyimpan">
          <ul>
            {issues.map((issue) => (
              <li key={`${issue.field}-${issue.message}`}>{issue.message}</li>
            ))}
          </ul>
        </FormErrorSummary>
      ) : null}
      <form action={saveProgramDraftAction} className="admin-editor-save">
        <input name="draft" type="hidden" value={JSON.stringify(draft)} />
        <AppButton disabled={issues.length > 0} type="submit">
          Simpan draft
        </AppButton>
      </form>
    </div>
  );
}
