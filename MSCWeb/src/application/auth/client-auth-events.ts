import { createSupabaseBrowserClient } from "@/infrastructure/supabase/client/browser";

export type AuthClientEvent = "SIGNED_IN" | "SIGNED_OUT" | "TOKEN_REFRESHED" | "USER_UPDATED";

export function subscribeToAuthClientEvents(
  listener: (event: AuthClientEvent) => void,
): () => void {
  const supabase = createSupabaseBrowserClient();
  const subscription = supabase.auth.onAuthStateChange((event) => {
    if (
      event === "SIGNED_IN" ||
      event === "SIGNED_OUT" ||
      event === "TOKEN_REFRESHED" ||
      event === "USER_UPDATED"
    )
      listener(event);
  }).data.subscription;
  return () => subscription.unsubscribe();
}
