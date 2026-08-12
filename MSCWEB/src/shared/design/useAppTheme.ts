import { useThemeContext, type AppColorScheme } from '@/shared/design/ThemeProvider';
import type { SemanticTokens } from '@/shared/design/tokens';

export function useAppTheme(): {
  colorScheme: AppColorScheme;
  colors: SemanticTokens;
} {
  const { colorScheme, colors } = useThemeContext();
  return { colorScheme, colors };
}
