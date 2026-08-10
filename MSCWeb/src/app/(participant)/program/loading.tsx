import { Skeleton } from "@/shared/ui";

export default function ProgramLoading() {
  return (
    <div className="program-page" role="status">
      <h1>Memuat program…</h1>
      <Skeleton label="Memuat katalog program" />
      <Skeleton label="Memuat program lain" />
    </div>
  );
}
