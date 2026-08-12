import '@/global.css';

import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { ThemeProvider } from '@/shared/design/ThemeProvider';
import { AppProviders } from '@/shared/AppProviders';

export default function RootLayout() {
  return (
    <SafeAreaProvider>
      <ThemeProvider>
        <AppProviders>
          <StatusBar style="auto" />
          <Stack screenOptions={{ headerShown: false }} />
        </AppProviders>
      </ThemeProvider>
    </SafeAreaProvider>
  );
}
