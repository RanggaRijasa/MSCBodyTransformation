import { NextResponse } from "next/server";

import { uploadManagedWinnerPoster } from "@/application/admin/poster-operations";
import { loadVerifiedProfile } from "@/features/auth/server/profile-repository";

export async function POST(request: Request) {
  const profile = await loadVerifiedProfile();
  if (!profile.isSuccess)
    return NextResponse.json({ message: "Sesi perlu diperbarui." }, { status: 401 });
  if (profile.value.role !== "admin")
    return NextResponse.json({ message: "Akses ditolak." }, { status: 403 });
  const form = await request.formData();
  const image = form.get("image");
  const operation = form.get("operation");
  const alternativeText = form.get("alternativeText");
  const reason = form.get("reason");
  const snapshotId = form.get("snapshotId");
  const requestedPosterId = form.get("posterId");
  if (
    !(image instanceof File) ||
    (operation !== "add" && operation !== "replace") ||
    typeof alternativeText !== "string" ||
    alternativeText.trim().length < 5 ||
    typeof reason !== "string" ||
    reason.trim().length < 5
  ) {
    return NextResponse.json(
      { message: "Lengkapi poster, teks alternatif, dan alasan." },
      { status: 422 },
    );
  }
  const result = await uploadManagedWinnerPoster({
    alternativeText: alternativeText.trim(),
    bytes: new Uint8Array(await image.arrayBuffer()),
    declaredMimeType: image.type,
    operation,
    posterId: typeof requestedPosterId === "string" ? requestedPosterId : null,
    reason: reason.trim(),
    snapshotId: typeof snapshotId === "string" ? snapshotId : null,
  });
  if (!result.isSuccess) {
    const status =
      result.error.code === "validation_failed"
        ? 422
        : result.error.code === "forbidden"
          ? 403
          : result.error.code === "conflict"
            ? 409
            : 503;
    return NextResponse.json(
      { message: result.error.message },
      { status, headers: { "Cache-Control": "private, no-store" } },
    );
  }
  return NextResponse.json(result.value, { headers: { "Cache-Control": "private, no-store" } });
}
