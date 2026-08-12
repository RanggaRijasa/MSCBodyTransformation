import { CalendarDotsIcon } from 'phosphor-react-native/src/icons/CalendarDots';
import { HouseIcon } from 'phosphor-react-native/src/icons/House';
import { UserCircleIcon } from 'phosphor-react-native/src/icons/UserCircle';
import type { ComponentProps } from 'react';
import { View } from 'react-native';

export type MSCIconName = 'home' | 'program' | 'profile';
export type MSCIconSize = 'small' | 'medium' | 'large';

type IconComponent = typeof HouseIcon;
type IconWeight = ComponentProps<IconComponent>['weight'];

const semanticIcons: Record<MSCIconName, IconComponent> = {
  home: HouseIcon,
  program: CalendarDotsIcon,
  profile: UserCircleIcon,
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
