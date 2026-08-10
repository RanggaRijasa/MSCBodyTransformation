import { copy } from "@/shared/i18n/id";

export default function Loading() {
  return (
    <main className="state-page" aria-busy="true" aria-live="polite">
      <p>{copy.common.loading}</p>
    </main>
  );
}
