import { useEffect, useRef } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { participantQueryKeys } from '@/features/participant/participant-queries';
import { publicQueryKeys } from '@/features/public/public-queries';
import { isLocalDevelopmentEnvironment } from '@/shared/config/public-environment';
import { getPaymentRepository } from './payment-repository';
import type { PaymentOrder } from './payment-models';

export const paymentQueryKeys = {
  ownOrders: (programId: string) => ['private', 'payment', 'orders', programId] as const,
  attempts: (orderId: string) => ['private', 'payment', 'attempts', orderId] as const,
  adminQueue: ['private', 'admin', 'payment', 'queue'] as const,
  adminEvents: (orderId: string) => ['private', 'admin', 'payment', 'events', orderId] as const,
};

export function useEnsureRepeatableLocalFixtures(enabled: boolean) {
  const client = useQueryClient();
  const requested = useRef(false);
  const mutation = useMutation({
    mutationFn: () => getPaymentRepository().ensureRepeatableLocalFixtures(),
    onSuccess: async (changed) => {
      if (!changed) return;
      await Promise.all([
        client.invalidateQueries({ queryKey: publicQueryKeys.programs }),
        client.invalidateQueries({ queryKey: participantQueryKeys.enrollments }),
      ]);
    },
  });

  useEffect(() => {
    if (!enabled || requested.current || !isLocalDevelopmentEnvironment()) return;
    requested.current = true;
    mutation.mutate();
  }, [enabled, mutation]);

  return mutation;
}

export function useOwnPaymentOrders(programId: string, enabled: boolean) {
  return useQuery({ queryKey: paymentQueryKeys.ownOrders(programId), queryFn: () => getPaymentRepository().listOwnOrders(programId), enabled: enabled && programId.length > 0 });
}

export function usePaymentAttempts(orderId: string | undefined, enabled: boolean) {
  return useQuery({ queryKey: paymentQueryKeys.attempts(orderId ?? ''), queryFn: () => getPaymentRepository().listAttempts(orderId as string), enabled: enabled && orderId !== undefined });
}

export function useCreateProgramPaymentOrder() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (command: { programId: string; rawPayload: string; idempotencyKey: string }) => getPaymentRepository().createProgramOrder(command.programId, command.rawPayload, command.idempotencyKey),
    onSuccess: async (_, command) => Promise.all([
      client.invalidateQueries({ queryKey: paymentQueryKeys.ownOrders(command.programId) }),
      client.invalidateQueries({ queryKey: participantQueryKeys.enrollments }),
      client.invalidateQueries({ queryKey: publicQueryKeys.programs }),
    ]),
  });
}

export function useEnrollFreeProgram() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (command: { programId: string; rawPayload: string }) => getPaymentRepository().enrollFree(command.programId, command.rawPayload),
    onSuccess: async () => Promise.all([
      client.invalidateQueries({ queryKey: participantQueryKeys.enrollments }),
      client.invalidateQueries({ queryKey: publicQueryKeys.programs }),
    ]),
  });
}

export function useSubmitPaymentEvidence(programId: string) {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (command: { orderId: string; file: Blob; idempotencyKey: string; onProgress?: (value: number, message: string) => void }) => getPaymentRepository().submitEvidence(command.orderId, command.file, command.idempotencyKey, command.onProgress),
    onSuccess: async (order) => Promise.all([
      client.invalidateQueries({ queryKey: paymentQueryKeys.ownOrders(programId) }),
      client.invalidateQueries({ queryKey: paymentQueryKeys.attempts(order.id) }),
      client.invalidateQueries({ queryKey: paymentQueryKeys.adminQueue }),
    ]),
  });
}

export function useAdminPaymentQueue(enabled: boolean) {
  return useQuery({ queryKey: paymentQueryKeys.adminQueue, queryFn: () => getPaymentRepository().listAdminQueue(), enabled });
}

export function useAdminPaymentEvents(orderId: string, enabled: boolean) {
  return useQuery({ queryKey: paymentQueryKeys.adminEvents(orderId), queryFn: () => getPaymentRepository().listAdminEvents(orderId), enabled: enabled && orderId.length > 0 });
}

export function useAdminPaymentDecision() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (command: { kind: 'approve'; order: PaymentOrder; reference: string; destinationMatches: boolean } | { kind: 'reject'; order: PaymentOrder; reason: string }) => command.kind === 'approve'
      ? getPaymentRepository().approve(command.order, command.reference, command.destinationMatches)
      : getPaymentRepository().reject(command.order, command.reason),
    onSettled: async (order, _error, command) => Promise.all([
      client.invalidateQueries({ queryKey: paymentQueryKeys.adminQueue }),
      client.invalidateQueries({ queryKey: paymentQueryKeys.adminEvents(command.order.id) }),
      client.invalidateQueries({ queryKey: paymentQueryKeys.attempts(command.order.id) }),
      order ? client.invalidateQueries({ queryKey: paymentQueryKeys.ownOrders(order.program_id) }) : Promise.resolve(),
    ]),
  });
}
