import { Platform } from 'react-native';
import * as Haptics from 'expo-haptics';

async function run(fn: () => Promise<void>) {
  if (Platform.OS === 'web') return;
  try {
    await fn();
  } catch {
    // Ignore haptic failures on unsupported runtimes.
  }
}

export function selectionHaptic() {
  return run(() => Haptics.selectionAsync());
}

export function impactLightHaptic() {
  return run(() => Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light));
}

export function impactMediumHaptic() {
  return run(() => Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium));
}

export function successHaptic() {
  return run(() => Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success));
}
