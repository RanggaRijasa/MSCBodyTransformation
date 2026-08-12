"use client";

import { useMemo, useRef, useState, type KeyboardEvent } from "react";

import { saveProgramDraftAction } from "@/application/admin/admin-mutations";
import type { AdminProgramDraft } from "@/domain/admin/admin-program";
import { copyDayContent, validateProgramDraft } from "@/domain/admin/admin-program";
import { ProgramContentEditor } from "@/features/admin/components/program-content-editor";
import { ProgramSettingsEditor } from "@/features/admin/components/program-settings-editor";
import { AppButton } from "@/shared/ui/controls/actions";
import { FormErrorSummary } from "@/shared/ui/forms/form-controls";
import { Surface } from "@/shared/ui/surfaces/surfaces";

export function AdminProgramEditor({
  initialDraft,
}: Readonly<{ initialDraft: AdminProgramDraft }>) {
  const [draft, setDraft] = useState(initialDraft);
  const [tab, setTab] = useState<"content" | "settings">("settings");
  const [sourceDayId, setSourceDayId] = useState(initialDraft.days[0]?.id ?? "");
  const settingsTab = useRef<HTMLButtonElement>(null);
  const contentTab = useRef<HTMLButtonElement>(null);
  const issues = useMemo(() => validateProgramDraft(draft), [draft]);
  const makeId = () => crypto.randomUUID();
  const selectTab = (nextTab: "content" | "settings") => {
    setTab(nextTab);
    (nextTab === "settings" ? settingsTab : contentTab).current?.focus();
  };
  const handleTabKey = (event: KeyboardEvent<HTMLButtonElement>) => {
    if (!["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) return;
    event.preventDefault();
    if (event.key === "Home" || event.key === "ArrowLeft") selectTab("settings");
    else selectTab("content");
  };
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
          aria-controls="admin-editor-settings-panel"
          aria-selected={tab === "settings"}
          id="admin-editor-settings-tab"
          onKeyDown={handleTabKey}
          onClick={() => setTab("settings")}
          ref={settingsTab}
          role="tab"
          tabIndex={tab === "settings" ? 0 : -1}
          type="button"
        >
          Pengaturan
        </button>
        <button
          aria-controls="admin-editor-content-panel"
          aria-selected={tab === "content"}
          id="admin-editor-content-tab"
          onKeyDown={handleTabKey}
          onClick={() => setTab("content")}
          ref={contentTab}
          role="tab"
          tabIndex={tab === "content" ? 0 : -1}
          type="button"
        >
          Hari dan konten
        </button>
      </div>
      {tab === "settings" ? (
        <div
          aria-labelledby="admin-editor-settings-tab"
          className="admin-editor-panel"
          id="admin-editor-settings-panel"
          role="tabpanel"
        >
          <Surface>
            <ProgramSettingsEditor draft={draft} onChange={setDraft} />
          </Surface>
        </div>
      ) : (
        <div
          aria-labelledby="admin-editor-content-tab"
          className="admin-editor-panel admin-editor-panel--content"
          id="admin-editor-content-panel"
          role="tabpanel"
        >
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
        </div>
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
