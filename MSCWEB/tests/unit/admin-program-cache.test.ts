import { QueryClient } from '@tanstack/react-query';
import { describe, expect, it } from 'vitest';

import type { AdminProgram } from '../../src/features/admin/admin-models';
import { adminKeys, cacheSavedAdminProgram } from '../../src/features/admin/admin-queries';

describe('admin program draft cache', () => {
  it('replaces a stale nested graph before returning to the previous editor', () => {
    const queryClient = new QueryClient();
    const programId = '11111111-1111-4111-8111-111111111111';
    const stale = {
      id: programId,
      days: [{ id: 'day', steps: [{ id: 'step', questions: [] }] }],
    } as unknown as AdminProgram;
    const saved = {
      ...stale,
      days: [{
        id: 'day',
        steps: [{ id: 'step', questions: [{ id: 'question', prompt: 'Pertanyaan tersimpan' }] }],
      }],
    } as unknown as AdminProgram;

    queryClient.setQueryData(adminKeys.program(programId), stale);
    cacheSavedAdminProgram(queryClient, saved);

    expect(queryClient.getQueryData(adminKeys.program(programId))).toStrictEqual(saved);
  });
});
