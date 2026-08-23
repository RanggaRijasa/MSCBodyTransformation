import {
  fetchWithTimeout,
  readLimitedJSON,
} from "../_shared/http_safety.ts";
import {
  isAuthorizedServiceRequest,
  loadSupabaseRuntimeKeys,
  serviceRequestHeaders,
} from "../_shared/supabase_keys.ts";

type OrphanObject = {
  object_name: string;
};

type CleanupTarget = {
  bucket: "question-photos" | "question-videos";
  listRPC: "list_orphan_question_photos" | "list_orphan_question_videos";
  auditRPC:
    | "record_orphan_question_photo_cleanup"
    | "record_orphan_question_video_cleanup";
};

const cleanupTargets: CleanupTarget[] = [
  {
    bucket: "question-photos",
    listRPC: "list_orphan_question_photos",
    auditRPC: "record_orphan_question_photo_cleanup",
  },
  {
    bucket: "question-videos",
    listRPC: "list_orphan_question_videos",
    auditRPC: "record_orphan_question_video_cleanup",
  },
];

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
  const response = await fetchWithTimeout(input, init);
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
    let keys: ReturnType<typeof loadSupabaseRuntimeKeys>;
    try {
      keys = loadSupabaseRuntimeKeys();
    } catch {
      return jsonResponse(500, { code: "server_configuration_missing" });
    }
    const authorization = request.headers.get("Authorization");
    const isServiceRequest = isAuthorizedServiceRequest(
      request,
      keys.secretKey,
    );
    if (!projectURL) {
      return jsonResponse(500, { code: "server_configuration_missing" });
    }
    if (!isServiceRequest && !authorization?.startsWith("Bearer ")) {
      return jsonResponse(401, { code: "authentication_required" });
    }

    const userHeaders = {
      "apikey": keys.publishableKey,
      "Authorization": authorization ?? "",
      "Content-Type": "application/json",
    };
    const serviceHeaders = {
      ...serviceRequestHeaders(keys.secretKey),
      "Content-Type": "application/json",
    };
    const operationHeaders = isServiceRequest ? serviceHeaders : userHeaders;

    try {
      if (!isServiceRequest) {
        await checkedFetch(
          new URL("/auth/v1/user", projectURL),
          { method: "GET", headers: userHeaders },
          "authentication_required",
        );
      }
      const body = await readLimitedJSON(request, 8_192) as {
        older_than_hours?: number;
        reason?: string;
      };
      const olderThanHours = body.older_than_hours ?? 24;
      const reason = body.reason?.trim() ??
        "Pembersihan media pertanyaan yatim.";
      if (!Number.isInteger(olderThanHours) || olderThanHours < 1 || !reason) {
        throw new Error("cleanup_request_invalid");
      }
      let deletedCount = 0;
      for (const target of cleanupTargets) {
        const listResponse = await checkedFetch(
          new URL(`/rest/v1/rpc/${target.listRPC}`, projectURL),
          {
            method: "POST",
            headers: operationHeaders,
            body: JSON.stringify({ older_than: `${olderThanHours} hours` }),
          },
          "orphan_list_failed",
        );
        const candidates = await listResponse.json() as OrphanObject[];
        const names = candidates.map((candidate) => candidate.object_name);
        if (names.length === 0) continue;

        await checkedFetch(
          new URL(`/storage/v1/object/${target.bucket}`, projectURL),
          {
            method: "DELETE",
            headers: serviceHeaders,
            body: JSON.stringify({ prefixes: names }),
          },
          "orphan_storage_delete_failed",
        );

        await checkedFetch(
          new URL(`/rest/v1/rpc/${target.auditRPC}`, projectURL),
          {
            method: "POST",
            headers: operationHeaders,
            body: JSON.stringify({
              deleted_object_names: names,
              cleanup_reason: reason,
            }),
          },
          "orphan_audit_failed",
        );
        deletedCount += names.length;
      }

      return jsonResponse(200, { deleted_count: deletedCount });
    } catch (error) {
      const code = error instanceof Error
        ? error.message
        : "orphan_cleanup_failed";
      const status = code === "authentication_required"
        ? 401
        : code === "permission_denied"
        ? 403
        : code === "cleanup_request_invalid" || code === "request_invalid"
        ? 422
        : 409;
      return jsonResponse(status, { code });
    }
  },
};
