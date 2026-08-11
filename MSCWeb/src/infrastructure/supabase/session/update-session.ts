import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

import { readPublicEnvironment } from "@/shared/config/environment";

export async function updateSupabaseSession(request: NextRequest, requestHeaders?: Headers) {
  const nextResponse = () =>
    NextResponse.next({ request: { headers: requestHeaders ?? request.headers } });
  const environment = readPublicEnvironment();
  if (!environment.isSuccess) {
    return nextResponse();
  }

  let response = nextResponse();
  const supabase = createServerClient(
    environment.value.supabaseUrl,
    environment.value.supabasePublishableKey,
    {
      cookies: {
        getAll: () => request.cookies.getAll(),
        setAll: (cookiesToSet, headersToSet) => {
          for (const { name, value } of cookiesToSet) {
            request.cookies.set(name, value);
          }

          response = nextResponse();
          for (const { name, value, options } of cookiesToSet) {
            response.cookies.set(name, value, options);
          }
          for (const [name, value] of Object.entries(headersToSet)) {
            response.headers.set(name, value);
          }
        },
      },
    },
  );

  await supabase.auth.getClaims();
  return response;
}
