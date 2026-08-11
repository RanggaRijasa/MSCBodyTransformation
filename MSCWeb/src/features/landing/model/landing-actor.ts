export type LandingRole = "participant" | "coach" | "admin";

export type LandingActor =
  Readonly<{ kind: "anonymous" }> | Readonly<{ kind: "authenticated"; role: LandingRole }>;

const roleDestinations: Readonly<Record<LandingRole, string>> = {
  participant: "/hari-ini",
  coach: "/coach-area",
  admin: "/admin",
};

export function resolveLandingDestination(actor: LandingActor): string {
  return actor.kind === "authenticated" ? roleDestinations[actor.role] : "/program";
}
