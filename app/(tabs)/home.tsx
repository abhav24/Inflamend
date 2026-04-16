import { useEffect, useState, useCallback } from 'react';
import {
  View, Text, ScrollView, TouchableOpacity,
  RefreshControl, ActivityIndicator, Platform,
} from 'react-native';
import { useRouter } from 'expo-router';
import { format } from 'date-fns';
import { Ionicons } from '@expo/vector-icons';
import { useAuthStore } from '../../store/authStore';
import { useFoodLogs, useBowelLogs, useSymptomLogs, useMedicationLogs } from '../../hooks/useLogs';
import { useRiskIndicator } from '../../hooks/useRiskIndicator';
import { useColors } from '../../constants/colors';
import { RiskIndicator, FoodLog, BowelLog, SymptomLog, MedicationLog } from '../../types';
import { UserAvatar } from '../../components/ui/DesignPrimitives';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

type AnyLog = { id: string; logged_at?: string; created_at: string; _type: string; was_taken?: boolean };

function greeting() {
  const h = new Date().getHours();
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}

// ─── Nav Header ───────────────────────────────────────────────────────────────

function NavHeader({ name, topInset }: { name: string | null; topInset: number }) {
  const C = useColors();
  return (
    <View style={{
      flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
      paddingHorizontal: 20,
      paddingTop: Math.max(topInset + 8, Platform.OS === 'ios' ? 24 : 20),
      paddingBottom: 4,
    }}>
      <View>
        <Text style={{ fontSize: 12, color: C.textMuted, fontWeight: '500', marginBottom: 1 }}>
          {format(new Date(), 'EEEE, MMMM d')}
        </Text>
        <View style={{ flexDirection: 'row', alignItems: 'baseline', gap: 4 }}>
          <Text style={{ fontSize: 14, color: C.textSecondary, fontWeight: '500' }}>
            {greeting()},
          </Text>
          <Text style={{ fontSize: 22, fontWeight: '800', color: C.textPrimary }}>
            {name ?? 'there'}
          </Text>
        </View>
      </View>
      {name ? (
        <UserAvatar name={name} size={36} />
      ) : (
        <View style={{
          width: 36, height: 36, borderRadius: 18,
          backgroundColor: C.primary + '20', alignItems: 'center', justifyContent: 'center',
        }}>
          <Ionicons name="person-outline" size={18} color={C.primary} />
        </View>
      )}
    </View>
  );
}

// ─── Hero Card ────────────────────────────────────────────────────────────────

function HeroCard({
  risk,
  foodCount,
  bowelCount,
}: {
  risk: RiskIndicator | null;
  foodCount: number;
  bowelCount: number;
}) {
  const score = risk?.score ?? 0;
  const level = risk?.level ?? 'low';
  const riskColor = level === 'high' ? '#FF6B6B' : level === 'medium' ? '#FBBF24' : '#4ADE80';

  return (
    <View style={{
      backgroundColor: '#6366F1',
      borderRadius: 24, overflow: 'hidden',
      marginHorizontal: 20, marginTop: 16, marginBottom: 24,
    }}>
      {/* Decorative blobs */}
      <View style={{
        position: 'absolute', width: 200, height: 200, borderRadius: 100,
        backgroundColor: '#FFFFFF', opacity: 0.06, right: -40, top: -60,
      }} />
      <View style={{
        position: 'absolute', width: 140, height: 140, borderRadius: 70,
        backgroundColor: '#8B5CF6', opacity: 0.5, left: -30, bottom: -40,
      }} />

      <View style={{ padding: 24 }}>
        {/* Label */}
        <Text style={{
          fontSize: 12, color: 'rgba(255,255,255,0.65)', fontWeight: '600',
          letterSpacing: 0.4, marginBottom: 6,
        }}>
          Flare Risk Score
        </Text>

        {/* Score + level */}
        <View style={{ flexDirection: 'row', alignItems: 'flex-end', gap: 8, marginBottom: 6 }}>
          <View style={{ flexDirection: 'row', alignItems: 'flex-start' }}>
            <Text style={{
              fontSize: 40, fontWeight: '800', color: '#FFFFFF', lineHeight: 44,
            }}>
              {score}
            </Text>
            <Text style={{
              fontSize: 18, fontWeight: '600', color: 'rgba(255,255,255,0.6)',
              marginTop: 6, marginLeft: 2,
            }}>
              %
            </Text>
          </View>
          <View style={{
            backgroundColor: riskColor + '28',
            borderRadius: 20, borderWidth: 1, borderColor: riskColor + '70',
            paddingHorizontal: 10, paddingVertical: 4, marginBottom: 4,
          }}>
            <Text style={{ fontSize: 11, fontWeight: '700', color: riskColor }}>
              {level.toUpperCase()}
            </Text>
          </View>
        </View>

        {(risk?.factors?.length ?? 0) > 0 && (
          <Text style={{
            fontSize: 12, color: 'rgba(255,255,255,0.6)', marginBottom: 18,
          }}>
            {risk!.factors.slice(0, 2).join(' · ')}
          </Text>
        )}

        {/* Divider */}
        <View style={{
          height: 1, backgroundColor: 'rgba(255,255,255,0.18)',
          marginBottom: 16,
          marginTop: (risk?.factors?.length ?? 0) > 0 ? 0 : 18,
        }} />

        {/* Mini-stats */}
        <View style={{ flexDirection: 'row' }}>
          <View style={{ flex: 1 }}>
            <Text style={{ fontSize: 18, fontWeight: '800', color: '#FFFFFF', marginBottom: 2 }}>
              {foodCount}
            </Text>
            <Text style={{ fontSize: 11, color: 'rgba(255,255,255,0.6)', fontWeight: '500' }}>
              Meals Today
            </Text>
          </View>
          <View style={{ flex: 1, alignItems: 'center' }}>
            <Text style={{ fontSize: 18, fontWeight: '800', color: '#FFFFFF', marginBottom: 2 }}>
              {bowelCount}
            </Text>
            <Text style={{ fontSize: 11, color: 'rgba(255,255,255,0.6)', fontWeight: '500' }}>
              Bowel Today
            </Text>
          </View>
          <View style={{ flex: 1, alignItems: 'flex-end' }}>
            <Text style={{ fontSize: 18, fontWeight: '800', color: '#FFFFFF', marginBottom: 2 }}>
              {level.charAt(0).toUpperCase() + level.slice(1)}
            </Text>
            <Text style={{ fontSize: 11, color: 'rgba(255,255,255,0.6)', fontWeight: '500' }}>
              Risk Level
            </Text>
          </View>
        </View>
      </View>
    </View>
  );
}

