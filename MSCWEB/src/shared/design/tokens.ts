export const primitiveTokens = {
  color: {
    red: '#D71920',
    redPressed: '#A80F16',
    yellow: '#FFD400',
    nearBlack: '#090909',
    black: '#000000',
    white: '#FFFFFF',
    transparent: 'transparent',
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
  easing: {
    standard: 'cubic-bezier(0.2, 0, 0, 1)',
    emphasized: 'cubic-bezier(0.2, 0.8, 0.2, 1)',
  },
} as const;

export const lightSemanticTokens = {
  background: '#FFFFFF',
  secondaryBackground: '#F2F2F2',
  surface: '#FFFFFF',
  elevatedSurface: '#FFFFFF',
  primaryText: '#000000',
  secondaryText: '#3F3F46',
  border: '#A1A1AA',
  primaryAction: primitiveTokens.color.red,
  primaryActionPressed: primitiveTokens.color.redPressed,
  accent: primitiveTokens.color.yellow,
  focus: '#2457A6',
  success: '#18794E',
  warning: '#8A5A00',
  destructive: '#C62828',
  info: '#2457A6',
  overlay: 'rgba(17, 17, 17, 0.52)',
  disabled: '#71717A',
} as const;

export const darkSemanticTokens = {
  background: '#000000',
  secondaryBackground: '#121212',
  surface: '#1A1A1A',
  elevatedSurface: '#222222',
  primaryText: '#FFFFFF',
  secondaryText: '#D4D4D8',
  border: '#5A5A5A',
  primaryAction: primitiveTokens.color.red,
  primaryActionPressed: primitiveTokens.color.redPressed,
  accent: primitiveTokens.color.yellow,
  focus: '#78A9FF',
  success: '#5ED39A',
  warning: '#FFD166',
  destructive: '#C62828',
  info: '#78A9FF',
  overlay: 'rgba(0, 0, 0, 0.72)',
  disabled: '#8A8A8F',
} as const;

export const componentTokens = {
  minimumTouchTarget: 44,
  primaryButtonHeight: 50,
  inputHeight: 50,
  compactHeaderHeight: 64,
  compactTabBarHeight: 64,
  cardPadding: 24,
  compactGutter: 16,
  mediumGutter: 24,
  wideGutter: 32,
  navigationWidth: 220,
  contentMaxWidth: 960,
  landingMaxWidth: 1200,
  readingMaxWidth: 680,
} as const;

export const typographyTokens = {
  display: { fontSize: 52, lineHeight: 56, fontWeight: '800' as const },
  titleLarge: { fontSize: 36, lineHeight: 42, fontWeight: '800' as const },
  title: { fontSize: 28, lineHeight: 34, fontWeight: '700' as const },
  headline: { fontSize: 20, lineHeight: 26, fontWeight: '700' as const },
  body: { fontSize: 16, lineHeight: 24, fontWeight: '400' as const },
  bodyStrong: { fontSize: 16, lineHeight: 24, fontWeight: '700' as const },
  callout: { fontSize: 15, lineHeight: 22, fontWeight: '500' as const },
  label: { fontSize: 14, lineHeight: 20, fontWeight: '700' as const },
  caption: { fontSize: 12, lineHeight: 16, fontWeight: '500' as const },
  numericDisplay: {
    fontSize: 32,
    lineHeight: 38,
    fontWeight: '800' as const,
    fontVariant: ['tabular-nums'] as const,
  },
} as const;

export const breakpointTokens = {
  medium: 768,
  wide: 1_200,
} as const;

export type SemanticTokens = {
  [Key in keyof typeof lightSemanticTokens]: string;
};
