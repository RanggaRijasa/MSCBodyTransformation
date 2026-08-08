import { Buffer } from "node:buffer";
import {
  Environment,
  type JWSTransactionDecodedPayload,
  type ResponseBodyV2DecodedPayload,
  SignedDataVerifier,
  Type,
} from "@apple/app-store-server-library";
import type { CommerceEnvironment } from "./commerce_http.ts";

export type PurchaseIntentVerificationContext = {
  purchase_intent_id: string;
  account_id: string;
  app_account_token: string;
  subject_kind: "program" | "coach_access";
  product_id: string;
  product_type: "non_consumable" | "non_renewing_subscription";
  environment: CommerceEnvironment;
  status: string;
  expires_at: string;
};

export type VerifiedAppleTransaction = {
  transactionID: string;
  originalTransactionID: string;
  productID: string;
  appAccountToken: string;
  environment: CommerceEnvironment;
  productType: "non_consumable" | "non_renewing_subscription";
  purchasedAt: string;
  signedAt: string;
  expiresAt: string | null;
  revocationAt: string | null;
  currencyCode: string | null;
  priceMilliunits: number | null;
  signedPayloadHash: string;
};

export type VerifiedAppleNotification = {
  payload: ResponseBodyV2DecodedPayload;
  environment: CommerceEnvironment;
  signedPayloadHash: string;
};

const expectedBundleID = "com.ranggar.MSCBodyTransformation";
const maximumSignedPayloadLength = 131_072;
const maximumFutureClockSkewMilliseconds = 5 * 60 * 1_000;

function appleEnvironment(environment: CommerceEnvironment): Environment {
  switch (environment) {
    case "xcode":
      return Environment.XCODE;
    case "local_testing":
      return Environment.LOCAL_TESTING;
    case "sandbox":
      return Environment.SANDBOX;
    case "production":
      return Environment.PRODUCTION;
  }
}

function commerceEnvironment(environment: string): CommerceEnvironment {
  switch (environment) {
    case Environment.XCODE:
      return "xcode";
    case Environment.LOCAL_TESTING:
      return "local_testing";
    case Environment.SANDBOX:
      return "sandbox";
    case Environment.PRODUCTION:
      return "production";
    default:
      throw new Error("transaction_mismatch");
  }
}

function decodeRootCertificates(environment: CommerceEnvironment): Buffer[] {
  if (environment === "xcode" || environment === "local_testing") {
    return [];
  }
  const encodedCertificates = Deno.env.get("APPLE_ROOT_CERTIFICATES_BASE64")
    ?.split(",")
    .map((value) => value.trim())
    .filter(Boolean) ?? [];
  if (encodedCertificates.length === 0) {
    throw new Error("apple_root_certificates_missing");
  }
  try {
    return encodedCertificates.map((encoded) =>
      Buffer.from(encoded, "base64")
    );
  } catch {
    throw new Error("apple_root_certificates_invalid");
  }
}

function loadAppAppleID(environment: CommerceEnvironment): number | undefined {
  const rawValue = Deno.env.get("APPLE_APP_ID")?.trim();
  if (!rawValue) {
    if (environment === "production") {
      throw new Error("apple_app_id_missing");
    }
    return undefined;
  }
  const value = Number(rawValue);
  if (!Number.isSafeInteger(value) || value <= 0) {
    throw new Error("apple_app_id_invalid");
  }
  return value;
}

function requireString(value: unknown): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new Error("purchase_unverified");
  }
  return value;
}

function requireDateMilliseconds(value: unknown): number {
  if (typeof value !== "number" || !Number.isSafeInteger(value) || value <= 0) {
    throw new Error("purchase_unverified");
  }
  return value;
}

function requireUUID(value: unknown): string {
  const result = requireString(value).toLowerCase();
  if (
    !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/
      .test(result)
  ) {
    throw new Error("transaction_mismatch");
  }
  return result;
}

