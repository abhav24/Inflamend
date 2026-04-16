import { Redirect, Stack } from 'expo-router';
import { ENV } from '../../lib/env';

export default function AuthLayout() {
  if (ENV.DEMO_MODE) {
    return <Redirect href="/(tabs)/home" />;
  }

  return <Stack screenOptions={{ headerShown: false }} />;
}
