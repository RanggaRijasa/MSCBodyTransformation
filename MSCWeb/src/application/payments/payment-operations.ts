import "server-only";

import {
  downloadLatestPaymentEvidence,
  downloadPaymentQris,
  listPaymentDestinations,
  loadAdminPaymentHistory,
  supabasePaymentRepository,
} from "@/infrastructure/supabase/payments/supabase-payment-repository";

export const approvePaymentOperation = supabasePaymentRepository.approve;
export const createCoachPaymentOrderOperation = supabasePaymentRepository.createCoachOrder;
export const createProgramPaymentOrderOperation = supabasePaymentRepository.createProgramOrder;
export const downloadLatestPaymentEvidenceOperation = downloadLatestPaymentEvidence;
export const downloadPaymentQrisOperation = downloadPaymentQris;
export const listAdminPaymentQueueOperation = supabasePaymentRepository.listAdminQueue;
export const listPaymentDestinationsOperation = listPaymentDestinations;
export const loadAdminPaymentOrderOperation = supabasePaymentRepository.loadAdminOrder;
export const loadAdminPaymentHistoryOperation = loadAdminPaymentHistory;
export const loadPaymentOrderOperation = supabasePaymentRepository.loadOwnerOrder;
export const rejectPaymentOperation = supabasePaymentRepository.reject;
export const uploadPaymentEvidenceOperation = supabasePaymentRepository.uploadEvidence;