async function sha256(value: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

export class AppleSignedDataVerifier {
  private readonly environment: CommerceEnvironment;
  private readonly verifier: SignedDataVerifier;

  constructor(environment: CommerceEnvironment) {
    this.environment = environment;
    const shouldCheckOnline = environment === "sandbox" ||
      environment === "production";
    this.verifier = new SignedDataVerifier(
      decodeRootCertificates(environment),
      shouldCheckOnline,
      appleEnvironment(environment),
      expectedBundleID,
      loadAppAppleID(environment),
    );
  }

  async verifyTransaction(
    signedTransaction: string,
    context?: PurchaseIntentVerificationContext,
  ): Promise<VerifiedAppleTransaction> {
    return await this.verifyTransactionPayload(
      signedTransaction,
      context,
      false,
    );
  }

  async verifyNotificationTransaction(
    signedTransaction: string,
  ): Promise<VerifiedAppleTransaction> {
    return await this.verifyTransactionPayload(
      signedTransaction,
      undefined,
      true,
    );
  }

  private async verifyTransactionPayload(
    signedTransaction: string,
    context: PurchaseIntentVerificationContext | undefined,
    permitsRevocation: boolean,
  ): Promise<VerifiedAppleTransaction> {
    if (
      signedTransaction.length === 0 ||
      signedTransaction.length > maximumSignedPayloadLength
    ) {
      throw new Error("purchase_unverified");
    }

    let payload: JWSTransactionDecodedPayload;
    try {
      payload = await this.verifier.verifyAndDecodeTransaction(
        signedTransaction,
      );
    } catch {
      throw new Error("purchase_unverified");
    }

    const transactionID = requireString(payload.transactionId);
    const originalTransactionID = requireString(payload.originalTransactionId);
    const productID = requireString(payload.productId);
    const appAccountToken = requireUUID(payload.appAccountToken);
    const environment = commerceEnvironment(requireString(payload.environment));
    const purchasedAt = requireDateMilliseconds(payload.purchaseDate);
    const signedAt = requireDateMilliseconds(payload.signedDate);
    if (
      signedAt > Date.now() + maximumFutureClockSkewMilliseconds ||
      purchasedAt > signedAt + maximumFutureClockSkewMilliseconds
    ) {
      throw new Error("purchase_unverified");
    }
    if (payload.quantity !== undefined && payload.quantity !== 1) {
      throw new Error("transaction_mismatch");
    }

    const productType = payload.type === Type.NON_CONSUMABLE
      ? "non_consumable"
      : payload.type === Type.NON_RENEWING_SUBSCRIPTION
      ? "non_renewing_subscription"
      : null;
    if (!productType) {
      throw new Error("transaction_mismatch");
    }
    if (!permitsRevocation && payload.revocationDate !== undefined) {
      throw new Error(payload.revocationReason === 0 ? "refunded" : "revoked");
    }

    if (context) {
      if (
        context.environment !== this.environment ||
        context.environment !== environment ||
        context.product_id !== productID ||
        context.app_account_token.toLowerCase() !== appAccountToken ||
        context.product_type !== productType
      ) {
        throw new Error("transaction_mismatch");
      }
    } else if (environment !== this.environment) {
      throw new Error("transaction_mismatch");
    }

    let priceMilliunits: number | null = null;
    if (payload.price !== undefined) {
      if (!Number.isSafeInteger(payload.price) || payload.price < 0) {
        throw new Error("purchase_unverified");
      }
      priceMilliunits = payload.price;
    }

    return {
      transactionID,
      originalTransactionID,
      productID,
      appAccountToken,
      environment,
      productType,
      purchasedAt: new Date(purchasedAt).toISOString(),
      signedAt: new Date(signedAt).toISOString(),
      expiresAt: payload.expiresDate === undefined
        ? null
        : new Date(requireDateMilliseconds(payload.expiresDate)).toISOString(),
      revocationAt: payload.revocationDate === undefined
        ? null
        : new Date(requireDateMilliseconds(payload.revocationDate))
          .toISOString(),
      currencyCode: payload.currency ?? null,
      priceMilliunits,
      signedPayloadHash: await sha256(signedTransaction),
    };
  }

  async verifyNotification(
    signedPayload: string,
  ): Promise<VerifiedAppleNotification> {
    if (
      signedPayload.length === 0 ||
      signedPayload.length > maximumSignedPayloadLength
    ) {
      throw new Error("purchase_unverified");
    }
    let payload: ResponseBodyV2DecodedPayload;
    try {
      payload = await this.verifier.verifyAndDecodeNotification(signedPayload);
    } catch {
      throw new Error("purchase_unverified");
    }
    const signedAt = requireDateMilliseconds(payload.signedDate);
    if (signedAt > Date.now() + maximumFutureClockSkewMilliseconds) {
      throw new Error("purchase_unverified");
    }
    return {
      payload,
      environment: this.environment,
      signedPayloadHash: await sha256(signedPayload),
    };
  }
}
