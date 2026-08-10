import {
  AppleIdentityConfiguration,
  callAppleServiceRPC,
  ClaimedAppleCredential,
  decryptAppleRefreshToken,
  revokeAppleRefreshToken,
} from "./apple_identity.ts";
import { fetchWithTimeout } from "./http_safety.ts";
import { serviceRequestHeaders } from "./supabase_keys.ts";

type MediaObject = { bucket_id: string; name: string };

export async function revokeClaimedAppleCredential(
  configuration: AppleIdentityConfiguration,
  credential: ClaimedAppleCredential,
): Promise<boolean> {
  try {
    const refreshToken = await decryptAppleRefreshToken(
      configuration,
      credential,
    );
    await revokeAppleRefreshToken(configuration, refreshToken);
    await callAppleServiceRPC<void>(
      configuration,
      "complete_apple_identity_revocation",
      {
        target_credential_id: credential.id,
        succeeded: true,
        error_code: null,
      },
    );
    return true;
  } catch (error) {
    const code = error instanceof Error
      ? error.message
      : "apple_revoke_failed";
    await callAppleServiceRPC<void>(
      configuration,
      "complete_apple_identity_revocation",
      {
        target_credential_id: credential.id,
        succeeded: false,
        error_code: code,
      },
    );
    return false;
  }
}

export async function purgeAppleCredentialAfterExternalRevocation(
  configuration: AppleIdentityConfiguration,
  accountID: string,
): Promise<void> {
  const credential = await callAppleServiceRPC<ClaimedAppleCredential | null>(
    configuration,
    "claim_apple_identity_credential_for_account",
    { target_account_id: accountID },
  );
  if (!credential) return;
  await callAppleServiceRPC<void>(
    configuration,
    "complete_apple_identity_revocation",
    {
      target_credential_id: credential.id,
      succeeded: true,
      error_code: null,
    },
  );
}

export async function deleteAccountFromAppleEvent(
  configuration: AppleIdentityConfiguration,
  accountID: string,
): Promise<void> {
  const manifest = await callAppleServiceRPC<MediaObject[]>(
    configuration,
    "prepare_external_apple_account_deletion",
    { target_account_id: accountID },
  );
  const objectsByBucket = new Map<string, string[]>();
  for (const object of manifest ?? []) {
    if (!object.bucket_id || !object.name) {
      throw new Error("private_media_cleanup_failed");
    }
    const paths = objectsByBucket.get(object.bucket_id) ?? [];
    paths.push(object.name);
    objectsByBucket.set(object.bucket_id, paths);
  }
  for (const [bucketID, paths] of objectsByBucket) {
    for (let index = 0; index < paths.length; index += 1_000) {
      const response = await fetchWithTimeout(
        new URL(
          `/storage/v1/object/${encodeURIComponent(bucketID)}`,
          configuration.projectURL,
        ),
        {
          method: "DELETE",
          headers: {
            ...serviceRequestHeaders(configuration.secretKey),
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ prefixes: paths.slice(index, index + 1_000) }),
        },
      );
      if (!response.ok) {
        throw new Error("private_media_cleanup_failed");
      }
    }
  }
  const finalized = await callAppleServiceRPC<string>(
    configuration,
    "finalize_external_apple_account_deletion",
    { target_account_id: accountID },
  );
  if (finalized !== accountID) {
    throw new Error("account_deletion_finalize_failed");
  }
  await purgeAppleCredentialAfterExternalRevocation(configuration, accountID);
  const authResponse = await fetchWithTimeout(
    new URL(`/auth/v1/admin/users/${encodeURIComponent(accountID)}`, configuration.projectURL),
    {
      method: "DELETE",
      headers: {
        ...serviceRequestHeaders(configuration.secretKey),
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ should_soft_delete: false }),
    },
  );
  if (!authResponse.ok && authResponse.status !== 404) {
    throw new Error("auth_identity_deletion_failed");
  }
}
