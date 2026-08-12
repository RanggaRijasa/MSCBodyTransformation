import { ArrowLeftIcon } from 'phosphor-react-native/src/icons/ArrowLeft';
import { BankIcon } from 'phosphor-react-native/src/icons/Bank';
import { CameraIcon } from 'phosphor-react-native/src/icons/Camera';
import { CalendarDotsIcon } from 'phosphor-react-native/src/icons/CalendarDots';
import { CheckCircleIcon } from 'phosphor-react-native/src/icons/CheckCircle';
import { ChecksIcon } from 'phosphor-react-native/src/icons/Checks';
import { ClockCountdownIcon } from 'phosphor-react-native/src/icons/ClockCountdown';
import { CopyIcon } from 'phosphor-react-native/src/icons/Copy';
import { DotsThreeIcon } from 'phosphor-react-native/src/icons/DotsThree';
import { FileTextIcon } from 'phosphor-react-native/src/icons/FileText';
import { GearSixIcon } from 'phosphor-react-native/src/icons/GearSix';
import { HouseIcon } from 'phosphor-react-native/src/icons/House';
import { InfoIcon } from 'phosphor-react-native/src/icons/Info';
import { LockIcon } from 'phosphor-react-native/src/icons/Lock';
import { PulseIcon } from 'phosphor-react-native/src/icons/Pulse';
import { QrCodeIcon } from 'phosphor-react-native/src/icons/QrCode';
import { RankingIcon } from 'phosphor-react-native/src/icons/Ranking';
import { SquaresFourIcon } from 'phosphor-react-native/src/icons/SquaresFour';
import { UploadSimpleIcon } from 'phosphor-react-native/src/icons/UploadSimple';
import { UserCircleIcon } from 'phosphor-react-native/src/icons/UserCircle';
import { UsersIcon } from 'phosphor-react-native/src/icons/Users';
import { UsersThreeIcon } from 'phosphor-react-native/src/icons/UsersThree';
import { WarningIcon } from 'phosphor-react-native/src/icons/Warning';
import { WifiSlashIcon } from 'phosphor-react-native/src/icons/WifiSlash';
import { XCircleIcon } from 'phosphor-react-native/src/icons/XCircle';
import type { ComponentProps } from 'react';
import { View } from 'react-native';

export type MSCIconName =
  | 'activity'
  | 'approved'
  | 'back'
  | 'bank'
  | 'camera'
  | 'coach'
  | 'content'
  | 'copy'
  | 'dashboard'
  | 'forbidden'
  | 'home'
  | 'info'
  | 'leaderboard'
  | 'more'
  | 'offline'
  | 'participants'
  | 'pending'
  | 'profile'
  | 'program'
  | 'qr'
  | 'rejected'
  | 'reviewEvidence'
  | 'settings'
  | 'upload'
  | 'warning';
export type MSCIconSize = 'small' | 'medium' | 'large';

type IconComponent = typeof HouseIcon;
type IconWeight = ComponentProps<IconComponent>['weight'];

const semanticIcons: Record<MSCIconName, IconComponent> = {
  activity: PulseIcon,
  approved: CheckCircleIcon,
  back: ArrowLeftIcon,
  bank: BankIcon,
  camera: CameraIcon,
  coach: UsersThreeIcon,
  content: FileTextIcon,
  copy: CopyIcon,
  dashboard: SquaresFourIcon,
  forbidden: LockIcon,
  home: HouseIcon,
  info: InfoIcon,
  leaderboard: RankingIcon,
  more: DotsThreeIcon,
  offline: WifiSlashIcon,
  participants: UsersIcon,
  pending: ClockCountdownIcon,
  program: CalendarDotsIcon,
  profile: UserCircleIcon,
  qr: QrCodeIcon,
  rejected: XCircleIcon,
  reviewEvidence: ChecksIcon,
  settings: GearSixIcon,
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
