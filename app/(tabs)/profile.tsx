import { useEffect, useState, useCallback } from 'react';
import {
  View, Text, ScrollView, TouchableOpacity,
  TextInput, Switch, Alert, ActivityIndicator, Platform,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Print from 'expo-print';
import * as Sharing from 'expo-sharing';
import { supabase } from '../../lib/supabase';
import { ENV } from '../../lib/env';
import {
  getHealthSyncDiagnostics, HealthSyncDiagnostic,
  requestAppleHealthPermissions, syncAppleHealthData,
} from '../../lib/healthSync';
import { useAuthStore } from '../../store/authStore';
import { Profile } from '../../types';
import { DIAGNOSIS_LABELS } from '../../constants';
import { useColors } from '../../constants/colors';
import { format, subDays } from 'date-fns';
import { UserAvatar } from '../../components/ui/DesignPrimitives';

const NOTIF_MED_KEY   = 'notif_medication_reminders';
const NOTIF_DAILY_KEY = 'notif_daily_log_reminder';

type IoniconName = React.ComponentProps<typeof Ionicons>['name'];

// ─── Settings Row — Apple Settings style ──────────────────────────────────────
// Solid-color rounded square badge (white icon) + label + optional right element

function SettingsRow({
  icon,
  iconBg,
  label,
  subtitle,
  onPress,
  right,
  isLast = false,
}: {
  icon: IoniconName;
  iconBg: string;
  label: string;
  subtitle?: string;
  onPress?: () => void;
  right?: React.ReactNode;
  isLast?: boolean;
}) {
  const C = useColors();
  return (
    <TouchableOpacity
      style={{
        flexDirection: 'row', alignItems: 'center',
        paddingHorizontal: 16, paddingVertical: 12,
        borderBottomWidth: isLast ? 0 : 0.5,
        borderBottomColor: C.separator,
      }}
      onPress={onPress}
      activeOpacity={onPress ? 0.6 : 1}
      disabled={!onPress && !right}
    >
      {/* Solid-color icon badge */}
      <View style={{
        width: 30, height: 30, borderRadius: 7,
        backgroundColor: iconBg,
        alignItems: 'center', justifyContent: 'center', marginRight: 14, flexShrink: 0,
      }}>
        <Ionicons name={icon} size={15} color="#FFFFFF" />
      </View>

      <View style={{ flex: 1 }}>
        <Text style={{ fontSize: 15, fontWeight: '400', color: C.textPrimary }}>{label}</Text>
        {subtitle ? (
          <Text style={{ fontSize: 12, color: C.textMuted, marginTop: 1 }}>{subtitle}</Text>
        ) : null}
      </View>

      {right ?? (
        onPress ? (
          <Ionicons name="chevron-forward" size={15} color={C.textMuted} />
        ) : null
      )}
    </TouchableOpacity>
  );
}

// ─── Settings Section ─────────────────────────────────────────────────────────

function SettingsSection({ title, children }: { title: string; children: React.ReactNode }) {
  const C = useColors();
  return (
    <View style={{ marginTop: 28, marginHorizontal: 20 }}>
      <Text style={{
        fontSize: 12, fontWeight: '600', color: C.textMuted,
        letterSpacing: 0.6, textTransform: 'uppercase', marginBottom: 8,
      }}>
        {title}
      </Text>
      <View style={{
        backgroundColor: C.surface, borderRadius: 16, overflow: 'hidden',
        shadowColor: '#000',
        shadowOpacity: C.background === '#000000' ? 0 : 0.05,
        shadowRadius: 8, shadowOffset: { width: 0, height: 1 },
        elevation: 2,
      }}>
        {children}
      </View>
    </View>
  );
}

// ─── 30-Day Stats Strip ───────────────────────────────────────────────────────

function ProfileStatsStrip({
  totalLogs, flareDays, medAdherence, loading,
}: {
  totalLogs: number | null; flareDays: number | null;
  medAdherence: string | null; loading: boolean;
}) {
  const C = useColors();
  const cells = [
    { label: 'Logs (30d)', value: loading ? '…' : totalLogs != null ? String(totalLogs) : '—', color: C.primary },
    { label: 'Flare Days', value: loading ? '…' : flareDays != null ? String(flareDays) : '—', color: C.danger },
    { label: 'Med Adherence', value: loading ? '…' : medAdherence ?? '—', color: C.success },
  ];
  return (
    <View style={{
      flexDirection: 'row',
      backgroundColor: C.surface,
      borderRadius: 20,
      marginHorizontal: 20, marginTop: 20, marginBottom: 4,
      shadowColor: '#000',
      shadowOpacity: C.background === '#000000' ? 0 : 0.05,
      shadowRadius: 10, shadowOffset: { width: 0, height: 2 }, elevation: 3,
      overflow: 'hidden',
    }}>
      {cells.map((cell, i) => (
        <View key={cell.label} style={{
          flex: 1, alignItems: 'center', paddingVertical: 16,
          borderRightWidth: i < cells.length - 1 ? 0.5 : 0,
          borderRightColor: C.separator,
        }}>
          <Text style={{ fontSize: 18, fontWeight: '800', color: cell.color, marginBottom: 3 }}>
            {cell.value}
          </Text>
          <Text style={{
            fontSize: 10, color: C.textMuted, fontWeight: '600',
            textTransform: 'uppercase', letterSpacing: 0.3, textAlign: 'center',
          }}>
            {cell.label}
          </Text>
        </View>
      ))}
    </View>
  );
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

export default function ProfileScreen() {
  const router = useRouter();
  const { profile, userId, setProfile } = useAuthStore();
  const C = useColors();

  const [editingName, setEditingName]   = useState(false);
  const [displayName, setDisplayName]   = useState(profile?.display_name ?? '');
  const [savingName, setSavingName]     = useState(false);

  const [tracksMenstrual, setTracksMenstrual] = useState(profile?.tracks_menstrual_cycle ?? false);
  const [savingMenstrual, setSavingMenstrual] = useState(false);

  const [medReminders, setMedReminders]   = useState(false);
  const [dailyReminder, setDailyReminder] = useState(false);

  const [totalLogs, setTotalLogs]         = useState<number | null>(null);
  const [flareDays, setFlareDays]         = useState<number | null>(null);
  const [medAdherence, setMedAdherence]   = useState<string | null>(null);
  const [statsLoading, setStatsLoading]   = useState(true);

  const [exportLoading, setExportLoading] = useState(false);
  const [healthBusy, setHealthBusy]       = useState(false);
  const [healthStatus, setHealthStatus]   = useState<string | null>(null);
  const [healthDiagnostics, setHealthDiagnostics] = useState<HealthSyncDiagnostic[]>([]);

  useEffect(() => {
    AsyncStorage.multiGet([NOTIF_MED_KEY, NOTIF_DAILY_KEY]).then(([[, med], [, daily]]) => {
      setMedReminders(med === 'true');
      setDailyReminder(daily === 'true');
    });
  }, []);

  useEffect(() => {
    if (profile) {
      setDisplayName(profile.display_name ?? '');
      setTracksMenstrual(profile.tracks_menstrual_cycle);
    }
  }, [profile]);

  const loadHealthDiagnostics = useCallback(async () => {
    if (!userId) { setHealthDiagnostics([]); return; }
    try { setHealthDiagnostics(await getHealthSyncDiagnostics(userId)); }
    catch (e) { console.error('loadHealthDiagnostics', e); }
  }, [userId]);

  useEffect(() => { loadHealthDiagnostics(); }, [loadHealthDiagnostics]);

  const loadStats = useCallback(async () => {
    if (!userId) { setStatsLoading(false); return; }
    try {
      const from = subDays(new Date(), 29).toISOString();
      const [{ data: sd }, { data: bd }, { data: fd }, { data: md }] = await Promise.all([
        supabase.from('symptom_logs').select('is_flare').eq('user_id', userId).gte('logged_at', from),
        supabase.from('bowel_logs').select('id').eq('user_id', userId).gte('logged_at', from),
        supabase.from('food_logs').select('id').eq('user_id', userId).gte('logged_at', from),
        supabase.from('medication_logs').select('was_taken').eq('user_id', userId).gte('created_at', from),
      ]);
      const symptoms = sd ?? []; const bowels = bd ?? []; const foods = fd ?? []; const meds = md ?? [];
      setTotalLogs(symptoms.length + bowels.length + foods.length + meds.length);
      setFlareDays(symptoms.filter((s: any) => s.is_flare).length);
      if (meds.length > 0) {
        const pct = Math.round((meds.filter((m: any) => m.was_taken).length / meds.length) * 100);
        setMedAdherence(`${pct}%`);
      } else {
        setMedAdherence('—');
      }
    } catch {
      setTotalLogs(null); setFlareDays(null); setMedAdherence(null);
    } finally {
      setStatsLoading(false);
    }
  }, [userId]);

  useEffect(() => { loadStats(); }, [loadStats]);

  const saveDisplayName = useCallback(async () => {
    if (!userId) return;
    setSavingName(true);
    const { data, error } = await supabase
      .from('profiles')
      .update({ display_name: displayName.trim(), updated_at: new Date().toISOString() })
      .eq('id', userId).select().single();
    setSavingName(false);
    if (error) { Alert.alert('Error', 'Could not save name.'); return; }
    setProfile(data as Profile); setEditingName(false);
  }, [userId, displayName, setProfile]);

  const toggleMenstrual = useCallback(async (value: boolean) => {
    if (!userId) return;
    setTracksMenstrual(value); setSavingMenstrual(true);
    const { data, error } = await supabase
      .from('profiles')
      .update({ tracks_menstrual_cycle: value, updated_at: new Date().toISOString() })
      .eq('id', userId).select().single();
    setSavingMenstrual(false);
    if (error) { setTracksMenstrual(!value); Alert.alert('Error', 'Could not update preference.'); return; }
    setProfile(data as Profile);
  }, [userId, setProfile]);

  const toggleMedReminders  = useCallback(async (v: boolean) => {
    setMedReminders(v);  await AsyncStorage.setItem(NOTIF_MED_KEY, String(v));
  }, []);
  const toggleDailyReminder = useCallback(async (v: boolean) => {
    setDailyReminder(v); await AsyncStorage.setItem(NOTIF_DAILY_KEY, String(v));
  }, []);

  const handleExport = useCallback(async () => {
    if (!userId || !profile) return;
    setExportLoading(true);
    try {
      const to = new Date(); const from = subDays(to, 29);
      const [{ data: sd }, { data: bd }, { data: fd }, { data: md }] = await Promise.all([
        supabase.from('symptom_logs').select('pain_level,fatigue_level,is_flare').eq('user_id', userId).gte('logged_at', from.toISOString()).lte('logged_at', to.toISOString()),
        supabase.from('bowel_logs').select('bristol_scale,blood_present').eq('user_id', userId).gte('logged_at', from.toISOString()).lte('logged_at', to.toISOString()),
        supabase.from('food_logs').select('description,is_trigger_food').eq('user_id', userId).gte('logged_at', from.toISOString()).lte('logged_at', to.toISOString()),
        supabase.from('medication_logs').select('was_taken,medication_name').eq('user_id', userId).gte('created_at', from.toISOString()).lte('created_at', to.toISOString()),
      ]);
      const symptoms = sd ?? []; const bowels = bd ?? []; const foods = fd ?? []; const meds = md ?? [];
      const avgPain = symptoms.length > 0
        ? (symptoms.reduce((s: number, l: any) => s + (l.pain_level ?? 0), 0) / symptoms.length).toFixed(1)
        : 'N/A';
      const flareDays = symptoms.filter((s: any) => s.is_flare).length;
      const medsTaken = meds.filter((m: any) => m.was_taken).length;
      const diagnosisLabel = profile.diagnosis_type
        ? (DIAGNOSIS_LABELS[profile.diagnosis_type] ?? profile.diagnosis_type)
        : 'Not set';

      const html = `<!DOCTYPE html><html><head><meta charset="utf-8"/><style>body{font-family:-apple-system,Helvetica,Arial,sans-serif;color:#1A1A1A;padding:32px;max-width:700px;margin:0 auto}h1{color:#6366F1;font-size:24px;margin-bottom:4px}.subtitle{color:#6B7280;font-size:14px;margin-bottom:24px}h2{font-size:16px;color:#1A1A1A;border-bottom:1px solid #E0E0E0;padding-bottom:6px;margin-top:28px}.row{display:flex;justify-content:space-between;padding:8px 0;border-bottom:1px solid #F8F9FA}.label{color:#6B7280;font-size:14px}.value{font-weight:600;font-size:14px}.footer{margin-top:40px;font-size:11px;color:#9CA3AF;text-align:center}</style></head><body><h1>Inflamend Health Report</h1><p class="subtitle">Generated on ${format(new Date(), 'MMMM d, yyyy')} &bull; ${format(from, 'MMM d, yyyy')} &ndash; ${format(to, 'MMM d, yyyy')}</p><h2>Patient</h2><div class="row"><span class="label">Name</span><span class="value">${profile.display_name ?? 'Not set'}</span></div><div class="row"><span class="label">Diagnosis</span><span class="value">${diagnosisLabel}</span></div><h2>Symptoms (30 days)</h2><div class="row"><span class="label">Entries</span><span class="value">${symptoms.length}</span></div><div class="row"><span class="label">Average Pain</span><span class="value">${avgPain} / 10</span></div><div class="row"><span class="label">Flare Days</span><span class="value">${flareDays}</span></div><h2>Bowel (30 days)</h2><div class="row"><span class="label">Movements</span><span class="value">${bowels.length}</span></div><div class="row"><span class="label">With Blood</span><span class="value">${bowels.filter((b: any) => b.blood_present).length}</span></div><h2>Nutrition (30 days)</h2><div class="row"><span class="label">Food Entries</span><span class="value">${foods.length}</span></div><div class="row"><span class="label">Trigger Foods</span><span class="value">${foods.filter((f: any) => f.is_trigger_food).length}</span></div><h2>Medications (30 days)</h2><div class="row"><span class="label">Doses Logged</span><span class="value">${meds.length}</span></div><div class="row"><span class="label">Doses Taken</span><span class="value">${medsTaken}</span></div><div class="row"><span class="label">Adherence</span><span class="value">${meds.length > 0 ? Math.round((medsTaken / meds.length) * 100) : 0}%</span></div><p class="footer">Generated by Inflamend. Not a substitute for professional medical advice.</p></body></html>`.trim();

      const { uri } = await Print.printToFileAsync({ html, base64: false });
      if (await Sharing.isAvailableAsync()) {
        await Sharing.shareAsync(uri, { mimeType: 'application/pdf', dialogTitle: 'Share Inflamend Report' });
      } else {
        Alert.alert('Exported', `Report saved to:\n${uri}`);
      }
    } catch {
      Alert.alert('Export Failed', 'Could not generate the report. Please try again.');
    } finally {
      setExportLoading(false);
    }
  }, [userId, profile]);

  const handleConnectAppleHealth = useCallback(async () => {
    if (!userId) return;
    setHealthBusy(true);
    try {
      const result = await requestAppleHealthPermissions(userId);
      setHealthStatus(result.message);
      if (!result.granted) Alert.alert('Apple Health', result.message);
    } catch {
      const msg = 'Failed to connect Apple Health.';
      setHealthStatus(msg); Alert.alert('Apple Health', msg);
    } finally {
      setHealthBusy(false); loadHealthDiagnostics();
    }
  }, [userId, loadHealthDiagnostics]);

  const handleSyncAppleHealth = useCallback(async () => {
    if (!userId) return;
    setHealthBusy(true);
    try {
      const result = await syncAppleHealthData(userId);
      setHealthStatus(result.message); Alert.alert('Apple Health Sync', result.message);
    } catch {
      const msg = 'Health sync failed.';
      setHealthStatus(msg); Alert.alert('Apple Health Sync', msg);
    } finally {
      setHealthBusy(false); loadHealthDiagnostics();
    }
  }, [userId, loadHealthDiagnostics]);

  const handleLogout = async () => {
    if (ENV.DEMO_MODE) {
      Alert.alert('Demo Mode', 'Sign out is disabled in demo mode.');
      return;
    }
    Alert.alert('Sign Out', 'Are you sure you want to sign out?', [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Sign Out', style: 'destructive', onPress: async () => {
        await supabase.auth.signOut(); router.replace('/(auth)/login');
      }},
    ]);
  };

  const diagnosisLabel = profile?.diagnosis_type
    ? (DIAGNOSIS_LABELS[profile.diagnosis_type] ?? profile.diagnosis_type)
    : null;

  const metricLabel: Record<HealthSyncDiagnostic['metric'], string> = {
    steps: 'Steps', heart_rate: 'Heart Rate',
    sleep_hours: 'Sleep', active_energy_kcal: 'Active Energy',
  };

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: C.background }}
      contentContainerStyle={{ paddingBottom: 60 }}
      showsVerticalScrollIndicator={false}
    >
      {/* ── Profile Header ── */}
      <View style={{
        alignItems: 'center',
        paddingTop: Platform.OS === 'ios' ? 68 : 36,
        paddingBottom: 28, paddingHorizontal: 20,
        backgroundColor: C.surface,
        borderBottomWidth: 0.5,
        borderBottomColor: C.separator,
      }}>
        {/* Avatar */}
        <UserAvatar name={profile?.display_name ?? 'U'} size={88} />

        {/* Name / Edit */}
        <View style={{ marginTop: 14, alignItems: 'center', width: '100%' }}>
          {editingName ? (
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8, width: '100%' }}>
              <TextInput
                style={{
                  flex: 1, backgroundColor: C.background, borderRadius: 12,
                  paddingHorizontal: 14, paddingVertical: 9,
                  fontSize: 16, color: C.textPrimary,
                  borderWidth: 1, borderColor: C.border,
                }}
                value={displayName}
                onChangeText={setDisplayName}
                placeholder="Your name"
                placeholderTextColor={C.placeholder}
                autoFocus
                maxLength={50}
              />
              <TouchableOpacity
                style={{
                  backgroundColor: C.primary, borderRadius: 12,
                  paddingHorizontal: 16, paddingVertical: 9, alignItems: 'center',
                }}
                onPress={saveDisplayName}
                disabled={savingName}
              >
                {savingName
                  ? <ActivityIndicator size="small" color="#FFF" />
                  : <Text style={{ color: '#FFF', fontWeight: '700', fontSize: 14 }}>Save</Text>}
              </TouchableOpacity>
              <TouchableOpacity onPress={() => { setDisplayName(profile?.display_name ?? ''); setEditingName(false); }}>
                <Text style={{ color: C.textMuted, fontSize: 14, paddingVertical: 9 }}>Cancel</Text>
              </TouchableOpacity>
            </View>
          ) : (
            <TouchableOpacity
              style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}
              onPress={() => setEditingName(true)}
              activeOpacity={0.7}
            >
              <Text style={{ fontSize: 22, fontWeight: '700', color: C.textPrimary }}>
                {profile?.display_name || 'Add your name'}
              </Text>
              <Ionicons name="pencil-outline" size={15} color={C.textMuted} />
            </TouchableOpacity>
          )}
        </View>

        {/* Diagnosis badge */}
        {diagnosisLabel && (
          <View style={{
            backgroundColor: C.primary + '15', borderRadius: 20,
            paddingHorizontal: 14, paddingVertical: 5, marginTop: 10,
          }}>
            <Text style={{ fontSize: 13, fontWeight: '600', color: C.primary }}>{diagnosisLabel}</Text>
          </View>
        )}

        {profile?.diagnosis_date && (
          <Text style={{ fontSize: 12, color: C.textMuted, marginTop: 6 }}>
            Since {format(new Date(profile.diagnosis_date), 'MMMM yyyy')}
          </Text>
        )}
      </View>

      {/* ── 30-Day Stats ── */}
      <ProfileStatsStrip
        totalLogs={totalLogs}
        flareDays={flareDays}
        medAdherence={medAdherence}
        loading={statsLoading}
      />

      {/* ── Tracking ── */}
      <SettingsSection title="Tracking">
        <SettingsRow
          icon="calendar-outline"
          iconBg="#8B5CF6"
          label="Menstrual Cycle"
          subtitle="Track alongside IBD symptoms"
          right={
            <Switch
              value={tracksMenstrual} onValueChange={toggleMenstrual}
              trackColor={{ false: C.border, true: C.primary }}
              thumbColor="#FFFFFF" disabled={savingMenstrual}
            />
          }
          isLast
        />
      </SettingsSection>

      {/* ── Notifications ── */}
      <SettingsSection title="Notifications">
        <SettingsRow
          icon="notifications-outline"
          iconBg="#F59E0B"
          label="Medication Reminders"
          subtitle="Get reminded to take your medications"
          right={
            <Switch value={medReminders} onValueChange={toggleMedReminders}
              trackColor={{ false: C.border, true: C.primary }} thumbColor="#FFFFFF" />
          }
        />
        <SettingsRow
          icon="alarm-outline"
          iconBg="#38BDF8"
          label="Daily Log Reminder"
          subtitle="Daily reminder to log your symptoms"
          right={
            <Switch value={dailyReminder} onValueChange={toggleDailyReminder}
              trackColor={{ false: C.border, true: C.primary }} thumbColor="#FFFFFF" />
          }
          isLast
        />
      </SettingsSection>

      {/* ── Data ── */}
      <SettingsSection title="Data">
        <SettingsRow
          icon="document-text-outline"
          iconBg="#8B5CF6"
          label="Export Health Report"
          subtitle="30-day PDF summary for your doctor"
          onPress={exportLoading ? undefined : handleExport}
          right={exportLoading ? <ActivityIndicator size="small" color={C.primary} /> : undefined}
          isLast
        />
      </SettingsSection>

      {/* ── Apple Health ── */}
      <SettingsSection title="Apple Health">
        <SettingsRow
          icon="heart-outline"
          iconBg="#EF4444"
          label="Connect Apple Health"
          onPress={healthBusy ? undefined : handleConnectAppleHealth}
          right={healthBusy ? <ActivityIndicator size="small" color={C.primary} /> : undefined}
        />
        <SettingsRow
          icon="sync-outline"
          iconBg="#10B981"
          label="Sync Health Data"
          onPress={healthBusy ? undefined : handleSyncAppleHealth}
          isLast
        />
        {healthStatus ? (
          <Text style={{
            fontSize: 12, color: C.textSecondary,
            paddingHorizontal: 16, paddingBottom: 12, lineHeight: 17,
          }}>
            {healthStatus}
          </Text>
        ) : null}
        {healthDiagnostics.length > 0 && (
          <View style={{
            marginHorizontal: 16, marginBottom: 14,
            borderTopWidth: 0.5, borderTopColor: C.separator, paddingTop: 10,
          }}>
            {healthDiagnostics.map((diag) => {
              const statusColor = diag.lastStatus === 'success' ? C.success
                : diag.lastStatus === 'error' ? C.danger
                : diag.lastStatus === 'syncing' ? C.warning
                : C.textSecondary;
              return (
                <View key={diag.metric} style={{ flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 4 }}>
                  <Text style={{ fontSize: 12, fontWeight: '600', color: C.textPrimary }}>
                    {metricLabel[diag.metric]}
                  </Text>
                  <Text style={{ fontSize: 11, fontWeight: '700', color: statusColor }}>
                    {diag.lastStatus.toUpperCase()}
                  </Text>
                </View>
              );
            })}
          </View>
        )}
      </SettingsSection>

      {/* ── Account ── */}
      <SettingsSection title="Account">
        <SettingsRow
          icon="lock-closed-outline"
          iconBg="#3B82F6"
          label="Change Password"
          onPress={() => Alert.alert('Change Password', 'Use "Forgot Password" on the login screen to reset your password.', [{ text: 'OK' }])}
        />
        <SettingsRow
          icon="shield-checkmark-outline"
          iconBg="#6366F1"
          label="Privacy Policy"
          onPress={() => Alert.alert('Privacy Policy', 'Coming soon.', [{ text: 'OK' }])}
        />
        <SettingsRow
          icon="document-outline"
          iconBg="#9CA3AF"
          label="Terms of Service"
          onPress={() => Alert.alert('Terms of Service', 'Coming soon.', [{ text: 'OK' }])}
          isLast
        />
      </SettingsSection>

      {/* ── Sign Out ── */}
      <TouchableOpacity
        style={{
          flexDirection: 'row', alignItems: 'center', justifyContent: 'center',
          marginHorizontal: 20, marginTop: 32,
          backgroundColor: C.danger + '12',
          borderWidth: 1, borderColor: C.danger + '40',
          borderRadius: 16, paddingVertical: 15, gap: 8,
        }}
        onPress={handleLogout}
        activeOpacity={0.75}
      >
        <Ionicons name="log-out-outline" size={18} color={C.danger} />
        <Text style={{ color: C.danger, fontSize: 15, fontWeight: '700' }}>Sign Out</Text>
      </TouchableOpacity>

      <Text style={{ textAlign: 'center', fontSize: 11, color: C.textMuted, marginTop: 20 }}>
        Inflamend v1.0.0
      </Text>
    </ScrollView>
  );
}
