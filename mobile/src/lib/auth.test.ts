jest.mock('@/lib/supabase', () => ({
  supabase: {
    auth: {
      signInWithIdToken: jest.fn(),
      updateUser: jest.fn(),
    },
  },
}));

jest.mock('expo-apple-authentication', () => ({
  signInAsync: jest.fn(),
  AppleAuthenticationScope: { FULL_NAME: 0, EMAIL: 1 },
}));

jest.mock('@react-native-google-signin/google-signin', () => ({
  GoogleSignin: {
    configure: jest.fn(),
    hasPlayServices: jest.fn(),
    signIn: jest.fn(),
  },
  isErrorWithCode: (e: unknown): e is { code: string; message: string } =>
    typeof e === 'object' && e !== null && 'code' in e,
}));

const ORIGINAL_ENV = process.env;

afterEach(() => {
  process.env = ORIGINAL_ENV;
});

/**
 * `@/lib/auth` reads its Google client ID env vars once, at module load
 * time, so each test needs its own fresh module registry to pick up a
 * different `process.env` and to get mock instances that actually match
 * what the freshly loaded `@/lib/auth` requires internally.
 */
function loadAuthModules(envOverrides: Record<string, string> = {}) {
  jest.resetModules();
  process.env = { ...ORIGINAL_ENV, ...envOverrides };

  return {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    AppleAuthentication: require('expo-apple-authentication') as typeof import('expo-apple-authentication'),
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    GoogleSignin: (require('@react-native-google-signin/google-signin') as typeof import('@react-native-google-signin/google-signin'))
      .GoogleSignin,
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    supabase: (require('@/lib/supabase') as typeof import('@/lib/supabase')).supabase,
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    ...(require('@/lib/auth') as typeof import('@/lib/auth')),
  };
}

describe('signInWithApple', () => {
  it('returns "cancelled" without an error message when the user dismisses the native sheet', async () => {
    const { AppleAuthentication, signInWithApple } = loadAuthModules();
    jest
      .mocked(AppleAuthentication.signInAsync)
      .mockRejectedValue(Object.assign(new Error('canceled'), { code: 'ERR_REQUEST_CANCELED' }));

    const result = await signInWithApple();

    expect(result).toEqual({ status: 'cancelled' });
  });

  it('signs in with Supabase using the Apple identity token', async () => {
    const { AppleAuthentication, supabase, signInWithApple } = loadAuthModules();
    jest.mocked(AppleAuthentication.signInAsync).mockResolvedValue({
      identityToken: 'apple-token',
      fullName: null,
    } as never);
    jest.mocked(supabase.auth.signInWithIdToken).mockResolvedValue({ error: null } as never);

    const result = await signInWithApple();

    expect(supabase.auth.signInWithIdToken).toHaveBeenCalledWith({
      provider: 'apple',
      token: 'apple-token',
    });
    expect(result).toEqual({ status: 'ok' });
  });
});

describe('signInWithGoogle', () => {
  it('fails gracefully with a "not configured" message and never calls the native SDK when no web client ID is set', async () => {
    const { GoogleSignin, signInWithGoogle } = loadAuthModules({ EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID: '' });

    const result = await signInWithGoogle();

    expect(result.status).toBe('error');
    expect(GoogleSignin.signIn).not.toHaveBeenCalled();
  });

  it('returns "cancelled" without an error message when the user dismisses the picker', async () => {
    const { GoogleSignin, signInWithGoogle } = loadAuthModules({
      EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID: 'web-client-id',
    });
    jest.mocked(GoogleSignin.hasPlayServices).mockResolvedValue(true);
    jest.mocked(GoogleSignin.signIn).mockResolvedValue({ type: 'cancelled', data: null });

    const result = await signInWithGoogle();

    expect(result).toEqual({ status: 'cancelled' });
  });

  it('signs in with Supabase using the Google ID token', async () => {
    const { GoogleSignin, supabase, signInWithGoogle } = loadAuthModules({
      EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID: 'web-client-id',
    });
    jest.mocked(GoogleSignin.hasPlayServices).mockResolvedValue(true);
    jest.mocked(GoogleSignin.signIn).mockResolvedValue({
      type: 'success',
      data: { idToken: 'google-token' },
    } as never);
    jest.mocked(supabase.auth.signInWithIdToken).mockResolvedValue({ error: null } as never);

    const result = await signInWithGoogle();

    expect(supabase.auth.signInWithIdToken).toHaveBeenCalledWith({
      provider: 'google',
      token: 'google-token',
    });
    expect(result).toEqual({ status: 'ok' });
  });
});