// ─── Stats Strip ──────────────────────────────────────────────────────────────

type StatCell = { label: string; value: string; icon: string; color: string };

function StatsStrip({ cells }: { cells: StatCell[] }) {
  const C = useColors();
  return (
    <View style={{
      flexDirection: 'row',
      backgroundColor: C.surface,
      borderRadius: 20,
      marginHorizontal: 20,
      marginBottom: 24,
      shadowColor: '#000',
      shadowOpacity: C.background === '#000000' ? 0.22 : 0.08,
      shadowRadius: 12, shadowOffset: { width: 0, height: 2 },
      elevation: 3, overflow: 'hidden', borderWidth: 1, borderColor: C.glassBorder,
    }}>
      {cells.map((cell, i) => (
        <View key={cell.label} style={{
          flex: 1, alignItems: 'center', paddingVertical: 16,
          borderRightWidth: i < cells.length - 1 ? 0.5 : 0,
          borderRightColor: C.separator,
        }}>
          <View style={{
            width: 32, height: 32, borderRadius: 10,
            backgroundColor: cell.color + '18',
            alignItems: 'center', justifyContent: 'center', marginBottom: 6,
          }}>
            <Ionicons name={cell.icon as any} size={15} color={cell.color} />
          </View>
          <Text style={{ fontSize: 17, fontWeight: '800', color: cell.color, marginBottom: 2 }}>
            {cell.value}
          </Text>
          <Text style={{
            fontSize: 10, color: C.textMuted, fontWeight: '600',
            textTransform: 'uppercase', letterSpacing: 0.3,
          }}>
            {cell.label}
          </Text>
        </View>
      ))}
    </View>
  );
}

// ─── Section Title ────────────────────────────────────────────────────────────

function SectionTitle({ title }: { title: string }) {
  const C = useColors();
  return (
    <Text style={{
      fontSize: 20, fontWeight: '700', color: C.textPrimary,
      marginBottom: 12, paddingHorizontal: 20,
    }}>
      {title}
    </Text>
  );
}

// ─── Quick Log Buttons ────────────────────────────────────────────────────────

