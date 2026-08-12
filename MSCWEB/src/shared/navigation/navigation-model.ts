import type { Href } from 'expo-router';

import type { MSCIconName } from '@/shared/icons/MSCIcon';

export type AppRole = 'guest' | 'participant' | 'coach' | 'admin';

export type NavigationDestination = Readonly<{
  id: string;
  label: string;
  href: Href;
  icon: MSCIconName;
}>;

const participantDestinations: readonly NavigationDestination[] = [
  { id: 'home', label: 'Beranda', href: '/app/home', icon: 'home' },
  { id: 'programs', label: 'Program', href: '/app/programs', icon: 'program' },
  { id: 'leaderboard', label: 'Peringkat', href: '/app/leaderboard', icon: 'leaderboard' },
  { id: 'coaches', label: 'Coach', href: '/app/coaches', icon: 'coach' },
  { id: 'profile', label: 'Profil', href: '/app/profile', icon: 'profile' },
];

export const navigationByRole: Record<AppRole, readonly NavigationDestination[]> = {
  guest: participantDestinations,
  participant: participantDestinations,
  coach: [
    { id: 'dashboard', label: 'Dashboard', href: '/coach', icon: 'dashboard' },
    { id: 'programs', label: 'Program', href: '/coach/programs', icon: 'program' },
    { id: 'profile', label: 'Profil', href: '/coach/profile', icon: 'profile' },
  ],
  admin: [
    { id: 'dashboard', label: 'Dashboard', href: '/admin', icon: 'dashboard' },
    { id: 'programs', label: 'Program', href: '/admin/programs', icon: 'program' },
    { id: 'people', label: 'Orang', href: '/admin/people', icon: 'participants' },
    { id: 'content', label: 'Konten', href: '/admin/content', icon: 'content' },
    { id: 'settings', label: 'Pengaturan', href: '/admin/settings', icon: 'settings' },
  ],
};
