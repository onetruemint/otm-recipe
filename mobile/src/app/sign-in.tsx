import * as AppleAuthentication from 'expo-apple-authentication';
import { GoogleSigninButton } from '@react-native-google-signin/google-signin';
import { useState } from 'react';
import { Platform, StyleSheet } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { ExternalLink } from '@/components/external-link';
import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { signInWithApple, signInWithGoogle } from '@/lib/auth';
import { MaxContentWidth, Spacing } from '@/constants/theme';

// Published by story 1.4; see docs/PROGRESS.md for the live-URL confirmation TODO.
const TERMS_URL = 'https://onetruemint.github.io/otm-recipe/terms.html';
const PRIVACY_URL = 'https://onetruemint.github.io/otm-recipe/privacy.html';

export default function SignInScreen() {
  const [error, setError] = useState<string | null>(null);
  const [isSigningIn, setIsSigningIn] = useState(false);

  async function handleApplePress() {
    setError(null);
    setIsSigningIn(true);
    try {
      const result = await signInWithApple();
      if (result.status === 'error') {
        setError(result.message);
      }
    } finally {
      setIsSigningIn(false);
    }
  }

  async function handleGooglePress() {
    setError(null);
    setIsSigningIn(true);
    try {
      const result = await signInWithGoogle();
      if (result.status === 'error') {
        setError(result.message);
      }
    } finally {
      setIsSigningIn(false);
    }
  }

  return (
    <ThemedView style={styles.container}>
      <SafeAreaView style={styles.safeArea}>
        <ThemedView style={styles.heroSection}>
          <ThemedText type="title" style={styles.title}>
            Sign in
          </ThemedText>
          <ThemedText type="default" themeColor="textSecondary" style={styles.subtitle}>
            Sign in to browse and share recipes.
          </ThemedText>
        </ThemedView>

        <ThemedView style={styles.buttons}>
          {Platform.OS === 'ios' && (
            <AppleAuthentication.AppleAuthenticationButton
              buttonType={AppleAuthentication.AppleAuthenticationButtonType.SIGN_IN}
              buttonStyle={AppleAuthentication.AppleAuthenticationButtonStyle.BLACK}
              cornerRadius={8}
              style={styles.appleButton}
              onPress={handleApplePress}
              testID="apple-sign-in-button"
            />
          )}

          <GoogleSigninButton
            size={GoogleSigninButton.Size.Wide}
            color={GoogleSigninButton.Color.Dark}
            style={styles.googleButton}
            onPress={handleGooglePress}
            disabled={isSigningIn}
            testID="google-sign-in-button"
          />

          {error && (
            <ThemedText type="small" themeColor="text" style={styles.error} testID="sign-in-error">
              {error}
            </ThemedText>
          )}
        </ThemedView>

        <ThemedText type="small" themeColor="textSecondary" style={styles.legal}>
          By signing in you agree to our{' '}
          <ExternalLink href={TERMS_URL}>
            <ThemedText type="link">Terms of Service</ThemedText>
          </ExternalLink>{' '}
          and{' '}
          <ExternalLink href={PRIVACY_URL}>
            <ThemedText type="link">Privacy Policy</ThemedText>
          </ExternalLink>
          .
        </ThemedText>
      </SafeAreaView>
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    flexDirection: 'row',
  },
  safeArea: {
    flex: 1,
    justifyContent: 'flex-end',
    paddingHorizontal: Spacing.four,
    alignItems: 'center',
    gap: Spacing.four,
    paddingBottom: Spacing.six,
    maxWidth: MaxContentWidth,
    alignSelf: 'center',
    width: '100%',
  },
  heroSection: {
    alignItems: 'center',
    justifyContent: 'flex-end',
    flex: 1,
    gap: Spacing.two,
  },
  title: {
    textAlign: 'center',
  },
  subtitle: {
    textAlign: 'center',
  },
  buttons: {
    alignSelf: 'stretch',
    gap: Spacing.three,
    alignItems: 'center',
  },
  appleButton: {
    width: '100%',
    height: 48,
  },
  googleButton: {
    width: '100%',
    height: 48,
  },
  error: {
    textAlign: 'center',
  },
  legal: {
    textAlign: 'center',
  },
});
