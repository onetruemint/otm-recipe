import { act, create } from 'react-test-renderer';

import { signInWithGoogle } from '@/lib/auth';
import SignInScreen from '@/app/sign-in';

jest.mock('@/lib/auth', () => ({
  signInWithApple: jest.fn(),
  signInWithGoogle: jest.fn(),
}));

// jest.mock() factories can't reference out-of-scope variables (Jest hoists
// them above imports), so each mock requires `react` for JSX internally.
jest.mock('expo-apple-authentication', () => ({
  AppleAuthenticationButton: (props: Record<string, unknown>) =>
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    (require('react') as typeof import('react')).createElement('AppleAuthenticationButton', props),
  AppleAuthenticationButtonType: { SIGN_IN: 0 },
  AppleAuthenticationButtonStyle: { BLACK: 0 },
}));

jest.mock('@react-native-google-signin/google-signin', () => {
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const React = require('react') as typeof import('react');
  const GoogleSigninButton = (props: Record<string, unknown>) =>
    React.createElement('GoogleSigninButton', props);
  GoogleSigninButton.Size = { Wide: 0 };
  GoogleSigninButton.Color = { Dark: 'dark' };
  return { GoogleSigninButton };
});

describe('SignInScreen', () => {
  it('renders without crashing', () => {
    let renderer: ReturnType<typeof create>;
    act(() => {
      renderer = create(<SignInScreen />);
    });

    expect(renderer!.toJSON()).toBeTruthy();
  });

  it('shows an inline message instead of crashing when sign-in fails', async () => {
    jest.mocked(signInWithGoogle).mockResolvedValue({ status: 'error', message: 'Google sign-in is not configured yet.' });

    let renderer: ReturnType<typeof create>;
    act(() => {
      renderer = create(<SignInScreen />);
    });

    const googleButton = renderer!.root.findByProps({ testID: 'google-sign-in-button' });
    await act(async () => {
      await googleButton.props.onPress();
    });

    const errorText = renderer!.root.findByProps({ testID: 'sign-in-error' });
    expect(errorText.props.children).toBe('Google sign-in is not configured yet.');
  });
});
