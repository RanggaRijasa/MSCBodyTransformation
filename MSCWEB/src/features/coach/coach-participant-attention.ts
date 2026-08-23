export type CoachAttentionEnrollment = {
  enrollment_status: 'active' | 'completed';
  due_step_count: number;
  completed_due_step_count: number;
};

export function needsCoachAttention(enrollment: CoachAttentionEnrollment): boolean {
  if (enrollment.enrollment_status === 'completed') return false;
  return enrollment.completed_due_step_count < enrollment.due_step_count;
}
