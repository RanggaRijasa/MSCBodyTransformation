import { useMutation, useQuery, useQueryClient, type QueryClient } from '@tanstack/react-query';

import { getAdminRepository } from './admin-repository';
import { publicQueryKeys } from '@/features/public/public-queries';
import type { AdminFoodOperation, AdminModerationItem, AdminProgram } from './admin-models';

export const adminKeys = {
  root: ['private', 'admin'] as const,
  dashboard: ['private', 'admin', 'dashboard'] as const,
  programs: ['private', 'admin', 'programs'] as const,
  program: (id: string) => ['private', 'admin', 'program', id] as const,
  people: ['private', 'admin', 'people'] as const,
  person: (id: string) => ['private', 'admin', 'person', id] as const,
  personOperations: (id: string) => ['private', 'admin', 'person-operations', id] as const,
  evidence: ['private', 'admin', 'evidence'] as const,
  moderation: ['private', 'admin', 'moderation'] as const,
  food: ['private', 'admin', 'food-insight'] as const,
  audit: ['private', 'admin', 'audit'] as const,
  closure: (id: string) => ['private', 'admin', 'closure', id] as const,
  winners: (id: string) => ['private', 'admin', 'winner-preview', id] as const,
  posters: ['private', 'admin', 'posters'] as const,
  winnerSnapshots: ['private', 'admin', 'winner-snapshots'] as const,
  paymentDestinationReadiness: ['private', 'admin', 'payment-destination-readiness'] as const,
};

export function useAdminDashboard(enabled: boolean) { return useQuery({ queryKey: adminKeys.dashboard, queryFn: () => getAdminRepository().getDashboard(), enabled }); }
export function useAdminPrograms(enabled = true) { return useQuery({ queryKey: adminKeys.programs, queryFn: () => getAdminRepository().listPrograms(), enabled }); }
export function useAdminProgram(id: string) { return useQuery({ queryKey: adminKeys.program(id), queryFn: () => getAdminRepository().getProgram(id), enabled: Boolean(id) }); }
export function useAdminPeople(enabled = true) { return useQuery({ queryKey: adminKeys.people, queryFn: () => getAdminRepository().listPeople(), enabled }); }
export function useAdminPerson(id: string, enabled = true) { return useQuery({ queryKey: adminKeys.person(id), queryFn: () => getAdminRepository().getPerson(id), enabled: enabled && Boolean(id) }); }
export function useAdminPersonOperations(id: string, enabled = true) { return useQuery({ queryKey: adminKeys.personOperations(id), queryFn: () => getAdminRepository().getPersonOperations(id), enabled: enabled && Boolean(id) }); }
export function useAdminEvidence(enabled = true) { return useQuery({ queryKey: adminKeys.evidence, queryFn: () => getAdminRepository().listEvidence(), enabled }); }
export function useAdminModeration(enabled = true) { return useQuery({ queryKey: adminKeys.moderation, queryFn: () => getAdminRepository().listModeration(), enabled }); }
export function useAdminFoodOperations(enabled = true) { return useQuery({ queryKey: adminKeys.food, queryFn: () => getAdminRepository().listFoodOperations(), enabled }); }
export function useAdminAudit(enabled = true) { return useQuery({ queryKey: adminKeys.audit, queryFn: () => getAdminRepository().listAudit(), enabled }); }
export function useAdminClosure(programId: string, enabled = true) { return useQuery({ queryKey: adminKeys.closure(programId), queryFn: () => getAdminRepository().getClosure(programId), enabled: enabled && Boolean(programId) }); }
export function useAdminWinnerPreview(programId: string, enabled = true) { return useQuery({ queryKey: adminKeys.winners(programId), queryFn: () => getAdminRepository().previewWinners(programId), enabled: enabled && Boolean(programId) }); }
export function useAdminPosters(enabled = true) { return useQuery({ queryKey: adminKeys.posters, queryFn: () => getAdminRepository().listPosters(), enabled }); }
export function useAdminWinnerSnapshots(enabled = true) { return useQuery({ queryKey: adminKeys.winnerSnapshots, queryFn: () => getAdminRepository().listWinnerSnapshots(), enabled }); }
export function useAdminPaymentDestinationReadiness(enabled = true) { return useQuery({ queryKey: adminKeys.paymentDestinationReadiness, queryFn: () => getAdminRepository().hasCurrentPaymentDestination(), enabled }); }

export function useAdminMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (command: AdminCommand) => {
      const repository = getAdminRepository();
      switch (command.kind) {
        case 'createProgram': return repository.createProgram();
        case 'saveProgram': return repository.saveProgram(command.program);
        case 'duplicateProgram': return repository.duplicateProgram(command.program);
        case 'publishProgram': await repository.publishProgram(command.programId); return command.programId;
        case 'archiveProgram': await repository.archiveProgram(command.programId, command.reason); return command.programId;
        case 'enrollParticipant': await repository.enrollParticipant(command.participantId, command.programId, command.reason); return command.participantId;
        case 'transferCoach': await repository.transferCoach(command.participantId, command.coachId, command.reason); return command.participantId;
        case 'adjustScore': await repository.adjustScore(command.enrollmentId, command.points, command.reason); return command.participantId;
        case 'moderate': await repository.moderateItem(command.item, command.decision, command.note); return command.item.id;
        case 'correctFood': await repository.correctFoodRating(command.operation, command.rating, command.reason); return command.operation.job_id;
        case 'completeProgram': await repository.completeProgram(command.programId, command.reason); return command.programId;
        case 'lockWinners': await repository.lockWinners(command.programId); return command.programId;
        case 'publishPoster': await repository.publishWinnerPoster(command.programId, command.snapshotId, command.mediaPath, command.altText); return command.programId;
        case 'archivePoster': await repository.archivePoster(command.posterId, command.reason); return command.posterId;
      }
    },
    onSuccess: async (_result, command) => {
      if (command.kind === 'saveProgram') cacheSavedAdminProgram(queryClient, command.program);
      await queryClient.invalidateQueries({ queryKey: adminKeys.root });
      if (command.kind === 'publishProgram') await queryClient.invalidateQueries({ queryKey: publicQueryKeys.programs });
    },
  });
}

export function cacheSavedAdminProgram(queryClient: QueryClient, program: AdminProgram): void {
  queryClient.setQueryData(adminKeys.program(program.id), program);
}

export type AdminCommand =
  | { kind: 'createProgram' }
  | { kind: 'saveProgram'; program: AdminProgram }
  | { kind: 'duplicateProgram'; program: AdminProgram }
  | { kind: 'publishProgram'; programId: string }
  | { kind: 'archiveProgram'; programId: string; reason: string }
  | { kind: 'enrollParticipant'; participantId: string; programId: string; reason: string }
  | { kind: 'transferCoach'; participantId: string; coachId: string; reason: string }
  | { kind: 'adjustScore'; participantId: string; enrollmentId: string; points: number; reason: string }
  | { kind: 'moderate'; item: AdminModerationItem; decision: 'approved' | 'rejected'; note: string }
  | { kind: 'correctFood'; operation: AdminFoodOperation; rating: number; reason: string }
  | { kind: 'completeProgram'; programId: string; reason: string }
  | { kind: 'lockWinners'; programId: string }
  | { kind: 'publishPoster'; programId: string; snapshotId: string; mediaPath: string; altText: string }
  | { kind: 'archivePoster'; posterId: string; reason: string };
