import {
  AppStoreServerAPIClient,
  Environment,
  GetTransactionHistoryVersion,
  Order,
  ProductType,
  type TransactionHistoryRequest,
} from "@apple/app-store-server-library";
import type { CommerceEnvironment } from "./commerce_http.ts";

const expectedBundleID = "com.ranggar.MSCBodyTransformation";
const maximumHistoryPages = 100;

export type AppleServerAPIConfiguration = {
  environment: "sandbox" | "production";
  client: AppStoreServerAPIClient;
};

export function loadAppleServerAPIConfiguration(
  commerceEnvironment: CommerceEnvironment,
): AppleServerAPIConfiguration {
  if (
    commerceEnvironment !== "sandbox" &&
    commerceEnvironment !== "production"
  ) {
    throw new Error("apple_server_api_environment_invalid");
  }
  const privateKey = Deno.env.get("APPLE_IAP_PRIVATE_KEY")?.trim();
  const keyID = Deno.env.get("APPLE_IAP_KEY_ID")?.trim();
  const issuerID = Deno.env.get("APPLE_IAP_ISSUER_ID")?.trim();
  if (!privateKey || !keyID || !issuerID) {
    throw new Error("apple_server_api_configuration_missing");
  }
  if (
    !privateKey.includes("BEGIN PRIVATE KEY") ||
    keyID.length > 64 || issuerID.length > 64
  ) {
    throw new Error("apple_server_api_configuration_invalid");
  }
  const environment = commerceEnvironment === "sandbox"
    ? Environment.SANDBOX
    : Environment.PRODUCTION;
  return {
    environment: commerceEnvironment,
    client: new AppStoreServerAPIClient(
      privateKey,
      keyID,
      issuerID,
      expectedBundleID,
      environment,
    ),
  };
}

export async function fetchAppleTransactionHistory(
  configuration: AppleServerAPIConfiguration,
  transactionID: string,
): Promise<string[]> {
  if (!/^[0-9]{6,64}$/.test(transactionID)) {
    throw new Error("transaction_mismatch");
  }
  const request: TransactionHistoryRequest = {
    sort: Order.ASCENDING,
    productTypes: [ProductType.NON_CONSUMABLE, ProductType.NON_RENEWABLE],
  };
  const transactions: string[] = [];
  let revision: string | null = null;
  for (let page = 0; page < maximumHistoryPages; page += 1) {
    const response = await configuration.client.getTransactionHistory(
      transactionID,
      revision,
      request,
      GetTransactionHistoryVersion.V2,
    );
    for (const signedTransaction of response.signedTransactions ?? []) {
      if (signedTransaction.length > 0) transactions.push(signedTransaction);
    }
    if (!response.hasMore) return transactions;
    if (!response.revision || response.revision === revision) {
      throw new Error("apple_server_api_pagination_invalid");
    }
    revision = response.revision;
  }
  throw new Error("apple_server_api_pagination_limit");
}