function QuickActions({ onPress }: { onPress: (tab: string) => void }) {
  const C = useColors();
  const actions = [
    { icon: 'restaurant-outline', label: 'Food',     tab: 'food',     iconBg: '#38BDF8' },
    { icon: 'water-outline',      label: 'Bowel',    tab: 'bowel',    iconBg: '#10B981' },
    { icon: 'pulse-outline',      label: 'Symptoms', tab: 'symptoms', iconBg: '#6366F1' },
  ];
  return (
    <View style={{ flexDirection: 'row', gap: 10, paddingHorizontal: 20, marginBottom: 28 }}>
      {actions.map((a) => (
        <TouchableOpacity
          key={a.tab}
          style={{
            flex: 1, borderRadius: 20,
            backgroundColor: C.surface,
            paddingVertical: 18,
            alignItems: 'center',
            shadowColor: '#000',
            shadowOpacity: C.background === '#000000' ? 0.2 : 0.08,
            shadowRadius: 8, shadowOffset: { width: 0, height: 2 }, elevation: 2,
            borderWidth: 1, borderColor: C.glassBorder,
          }}
          onPress={() => onPress(a.tab)}
          activeOpacity={0.72}
        >
          <View style={{
            width: 44, height: 44, borderRadius: 22,
            backgroundColor: a.iconBg,
            alignItems: 'center', justifyContent: 'center', marginBottom: 8,
          }}>
            <Ionicons name={a.icon as any} size={20} color="#FFFFFF" />
          </View>
          <Text style={{ fontSize: 13, fontWeight: '700', color: C.textPrimary }}>{a.label}</Text>
        </TouchableOpacity>
      ))}
    </View>
  );
}

// ─── Timeline Entry ───────────────────────────────────────────────────────────

