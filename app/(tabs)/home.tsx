import { useEffect, useState, useCallback } from 'react';
import {
  View, Text, StyleSheet, ScrollView, TouchableOpacity,
  RefreshControl, ActivityIndicator,
} from 'react-native';
import { useRouter } from 'expo-router';
import { format } from 'date-fns';
import { useAuthStore } from '../../store/authStore';
import { useSyncStore } from '../../store/syncStore';
import { useFoodLogs, useBowelLogs, useSymptomLogs, useMedicationLogs } from '../../hooks/useLogs';
import { useRiskIndicator } from '../../hooks/useRiskIndicator';
import { Colors } from '../../constants/colors';
import { Theme } from '../../constants/theme';
import { RiskIndicator, FoodLog, BowelLog, SymptomLog, MedicationLog } from '../../types';

type AnyLog = { id: string; logged_at?: string; created_at: string; _type: string; was_taken?: boolean };

function riskColor(level: string) {
  if (level === 'high') return Colors.riskHigh;
  if (level === 'medium') return Colors.riskMedium;
  return Colors.riskLow;
}

function SyncBadge() {
  const { status, pendingCount } = useSyncStore();
  if (status === 'idle' && pendingCount === 0) return null;
  const label = status === 'syncing' ? 'Syncing...' : `${pendingCount} pending`;
  const color = status === 'error' ? Colors.warning : Colors.textSecondary;
  return (
    <View style={syncStyles.badge}>
      <Text style={[syncStyles.text, { color }]}>{label}</Text>
    </View>
  );
}
const syncStyles = StyleSheet.create({
  badge: { paddingHorizontal: 10, paddingVertical: 3, backgroundColor: Colors.border, borderRadius: 20 },
  text: { fontSize: 11 },
});

