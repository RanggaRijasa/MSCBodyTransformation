import "server-only";

import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

import { readPublicEnvironment } from "@/shared/config/environment";

export async function createSupabaseServerClient() {
  const environment = readPublicEnvironment();
  if (!environment.isSuccess) {
    throw environment.error;
  }

  const cookieStore = await cookies();

  return createServerClient(
    environment.value.supabaseUrl,
    environment.value.supabasePublishableKey,
    {
      cookies: {
        getAll: () => cookieStore.getAll(),
        setAll: (cookiesToSet) => {
          try {
            for (const { name, value, options } of cookiesToSet) {
              cookieStore.set(name, value, options);
            }
          } catch {
            // Server Components cannot write cookies. Proxy owns token refresh.
          }
        },
      },
    },
  );
}
