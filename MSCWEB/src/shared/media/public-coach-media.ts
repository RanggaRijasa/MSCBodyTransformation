import { readPublicEnvironment } from '@/shared/config/public-environment';

const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/iu;

export function publicCoachMediaUrl(assetId?: string | null): string | undefined {
  if (!assetId || !uuidPattern.test(assetId)) return undefined;
  const { supabaseUrl } = readPublicEnvironment();
  return new URL(
    `/functions/v1/public-coach-media/${encodeURIComponent(assetId)}`,
    supabaseUrl,
  ).toString();
}