function TimelineEntry({ entry }: { entry: AnyLog }) {
  const C = useColors();
  const time = format(new Date(entry.logged_at ?? entry.created_at), 'h:mm a');
  type Config = { icon: string; label: string; color: string };
  const config: Record<string, Config> = {
    food:       { icon: 'restaurant-outline', label: 'Meal logged',     color: '#38BDF8' },
    bowel:      { icon: 'water-outline',      label: 'Bowel movement',  color: C.success },
    symptom:    { icon: 'pulse-outline',      label: 'Symptoms logged', color: C.warning },
    medication: {
      icon: 'medkit-outline',
      label: `Medication ${entry.was_taken ? 'taken' : 'missed'}`,
      color: entry.was_taken ? C.success : C.danger,
    },
  };
  const { icon, label, color } = config[entry._type] ?? { icon: 'ellipse-outline', label: 'Entry', color: C.textMuted };

  return (
    <View style={{
      flexDirection: 'row', alignItems: 'center',
      backgroundColor: C.surface, borderRadius: 16, padding: 14,
      marginBottom: 8, marginHorizontal: 20,
      shadowColor: '#000',
      shadowOpacity: C.background === '#000000' ? 0.18 : 0.06,
      shadowRadius: 8, shadowOffset: { width: 0, height: 1 }, elevation: 2,
      borderWidth: 1, borderColor: C.glassBorder,
    }}>
      <View style={{
        width: 42, height: 42, borderRadius: 13,
        backgroundColor: color + '18',
        alignItems: 'center', justifyContent: 'center', marginRight: 14,
      }}>
        <Ionicons name={icon as any} size={19} color={color} />
      </View>
      <View style={{ flex: 1 }}>
        <Text style={{ fontSize: 14, fontWeight: '600', color: C.textPrimary }}>{label}</Text>
        <Text style={{ fontSize: 12, color: C.textMuted, marginTop: 2 }}>{time}</Text>
      </View>
      <View style={{ width: 6, height: 6, borderRadius: 3, backgroundColor: color, opacity: 0.7 }} />
    </View>
  );
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

export default function HomeScreen() {
  const router = useRouter();
  const { profile } = useAuthStore();
  const { fetchToday: fetchFood }    = useFoodLogs();
  const { fetchToday: fetchBowel }   = useBowelLogs();
  const { fetchToday: fetchSymptom } = useSymptomLogs();
  const { fetchToday: fetchMedLogs } = useMedicationLogs();
  const { calculate } = useRiskIndicator();
  const C = useColors();
  const insets = useSafeAreaInsets();

  const [risk, setRisk]               = useState<RiskIndicator | null>(null);
  const [foodLogs, setFoodLogs]       = useState<FoodLog[]>([]);
  const [bowelLogs, setBowelLogs]     = useState<BowelLog[]>([]);
  const [symptomLogs, setSymptomLogs] = useState<SymptomLog[]>([]);
  const [medLogs, setMedLogs]         = useState<MedicationLog[]>([]);
  const [loading, setLoading]         = useState(true);
  const [refreshing, setRefreshing]   = useState(false);

  const load = useCallback(async () => {
    try {
      const [food, bowel, symptom, meds, r] = await Promise.all([
        fetchFood(), fetchBowel(), fetchSymptom(), fetchMedLogs(), calculate(),
      ]);
      setFoodLogs(food); setBowelLogs(bowel); setSymptomLogs(symptom);
      setMedLogs(meds); setRisk(r);
    } finally {
      setLoading(false); setRefreshing(false);
    }
  }, [fetchFood, fetchBowel, fetchSymptom, fetchMedLogs, calculate]);

  useEffect(() => { load(); }, [load]);

  const medsTaken = medLogs.filter((m) => m.was_taken).length;
  const medsTotal = medLogs.length;

  const allEntries: AnyLog[] = [
    ...foodLogs.map((l): AnyLog => ({ id: l.id, logged_at: l.logged_at, created_at: l.created_at, _type: 'food' })),
    ...bowelLogs.map((l): AnyLog => ({ id: l.id, logged_at: l.logged_at, created_at: l.created_at, _type: 'bowel' })),
    ...symptomLogs.map((l): AnyLog => ({ id: l.id, logged_at: l.logged_at, created_at: l.created_at, _type: 'symptom' })),
    ...medLogs.map((l): AnyLog => ({ id: l.id, logged_at: l.taken_at ?? undefined, created_at: l.created_at, _type: 'medication', was_taken: l.was_taken })),
  ];
  const timeline = allEntries.sort(
    (a, b) => new Date(b.logged_at ?? b.created_at).getTime() - new Date(a.logged_at ?? a.created_at).getTime(),
  );

  const statCells: StatCell[] = [
    { label: 'Meals',    value: String(foodLogs.length),   icon: 'restaurant-outline', color: '#38BDF8' },
    { label: 'Bowel',    value: String(bowelLogs.length),  icon: 'water-outline',      color: C.success },
    { label: 'Symptoms', value: symptomLogs.length > 0 ? String(symptomLogs.length) : '—', icon: 'pulse-outline', color: C.warning },
    { label: 'Meds',     value: medsTotal > 0 ? `${medsTaken}/${medsTotal}` : '—', icon: 'medkit-outline', color: C.primary },
  ];

  if (loading) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: C.background }}>
        <ActivityIndicator size="large" color={C.primary} />
      </View>
    );
  }

  return (
    <View style={{ flex: 1, backgroundColor: C.background }}>
      <ScrollView
        style={{ flex: 1 }}
        contentContainerStyle={{ paddingBottom: 150 + Math.max(insets.bottom, 12) }}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={() => { setRefreshing(true); load(); }}
            tintColor={C.primary}
          />
        }
        showsVerticalScrollIndicator={false}
      >
  <NavHeader name={profile?.display_name ?? null} topInset={insets.top} />
        <HeroCard
          risk={risk}
          foodCount={foodLogs.length}
          bowelCount={bowelLogs.length}
        />

        <SectionTitle title="Today at a Glance" />
        <StatsStrip cells={statCells} />

        <SectionTitle title="Quick Log" />
        <QuickActions onPress={(tab) => router.push(`/(tabs)/log?tab=${tab}` as any)} />

        {timeline.length > 0 && (
          <>
            <SectionTitle title="Today's Timeline" />
            {timeline.map((entry) => (
              <TimelineEntry key={`${entry._type}-${entry.id}`} entry={entry} />
            ))}
          </>
        )}

        {timeline.length === 0 && (
          <View style={{ alignItems: 'center', paddingVertical: 40, paddingHorizontal: 20 }}>
            <View style={{
              width: 80, height: 80, borderRadius: 40,
              backgroundColor: C.primary + '18',
              alignItems: 'center', justifyContent: 'center', marginBottom: 16,
            }}>
              <Ionicons name="clipboard-outline" size={38} color={C.primary} style={{ opacity: 0.6 }} />
            </View>
            <Text style={{ fontSize: 18, fontWeight: '700', color: C.textPrimary, marginBottom: 6 }}>
              Nothing logged today
            </Text>
            <Text style={{ fontSize: 14, color: C.textSecondary, textAlign: 'center', lineHeight: 20 }}>
              Tap Quick Log above or use the + button to get started.
            </Text>
          </View>
        )}
      </ScrollView>

      {/* FAB */}
      <TouchableOpacity
        style={{
          position: 'absolute', bottom: 94 + Math.max(insets.bottom, 12), right: 24,
          width: 56, height: 56, borderRadius: 28,
          backgroundColor: C.primary,
          borderWidth: 1,
          borderColor: C.glassBorder,
          alignItems: 'center', justifyContent: 'center',
          shadowColor: C.primary, shadowOpacity: 0.4,
          shadowRadius: 12, shadowOffset: { width: 0, height: 4 }, elevation: 8,
        }}
        onPress={() => router.push('/(tabs)/log' as any)}
        activeOpacity={0.85}
      >
        <Ionicons name="add" size={28} color="#FFFFFF" />
      </TouchableOpacity>
    </View>
  );
}
