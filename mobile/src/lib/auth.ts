import * as AppleAuthentication from 'expo-apple-authentication';
import * as Crypto from 'expo-crypto';
import { GoogleSignin, isErrorWithCode } from '@react-native-google-signin/google-signin';

import { supabase } from '@/lib/supabase';

export type SignInResult = { status: 'ok' } | { status: 'cancelled' } | { status: 'error'; message: string };

const googleIosClientId = process.env.EXPO_PUBLIC_GOOGLE_IOS_CLIENT_ID;
const googleWebClientId = process.env.EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID;

let googleConfigured = false;

function configureGoogleSignInOnce() {
  if (googleConfigured) return;
  GoogleSignin.configure({
    iosClientId: googleIosClientId || undefined,
    webClientId: googleWebClientId,
  });
  googleConfigured = true;
}

export async function signInWithApple(): Promise<SignInResult> {
  try {
    // Replay protection: Apple embeds a hash of `nonce` in the identity
    // token; Supabase re-hashes the raw value we send it and compares.
    // https://openid.net/specs/openid-connect-core-1_0.html#CodeFlowSteps
    const rawNonce = Crypto.randomUUID();
    const hashedNonce = await Crypto.digestStringAsync(Crypto.CryptoDigestAlgorithm.SHA256, rawNonce, {
      encoding: Crypto.CryptoEncoding.HEX,
    });

    const credential = await AppleAuthentication.signInAsync({
      requestedScopes: [
        AppleAuthentication.AppleAuthenticationScope.FULL_NAME,
        AppleAuthentication.AppleAuthenticationScope.EMAIL,
      ],
      nonce: hashedNonce,
    });

    if (!credential.identityToken) {
      return { status: 'error', message: 'Apple sign-in did not return an identity token.' };
    }

    const { error } = await supabase.auth.signInWithIdToken({
      provider: 'apple',
      token: credential.identityToken,
      nonce: rawNonce,
    });

    if (error) {
      return { status: 'error', message: error.message };
    }

    if (credential.fullName?.givenName || credential.fullName?.familyName) {
      // Apple only shares the name on the very first sign-in — capture it now.
      await supabase.auth.updateUser({
        data: {
          given_name: credential.fullName.givenName,
          family_name: credential.fullName.familyName,
        },
      });
    }

    return { status: 'ok' };
  } catch (e) {
    if (e && typeof e === 'object' && 'code' in e && e.code === 'ERR_REQUEST_CANCELED') {
      return { status: 'cancelled' };
    }
    return { status: 'error', message: e instanceof Error ? e.message : 'Apple sign-in failed.' };
  }
}

export async function signInWithGoogle(): Promise<SignInResult> {
  if (!googleWebClientId) {
    return {
      status: 'error',
      message: 'Google sign-in is not configured yet. Ask the app owner to set up Google Cloud OAuth.',
    };
  }

  try {
    configureGoogleSignInOnce();
    await GoogleSignin.hasPlayServices();
    // No nonce here: unlike expo-apple-authentication, the open-source
    // @react-native-google-signin/google-signin's signIn() doesn't accept
    // one (its README lists custom nonce support as a paid-tier feature of
    // its sibling package). Matches Supabase's own documented example for
    // this library, which also omits it.
    const response = await GoogleSignin.signIn();

    if (response.type === 'cancelled') {
      return { status: 'cancelled' };
    }

    if (!response.data.idToken) {
      return { status: 'error', message: 'Google sign-in did not return an identity token.' };
    }

    const { error } = await supabase.auth.signInWithIdToken({
      provider: 'google',
      token: response.data.idToken,
    });

    if (error) {
      return { status: 'error', message: error.message };
    }

    return { status: 'ok' };
  } catch (e) {
    if (isErrorWithCode(e)) {
      return { status: 'error', message: e.message };
    }
    return { status: 'error', message: e instanceof Error ? e.message : 'Google sign-in failed.' };
  }
}
