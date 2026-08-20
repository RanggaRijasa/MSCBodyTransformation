import { ParticipantCoachOnboardingScreen } from '@/features/onboarding/OnboardingComponents';
import { useAuth } from '@/shared/auth/AuthProvider';

export default function ParticipantCoachOnboardingRoute() {
  const { state } = useAuth();
  return <ParticipantCoachOnboardingScreen key={state.status === 'onboarding' ? state.context.user_id : state.status} />;
}
