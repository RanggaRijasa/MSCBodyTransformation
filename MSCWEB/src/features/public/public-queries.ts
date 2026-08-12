import { useQuery } from '@tanstack/react-query';

import { getPublicRepository } from './public-repository';

export const publicQueryKeys = {
  programs: ['public', 'programs'] as const,
  program: (id: string) => ['public', 'program', id] as const,
  coaches: ['public', 'coaches'] as const,
  coach: (id: string) => ['public', 'coach', id] as const,
  leaderboard: (id: string) => ['public', 'leaderboard', id] as const,
  winners: (id: string) => ['public', 'winners', id] as const,
  posters: ['public', 'winner-posters'] as const,
};

export function usePrograms() {
  return useQuery({ queryKey: publicQueryKeys.programs, queryFn: () => getPublicRepository().listPrograms() });
}

export function useProgram(id: string) {
  return useQuery({ queryKey: publicQueryKeys.program(id), queryFn: () => getPublicRepository().getProgram(id), enabled: id !== '' });
}

export function useCoaches() {
  return useQuery({ queryKey: publicQueryKeys.coaches, queryFn: () => getPublicRepository().listCoaches() });
}

export function useCoach(id: string) {
  return useQuery({ queryKey: publicQueryKeys.coach(id), queryFn: () => getPublicRepository().getCoach(id), enabled: id !== '' });
}

export function useLeaderboard(programId?: string) {
  return useQuery({
    queryKey: publicQueryKeys.leaderboard(programId ?? 'none'),
    queryFn: () => getPublicRepository().listLeaderboard(programId ?? ''),
    enabled: programId !== undefined,
  });
}

export function useWinners(programId?: string) {
  return useQuery({
    queryKey: publicQueryKeys.winners(programId ?? 'none'),
    queryFn: () => getPublicRepository().listWinners(programId ?? ''),
    enabled: programId !== undefined,
  });
}

export function useWinnerPosters() {
  return useQuery({ queryKey: publicQueryKeys.posters, queryFn: () => getPublicRepository().listWinnerPosters() });
}
