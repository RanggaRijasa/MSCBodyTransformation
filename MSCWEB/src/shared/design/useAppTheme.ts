import { useColorScheme } from 'react-native';

import {
  darkSemanticTokens,
  lightSemanticTokens,
  type SemanticTokens,
} from '@/shared/design/tokens';

export type AppColorScheme = 'light' | 'dark';

export function useAppTheme(): {
  colorScheme: AppColorScheme;
  colors: SemanticTokens;
} {
  const colorScheme = useColorScheme() === 'dark' ? 'dark' : 'light';

  return {
    colorScheme,
    colors: colorScheme === 'dark' ? darkSemanticTokens : lightSemanticTokens,
  };
}
