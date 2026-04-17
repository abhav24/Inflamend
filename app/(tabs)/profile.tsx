import { useCallback, useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Modal,
  Platform,
  ScrollView,
  Switch,
  Text,
  View,
} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Print from 'expo-print';
import * as Sharing from 'expo-sharing';
import { format, subDays } from 'date-fns';
import { useRouter } from 'expo-router';
import { supabase } from '../../lib/supabase';
import { ENV } from '../../lib/env';
import {
  getHealthSyncDiagnostics,
  HealthSyncDiagnostic,
  requestAppleHealthPermissions,
  syncAppleHealthData,
} from '../../lib/healthSync';
import { useAuthStore } from '../../store/authStore';
import { DIAGNOSIS_LABELS } from '../../constants';
import { useColors } from '../../constants/colors';
import {
  AppCard,
  AppIcon,
  GlassSheet,
  GlassTextInput,
  PressScale,
  UserAvatar,
} from '../../components/ui/DesignPrimitives';
import { impactLightHaptic, selectionHaptic, successHaptic } from '../../lib/haptics';
import { getDemoCollection, getDemoProfile, setDemoProfile } from '../../lib/demoData';
import { Profile } from '../../types';

const NOTIF_MED_KEY = 'notif_medication_reminders';
const NOTIF_DAILY_KEY = 'notif_daily_log_reminder';

function SettingsRow({
  icon,
  fallback,
  tint,
  label,
  subtitle,
  onPress,
  right,
}: {
  icon: React.ComponentProps<typeof AppIcon>['symbol'];
  fallback: React.ComponentProps<typeof AppIcon>['fallback'];
  tint: string;
  label: string;
  subtitle?: string;
  onPress?: () => void;
  right?: React.ReactNode;
}) {
  const C = useColors();
  return (
    <PressScale
      haptic={Boolean(onPress)}
      onPress={onPress}
      style={{ marginBottom: 10 }}
    >
      <AppCard style={{ padding: 14 }} intensity={46}>
        <View style={{ flexDirection: 'row', alignItems: 'center' }}>
          <View style={{ width: 34, height: 34, borderRadius: 12, alignItems: 'center', justifyContent: 'center', backgroundColor: `${tint}20`, marginRight: 12 }}>
            <AppIcon symbol={icon} fallback={fallback} size={16} tintColor={tint} />
          </View>
          <View style={{ flex: 1 }}>
            <Text style={{ fontSize: 16, fontWeight: '600', color: C.textPrimary, letterSpacing: -0.24 }}>
              {label}
            </Text>
            {subtitle ? <Text style={{ marginTop: 2, fontSize: 13, color: C.textSecondary }}>{subtitle}</Text> : null}
          </View>
          {right ?? <AppIcon symbol="chevron.right" fallback="chevron-forward" size={15} tintColor={C.textMuted} />}
        </View>
      </AppCard>
    </PressScale>
  );
}

function SectionTitle({ title }: { title: string }) {
  const C = useColors();
  return (
    <Text style={{ marginHorizontal: 20, marginTop: 24, marginBottom: 10, fontSize: 12, fontWeight: '700', color: C.textMuted, textTransform: 'uppercase', letterSpacing: 0.32 }}>
      {title}
    </Text>
  );
}

function StatStrip({
  totalLogs,
  flareDays,
  medAdherence,
  loading,
}: {
  totalLogs: number | null;
  flareDays: number | null;
  medAdherence: string | null;
  loading: boolean;
}) {
  const C = useColors();
  const cells = [
    { label: 'Logs', value: loading ? '…' : totalLogs != null ? String(totalLogs) : '—', color: C.primary },
    { label: 'Flare Days', value: loading ? '…' : flareDays != null ? String(flareDays) : '—', color: C.danger },
    { label: 'Adherence', value: loading ? '…' : medAdherence ?? '—', color: C.success },
  ];
  return (
    <AppCard style={{ marginHorizontal: 20, paddingVertical: 8 }}>
      <View style={{ flexDirection: 'row' }}>
        {cells.map((cell, index) => (
          <View key={cell.label} style={{ flex: 1, alignItems: 'center', paddingVertical: 14, borderRightWidth: index < cells.length - 1 ? 1 : 0, borderRightColor: C.separator }}>
            <Text style={{ fontSize: 19, fontWeight: '800', color: cell.color, letterSpacing: -0.24 }}>
              {cell.value}
            </Text>
            <Text style={{ marginTop: 4, fontSize: 11, fontWeight: '600', color: C.textMuted, textTransform: 'uppercase', letterSpacing: 0.32 }}>
              {cell.label}
            </Text>
          </View>
        ))}
      </View>
    </AppCard>
  );
}

