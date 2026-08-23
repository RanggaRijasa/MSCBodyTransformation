import { ActivityIndicator, Image, Pressable, StyleSheet, View } from 'react-native';

import { componentTokens, primitiveTokens } from '@/shared/design/tokens';

const googleButtonImage = { uri: '/images/sign-in-with-google-light-pill.png' } as const;

export function GoogleOAuthButton({
  loading,
  onPress,
}: {
  loading: boolean;
  onPress: () => void;
}) {
  return (
    <View style={styles.container}>
      <Pressable
        accessibilityLabel="Lanjutkan dengan Google"
        accessibilityRole="button"
        accessibilityState={{ busy: loading, disabled: loading }}
        disabled={loading}
        onPress={onPress}
        testID="google-login"
        style={({ hovered, pressed }) => [
          styles.pressable,
          { opacity: loading ? 0.6 : pressed ? 0.82 : hovered ? 0.92 : 1 },
        ]}
      >
        <Image
          accessibilityIgnoresInvertColors
          resizeMode="contain"
          source={googleButtonImage}
          style={styles.image}
        />
        {loading ? (
          <View pointerEvents="none" style={styles.loadingOverlay}>
            <ActivityIndicator color={primitiveTokens.color.black} />
          </View>
        ) : null}
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    minHeight: componentTokens.minimumTouchTarget,
    width: '100%',
  },
  pressable: {
    alignItems: 'center',
    borderRadius: primitiveTokens.radius.capsule,
    justifyContent: 'center',
    minHeight: componentTokens.minimumTouchTarget,
    minWidth: componentTokens.minimumTouchTarget,
  },
  image: {
    height: 48,
    width: 216,
  },
  loadingOverlay: {
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.84)',
    borderRadius: primitiveTokens.radius.capsule,
    bottom: 0,
    justifyContent: 'center',
    left: 0,
    position: 'absolute',
    right: 0,
    top: 0,
  },
});
