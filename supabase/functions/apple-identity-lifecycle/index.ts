import {
  appleIdentityErrorResponse,
  authenticateSupabaseUser,
  callAppleServiceRPC,
  encryptAppleRefreshToken,
  exchangeAppleAuthorizationCode,
  loadAppleIdentityConfiguration,
  sha256Hex,
} from "../_shared/apple_identity.ts";
import { readLimitedText } from "../_shared/http_safety.ts";

const noStoreHeaders = { "Cache-Control": "no-store" };

export default {
  async fetch(request: Request): Promise<Response> {
    if (request.method !== "POST") {
      return appleIdentityErrorResponse(new Error("method_not_allowed"));
    }
    try {
      const configuration = loadAppleIdentityConfiguration();
      const authorization = request.headers.get("Authorization") ?? "";
      const user = await authenticateSupabaseUser(configuration, authorization);
      const rawBody = await readLimitedText(request, 8_192);
      const body = JSON.parse(rawBody) as { authorization_code?: string };
      const authorizationCode = body.authorization_code?.trim() ?? "";
      if (authorizationCode.length < 8 || authorizationCode.length > 4_096) {
        throw new Error("request_invalid");
      }
      const appleTokens = await exchangeAppleAuthorizationCode(
        configuration,
        authorizationCode,
      );
      if (!user.appleSubjects.includes(appleTokens.subject)) {
        throw new Error("apple_identity_mismatch");
      }
      const encrypted = await encryptAppleRefreshToken(
        configuration,
        appleTokens.refreshToken,
      );
      await callAppleServiceRPC<string>(
        configuration,
        "store_apple_identity_credential",
        {
          target_account_id: user.id,
          target_apple_subject_hash: await sha256Hex(appleTokens.subject),
          target_encrypted_refresh_token: encrypted.ciphertext,
          target_encryption_nonce: encrypted.nonce,
        },
      );
      return new Response(null, { status: 204, headers: noStoreHeaders });
    } catch (error) {
      return appleIdentityErrorResponse(error);
    }
  },
};
