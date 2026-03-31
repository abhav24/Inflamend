import { useEffect, useState, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  TextInput,
  Switch,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { useRouter } from 'expo-router';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Print from 'expo-print';
import * as Sharing from 'expo-sharing';
import { supabase } from '../../lib/supabase';
import { useAuthStore } from '../../store/authStore';
import { Profile } from '../../types';
import { DIAGNOSIS_LABELS } from '../../constants';
import { Colors } from '../../constants/colors';
import { format, subDays } from 'date-fns';

const NOTIF_MED_KEY = 'notif_medication_reminders';
const NOTIF_DAILY_KEY = 'notif_daily_log_reminder';

export default function ProfileScreen() {
  const router = useRouter();
  const { profile, userId, setProfile } = useAuthStore();

  const [editingName, setEditingName] = useState(false);
  const [displayName, setDisplayName] = useState(profile?.display_name ?? '');
  const [savingName, setSavingName] = useState(false);

  const [tracksMenstrual, setTracksMenstrual] = useState(
    profile?.tracks_menstrual_cycle ?? false
  );
  const [savingMenstrual, setSavingMenstrual] = useState(false);

  const [medReminders, setMedReminders] = useState(false);
  const [dailyReminder, setDailyReminder] = useState(false);

  const [exportLoading, setExportLoading] = useState(false);

  // Load notification prefs from AsyncStorage
  useEffect(() => {
    const loadNotifPrefs = async () => {
      try {
        const [med, daily] = await Promise.all([
          AsyncStorage.getItem(NOTIF_MED_KEY),
          AsyncStorage.getItem(NOTIF_DAILY_KEY),
        ]);
        setMedReminders(med === 'true');
        setDailyReminder(daily === 'true');
      } catch (e) {
        console.error('loadNotifPrefs', e);
      }
    };
    loadNotifPrefs();
  }, []);

  // Sync local state with profile changes
  useEffect(() => {
    if (profile) {
      setDisplayName(profile.display_name ?? '');
      setTracksMenstrual(profile.tracks_menstrual_cycle);
    }
  }, [profile]);

  const saveDisplayName = useCallback(async () => {
    if (!userId) return;
    const trimmed = displayName.trim();
    setSavingName(true);
    const { data, error } = await supabase
      .from('profiles')
      .update({ display_name: trimmed, updated_at: new Date().toISOString() })
      .eq('id', userId)
      .select()
      .single();
    setSavingName(false);
    if (error) {
      Alert.alert('Error', 'Could not save name. Please try again.');
      return;
    }
    setProfile(data as Profile);
    setEditingName(false);
  }, [userId, displayName, setProfile]);

  const toggleMenstrual = useCallback(async (value: boolean) => {
    if (!userId) return;
    setTracksMenstrual(value);
    setSavingMenstrual(true);
    const { data, error } = await supabase
      .from('profiles')
      .update({ tracks_menstrual_cycle: value, updated_at: new Date().toISOString() })
      .eq('id', userId)
      .select()
      .single();
    setSavingMenstrual(false);
    if (error) {
      setTracksMenstrual(!value);
      Alert.alert('Error', 'Could not update preference. Please try again.');
      return;
    }
    setProfile(data as Profile);
  }, [userId, setProfile]);

  const toggleMedReminders = useCallback(async (value: boolean) => {
    setMedReminders(value);
    await AsyncStorage.setItem(NOTIF_MED_KEY, String(value));
  }, []);

  const toggleDailyReminder = useCallback(async (value: boolean) => {
    setDailyReminder(value);
    await AsyncStorage.setItem(NOTIF_DAILY_KEY, String(value));
  }, []);

  const handleExport = useCallback(async () => {
    if (!userId || !profile) return;
    setExportLoading(true);
    try {
      const to = new Date();
      const from = subDays(to, 29);
      const fromStr = from.toISOString();
      const toStr = to.toISOString();
      const fromDate = format(from, 'MMM d, yyyy');
      const toDate = format(to, 'MMM d, yyyy');

      // Fetch summary data
      const [
        { data: symptomData },
        { data: bowelData },
        { data: foodData },
        { data: medData },
      ] = await Promise.all([
        supabase
          .from('symptom_logs')
          .select('pain_level, fatigue_level, is_flare')
          .eq('user_id', userId)
          .gte('logged_at', fromStr)
          .lte('logged_at', toStr),
        supabase
          .from('bowel_logs')
          .select('bristol_scale, blood_present')
          .eq('user_id', userId)
          .gte('logged_at', fromStr)
          .lte('logged_at', toStr),
        supabase
          .from('food_logs')
          .select('description, is_trigger_food')
          .eq('user_id', userId)
          .gte('logged_at', fromStr)
          .lte('logged_at', toStr),
        supabase
          .from('medication_logs')
          .select('was_taken, medication_name')
          .eq('user_id', userId)
          .gte('created_at', fromStr)
          .lte('created_at', toStr),
      ]);

      const symptoms = symptomData ?? [];
      const bowels = bowelData ?? [];
      const foods = foodData ?? [];
      const meds = medData ?? [];

      const avgPain =
        symptoms.length > 0
          ? (symptoms.reduce((s: number, l: any) => s + (l.pain_level ?? 0), 0) / symptoms.length).toFixed(1)
          : 'N/A';
      const flareDays = symptoms.filter((s: any) => s.is_flare).length;
      const bowelCount = bowels.length;
      const bloodInStool = bowels.filter((b: any) => b.blood_present).length;
      const triggerFoods = foods.filter((f: any) => f.is_trigger_food).length;
      const medsTaken = meds.filter((m: any) => m.was_taken).length;
      const medsTotal = meds.length;
      const diagnosisLabel =
        profile.diagnosis_type ? (DIAGNOSIS_LABELS[profile.diagnosis_type] ?? profile.diagnosis_type) : 'Not set';

      const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <style>
    body { font-family: -apple-system, Helvetica, Arial, sans-serif; color: #1A1A1A; padding: 32px; max-width: 700px; margin: 0 auto; }
    h1 { color: #4A90D9; font-size: 24px; margin-bottom: 4px; }
    .subtitle { color: #6B7280; font-size: 14px; margin-bottom: 24px; }
    h2 { font-size: 16px; color: #1A1A1A; border-bottom: 1px solid #E0E0E0; padding-bottom: 6px; margin-top: 28px; }
    .row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #F8F9FA; }
    .label { color: #6B7280; font-size: 14px; }
    .value { font-weight: 600; font-size: 14px; }
    .footer { margin-top: 40px; font-size: 11px; color: #9CA3AF; text-align: center; }
  </style>
</head>
<body>
  <h1>Inflamend Health Report</h1>
  <p class="subtitle">Generated on ${format(new Date(), 'MMMM d, yyyy')} &bull; ${fromDate} &ndash; ${toDate}</p>

  <h2>Patient Information</h2>
  <div class="row"><span class="label">Name</span><span class="value">${profile.display_name ?? 'Not set'}</span></div>
  <div class="row"><span class="label">Diagnosis</span><span class="value">${diagnosisLabel}</span></div>
  <div class="row"><span class="label">Diagnosis Date</span><span class="value">${profile.diagnosis_date ? format(new Date(profile.diagnosis_date), 'MMMM d, yyyy') : 'Not set'}</span></div>

  <h2>Symptom Summary (Last 30 Days)</h2>
  <div class="row"><span class="label">Symptom Entries</span><span class="value">${symptoms.length}</span></div>
  <div class="row"><span class="label">Average Pain Level</span><span class="value">${avgPain} / 10</span></div>
  <div class="row"><span class="label">Flare Days</span><span class="value">${flareDays}</span></div>

  <h2>Bowel Health (Last 30 Days)</h2>
  <div class="row"><span class="label">Total Bowel Movements</span><span class="value">${bowelCount}</span></div>
  <div class="row"><span class="label">Entries with Blood</span><span class="value">${bloodInStool}</span></div>

  <h2>Nutrition (Last 30 Days)</h2>
  <div class="row"><span class="label">Food Entries</span><span class="value">${foods.length}</span></div>
  <div class="row"><span class="label">Trigger Food Incidents</span><span class="value">${triggerFoods}</span></div>

  <h2>Medications (Last 30 Days)</h2>
  <div class="row"><span class="label">Doses Logged</span><span class="value">${medsTotal}</span></div>
  <div class="row"><span class="label">Doses Taken</span><span class="value">${medsTaken}</span></div>
  <div class="row"><span class="label">Adherence Rate</span><span class="value">${medsTotal > 0 ? Math.round((medsTaken / medsTotal) * 100) : 0}%</span></div>

  <p class="footer">This report was generated by Inflamend. It is not a substitute for professional medical advice. Always consult your healthcare provider.</p>
</body>
</html>
      `.trim();

      const { uri } = await Print.printToFileAsync({ html, base64: false });
      const canShare = await Sharing.isAvailableAsync();
      if (canShare) {
        await Sharing.shareAsync(uri, {
          mimeType: 'application/pdf',
          dialogTitle: 'Share Inflamend Report',
        });
      } else {
        Alert.alert('Exported', `Report saved to:\n${uri}`);
      }
    } catch (err: any) {
      console.error('export error', err);
      Alert.alert('Export Failed', 'Could not generate the report. Please try again.');
    } finally {
      setExportLoading(false);
    }
  }, [userId, profile]);

  const handleChangePassword = () => {
    Alert.alert(
      'Change Password',
      'To change your password, please use the "Forgot Password" flow on the login screen. Sign out and tap "Forgot Password" to receive a reset email.',
      [{ text: 'OK' }]
    );
  };

  const handlePrivacyPolicy = () => {
    Alert.alert('Privacy Policy', 'Coming soon.', [{ text: 'OK' }]);
  };

  const handleTerms = () => {
    Alert.alert('Terms of Service', 'Coming soon.', [{ text: 'OK' }]);
  };

  const handleLogout = async () => {
    Alert.alert('Sign Out', 'Are you sure you want to sign out?', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Sign Out',
        style: 'destructive',
        onPress: async () => {
          await supabase.auth.signOut();
          router.replace('/(auth)/login');
        },
      },
    ]);
  };

  const diagnosisLabel =
    profile?.diagnosis_type
      ? (DIAGNOSIS_LABELS[profile.diagnosis_type] ?? profile.diagnosis_type)
      : 'Not set';

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Profile</Text>
        <Text style={styles.headerSubtitle}>Manage your account and preferences</Text>
      </View>

      {/* User Info */}
      <Text style={styles.sectionLabel}>ACCOUNT</Text>
      <View style={styles.card}>
        <View style={styles.avatarRow}>
          <View style={styles.avatar}>
            <Text style={styles.avatarText}>
              {(profile?.display_name ?? 'U').charAt(0).toUpperCase()}
            </Text>
          </View>
          <View style={styles.avatarInfo}>
            {editingName ? (
              <View style={styles.nameEditRow}>
                <TextInput
                  style={styles.nameInput}
                  value={displayName}
                  onChangeText={setDisplayName}
                  placeholder="Your name"
                  placeholderTextColor={Colors.placeholder}
                  autoFocus
                  maxLength={50}
                />
                <TouchableOpacity
                  style={styles.saveNameButton}
                  onPress={saveDisplayName}
                  disabled={savingName}
                >
                  {savingName ? (
                    <ActivityIndicator size="small" color={Colors.white} />
                  ) : (
                    <Text style={styles.saveNameButtonText}>Save</Text>
                  )}
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.cancelNameButton}
                  onPress={() => {
                    setDisplayName(profile?.display_name ?? '');
                    setEditingName(false);
                  }}
                >
                  <Text style={styles.cancelNameButtonText}>Cancel</Text>
                </TouchableOpacity>
              </View>
            ) : (
              <View style={styles.nameRow}>
                <Text style={styles.userName}>{profile?.display_name || 'Add your name'}</Text>
                <TouchableOpacity onPress={() => setEditingName(true)} style={styles.editButton}>
                  <Text style={styles.editButtonText}>Edit</Text>
                </TouchableOpacity>
              </View>
            )}
            <Text style={styles.userDiagnosis}>{diagnosisLabel}</Text>
            {profile?.diagnosis_date && (
              <Text style={styles.userDate}>
                Since {format(new Date(profile.diagnosis_date), 'MMMM yyyy')}
              </Text>
            )}
          </View>
        </View>
      </View>

      {/* Tracking Preferences */}
      <Text style={styles.sectionLabel}>TRACKING PREFERENCES</Text>
      <View style={styles.card}>
        <View style={styles.settingRow}>
          <View style={styles.settingInfo}>
            <Text style={styles.settingTitle}>Menstrual Cycle Tracking</Text>
            <Text style={styles.settingSubtitle}>Track cycle alongside IBD symptoms</Text>
          </View>
          <Switch
            value={tracksMenstrual}
            onValueChange={toggleMenstrual}
            trackColor={{ false: Colors.border, true: Colors.primary }}
            thumbColor={Colors.white}
            disabled={savingMenstrual}
          />
        </View>
      </View>

      {/* Notification Settings */}
      <Text style={styles.sectionLabel}>NOTIFICATIONS</Text>
      <View style={styles.card}>
        <View style={styles.settingRow}>
          <View style={styles.settingInfo}>
            <Text style={styles.settingTitle}>Medication Reminders</Text>
            <Text style={styles.settingSubtitle}>Get reminded to take your medications</Text>
          </View>
          <Switch
            value={medReminders}
            onValueChange={toggleMedReminders}
            trackColor={{ false: Colors.border, true: Colors.primary }}
            thumbColor={Colors.white}
          />
        </View>
        <View style={[styles.settingRow, styles.settingRowLast]}>
          <View style={styles.settingInfo}>
            <Text style={styles.settingTitle}>Daily Log Reminder</Text>
            <Text style={styles.settingSubtitle}>Reminder to log your symptoms each day</Text>
          </View>
          <Switch
            value={dailyReminder}
            onValueChange={toggleDailyReminder}
            trackColor={{ false: Colors.border, true: Colors.primary }}
            thumbColor={Colors.white}
          />
        </View>
      </View>

      {/* Data Export */}
      <Text style={styles.sectionLabel}>DATA</Text>
      <View style={styles.card}>
        <TouchableOpacity
          style={styles.exportButton}
          onPress={handleExport}
          disabled={exportLoading}
          activeOpacity={0.8}
        >
          {exportLoading ? (
            <ActivityIndicator size="small" color={Colors.white} />
          ) : (
            <>
              <Text style={styles.exportButtonEmoji}>📄</Text>
              <Text style={styles.exportButtonText}>Export Report (PDF)</Text>
            </>
          )}
        </TouchableOpacity>
        <Text style={styles.exportHint}>
          Generates a 30-day summary report you can share with your healthcare provider.
        </Text>
      </View>

      {/* Account */}
      <Text style={styles.sectionLabel}>ACCOUNT SETTINGS</Text>
      <View style={styles.card}>
        <TouchableOpacity style={styles.linkRow} onPress={handleChangePassword} activeOpacity={0.7}>
          <Text style={styles.linkRowText}>Change Password</Text>
          <Text style={styles.linkRowChevron}>›</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.linkRow} onPress={handlePrivacyPolicy} activeOpacity={0.7}>
          <Text style={styles.linkRowText}>Privacy Policy</Text>
          <Text style={styles.linkRowChevron}>›</Text>
        </TouchableOpacity>
        <TouchableOpacity style={[styles.linkRow, styles.linkRowLast]} onPress={handleTerms} activeOpacity={0.7}>
          <Text style={styles.linkRowText}>Terms of Service</Text>
          <Text style={styles.linkRowChevron}>›</Text>
        </TouchableOpacity>
      </View>

      {/* Logout */}
      <TouchableOpacity style={styles.logoutButton} onPress={handleLogout} activeOpacity={0.8}>
        <Text style={styles.logoutButtonText}>Sign Out</Text>
      </TouchableOpacity>

      <Text style={styles.version}>Inflamend v1.0.0</Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  content: {
    paddingBottom: 48,
  },
  header: {
    backgroundColor: Colors.white,
    paddingTop: 56,
    paddingBottom: 16,
    paddingHorizontal: 20,
    borderBottomWidth: 1,
    borderBottomColor: Colors.border,
  },
  headerTitle: {
    fontSize: 22,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  headerSubtitle: {
    fontSize: 13,
    color: Colors.textSecondary,
    marginTop: 2,
  },
  sectionLabel: {
    fontSize: 11,
    fontWeight: '700',
    color: Colors.textMuted,
    letterSpacing: 0.8,
    marginTop: 24,
    marginBottom: 8,
    marginHorizontal: 20,
  },
  card: {
    backgroundColor: Colors.white,
    borderRadius: 14,
    marginHorizontal: 20,
    shadowColor: '#000',
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
    overflow: 'hidden',
  },
  avatarRow: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
  },
  avatar: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: Colors.primaryLight,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 14,
    flexShrink: 0,
  },
  avatarText: {
    fontSize: 22,
    fontWeight: '700',
    color: Colors.primary,
  },
  avatarInfo: {
    flex: 1,
  },
  nameRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 2,
  },
  userName: {
    fontSize: 18,
    fontWeight: '700',
    color: Colors.textPrimary,
    flex: 1,
  },
  editButton: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    backgroundColor: Colors.primaryLight,
    borderRadius: 8,
  },
  editButtonText: {
    fontSize: 12,
    color: Colors.primary,
    fontWeight: '600',
  },
  nameEditRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 2,
  },
  nameInput: {
    flex: 1,
    backgroundColor: Colors.background,
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 6,
    fontSize: 15,
    color: Colors.textPrimary,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  saveNameButton: {
    backgroundColor: Colors.primary,
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 6,
    minWidth: 52,
    alignItems: 'center',
  },
  saveNameButtonText: {
    color: Colors.white,
    fontWeight: '700',
    fontSize: 13,
  },
  cancelNameButton: {
    paddingHorizontal: 8,
    paddingVertical: 6,
  },
  cancelNameButtonText: {
    color: Colors.textSecondary,
    fontSize: 13,
  },
  userDiagnosis: {
    fontSize: 14,
    color: Colors.textSecondary,
    marginTop: 2,
  },
  userDate: {
    fontSize: 12,
    color: Colors.textMuted,
    marginTop: 2,
  },
  settingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderBottomWidth: 1,
    borderBottomColor: Colors.background,
  },
  settingRowLast: {
    borderBottomWidth: 0,
  },
  settingInfo: {
    flex: 1,
    marginRight: 12,
  },
  settingTitle: {
    fontSize: 15,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  settingSubtitle: {
    fontSize: 12,
    color: Colors.textSecondary,
    marginTop: 2,
  },
  exportButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.primary,
    margin: 16,
    borderRadius: 12,
    paddingVertical: 14,
    gap: 8,
  },
  exportButtonEmoji: {
    fontSize: 18,
  },
  exportButtonText: {
    color: Colors.white,
    fontWeight: '700',
    fontSize: 15,
  },
  exportHint: {
    fontSize: 12,
    color: Colors.textSecondary,
    textAlign: 'center',
    marginBottom: 16,
    marginHorizontal: 16,
  },
  linkRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 15,
    borderBottomWidth: 1,
    borderBottomColor: Colors.background,
  },
  linkRowLast: {
    borderBottomWidth: 0,
  },
  linkRowText: {
    flex: 1,
    fontSize: 15,
    color: Colors.textPrimary,
  },
  linkRowChevron: {
    fontSize: 20,
    color: Colors.textMuted,
  },
  logoutButton: {
    marginHorizontal: 20,
    marginTop: 24,
    backgroundColor: Colors.danger,
    borderRadius: 14,
    paddingVertical: 16,
    alignItems: 'center',
  },
  logoutButtonText: {
    color: Colors.white,
    fontSize: 16,
    fontWeight: '700',
  },
  version: {
    textAlign: 'center',
    fontSize: 12,
    color: Colors.textMuted,
    marginTop: 20,
  },
});
