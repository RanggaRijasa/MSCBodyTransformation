import { createBrowserClient } from "@supabase/ssr";

import { readPublicEnvironment } from "@/shared/config/environment";

export function createSupabaseBrowserClient() {
  const environment = readPublicEnvironment();
  if (!environment.isSuccess) {
    throw environment.error;
  }

  return createBrowserClient(
    environment.value.supabaseUrl,
    environment.value.supabasePublishableKey,
  );
}
