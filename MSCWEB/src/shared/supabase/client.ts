import { createPkceSupabaseClient, type PkceSupabaseClient } from '@/shared/auth/create-pkce-supabase-client';
import { readPublicEnvironment } from '@/shared/config/public-environment';

let browserClient: PkceSupabaseClient | undefined;

export function getSupabaseBrowserClient(): PkceSupabaseClient {
  browserClient ??= createPkceSupabaseClient({
    url: readPublicEnvironment().supabaseUrl,
    publishableKey: readPublicEnvironment().supabasePublishableKey,
  });
  return browserClient;
}