export default function HomeScreen() {
  const router = useRouter();
  const { profile } = useAuthStore();
  const { fetchToday: fetchFood } = useFoodLogs();
  const { fetchToday: fetchBowel } = useBowelLogs();
  const { fetchToday: fetchSymptom } = useSymptomLogs();
  const { fetchToday: fetchMedLogs } = useMedicationLogs();
  const { calculate } = useRiskIndicator();

  const [risk, setRisk] = useState<RiskIndicator | null>(null);
  const [foodLogs, setFoodLogs] = useState<FoodLog[]>([]);
  const [bowelLogs, setBowelLogs] = useState<BowelLog[]>([]);
  const [symptomLogs, setSymptomLogs] = useState<SymptomLog[]>([]);
  const [medLogs, setMedLogs] = useState<MedicationLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);

  const load = useCallback(async () => {
    try {
      setLoadError(null);
      const [food, bowel, symptom, meds, r] = await Promise.all([
        fetchFood(),
        fetchBowel(),
        fetchSymptom(),
        fetchMedLogs(),
        calculate(),
      ]);
      setFoodLogs(food);
      setBowelLogs(bowel);
      setSymptomLogs(symptom);
      setMedLogs(meds);
      setRisk(r);
    } catch (error) {
      console.error('Home load failed', error);
      setLoadError('We could not refresh your dashboard. Pull to retry.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, [fetchFood, fetchBowel, fetchSymptom, fetchMedLogs, calculate]);

  useEffect(() => { load(); }, [load]);

  const onRefresh = () => {
    setRefreshing(true);
    load();
  };

  const medsTaken = medLogs.filter((m) => m.was_taken).length;
  const medsTotal = medLogs.length;

  // Build timeline from all today's logs
  const allEntries: AnyLog[] = [
    ...foodLogs.map((l): AnyLog => ({ id: l.id, logged_at: l.logged_at, created_at: l.created_at, _type: 'food' })),
    ...bowelLogs.map((l): AnyLog => ({ id: l.id, logged_at: l.logged_at, created_at: l.created_at, _type: 'bowel' })),
    ...symptomLogs.map((l): AnyLog => ({ id: l.id, logged_at: l.logged_at, created_at: l.created_at, _type: 'symptom' })),
    ...medLogs.map((l): AnyLog => ({ id: l.id, logged_at: l.taken_at ?? undefined, created_at: l.created_at, _type: 'medication', was_taken: l.was_taken })),
  ];
  const timeline = allEntries.sort((a, b) =>
    new Date(b.logged_at ?? b.created_at).getTime() - new Date(a.logged_at ?? a.created_at).getTime()
  );

  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={Colors.primary} />
      </View>
    );
  }

  const greeting = () => {
    const h = new Date().getHours();
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  };

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.content}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={Colors.primary} />}
    >
      {/* Header */}
      <View style={styles.header}>
        <View>
          <Text style={styles.date}>{format(new Date(), 'EEEE, MMMM d')}</Text>
          <Text style={styles.greeting}>
            {greeting()}{profile?.display_name ? `, ${profile.display_name}` : ''}
          </Text>
        </View>
        <SyncBadge />
      </View>

      {/* Risk Indicator */}
      {loadError && (
        <View style={styles.errorCard}>
          <Text style={styles.errorTitle}>Couldn’t refresh</Text>
          <Text style={styles.errorText}>{loadError}</Text>
          <TouchableOpacity style={styles.retryBtn} onPress={load}>
            <Text style={styles.retryText}>Retry now</Text>
          </TouchableOpacity>
        </View>
      )}

      {risk && (
        <View style={[styles.riskCard, { borderLeftColor: riskColor(risk.level) }]}>
          <View style={styles.riskRow}>
            <Text style={styles.riskLabel}>Flare Risk</Text>
            <Text style={[styles.riskLevel, { color: riskColor(risk.level) }]}>
              {risk.level.toUpperCase()} · {risk.score}%
            </Text>
          </View>
          <View style={styles.progressBar}>
            <View
              style={[
                styles.progressFill,
                { width: `${risk.score}%` as `${number}%`, backgroundColor: riskColor(risk.level) },
              ]}
            />
          </View>
          {risk.factors.length > 0 && (
            <Text style={styles.riskFactors}>{risk.factors.slice(0, 2).join(' · ')}</Text>
          )}
        </View>
      )}

      {/* Quick Stats */}
      <Text style={styles.sectionTitle}>Today at a Glance</Text>
      <View style={styles.statsGrid}>
        <StatCard label="Meals" value={foodLogs.length} />
        <StatCard label="Bowel" value={bowelLogs.length} />
        <StatCard label="Symptoms" value={symptomLogs.length > 0 ? 'Logged' : 'None'} />
        <StatCard
          label="Meds"
          value={medsTotal > 0 ? `${medsTaken}/${medsTotal}` : 'None'}
        />
      </View>

      {/* Quick Actions */}
      <Text style={styles.sectionTitle}>Quick Log</Text>
      <View style={styles.actionRow}>
        <QuickAction badge="FD" label="Food" onPress={() => router.push('/(tabs)/log?tab=food')} />
        <QuickAction badge="BW" label="Bowel" onPress={() => router.push('/(tabs)/log?tab=bowel')} />
        <QuickAction badge="SY" label="Symptoms" onPress={() => router.push('/(tabs)/log?tab=symptoms')} />
      </View>

      {/* Timeline */}
      {timeline.length > 0 && (
        <>
          <Text style={styles.sectionTitle}>Today’s Timeline</Text>
          {timeline.map((entry) => (
            <TimelineEntry key={`${entry._type}-${entry.id}`} entry={entry} />
          ))}
        </>
      )}

      {timeline.length === 0 && (
        <View style={styles.emptyState}>
          <Text style={styles.emptyText}>Nothing logged today yet.</Text>
          <Text style={styles.emptySubtext}>Tap Quick Log above to get started.</Text>
        </View>
      )}
    </ScrollView>
  );
}

function StatCard({ label, value }: { label: string; value: string | number }) {
  return (
    <View style={statStyles.card}>
      <View style={statStyles.badge}><Text style={statStyles.badgeText}>{label.slice(0, 2).toUpperCase()}</Text></View>
      <Text style={statStyles.value}>{value}</Text>
      <Text style={statStyles.label}>{label}</Text>
    </View>
  );
}

function QuickAction({ badge, label, onPress }: { badge: string; label: string; onPress: () => void }) {
  return (
    <TouchableOpacity style={actionStyles.btn} onPress={onPress} accessibilityLabel={`Log ${label}`}>
      <View style={actionStyles.badge}><Text style={actionStyles.badgeText}>{badge}</Text></View>
      <Text style={actionStyles.label}>{label}</Text>
    </TouchableOpacity>
  );
}

