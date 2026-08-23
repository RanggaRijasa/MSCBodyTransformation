import { describe, expect, it } from 'vitest';

import { needsCoachAttention } from '@/features/coach/coach-participant-attention';

describe('status perhatian peserta Coach', () => {
  it('tidak menandai peserta yang menyelesaikan seluruh langkah jatuh tempo', () => {
    expect(needsCoachAttention({
      enrollment_status: 'active',
      due_step_count: 2,
      completed_due_step_count: 2,
    })).toBe(false);
  });

  it('menandai peserta bila ada langkah jatuh tempo yang belum selesai', () => {
    expect(needsCoachAttention({
      enrollment_status: 'active',
      due_step_count: 7,
      completed_due_step_count: 2,
    })).toBe(true);
  });

  it('tidak menghitung hari mendatang atau enrollment selesai sebagai perhatian', () => {
    expect(needsCoachAttention({
      enrollment_status: 'active',
      due_step_count: 0,
      completed_due_step_count: 0,
    })).toBe(false);
    expect(needsCoachAttention({
      enrollment_status: 'completed',
      due_step_count: 7,
      completed_due_step_count: 2,
    })).toBe(false);
  });
});
