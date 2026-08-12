import { createContext, type PropsWithChildren, useContext, useMemo, useState } from 'react';
import { useColorScheme } from 'react-native';

import {
  darkSemanticTokens,
  lightSemanticTokens,
  type SemanticTokens,
} from './tokens';

export type AppColorScheme = 'light' | 'dark';

type ThemeContextValue = {
  colorScheme: AppColorScheme;
  colors: SemanticTokens;
  setColorScheme: (scheme: AppColorScheme | null) => void;
};

const ThemeContext = createContext<ThemeContextValue | null>(null);

export function ThemeProvider({ children }: PropsWithChildren) {
  const systemScheme = useColorScheme() === 'dark' ? 'dark' : 'light';
  const [override, setOverride] = useState<AppColorScheme | null>(null);
  const colorScheme = override ?? systemScheme;
  const value = useMemo<ThemeContextValue>(
    () => ({
      colorScheme,
      colors: colorScheme === 'dark' ? darkSemanticTokens : lightSemanticTokens,
      setColorScheme: setOverride,
    }),
    [colorScheme],
  );

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useThemeContext(): ThemeContextValue {
  const value = useContext(ThemeContext);
  if (value === null) {
    throw new Error('useThemeContext harus digunakan di dalam ThemeProvider.');
  }
  return value;
}
