import "server-only";

import { cookies } from "next/headers";

import {
  PENDING_PROGRAM_COOKIE,
  isPendingProgramIntentValid,
  type PendingProgramIntent,
} from "@/features/auth/model/auth-flow";
import { readAuthServerEnvironment } from "@/features/auth/server/auth-environment";
import { unsealCookie } from "@/features/auth/server/sealed-cookie";

export async function revalidatePendingProgramIntent(
  programId: string,
): Promise<"discarded" | "matched" | "none"> {
  const cookieStore = await cookies();
  const sealed = cookieStore.get(PENDING_PROGRAM_COOKIE)?.value;
  if (!sealed) return "none";
  try {
    const environment = readAuthServerEnvironment();
    const intent = await unsealCookie<PendingProgramIntent>(sealed, environment.cookieSecret);
    if (
      !intent ||
      intent.programId !== programId ||
      !isPendingProgramIntentValid(intent, {
        environment: environment.environmentName,
        now: Math.floor(Date.now() / 1000),
      })
    ) {
      return "discarded";
    }
    return "matched";
  } catch {
    return "discarded";
  }
}
