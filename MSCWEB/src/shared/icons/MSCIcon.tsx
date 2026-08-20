import { ArrowLeftIcon } from 'phosphor-react-native/src/icons/ArrowLeft';
import { ArchiveIcon } from 'phosphor-react-native/src/icons/Archive';
import { BankIcon } from 'phosphor-react-native/src/icons/Bank';
import { CameraIcon } from 'phosphor-react-native/src/icons/Camera';
import { CaretRightIcon } from 'phosphor-react-native/src/icons/CaretRight';
import { CalendarDotsIcon } from 'phosphor-react-native/src/icons/CalendarDots';
import { ChartLineUpIcon } from 'phosphor-react-native/src/icons/ChartLineUp';
import { CheckCircleIcon } from 'phosphor-react-native/src/icons/CheckCircle';
import { ChecksIcon } from 'phosphor-react-native/src/icons/Checks';
import { ClockCounterClockwiseIcon } from 'phosphor-react-native/src/icons/ClockCounterClockwise';
import { ClockCountdownIcon } from 'phosphor-react-native/src/icons/ClockCountdown';
import { ClipboardTextIcon } from 'phosphor-react-native/src/icons/ClipboardText';
import { CopyIcon } from 'phosphor-react-native/src/icons/Copy';
import { CrownIcon } from 'phosphor-react-native/src/icons/Crown';
import { DotsThreeIcon } from 'phosphor-react-native/src/icons/DotsThree';
import { EqualsIcon } from 'phosphor-react-native/src/icons/Equals';
import { FileTextIcon } from 'phosphor-react-native/src/icons/FileText';
import { GearSixIcon } from 'phosphor-react-native/src/icons/GearSix';
import { HouseIcon } from 'phosphor-react-native/src/icons/House';
import { InfoIcon } from 'phosphor-react-native/src/icons/Info';
import { ImageSquareIcon } from 'phosphor-react-native/src/icons/ImageSquare';
import { LockIcon } from 'phosphor-react-native/src/icons/Lock';
import { MagnifyingGlassIcon } from 'phosphor-react-native/src/icons/MagnifyingGlass';
import { PulseIcon } from 'phosphor-react-native/src/icons/Pulse';
import { PersonSimpleRunIcon } from 'phosphor-react-native/src/icons/PersonSimpleRun';
import { PlusIcon } from 'phosphor-react-native/src/icons/Plus';
import { QrCodeIcon } from 'phosphor-react-native/src/icons/QrCode';
import { RankingIcon } from 'phosphor-react-native/src/icons/Ranking';
import { SquaresFourIcon } from 'phosphor-react-native/src/icons/SquaresFour';
import { StarIcon } from 'phosphor-react-native/src/icons/Star';
import { StackIcon } from 'phosphor-react-native/src/icons/Stack';
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
  | 'archive'
  | 'approved'
  | 'back'
  | 'bank'
  | 'camera'
  | 'chevron'
  | 'coach'
  | 'content'
  | 'clipboard'
  | 'copy'
  | 'crown'
  | 'dashboard'
  | 'forbidden'
  | 'filter'
  | 'history'
  | 'home'
  | 'info'
  | 'image'
  | 'leaderboard'
  | 'assigned'
  | 'more'
  | 'offline'
  | 'participants'
  | 'pending'
  | 'plus'
  | 'profile'
  | 'progress'
  | 'program'
  | 'qr'
  | 'rejected'
  | 'reviewEvidence'
  | 'search'
  | 'settings'
  | 'star'
  | 'stack'
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
  archive: ArchiveIcon,
  approved: CheckCircleIcon,
  back: ArrowLeftIcon,
  bank: BankIcon,
  camera: CameraIcon,
  chevron: CaretRightIcon,
  coach: UsersThreeIcon,
  content: FileTextIcon,
  clipboard: ClipboardTextIcon,
  copy: CopyIcon,
  crown: CrownIcon,
  dashboard: SquaresFourIcon,
  forbidden: LockIcon,
  filter: SlidersHorizontalIcon,
  history: ClockCounterClockwiseIcon,
  home: HouseIcon,
  info: InfoIcon,
  image: ImageSquareIcon,
  leaderboard: RankingIcon,
  assigned: UserCircleCheckIcon,
  more: DotsThreeIcon,
  offline: WifiSlashIcon,
  participants: UsersIcon,
  pending: ClockCountdownIcon,
  plus: PlusIcon,
  program: CalendarDotsIcon,
  profile: UserCircleIcon,
  progress: ChartLineUpIcon,
  qr: QrCodeIcon,
  rejected: XCircleIcon,
  reviewEvidence: ChecksIcon,
  search: MagnifyingGlassIcon,
  settings: GearSixIcon,
  star: StarIcon,
  stack: StackIcon,
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
