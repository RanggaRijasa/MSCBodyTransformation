import { ArrowLeftIcon } from 'phosphor-react-native/src/icons/ArrowLeft';
import { BankIcon } from 'phosphor-react-native/src/icons/Bank';
import { CameraIcon } from 'phosphor-react-native/src/icons/Camera';
import { CalendarDotsIcon } from 'phosphor-react-native/src/icons/CalendarDots';
import { ChartLineUpIcon } from 'phosphor-react-native/src/icons/ChartLineUp';
import { CheckCircleIcon } from 'phosphor-react-native/src/icons/CheckCircle';
import { ChecksIcon } from 'phosphor-react-native/src/icons/Checks';
import { ClockCounterClockwiseIcon } from 'phosphor-react-native/src/icons/ClockCounterClockwise';
import { ClockCountdownIcon } from 'phosphor-react-native/src/icons/ClockCountdown';
import { CopyIcon } from 'phosphor-react-native/src/icons/Copy';
import { CrownIcon } from 'phosphor-react-native/src/icons/Crown';
import { DotsThreeIcon } from 'phosphor-react-native/src/icons/DotsThree';
import { EqualsIcon } from 'phosphor-react-native/src/icons/Equals';
import { FileTextIcon } from 'phosphor-react-native/src/icons/FileText';
import { GearSixIcon } from 'phosphor-react-native/src/icons/GearSix';
import { HouseIcon } from 'phosphor-react-native/src/icons/House';
import { InfoIcon } from 'phosphor-react-native/src/icons/Info';
import { LockIcon } from 'phosphor-react-native/src/icons/Lock';
import { MagnifyingGlassIcon } from 'phosphor-react-native/src/icons/MagnifyingGlass';
import { PulseIcon } from 'phosphor-react-native/src/icons/Pulse';
import { PersonSimpleRunIcon } from 'phosphor-react-native/src/icons/PersonSimpleRun';
import { QrCodeIcon } from 'phosphor-react-native/src/icons/QrCode';
import { RankingIcon } from 'phosphor-react-native/src/icons/Ranking';
import { SquaresFourIcon } from 'phosphor-react-native/src/icons/SquaresFour';
import { StarIcon } from 'phosphor-react-native/src/icons/Star';
import { SlidersHorizontalIcon } from 'phosphor-react-native/src/icons/SlidersHorizontal';
import { TrophyIcon } from 'phosphor-react-native/src/icons/Trophy';
import { UploadSimpleIcon } from 'phosphor-react-native/src/icons/UploadSimple';
import { UserCircleIcon } from 'phosphor-react-native/src/icons/UserCircle';
import { UserCircleCheckIcon } from 'phosphor-react-native/src/icons/UserCircleCheck';
import { UsersIcon } from 'phosphor-react-native/src/icons/Users';
import { UsersThreeIcon } from 'phosphor-react-native/src/icons/UsersThree';
import { WarningIcon } from 'phosphor-react-native/src/icons/Warning';
import { WifiSlashIcon } from 'phosphor-react-native/src/icons/WifiSlash';
import { XCircleIcon } from 'phosphor-react-native/src/icons/XCircle';
import type { ComponentProps } from 'react';
import { View } from 'react-native';

export type MSCIconName =
  | 'activity'
  | 'activeProgram'
  | 'approved'
  | 'back'
  | 'bank'
  | 'camera'
  | 'coach'
  | 'content'
  | 'copy'
  | 'crown'
  | 'dashboard'
  | 'forbidden'
  | 'filter'
  | 'history'
  | 'home'
  | 'info'
  | 'leaderboard'
  | 'assigned'
  | 'more'
  | 'offline'
  | 'participants'
  | 'pending'
  | 'profile'
  | 'progress'
  | 'program'
  | 'qr'
  | 'rejected'
  | 'reviewEvidence'
  | 'search'
  | 'settings'
  | 'star'
  | 'tie'
  | 'trophy'
  | 'upload'
  | 'warning';
export type MSCIconSize = 'small' | 'medium' | 'large';

type IconComponent = typeof HouseIcon;
type IconWeight = ComponentProps<IconComponent>['weight'];

const semanticIcons: Record<MSCIconName, IconComponent> = {
  activity: PulseIcon,
  activeProgram: PersonSimpleRunIcon,
  approved: CheckCircleIcon,
  back: ArrowLeftIcon,
  bank: BankIcon,
  camera: CameraIcon,
  coach: UsersThreeIcon,
  content: FileTextIcon,
  copy: CopyIcon,
  crown: CrownIcon,
  dashboard: SquaresFourIcon,
  forbidden: LockIcon,
  filter: SlidersHorizontalIcon,
  history: ClockCounterClockwiseIcon,
  home: HouseIcon,
  info: InfoIcon,
  leaderboard: RankingIcon,
  assigned: UserCircleCheckIcon,
  more: DotsThreeIcon,
  offline: WifiSlashIcon,
  participants: UsersIcon,
  pending: ClockCountdownIcon,
  program: CalendarDotsIcon,
  profile: UserCircleIcon,
  progress: ChartLineUpIcon,
  qr: QrCodeIcon,
  rejected: XCircleIcon,
  reviewEvidence: ChecksIcon,
  search: MagnifyingGlassIcon,
  settings: GearSixIcon,
  star: StarIcon,
  tie: EqualsIcon,
  trophy: TrophyIcon,
  upload: UploadSimpleIcon,
  warning: WarningIcon,
};

const iconSizes: Record<MSCIconSize, number> = {
  small: 18,
  medium: 24,
  large: 30,
};

type MSCIconProps = {
  name: MSCIconName;
  size?: MSCIconSize;
  color: string;
  weight?: IconWeight;
  accessibilityLabel?: string;
};

export function MSCIcon({
  name,
  size = 'medium',
  color,
  weight = 'regular',
  accessibilityLabel,
}: MSCIconProps) {
  const Icon = semanticIcons[name];

  return (
    <View
      accessible={accessibilityLabel !== undefined}
      accessibilityLabel={accessibilityLabel}
      accessibilityElementsHidden={accessibilityLabel === undefined}
      importantForAccessibility={accessibilityLabel === undefined ? 'no' : 'yes'}
    >
      <Icon color={color} size={iconSizes[size]} weight={weight} />
    </View>
  );
}
