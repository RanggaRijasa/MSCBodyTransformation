"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";

import type { CoachContext } from "@/domain/coach/coach-experience";
import { AppButton, TextareaField, TextField } from "@/shared/ui";

export function CoachPublicProfileForm({ context }: Readonly<{ context: CoachContext }>) {
  const router = useRouter();
  const [biography, setBiography] = useState(context.biography);
  const [city, setCity] = useState(context.city);
  const [isPublic, setPublic] = useState(context.isPublic);
  const [isBusy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  async function save() {
    setBusy(true);
    setMessage(null);
    try {
      const response = await fetch("/api/coach/profile", {
        body: JSON.stringify({ biography, city, displayName: context.displayName, isPublic }),
        headers: { "Content-Type": "application/json" },
        method: "PATCH",
      });
      if (!response.ok) throw new Error("profile_failed");
      setMessage("Profil publik Coach berhasil diperbarui.");
      router.refresh();
    } catch {
      setMessage("Profil Coach belum dapat diperbarui. Periksa data dan koneksi.");
    } finally {
      setBusy(false);
    }
  }
  return (
    <section
      aria-labelledby="coach-public-profile-title"
      className="app-surface profile-lifecycle__section"
    >
      <h2 id="coach-public-profile-title">Profil publik Coach</h2>
      <TextareaField
        id="coach-biography"
        label="Bio publik"
        maxLength={500}
        onChange={(event) => setBiography(event.target.value)}
        value={biography}
      />
      <TextField
        id="coach-city"
        label="Kota"
        maxLength={80}
        onChange={(event) => setCity(event.target.value)}
        value={city}
      />
      <label className="app-checkbox">
        <input
          checked={isPublic}
          onChange={(event) => setPublic(event.target.checked)}
          type="checkbox"
        />
        <span>Tampilkan profil pada direktori Coach publik</span>
      </label>
      <AppButton disabled={isBusy} onClick={() => void save()}>
        Simpan profil publik
      </AppButton>
      {message ? <p role="status">{message}</p> : null}
    </section>
  );
}
