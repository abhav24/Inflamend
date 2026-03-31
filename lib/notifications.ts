import * as Notifications from 'expo-notifications';
import { Platform } from 'react-native';
import { Medication } from '../types';

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
    shouldShowBanner: true,
    shouldShowList: true,
  }),
});

export async function requestNotificationPermissions(): Promise<boolean> {
  if (Platform.OS === 'android') {
    await Notifications.setNotificationChannelAsync('medication-reminders', {
      name: 'Medication Reminders',
      importance: Notifications.AndroidImportance.HIGH,
      sound: 'default',
    });
  }
  const { status: existingStatus } = await Notifications.getPermissionsAsync();
  if (existingStatus === 'granted') return true;
  const { status } = await Notifications.requestPermissionsAsync();
  return status === 'granted';
}

export async function scheduleMedicationReminders(medications: Medication[]): Promise<void> {
  // Cancel all existing medication reminders before rescheduling
  await cancelAllMedicationReminders();

  for (const med of medications) {
    if (!med.is_active || !med.time_of_day?.length) continue;

    for (const timeStr of med.time_of_day) {
      const [hourStr, minuteStr] = timeStr.split(':');
      const hour = parseInt(hourStr, 10);
      const minute = parseInt(minuteStr ?? '0', 10);

      if (isNaN(hour) || isNaN(minute)) continue;

      await Notifications.scheduleNotificationAsync({
        identifier: `med-${med.id}-${hour}-${minute}`,
        content: {
          title: 'Medication Reminder',
          body: `Time to take ${med.name}${med.dosage ? ` (${med.dosage} ${med.dosage_unit ?? ''})` : ''}`,
          data: { medicationId: med.id, type: 'medication' },
          sound: 'default',
        },
        trigger: {
          type: Notifications.SchedulableTriggerInputTypes.DAILY,
          hour,
          minute,
        },
      });
    }
  }

  console.log(`Scheduled reminders for ${medications.length} medications`);
}

export async function cancelAllMedicationReminders(): Promise<void> {
  const scheduled = await Notifications.getAllScheduledNotificationsAsync();
  for (const notif of scheduled) {
    if (notif.identifier.startsWith('med-')) {
      await Notifications.cancelScheduledNotificationAsync(notif.identifier);
    }
  }
}

export function addNotificationResponseListener(
  handler: (response: Notifications.NotificationResponse) => void
) {
  return Notifications.addNotificationResponseReceivedListener(handler);
}
