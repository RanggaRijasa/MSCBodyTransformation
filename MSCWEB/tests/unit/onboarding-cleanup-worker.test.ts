import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

const worker = readFileSync('supabase/functions/process-provisional-cancellations/index.ts', 'utf8');
const localWorker = readFileSync('scripts/process-local-provisional-cancellations.mjs', 'utf8');
const migration = readFileSync('supabase/migrations/20260820115825_w07_4_registration_onboarding_remediation.sql', 'utf8');

describe('W07.4 cancellation worker contract', () => {
  it('uses leased receipt claims, Storage API removal, session revocation, Auth deletion, and durable completion', () => {
    expect(worker).toContain("rpc('claim_provisional_cancellation')");
    expect(worker).toContain("storage.from('payment-evidence').remove");
    expect(worker).toContain("rpc('revoke_provisional_cancellation_sessions'");
    expect(worker).toContain('auth.admin.deleteUser');
    expect(worker).toContain("rpc('complete_provisional_cancellation'");
    expect(worker).toContain("rpc('fail_provisional_cancellation'");
    expect(migration).toContain("for update skip locked");
    expect(migration).toContain("status in ('queued', 'failed', 'processing')");
    expect(localWorker).toContain("CLEANUP_RECEIPT_ID");
    expect(localWorker).toContain("auth.admin.deleteUser");
  });

  it('does not log identity, proof paths, tokens, or service credentials', () => {
    expect(worker).not.toContain('console.log');
    expect(worker).not.toContain('access_token');
    expect(worker).not.toContain('refresh_token');
    expect(worker).not.toContain('service_role');
  });
});
