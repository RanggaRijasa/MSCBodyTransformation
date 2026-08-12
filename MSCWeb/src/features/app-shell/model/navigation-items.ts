import { copy } from "@/shared/i18n/id";
import type { AppIconName } from "@/shared/ui/icons/app-icon";

export type ShellKind = "participant" | "coach" | "admin";

export type ShellNavigationItem = Readonly<{
  exact?: boolean;
  href: string;
  icon: AppIconName;
  label: string;
}>;

export const participantNavigation: readonly ShellNavigationItem[] = [
  { href: "/hari-ini", icon: "home", label: copy.navigation.participant.today },
  { href: "/program", icon: "program", label: copy.navigation.participant.program },
  { href: "/peringkat", icon: "ranking", label: copy.navigation.participant.ranking },
  { href: "/coach", icon: "coach", label: copy.navigation.participant.coach },
  { href: "/profil", icon: "person", label: copy.navigation.participant.profile },
];

export const coachNavigation: readonly ShellNavigationItem[] = [
  { exact: true, href: "/coach-area", icon: "dashboard", label: copy.navigation.coach.dashboard },
  { href: "/coach-area/program", icon: "program", label: copy.navigation.coach.program },
  { href: "/coach-area/profil", icon: "person", label: copy.navigation.coach.profile },
];

export const adminNavigation: readonly ShellNavigationItem[] = [
  { exact: true, href: "/admin", icon: "dashboard", label: copy.navigation.admin.dashboard },
  { href: "/admin/pembayaran", icon: "payment", label: copy.navigation.admin.payment },
  { href: "/admin/program", icon: "program", label: copy.navigation.admin.program },
  { href: "/admin/orang", icon: "people", label: copy.navigation.admin.people },
  { href: "/admin/konten", icon: "content", label: copy.navigation.admin.content },
  { href: "/admin/pengaturan", icon: "settings", label: copy.navigation.admin.settings },
];

export const adminMobileNavigation: readonly ShellNavigationItem[] = [
  adminNavigation[0],
  adminNavigation[2],
  adminNavigation[3],
  adminNavigation[4],
  adminNavigation[5],
].filter((item): item is ShellNavigationItem => item !== undefined);

export const navigationByKind: Readonly<Record<ShellKind, readonly ShellNavigationItem[]>> = {
  participant: participantNavigation,
  coach: coachNavigation,
  admin: adminNavigation,
};
