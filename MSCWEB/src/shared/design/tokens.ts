export const primitiveTokens = {
  color: {
    red: '#D92D20',
    redPressed: '#B42318',
    yellow: '#F5C542',
    nearBlack: '#111111',
    white: '#FFFFFF',
  },
  space: {
    xxSmall: 4,
    xSmall: 8,
    small: 12,
    medium: 16,
    large: 24,
    xLarge: 32,
    xxLarge: 48,
  },
  radius: {
    small: 8,
    medium: 12,
    large: 16,
    prominent: 24,
    capsule: 999,
  },
  duration: {
    instant: 0,
    fast: 120,
    normal: 200,
    slow: 320,
  },
} as const;

export const lightSemanticTokens = {
  background: '#F7F7F8',
  secondaryBackground: '#FFFFFF',
  surface: '#FFFFFF',
  elevatedSurface: '#FFFFFF',
  primaryText: '#111111',
  secondaryText: '#5F6368',
  border: '#DADCE0',
  primaryAction: primitiveTokens.color.red,
  primaryActionPressed: primitiveTokens.color.redPressed,
  accent: primitiveTokens.color.yellow,
  focus: '#2457A6',
  success: '#18794E',
  warning: '#8A5A00',
  destructive: '#C62828',
} as const;

export const darkSemanticTokens = {
  background: '#0D0D0F',
  secondaryBackground: '#151517',
  surface: '#1C1C1E',
  elevatedSurface: '#242426',
  primaryText: '#F5F5F5',
  secondaryText: '#B0B0B5',
  border: '#3A3A3C',
  primaryAction: primitiveTokens.color.red,
  primaryActionPressed: primitiveTokens.color.redPressed,
  accent: primitiveTokens.color.yellow,
  focus: '#78A9FF',
  success: '#5ED39A',
  warning: '#FFD166',
  destructive: '#C62828',
} as const;

export const componentTokens = {
  minimumTouchTarget: 44,
  primaryButtonHeight: 50,
  compactGutter: 16,
  mediumGutter: 24,
  wideGutter: 32,
  navigationWidth: 220,
  contentMaxWidth: 960,
} as const;

export const breakpointTokens = {
  medium: 768,
  wide: 1_200,
} as const;

export type SemanticTokens = {
  [Key in keyof typeof lightSemanticTokens]: string;
};
