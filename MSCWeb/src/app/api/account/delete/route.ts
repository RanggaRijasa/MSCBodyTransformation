import { NextResponse } from "next/server";

import { deleteAccountOperation } from "@/application/auth/server-auth-operations";

export async function POST() {
  const result = await deleteAccountOperation();
  if (!result.success) {
    const code = result.code ?? "account_deletion_failed";
    return NextResponse.json(
      { code },
      {
        status:
          code === "authentication_required" || code === "recent_reauthentication_required"
            ? 401
            : 409,
      },
    );
  }
  return new NextResponse(null, {
    status: 204,
    headers: { "Cache-Control": "no-store", "Clear-Site-Data": '"cache", "storage"' },
  });
}
