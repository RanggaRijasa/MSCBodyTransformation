import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import type { AdminProgramListItem } from "@/domain/admin/admin-program";
import { AdminDashboard } from "@/features/admin/components/admin-dashboard";
import { AdminProgramList } from "@/features/admin/components/admin-program-list";

function program(index: number): AdminProgramListItem {
  return {
    desiredPrice: index % 2 ? "250000" : null,
    endsOn: "2026-08-31",
    enrollmentCount: index,
    id: `program-${index}`,
    participantLimit: 50,
    pricingMode: index % 2 ? "paid" : "free",
    startsOn: "2026-08-01",
    status: index % 3 ? "active" : "draft",
    title: `Program ${index}`,
  };
}

describe("pengalaman Admin", () => {
  it("menampilkan action counts dan quick actions yang berbeda", () => {
    render(
      <AdminDashboard
        snapshot={{
          activePrograms: 2,
          closureBlockers: 1,
          coachApplications: 3,
          paymentReviews: 4,
          recentAudit: [],
          systemAttention: 5,
        }}
      />,
    );
    expect(screen.getByText("Pembayaran")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Buat program" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Tambah poster" })).toBeInTheDocument();
  });

  it("memiliki empty state dan pagination bounded untuk data besar", () => {
    const { rerender } = render(<AdminProgramList items={[]} query="" status="" />);
    expect(screen.getByRole("heading", { name: "Tidak ada program" })).toBeInTheDocument();
    rerender(
      <AdminProgramList
        items={Array.from({ length: 25 }, (_, index) => program(index + 1))}
        page={2}
        query=""
        status=""
      />,
    );
    expect(screen.getByText("Halaman 2")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Halaman sebelumnya" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Halaman berikutnya" })).toBeInTheDocument();
    expect(screen.getAllByRole("link", { name: "Buka program" })).toHaveLength(12);
  });

  it("menerapkan search dan status tanpa merender data di luar hasil", () => {
    render(
      <AdminProgramList
        items={[program(1), { ...program(2), status: "completed", title: "Program Selesai" }]}
        query="Selesai"
        status="completed"
      />,
    );
    expect(screen.getByRole("heading", { name: "Program Selesai" })).toBeInTheDocument();
    expect(screen.queryByRole("heading", { name: "Program 1" })).not.toBeInTheDocument();
  });
});