export default function ProfileScreen() {
  const router = useRouter();
  const C = useColors();
  const { profile, userId, setProfile } = useAuthStore();
  const [editVisible, setEditVisible] = useState(false);
  const [displayName, setDisplayName] = useState(profile?.display_name ?? '');
  const [savingName, setSavingName] = useState(false);
  const [tracksMenstrual, setTracksMenstrual] = useState(profile?.tracks_menstrual_cycle ?? false);
  const [savingMenstrual, setSavingMenstrual] = useState(false);
  const [medReminders, setMedReminders] = useState(false);
  const [dailyReminder, setDailyReminder] = useState(false);
  const [totalLogs, setTotalLogs] = useState<number | null>(null);
  const [flareDays, setFlareDays] = useState<number | null>(null);
  const [medAdherence, setMedAdherence] = useState<string | null>(null);
  const [statsLoading, setStatsLoading] = useState(true);
  const [exportLoading, setExportLoading] = useState(false);
  const [healthBusy, setHealthBusy] = useState(false);
  const [healthStatus, setHealthStatus] = useState<string | null>(null);
  const [healthDiagnostics, setHealthDiagnostics] = useState<HealthSyncDiagnostic[]>([]);

  useEffect(() => {
    AsyncStorage.multiGet([NOTIF_MED_KEY, NOTIF_DAILY_KEY]).then((entries) => {
      setMedReminders(entries[0]?.[1] === 'true');
      setDailyReminder(entries[1]?.[1] === 'true');
    });
  }, []);

  useEffect(() => {
    setDisplayName(profile?.display_name ?? '');
    setTracksMenstrual(profile?.tracks_menstrual_cycle ?? false);
  }, [profile]);

  const loadHealthDiagnostics = useCallback(async () => {
    if (!userId || ENV.DEMO_MODE) {
      setHealthDiagnostics([]);
      return;
    }
    try {
      setHealthDiagnostics(await getHealthSyncDiagnostics(userId));
    } catch (error) {
      console.error('loadHealthDiagnostics', error);
    }
  }, [userId]);

  useEffect(() => {
    loadHealthDiagnostics();
  }, [loadHealthDiagnostics]);

  const loadStats = useCallback(async () => {
    if (!userId) {
      setStatsLoading(false);
      return;
    }
    setStatsLoading(true);
    try {
      if (ENV.DEMO_MODE) {
        const [symptoms, bowels, foods, meds] = await Promise.all([
          getDemoCollection('symptom_logs'),
          getDemoCollection('bowel_logs'),
          getDemoCollection('food_logs'),
          getDemoCollection('medication_logs'),
        ]);
        setTotalLogs(symptoms.length + bowels.length + foods.length + meds.length);
        setFlareDays(symptoms.filter((item) => item.is_flare).length);
        setMedAdherence(meds.length > 0 ? `${Math.round((meds.filter((item) => item.was_taken).length / meds.length) * 100)}%` : '—');
      } else {
        const from = subDays(new Date(), 29).toISOString();
        const [{ data: symptoms }, { data: bowels }, { data: foods }, { data: meds }] = await Promise.all([
          supabase.from('symptom_logs').select('is_flare').eq('user_id', userId).gte('logged_at', from),
          supabase.from('bowel_logs').select('id').eq('user_id', userId).gte('logged_at', from),
          supabase.from('food_logs').select('id').eq('user_id', userId).gte('logged_at', from),
          supabase.from('medication_logs').select('was_taken').eq('user_id', userId).gte('created_at', from),
        ]);
        const symptomRows = symptoms ?? [];
        const bowelRows = bowels ?? [];
        const foodRows = foods ?? [];
        const medRows = meds ?? [];
        setTotalLogs(symptomRows.length + bowelRows.length + foodRows.length + medRows.length);
        setFlareDays(symptomRows.filter((item: any) => item.is_flare).length);
        setMedAdherence(medRows.length > 0 ? `${Math.round((medRows.filter((item: any) => item.was_taken).length / medRows.length) * 100)}%` : '—');
      }
    } catch {
      setTotalLogs(null);
      setFlareDays(null);
      setMedAdherence(null);
    } finally {
      setStatsLoading(false);
    }
  }, [userId]);

  useEffect(() => {
    loadStats();
  }, [loadStats]);

  const saveDisplayName = useCallback(async () => {
    if (!displayName.trim()) {
      Alert.alert('Missing Name', 'Enter your name first.');
      return;
    }
    setSavingName(true);

    if (ENV.DEMO_MODE) {
      const fallbackProfile: Profile = {
        id: 'demo-local-profile',
        display_name: displayName.trim(),
        date_of_birth: null,
        diagnosis_type: profile?.diagnosis_type ?? null,
        diagnosis_date: profile?.diagnosis_date ?? null,
        tracks_menstrual_cycle: tracksMenstrual,
        created_at: profile?.created_at ?? new Date().toISOString(),
        updated_at: new Date().toISOString(),
      };
      const nextProfile = { ...(await getDemoProfile(fallbackProfile)), ...fallbackProfile };
      await setDemoProfile(nextProfile);
      setProfile(nextProfile);
      setSavingName(false);
      setEditVisible(false);
      successHaptic();
      return;
    }

    if (!userId) return;
    const { data, error } = await supabase
      .from('profiles')
      .update({ display_name: displayName.trim(), updated_at: new Date().toISOString() })
      .eq('id', userId)
      .select()
      .single();
    setSavingName(false);

    if (error) {
      Alert.alert('Error', 'Could not save your name.');
      return;
    }

    setProfile(data as Profile);
    setEditVisible(false);
    successHaptic();
  }, [displayName, profile, setProfile, tracksMenstrual, userId]);

  const toggleMenstrual = useCallback(async (value: boolean) => {
    setTracksMenstrual(value);
    setSavingMenstrual(true);

    if (ENV.DEMO_MODE) {
      const nextProfile: Profile = {
        id: 'demo-local-profile',
        display_name: profile?.display_name ?? 'Bob',
        date_of_birth: profile?.date_of_birth ?? null,
        diagnosis_type: profile?.diagnosis_type ?? null,
        diagnosis_date: profile?.diagnosis_date ?? null,
        tracks_menstrual_cycle: value,
        created_at: profile?.created_at ?? new Date().toISOString(),
        updated_at: new Date().toISOString(),
      };
      await setDemoProfile(nextProfile);
      setProfile(nextProfile);
      setSavingMenstrual(false);
      return;
    }

    if (!userId) return;
    const { data, error } = await supabase
      .from('profiles')
      .update({ tracks_menstrual_cycle: value, updated_at: new Date().toISOString() })
      .eq('id', userId)
      .select()
      .single();
    setSavingMenstrual(false);

    if (error) {
      setTracksMenstrual(!value);
      Alert.alert('Error', 'Could not update your preference.');
      return;
    }

    setProfile(data as Profile);
  }, [profile, setProfile, userId]);

  const toggleStoredSwitch = useCallback(async (key: string, value: boolean, setter: (value: boolean) => void) => {
    setter(value);
    impactLightHaptic();
    await AsyncStorage.setItem(key, String(value));
  }, []);

  const handleExport = useCallback(async () => {
    setExportLoading(true);
    try {
      const diagnosisLabel = profile?.diagnosis_type
        ? DIAGNOSIS_LABELS[profile.diagnosis_type] ?? profile.diagnosis_type
        : 'Not set';

      let symptoms: any[] = [];
      let bowels: any[] = [];
      let foods: any[] = [];
      let meds: any[] = [];

      if (ENV.DEMO_MODE) {
        [symptoms, bowels, foods, meds] = await Promise.all([
          getDemoCollection('symptom_logs'),
          getDemoCollection('bowel_logs'),
          getDemoCollection('food_logs'),
          getDemoCollection('medication_logs'),
        ]);
      } else if (userId) {
        const to = new Date();
        const from = subDays(to, 29);
        const [{ data: symptomData }, { data: bowelData }, { data: foodData }, { data: medData }] = await Promise.all([
          supabase.from('symptom_logs').select('pain_level,fatigue_level,is_flare').eq('user_id', userId).gte('logged_at', from.toISOString()).lte('logged_at', to.toISOString()),
          supabase.from('bowel_logs').select('bristol_scale,blood_present').eq('user_id', userId).gte('logged_at', from.toISOString()).lte('logged_at', to.toISOString()),
          supabase.from('food_logs').select('description,is_trigger_food').eq('user_id', userId).gte('logged_at', from.toISOString()).lte('logged_at', to.toISOString()),
          supabase.from('medication_logs').select('was_taken,medication_name').eq('user_id', userId).gte('created_at', from.toISOString()).lte('created_at', to.toISOString()),
        ]);
        symptoms = symptomData ?? [];
        bowels = bowelData ?? [];
        foods = foodData ?? [];
        meds = medData ?? [];
      }

      const avgPain = symptoms.length > 0 ? (symptoms.reduce((sum, item) => sum + (item.pain_level ?? 0), 0) / symptoms.length).toFixed(1) : 'N/A';
      const medsTaken = meds.filter((item) => item.was_taken).length;
      const html = `<!DOCTYPE html><html><head><meta charset="utf-8"/><style>body{font-family:-apple-system,Helvetica,Arial,sans-serif;color:#12131A;padding:32px;max-width:680px;margin:0 auto}h1{color:#5A67F5;font-size:24px;margin-bottom:4px}.subtitle{color:#697284;font-size:14px;margin-bottom:24px}.row{display:flex;justify-content:space-between;padding:10px 0;border-bottom:1px solid #EEF1FF}.label{color:#697284;font-size:14px}.value{font-size:14px;font-weight:600}h2{margin-top:28px;font-size:16px}</style></head><body><h1>Inflamend Health Report</h1><p class="subtitle">Generated on ${format(new Date(), 'MMMM d, yyyy')}</p><h2>Profile</h2><div class="row"><span class="label">Name</span><span class="value">${profile?.display_name ?? 'Not set'}</span></div><div class="row"><span class="label">Diagnosis</span><span class="value">${diagnosisLabel}</span></div><h2>Last 30 Days</h2><div class="row"><span class="label">Symptom entries</span><span class="value">${symptoms.length}</span></div><div class="row"><span class="label">Average pain</span><span class="value">${avgPain}/10</span></div><div class="row"><span class="label">Flare days</span><span class="value">${symptoms.filter((item) => item.is_flare).length}</span></div><div class="row"><span class="label">Bowel entries</span><span class="value">${bowels.length}</span></div><div class="row"><span class="label">Trigger foods</span><span class="value">${foods.filter((item) => item.is_trigger_food).length}</span></div><div class="row"><span class="label">Medication logs</span><span class="value">${meds.length}</span></div><div class="row"><span class="label">Adherence</span><span class="value">${meds.length > 0 ? Math.round((medsTaken / meds.length) * 100) : 0}%</span></div></body></html>`;
      const { uri } = await Print.printToFileAsync({ html });
      if (await Sharing.isAvailableAsync()) {
        await Sharing.shareAsync(uri, {
          mimeType: 'application/pdf',
          dialogTitle: 'Share Inflamend Report',
        });
      } else {
        Alert.alert('Exported', uri);
      }
    } catch {
      Alert.alert('Export Failed', 'Could not generate the report.');
    } finally {
      setExportLoading(false);
    }
  }, [profile, userId]);

  const handleConnectHealth = useCallback(async () => {
    if (!userId || ENV.DEMO_MODE) {
      Alert.alert('Apple Health', 'Apple Health requires a connected account.');
      return;
    }
    setHealthBusy(true);
    try {
      const result = await requestAppleHealthPermissions(userId);
      setHealthStatus(result.message);
      if (!result.granted) Alert.alert('Apple Health', result.message);
    } finally {
      setHealthBusy(false);
      loadHealthDiagnostics();
    }
  }, [loadHealthDiagnostics, userId]);

  const handleSyncHealth = useCallback(async () => {
    if (!userId || ENV.DEMO_MODE) {
      Alert.alert('Apple Health', 'Apple Health requires a connected account.');
      return;
    }
    setHealthBusy(true);
    try {
      const result = await syncAppleHealthData(userId);
      setHealthStatus(result.message);
      Alert.alert('Apple Health Sync', result.message);
    } finally {
      setHealthBusy(false);
      loadHealthDiagnostics();
    }
  }, [loadHealthDiagnostics, userId]);

  const handleLogout = useCallback(() => {
    if (ENV.DEMO_MODE) {
      Alert.alert('Demo Mode', 'Sign out is unavailable while demo mode is enabled.');
      return;
    }
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
  }, [router]);

  const diagnosisLabel = profile?.diagnosis_type ? DIAGNOSIS_LABELS[profile.diagnosis_type] ?? profile.diagnosis_type : null;
  const metricLabel: Record<HealthSyncDiagnostic['metric'], string> = {
    steps: 'Steps',
    heart_rate: 'Heart Rate',
    sleep_hours: 'Sleep',
    active_energy_kcal: 'Active Energy',
  };

  return (
    <ScrollView style={{ flex: 1 }} contentContainerStyle={{ paddingBottom: 100 }} showsVerticalScrollIndicator={false}>
      <View style={{ paddingTop: Platform.OS === 'ios' ? 62 : 24, paddingHorizontal: 20 }}>
        <AppCard style={{ padding: 20, alignItems: 'center' }} intensity={56}>
          <UserAvatar name={profile?.display_name ?? 'U'} size={92} />
          <Text style={{ marginTop: 16, fontSize: 28, fontWeight: '800', color: C.textPrimary, letterSpacing: -0.5 }}>
            {profile?.display_name ?? 'Your Profile'}
          </Text>
          {diagnosisLabel ? (
            <Text style={{ marginTop: 6, fontSize: 14, fontWeight: '600', color: C.primary }}>
              {diagnosisLabel}
            </Text>
          ) : null}
          <PressScale
            onPress={() => {
              selectionHaptic();
              setEditVisible(true);
            }}
          >
            <View style={{ marginTop: 16, paddingHorizontal: 14, paddingVertical: 9, borderRadius: 18, backgroundColor: C.fillTertiary, borderWidth: 1, borderColor: C.glassBorder }}>
              <Text style={{ fontSize: 14, fontWeight: '600', color: C.primary }}>Edit Name</Text>
            </View>
          </PressScale>
        </AppCard>
      </View>

      <View style={{ marginTop: 18 }}>
        <StatStrip totalLogs={totalLogs} flareDays={flareDays} medAdherence={medAdherence} loading={statsLoading} />
      </View>

      <SectionTitle title="Tracking" />
      <View style={{ paddingHorizontal: 20 }}>
        <SettingsRow
          icon="calendar"
          fallback="calendar-outline"
          tint={C.primary}
          label="Menstrual Cycle"
          subtitle="Track alongside symptom changes"
          right={
            savingMenstrual ? (
              <ActivityIndicator size="small" color={C.primary} />
            ) : (
              <Switch
                value={tracksMenstrual}
                onValueChange={toggleMenstrual}
                trackColor={{ false: C.border, true: C.primary }}
              />
            )
          }
        />
      </View>

      <SectionTitle title="Notifications" />
      <View style={{ paddingHorizontal: 20 }}>
        <SettingsRow
          icon="bell.fill"
          fallback="notifications-outline"
          tint={C.warning}
          label="Medication Reminders"
          subtitle="Saved locally on this device"
          right={
            <Switch
              value={medReminders}
              onValueChange={(value) => toggleStoredSwitch(NOTIF_MED_KEY, value, setMedReminders)}
              trackColor={{ false: C.border, true: C.primary }}
            />
          }
        />
        <SettingsRow
          icon="alarm.fill"
          fallback="alarm-outline"
          tint={C.info}
          label="Daily Reminder"
          subtitle="Prompt yourself to log symptoms"
          right={
            <Switch
              value={dailyReminder}
              onValueChange={(value) => toggleStoredSwitch(NOTIF_DAILY_KEY, value, setDailyReminder)}
              trackColor={{ false: C.border, true: C.primary }}
            />
          }
        />
      </View>

      <SectionTitle title="Data" />
      <View style={{ paddingHorizontal: 20 }}>
        <SettingsRow
          icon="doc.text.fill"
          fallback="document-text-outline"
          tint={C.secondary}
          label="Export Health Report"
          subtitle="Generate a 30-day PDF summary"
          onPress={exportLoading ? undefined : handleExport}
          right={exportLoading ? <ActivityIndicator size="small" color={C.primary} /> : undefined}
        />
      </View>

      <SectionTitle title="Apple Health" />
      <View style={{ paddingHorizontal: 20 }}>
        <SettingsRow
          icon="heart.fill"
          fallback="heart-outline"
          tint={C.danger}
          label="Connect Apple Health"
          subtitle="Grant read access for synced metrics"
          onPress={healthBusy ? undefined : handleConnectHealth}
          right={healthBusy ? <ActivityIndicator size="small" color={C.primary} /> : undefined}
        />
        <SettingsRow
          icon="arrow.triangle.2.circlepath"
          fallback="sync-outline"
          tint={C.success}
          label="Sync Health Data"
          subtitle={healthStatus ?? 'Run a manual sync'}
          onPress={healthBusy ? undefined : handleSyncHealth}
        />
        {healthDiagnostics.length > 0 ? (
          <AppCard style={{ padding: 14, marginTop: 2 }} intensity={42}>
            {healthDiagnostics.map((diagnostic) => {
              const tone = diagnostic.lastStatus === 'success' ? C.success : diagnostic.lastStatus === 'error' ? C.danger : diagnostic.lastStatus === 'syncing' ? C.warning : C.textSecondary;
              return (
                <View key={diagnostic.metric} style={{ flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 5 }}>
                  <Text style={{ fontSize: 13, fontWeight: '600', color: C.textPrimary }}>
                    {metricLabel[diagnostic.metric]}
                  </Text>
                  <Text style={{ fontSize: 12, fontWeight: '700', color: tone }}>
                    {diagnostic.lastStatus.toUpperCase()}
                  </Text>
                </View>
              );
            })}
          </AppCard>
        ) : null}
      </View>

      <SectionTitle title="Account" />
      <View style={{ paddingHorizontal: 20 }}>
        <SettingsRow
          icon="lock.fill"
          fallback="lock-closed-outline"
          tint={C.info}
          label="Change Password"
          subtitle="Use Forgot Password on the sign-in screen"
          onPress={() => Alert.alert('Change Password', 'Use the Forgot Password flow on the login screen.')}
        />
        <SettingsRow
          icon="hand.raised.fill"
          fallback="shield-checkmark-outline"
          tint={C.primary}
          label="Privacy Policy"
          subtitle="In-app policy copy is still pending"
          onPress={() => Alert.alert('Privacy Policy', 'Policy copy is not bundled yet.')}
        />
        <SettingsRow
          icon="doc.plaintext"
          fallback="document-outline"
          tint={C.textMuted}
          label="Terms of Service"
          subtitle="In-app terms copy is still pending"
          onPress={() => Alert.alert('Terms of Service', 'Terms copy is not bundled yet.')}
        />
      </View>

      <View style={{ paddingHorizontal: 20, marginTop: 24 }}>
        <PressScale onPress={handleLogout}>
          <AppCard style={{ padding: 16, alignItems: 'center', backgroundColor: `${C.danger}18` }} intensity={44}>
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
              <AppIcon symbol="rectangle.portrait.and.arrow.right" fallback="log-out-outline" size={18} tintColor={C.danger} />
              <Text style={{ fontSize: 16, fontWeight: '700', color: C.danger }}>Sign Out</Text>
            </View>
          </AppCard>
        </PressScale>
      </View>

      <Text style={{ marginTop: 20, textAlign: 'center', fontSize: 11, color: C.textMuted }}>
        Inflamend v1.0.0
      </Text>

      <Modal visible={editVisible} transparent animationType="fade" onRequestClose={() => setEditVisible(false)}>
        <View style={{ flex: 1, justifyContent: 'flex-end', backgroundColor: C.scrim, padding: 12 }}>
          <GlassSheet style={{ padding: 20 }}>
            <Text style={{ fontSize: 28, fontWeight: '800', color: C.textPrimary, letterSpacing: -0.5 }}>
              Edit Name
            </Text>
            <Text style={{ marginTop: 6, fontSize: 15, color: C.textSecondary }}>
              Update how your profile appears throughout the app.
            </Text>
            <View style={{ height: 16 }} />
            <GlassTextInput value={displayName} onChangeText={setDisplayName} placeholder="Your name" autoFocus />
            <View style={{ height: 14 }} />
            <PressScale disabled={savingName} onPress={saveDisplayName}>
              <AppCard style={{ padding: 14, alignItems: 'center', backgroundColor: `${C.primary}E6` }} intensity={60}>
                {savingName ? <ActivityIndicator size="small" color={C.onGradient} /> : <Text style={{ fontSize: 16, fontWeight: '700', color: C.onGradient }}>Save</Text>}
              </AppCard>
            </PressScale>
            <View style={{ height: 10 }} />
            <PressScale onPress={() => setEditVisible(false)}>
              <AppCard style={{ padding: 14, alignItems: 'center' }} intensity={44}>
                <Text style={{ fontSize: 15, fontWeight: '600', color: C.textSecondary }}>Cancel</Text>
              </AppCard>
            </PressScale>
          </GlassSheet>
        </View>
      </Modal>
    </ScrollView>
  );
}
