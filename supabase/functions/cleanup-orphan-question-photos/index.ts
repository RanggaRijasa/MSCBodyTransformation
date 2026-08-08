type OrphanObject = {
  object_name: string;
};

const jsonHeaders = {
  "Content-Type": "application/json",
  "Cache-Control": "no-store",
};

function jsonResponse(status: number, payload: Record<string, unknown>): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: jsonHeaders,
  });
}

async function checkedFetch(
  input: URL | string,
  init: RequestInit,
  failureCode: string,
): Promise<Response> {
  const response = await fetch(input, init);
  if (!response.ok) {
    const payload = await response.clone().json().catch(() => null) as {
      message?: string;
    } | null;
    throw new Error(payload?.message ?? failureCode);
  }
  return response;
}

export default {
  async fetch(request: Request): Promise<Response> {
    if (request.method !== "POST") {
      return jsonResponse(405, { code: "method_not_allowed" });
    }

    const projectURL = Deno.env.get("SUPABASE_URL");
    const publishableKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const authorization = request.headers.get("Authorization");
    if (!projectURL || !publishableKey || !serviceRoleKey) {
      return jsonResponse(500, { code: "server_configuration_missing" });
    }
    if (!authorization?.startsWith("Bearer ")) {
      return jsonResponse(401, { code: "authentication_required" });
    }

    const body = await request.json().catch(() => ({})) as {
      older_than_hours?: number;
      reason?: string;
    };
    const olderThanHours = body.older_than_hours ?? 24;
    const reason = body.reason?.trim() ?? "Pembersihan media pertanyaan yatim.";
    if (!Number.isInteger(olderThanHours) || olderThanHours < 1 || !reason) {
      return jsonResponse(422, { code: "cleanup_request_invalid" });
    }

    const userHeaders = {
      "apikey": publishableKey,
      "Authorization": authorization,
      "Content-Type": "application/json",
    };
    const serviceHeaders = {
      "apikey": serviceRoleKey,
      "Authorization": `Bearer ${serviceRoleKey}`,
      "Content-Type": "application/json",
    };

    try {
      const listResponse = await checkedFetch(
        new URL("/rest/v1/rpc/list_orphan_question_photos", projectURL),
        {
          method: "POST",
          headers: userHeaders,
          body: JSON.stringify({ older_than: `${olderThanHours} hours` }),
        },
        "orphan_list_failed",
      );
      const candidates = await listResponse.json() as OrphanObject[];
      const names = candidates.map((candidate) => candidate.object_name);
      if (names.length === 0) {
        return jsonResponse(200, { deleted_count: 0 });
      }

      await checkedFetch(
        new URL("/storage/v1/object/question-photos", projectURL),
        {
          method: "DELETE",
          headers: serviceHeaders,
          body: JSON.stringify({ prefixes: names }),
        },
        "orphan_storage_delete_failed",
      );

      await checkedFetch(
        new URL(
          "/rest/v1/rpc/record_orphan_question_photo_cleanup",
          projectURL,
        ),
        {
          method: "POST",
          headers: userHeaders,
          body: JSON.stringify({
            deleted_object_names: names,
            cleanup_reason: reason,
          }),
        },
        "orphan_audit_failed",
      );

      return jsonResponse(200, { deleted_count: names.length });
    } catch (error) {
      const code = error instanceof Error
        ? error.message
        : "orphan_cleanup_failed";
      const status = code === "permission_denied" ? 403 : 409;
      return jsonResponse(status, { code });
    }
  },
};
