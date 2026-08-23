import { createClient } from "npm:@supabase/supabase-js@2.112.3";
import { loadSupabaseRuntimeKeys } from "../_shared/supabase_keys.ts";

const assetPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/iu;
const commonHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Cache-Control": "no-store, max-age=0",
  "Cross-Origin-Resource-Policy": "cross-origin",
  "Referrer-Policy": "no-referrer",
  "X-Content-Type-Options": "nosniff",
};

Deno.serve(async (request) => {
  if (!['GET', 'HEAD'].includes(request.method)) {
    return new Response(null, { status: 405, headers: { ...commonHeaders, Allow: 'GET, HEAD' } });
  }

  const assetId = new URL(request.url).pathname.split('/').filter(Boolean).at(-1) ?? '';
  if (!assetPattern.test(assetId)) return new Response(null, { status: 404, headers: commonHeaders });

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  if (!supabaseUrl) return new Response(null, { status: 503, headers: commonHeaders });

  let secretKey: string;
  try {
    ({ secretKey } = loadSupabaseRuntimeKeys());
  } catch {
    return new Response(null, { status: 503, headers: commonHeaders });
  }

  const client = createClient(supabaseUrl, secretKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const resolved = await client.rpc('resolve_public_coach_media_asset', {
    target_asset_id: assetId,
  });
  if (resolved.error || typeof resolved.data !== 'string') {
    return new Response(null, { status: 404, headers: commonHeaders });
  }

  const downloaded = await client.storage.from('coach-public-media').download(resolved.data);
  if (downloaded.error || !downloaded.data) {
    return new Response(null, { status: 404, headers: commonHeaders });
  }

  const headers = new Headers(commonHeaders);
  headers.set('Content-Type', downloaded.data.type || 'image/jpeg');
  headers.set('Content-Length', String(downloaded.data.size));
  return new Response(request.method === 'HEAD' ? null : downloaded.data, {
    status: 200,
    headers,
  });
});
