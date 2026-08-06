type MediaObject = {
  bucket_id: string;
  name: string;
};

const jsonHeaders = {
  "Content-Type": "application/json",
  "Cache-Control": "no-store",
};

function jsonResponse(status: number, code: string): Response {
  return new Response(JSON.stringify({ code }), {
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
    const allowedCodes = new Set([
      "recent_reauthentication_required",
      "admin_account_deletion_not_allowed",
      "account_relationships_require_transfer",
      "private_media_cleanup_required",
    ]);
    const payload = await response.clone().json().catch(() => null) as {
      message?: string;
    } | null;
    const code = payload?.message && allowedCodes.has(payload.message)
      ? payload.message
      : failureCode;
    throw new Error(code);
  }
  return response;
}

function chunks<Value>(values: Value[], size: number): Value[][] {
  const result: Value[][] = [];
  for (let index = 0; index < values.length; index += size) {
    result.push(values.slice(index, index + size));
  }
  return result;
}

export default {
  async fetch(request: Request): Promise<Response> {
    if (request.method !== "POST") {
      return jsonResponse(405, "method_not_allowed");
    }

    const projectURL = Deno.env.get("SUPABASE_URL");
    const publishableKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const authorization = request.headers.get("Authorization");

    if (!projectURL || !publishableKey || !serviceRoleKey) {
      return jsonResponse(500, "server_configuration_missing");
    }
    if (!authorization?.startsWith("Bearer ")) {
      return jsonResponse(401, "authentication_required");
    }

    const userHeaders = {
      "apikey": publishableKey,
      "Authorization": authorization,
      "Content-Type": "application/json",
    };
    const adminHeaders = {
      "apikey": serviceRoleKey,
      "Authorization": `Bearer ${serviceRoleKey}`,
      "Content-Type": "application/json",
    };

    try {
      const userResponse = await checkedFetch(
        new URL("/auth/v1/user", projectURL),
        { method: "GET", headers: userHeaders },
        "authentication_required",
      );
      const user = await userResponse.json() as { id?: string };
      if (!user.id) {
        return jsonResponse(401, "authentication_required");
      }

      const manifestResponse = await checkedFetch(
        new URL(
          "/rest/v1/rpc/prepare_my_account_deletion",
          projectURL,
        ),
        {
          method: "POST",
          headers: userHeaders,
          body: "{}",
        },
        "account_deletion_preflight_failed",
      );
      const manifest = await manifestResponse.json() as MediaObject[];
      const objectsByBucket = new Map<string, string[]>();
      for (const object of manifest) {
        if (!object.bucket_id || !object.name) {
          throw new Error("account_deletion_preflight_failed");
        }
        const paths = objectsByBucket.get(object.bucket_id) ?? [];
        paths.push(object.name);
        objectsByBucket.set(object.bucket_id, paths);
      }

      for (const [bucketID, paths] of objectsByBucket) {
        for (const pathChunk of chunks(paths, 1_000)) {
          await checkedFetch(
            new URL(
              `/storage/v1/object/${encodeURIComponent(bucketID)}`,
              projectURL,
            ),
            {
              method: "DELETE",
              headers: adminHeaders,
              body: JSON.stringify({ prefixes: pathChunk }),
            },
            "private_media_cleanup_failed",
          );
        }
      }

      const finalizeResponse = await checkedFetch(
        new URL(
          "/rest/v1/rpc/finalize_my_account_deletion",
          projectURL,
        ),
        {
          method: "POST",
          headers: userHeaders,
          body: "{}",
        },
        "account_deletion_finalize_failed",
      );
      const finalizedUserID = await finalizeResponse.json() as string;
      if (finalizedUserID !== user.id) {
        throw new Error("account_deletion_finalize_failed");
      }

      await checkedFetch(
        new URL(
          `/auth/v1/admin/users/${encodeURIComponent(user.id)}`,
          projectURL,
        ),
        {
          method: "DELETE",
          headers: adminHeaders,
          body: JSON.stringify({ should_soft_delete: false }),
        },
        "auth_identity_deletion_failed",
      );

      return new Response(null, {
        status: 204,
        headers: {
          "Cache-Control": "no-store",
        },
      });
    } catch (error) {
      const code = error instanceof Error
        ? error.message
        : "account_deletion_failed";
      const status = code === "authentication_required" ? 401 : 409;
      return jsonResponse(status, code);
    }
  },
};
