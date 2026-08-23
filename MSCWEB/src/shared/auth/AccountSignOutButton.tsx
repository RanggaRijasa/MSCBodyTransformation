import { useState } from 'react';
import { StyleSheet, View } from 'react-native';

import { useAuth } from './AuthProvider';
import { primitiveTokens } from '@/shared/design/tokens';
import { Button, InlineMessage } from '@/shared/ui/primitives';

export function AccountSignOutButton() {
  const { signOut } = useAuth();
  const [isSigningOut, setIsSigningOut] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string>();

  async function handleSignOut() {
    setIsSigningOut(true);
    setErrorMessage(undefined);
    try {
      await signOut();
    } catch (error) {
      setIsSigningOut(false);
      setErrorMessage(error instanceof Error ? error.message : 'Tidak dapat keluar. Coba lagi.');
    }
  }

  return (
    <View style={styles.container}>
      {errorMessage ? <InlineMessage title="Tidak dapat keluar" message={errorMessage} tone="destructive" /> : null}
      <Button
        label="Keluar"
        tone="destructive"
        loading={isSigningOut}
        disabled={isSigningOut}
        onPress={() => void handleSignOut()}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { gap: primitiveTokens.space.small },
});