function TimelineEntry({ entry }: { entry: AnyLog }) {
  const time = format(new Date(entry.logged_at ?? entry.created_at), 'h:mm a');
  const icons: Record<string, string> = {
    food: 'FD', bowel: 'BW', symptom: 'SY', medication: 'MD',
  };
  const labels: Record<string, string> = {
    food: `Meal logged`,
    bowel: 'Bowel movement',
    symptom: 'Symptoms logged',
    medication: `Medication ${entry.was_taken ? 'taken' : 'missed'}`,
  };
  return (
    <View style={tlStyles.row}>
      <View style={tlStyles.iconBadge}><Text style={tlStyles.icon}>{icons[entry._type]}</Text></View>
      <View style={tlStyles.info}>
        <Text style={tlStyles.label}>{labels[entry._type]}</Text>
        <Text style={tlStyles.time}>{time}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.background },
  content: { padding: 20, paddingBottom: 40 },
  center: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20, marginTop: 16 },
  date: { fontSize: 13, color: Colors.textSecondary, marginBottom: 2 },
  greeting: { fontSize: 22, fontWeight: '700', color: Colors.textPrimary },
  riskCard: {
    backgroundColor: Colors.white, borderRadius: Theme.radius.lg, padding: Theme.spacing.lg,
    borderLeftWidth: 4, marginBottom: 24,
    ...Theme.shadow.card,
  },
  riskRow: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 10 },
  riskLabel: { fontSize: 15, fontWeight: '600', color: Colors.textPrimary },
  riskLevel: { fontSize: 15, fontWeight: '700' },
  progressBar: { height: 8, backgroundColor: Colors.border, borderRadius: 4, overflow: 'hidden', marginBottom: 8 },
  progressFill: { height: '100%', borderRadius: 4 },
  riskFactors: { fontSize: 12, color: Colors.textSecondary },
  sectionTitle: { fontSize: 17, fontWeight: '700', color: Colors.textPrimary, marginBottom: 12 },
  statsGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 10, marginBottom: 24 },
  actionRow: { flexDirection: 'row', gap: 10, marginBottom: 24 },
  emptyState: { alignItems: 'center', paddingVertical: 40 },
  emptyText: { fontSize: 16, fontWeight: '600', color: Colors.textSecondary },
  emptySubtext: { fontSize: 13, color: Colors.textMuted, marginTop: 4 },
  errorCard: {
    backgroundColor: '#FEF2F2',
    borderColor: '#FECACA',
    borderWidth: 1,
    borderRadius: Theme.radius.md,
    padding: Theme.spacing.lg,
    marginBottom: 18,
  },
  errorTitle: { color: '#A93838', fontWeight: '700', marginBottom: 4, fontSize: 14 },
  errorText: { color: '#7A4B4B', fontSize: 13, marginBottom: 10 },
  retryBtn: {
    alignSelf: 'flex-start',
    backgroundColor: Colors.white,
    borderWidth: 1,
    borderColor: '#F3BBBB',
    borderRadius: Theme.radius.sm,
    paddingHorizontal: 12,
    paddingVertical: 6,
  },
  retryText: { color: '#A93838', fontWeight: '600', fontSize: 12 },
});

const statStyles = StyleSheet.create({
  card: {
    flex: 1, minWidth: '45%', backgroundColor: Colors.white, borderRadius: Theme.radius.md,
    padding: 14, alignItems: 'center',
    ...Theme.shadow.subtle,
  },
  badge: {
    backgroundColor: Colors.primaryLight,
    borderRadius: 8,
    paddingHorizontal: 8,
    paddingVertical: 4,
    marginBottom: 8,
  },
  badgeText: { fontSize: 11, fontWeight: '700', color: Colors.primary },
  value: { fontSize: 20, fontWeight: '700', color: Colors.textPrimary },
  label: { fontSize: 12, color: Colors.textSecondary, marginTop: 2 },
});

const actionStyles = StyleSheet.create({
  btn: {
    flex: 1, backgroundColor: Colors.white, borderRadius: Theme.radius.md, paddingVertical: 14,
    alignItems: 'center', borderWidth: 1, borderColor: Colors.border,
  },
  badge: {
    backgroundColor: Colors.primaryLight,
    borderRadius: 10,
    paddingHorizontal: 10,
    paddingVertical: 6,
    marginBottom: 6,
  },
  badgeText: { fontSize: 11, fontWeight: '700', color: Colors.primary },
  label: { fontSize: 13, fontWeight: '600', color: Colors.textPrimary },
});

const tlStyles = StyleSheet.create({
  row: {
    flexDirection: 'row', alignItems: 'center', backgroundColor: Colors.white,
    borderRadius: Theme.radius.md, padding: 12, marginBottom: 8,
    borderWidth: 1, borderColor: Colors.border,
  },
  iconBadge: {
    backgroundColor: Colors.primaryLight,
    borderRadius: 8,
    paddingHorizontal: 8,
    paddingVertical: 5,
    marginRight: 12,
  },
  icon: { fontSize: 11, fontWeight: '700', color: Colors.primary },
  info: { flex: 1 },
  label: { fontSize: 14, fontWeight: '600', color: Colors.textPrimary },
  time: { fontSize: 12, color: Colors.textSecondary, marginTop: 2 },
});
