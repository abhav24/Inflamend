import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  ActivityIndicator,
  Modal,
  RefreshControl,
  ScrollView,
  Text,
  View,
} from 'react-native';
import { useRouter } from 'expo-router';
import { format } from 'date-fns';
import { LinearGradient } from 'expo-linear-gradient';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useAuthStore } from '../../store/authStore';
import { useFoodLogs, useBowelLogs, useMedicationLogs, useSymptomLogs } from '../../hooks/useLogs';
import { useRiskIndicator } from '../../hooks/useRiskIndicator';
import { BowelLog, FoodLog, MedicationLog, RiskIndicator, SymptomLog } from '../../types';
import {
  AppCard,
  AppIcon,
  GlassSheet,
  PressScale,
  UserAvatar,
} from '../../components/ui/DesignPrimitives';
import { useColors } from '../../constants/colors';
import { impactLightHaptic, selectionHaptic } from '../../lib/haptics';

type AnyLog = {
  id: string;
  logged_at?: string;
  created_at: string;
  type: 'food' | 'bowel' | 'symptom' | 'medication';
  was_taken?: boolean;
};

function greeting() {
  const hour = new Date().getHours();
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

function NavHeader({
  name,
  topInset,
  onProfilePress,
}: {
  name: string | null;
  topInset: number;
  onProfilePress: () => void;
}) {
  const C = useColors();

  return (
    <View style={{ paddingHorizontal: 20, paddingTop: topInset + 8, paddingBottom: 8, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' }}>
      <View>
        <Text style={{ fontSize: 13, fontWeight: '500', color: C.textSecondary, letterSpacing: -0.08 }}>
          {format(new Date(), 'EEEE, MMMM d')}
        </Text>
        <Text style={{ marginTop: 6, fontSize: 28, fontWeight: '800', letterSpacing: -0.5, color: C.textPrimary }}>
          {greeting()}, {name ?? 'there'}
        </Text>
      </View>
      <PressScale onPress={onProfilePress}>
        {name ? (
          <UserAvatar name={name} size={42} />
        ) : (
          <AppCard style={{ width: 42, height: 42, alignItems: 'center', justifyContent: 'center' }} intensity={70}>
            <AppIcon symbol="person.fill" fallback="person" size={18} tintColor={C.primary} />
          </AppCard>
        )}
      </PressScale>
    </View>
  );
}

function HeroCard({
  risk,
  foodCount,
  bowelCount,
}: {
  risk: RiskIndicator | null;
  foodCount: number;
  bowelCount: number;
}) {
  const C = useColors();
  const score = risk?.score ?? 0;
  const level = risk?.level ?? 'low';
  const riskColor = level === 'high' ? C.riskHigh : level === 'medium' ? C.riskMedium : C.riskLow;

  return (
    <View style={{ marginHorizontal: 20, marginTop: 14, marginBottom: 24 }}>
      <AppCard style={{ overflow: 'hidden', borderRadius: 26 }} intensity={52}>
        <LinearGradient
          colors={[C.gradientBrandStart, C.gradientBrandEnd]}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={{ position: 'absolute', inset: 0 }}
        />
        <View style={{ position: 'absolute', width: 220, height: 220, borderRadius: 110, backgroundColor: C.onGradient, opacity: 0.08, right: -60, top: -90 }} />
        <View style={{ position: 'absolute', width: 160, height: 160, borderRadius: 80, backgroundColor: C.glassHighlight, opacity: C.isDark ? 0.08 : 0.2, left: -34, bottom: -60 }} />

        <View style={{ padding: 24 }}>
          <Text style={{ fontSize: 13, fontWeight: '600', color: `${C.onGradient}B8`, letterSpacing: 0.2 }}>
            Flare Risk Score
          </Text>
          <View style={{ flexDirection: 'row', alignItems: 'flex-end', justifyContent: 'space-between', marginTop: 14 }}>
            <View>
              <View style={{ flexDirection: 'row', alignItems: 'flex-start' }}>
                <Text style={{ fontSize: 48, fontWeight: '800', color: C.onGradient, lineHeight: 50, letterSpacing: -1 }}>
                  {score}
                </Text>
                <Text style={{ marginTop: 8, marginLeft: 4, fontSize: 22, fontWeight: '600', color: `${C.onGradient}CC` }}>
                  %
                </Text>
              </View>
              <Text style={{ marginTop: 6, fontSize: 17, fontWeight: '600', color: `${C.onGradient}D1`, letterSpacing: -0.24 }}>
                {level.charAt(0).toUpperCase() + level.slice(1)} risk today
              </Text>
            </View>

            <View style={{ backgroundColor: `${riskColor}26`, borderRadius: 20, paddingHorizontal: 12, paddingVertical: 7, borderWidth: 1, borderColor: `${riskColor}78` }}>
              <Text style={{ fontSize: 12, fontWeight: '800', color: riskColor, letterSpacing: 0.3 }}>
                {level.toUpperCase()}
              </Text>
            </View>
          </View>

          <Text style={{ marginTop: 12, fontSize: 13, lineHeight: 18, color: `${C.onGradient}B8` }}>
            {(risk?.factors?.length ?? 0) > 0 ? risk!.factors.slice(0, 2).join(' · ') : 'No elevated risk factors detected in the last week.'}
          </Text>

          <View style={{ height: 1, backgroundColor: `${C.onGradient}29`, marginVertical: 18 }} />

          <View style={{ flexDirection: 'row' }}>
            {[
              { label: 'Meals Today', value: String(foodCount) },
              { label: 'Bowel Today', value: String(bowelCount) },
              { label: 'Risk Level', value: level.charAt(0).toUpperCase() + level.slice(1) },
            ].map((item, index) => (
              <View key={item.label} style={{ flex: 1, alignItems: index === 0 ? 'flex-start' : index === 2 ? 'flex-end' : 'center' }}>
                <Text style={{ fontSize: 20, fontWeight: '800', color: C.onGradient, letterSpacing: -0.24 }}>
                  {item.value}
                </Text>
                <Text style={{ marginTop: 4, fontSize: 11, fontWeight: '600', color: `${C.onGradient}A8`, textTransform: 'uppercase', letterSpacing: 0.32 }}>
                  {item.label}
                </Text>
              </View>
            ))}
          </View>
        </View>
      </AppCard>
    </View>
  );
}

function StatStrip({
  cells,
  onPressCell,
}: {
  cells: { label: string; value: string; color: string; icon: { symbol: React.ComponentProps<typeof AppIcon>['symbol']; fallback: React.ComponentProps<typeof AppIcon>['fallback'] } }[];
  onPressCell: (label: string) => void;
}) {
  const C = useColors();
  return (
    <AppCard style={{ marginHorizontal: 20, marginBottom: 24, paddingVertical: 6 }}>
      <View style={{ flexDirection: 'row' }}>
        {cells.map((cell, index) => (
          <PressScale key={cell.label} onPress={() => onPressCell(cell.label)} style={{ flex: 1 }}>
            <View style={{ paddingVertical: 14, alignItems: 'center', borderRightWidth: index < cells.length - 1 ? 1 : 0, borderRightColor: C.separator }}>
              <View style={{ width: 36, height: 36, borderRadius: 14, backgroundColor: `${cell.color}20`, alignItems: 'center', justifyContent: 'center' }}>
                <AppIcon symbol={cell.icon.symbol} fallback={cell.icon.fallback} size={17} tintColor={cell.color} />
              </View>
              <Text style={{ marginTop: 10, fontSize: 18, fontWeight: '800', color: cell.color, letterSpacing: -0.24 }}>
                {cell.value}
              </Text>
              <Text style={{ marginTop: 4, fontSize: 11, fontWeight: '600', color: C.textMuted, textTransform: 'uppercase', letterSpacing: 0.32 }}>
                {cell.label}
              </Text>
            </View>
          </PressScale>
        ))}
      </View>
    </AppCard>
  );
}

function SectionTitle({ title }: { title: string }) {
  const C = useColors();
  return (
    <Text style={{ marginHorizontal: 20, marginBottom: 12, fontSize: 22, fontWeight: '700', letterSpacing: -0.4, color: C.textPrimary }}>
      {title}
    </Text>
  );
}

function QuickActions({ onPress }: { onPress: (tab: 'food' | 'bowel' | 'symptoms') => void }) {
  const C = useColors();
  const actions: {
    key: 'food' | 'bowel' | 'symptoms';
    label: string;
    color: string;
    symbol: React.ComponentProps<typeof AppIcon>['symbol'];
    fallback: React.ComponentProps<typeof AppIcon>['fallback'];
  }[] = [
    { key: 'food' as const, label: 'Food', color: C.info, symbol: 'fork.knife', fallback: 'restaurant-outline' as const },
    { key: 'bowel' as const, label: 'Bowel', color: C.success, symbol: 'drop.fill', fallback: 'water-outline' as const },
    { key: 'symptoms' as const, label: 'Symptoms', color: C.primary, symbol: 'waveform.path.ecg', fallback: 'pulse-outline' as const },
  ];

  return (
    <View style={{ flexDirection: 'row', gap: 10, paddingHorizontal: 20, marginBottom: 28 }}>
      {actions.map((action) => (
        <PressScale key={action.key} onPress={() => onPress(action.key)} style={{ flex: 1 }}>
          <AppCard style={{ paddingVertical: 18, alignItems: 'center' }} intensity={50}>
            <View style={{ width: 46, height: 46, borderRadius: 18, alignItems: 'center', justifyContent: 'center', backgroundColor: `${action.color}22` }}>
              <AppIcon symbol={action.symbol} fallback={action.fallback} size={20} tintColor={action.color} />
            </View>
            <Text style={{ marginTop: 10, fontSize: 13, fontWeight: '700', color: C.textPrimary, letterSpacing: -0.08 }}>
              {action.label}
            </Text>
          </AppCard>
        </PressScale>
      ))}
    </View>
  );
}

function TimelineEntry({ entry }: { entry: AnyLog }) {
  const C = useColors();
  const time = format(new Date(entry.logged_at ?? entry.created_at), 'h:mm a');
  const config: Record<
    AnyLog['type'],
    {
      icon: {
        symbol: React.ComponentProps<typeof AppIcon>['symbol'];
        fallback: React.ComponentProps<typeof AppIcon>['fallback'];
      };
      label: string;
      color: string;
    }
  > = {
    food: { icon: { symbol: 'fork.knife', fallback: 'restaurant-outline' as const }, label: 'Meal logged', color: C.info },
    bowel: { icon: { symbol: 'drop.fill', fallback: 'water-outline' as const }, label: 'Bowel movement', color: C.success },
    symptom: { icon: { symbol: 'waveform.path.ecg', fallback: 'pulse-outline' as const }, label: 'Symptoms logged', color: C.warning },
    medication: {
      icon: { symbol: 'pill.fill', fallback: 'medkit-outline' as const },
      label: `Medication ${entry.was_taken ? 'taken' : 'missed'}`,
      color: entry.was_taken ? C.success : C.danger,
    },
  };
  const item = config[entry.type];

  return (
    <AppCard style={{ marginHorizontal: 20, marginBottom: 10, padding: 14 }} intensity={44}>
      <View style={{ flexDirection: 'row', alignItems: 'center' }}>
        <View style={{ width: 42, height: 42, borderRadius: 14, backgroundColor: `${item.color}18`, alignItems: 'center', justifyContent: 'center', marginRight: 14 }}>
          <AppIcon symbol={item.icon.symbol} fallback={item.icon.fallback} size={19} tintColor={item.color} />
        </View>
        <View style={{ flex: 1 }}>
          <Text style={{ fontSize: 15, fontWeight: '600', color: C.textPrimary, letterSpacing: -0.24 }}>
            {item.label}
          </Text>
          <Text style={{ marginTop: 2, fontSize: 13, fontWeight: '500', color: C.textSecondary }}>
            {time}
          </Text>
        </View>
        <View style={{ width: 7, height: 7, borderRadius: 3.5, backgroundColor: item.color }} />
      </View>
    </AppCard>
  );
}

function QuickLogSheet({
  visible,
  onClose,
  onSelect,
}: {
  visible: boolean;
  onClose: () => void;
  onSelect: (tab: 'food' | 'bowel' | 'symptoms') => void;
}) {
  const C = useColors();
  const options: {
    key: 'food' | 'bowel' | 'symptoms';
    title: string;
    subtitle: string;
    icon: {
      symbol: React.ComponentProps<typeof AppIcon>['symbol'];
      fallback: React.ComponentProps<typeof AppIcon>['fallback'];
    };
    color: string;
  }[] = [
    { key: 'food' as const, title: 'Log Food', subtitle: 'Capture meals and hydration', icon: { symbol: 'fork.knife', fallback: 'restaurant-outline' as const }, color: C.info },
    { key: 'bowel' as const, title: 'Log Bowel', subtitle: 'Record urgency and Bristol type', icon: { symbol: 'drop.fill', fallback: 'water-outline' as const }, color: C.success },
    { key: 'symptoms' as const, title: 'Log Symptoms', subtitle: 'Track pain, stress, and flare status', icon: { symbol: 'waveform.path.ecg', fallback: 'pulse-outline' as const }, color: C.primary },
  ];

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <View style={{ flex: 1, justifyContent: 'flex-end', backgroundColor: C.scrim, padding: 12 }}>
        <GlassSheet style={{ padding: 20, gap: 10 }}>
          <View style={{ alignItems: 'center', paddingBottom: 6 }}>
            <View style={{ width: 38, height: 5, borderRadius: 999, backgroundColor: C.fillTertiary }} />
          </View>
          <Text style={{ fontSize: 28, fontWeight: '800', color: C.textPrimary, letterSpacing: -0.5 }}>
            Quick Log
          </Text>
          <Text style={{ fontSize: 15, fontWeight: '500', color: C.textSecondary, letterSpacing: -0.24 }}>
            Jump into the entry you need right now.
          </Text>
          {options.map((option) => (
            <PressScale
              key={option.key}
              onPress={() => {
                onSelect(option.key);
                onClose();
              }}
            >
              <AppCard style={{ padding: 16 }} intensity={54}>
                <View style={{ flexDirection: 'row', alignItems: 'center' }}>
                  <View style={{ width: 44, height: 44, borderRadius: 16, alignItems: 'center', justifyContent: 'center', backgroundColor: `${option.color}22` }}>
                    <AppIcon symbol={option.icon.symbol} fallback={option.icon.fallback} size={21} tintColor={option.color} />
                  </View>
                  <View style={{ flex: 1, marginLeft: 14 }}>
                    <Text style={{ fontSize: 17, fontWeight: '700', color: C.textPrimary, letterSpacing: -0.24 }}>
                      {option.title}
                    </Text>
                    <Text style={{ marginTop: 2, fontSize: 13, fontWeight: '500', color: C.textSecondary }}>
                      {option.subtitle}
                    </Text>
                  </View>
                  <AppIcon symbol="chevron.right" fallback="chevron-forward" size={16} tintColor={C.textMuted} />
                </View>
              </AppCard>
            </PressScale>
          ))}
        </GlassSheet>
      </View>
    </Modal>
  );
}

export default function HomeScreen() {
  const router = useRouter();
  const C = useColors();
  const insets = useSafeAreaInsets();
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
  const [showQuickSheet, setShowQuickSheet] = useState(false);

  const load = useCallback(async () => {
    try {
      const [food, bowel, symptom, meds, nextRisk] = await Promise.all([
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
      setRisk(nextRisk);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, [calculate, fetchBowel, fetchFood, fetchMedLogs, fetchSymptom]);

  useEffect(() => {
    load();
  }, [load]);

  const timeline = useMemo<AnyLog[]>(() => {
    return [
      ...foodLogs.map((log) => ({ id: log.id, logged_at: log.logged_at, created_at: log.created_at, type: 'food' as const })),
      ...bowelLogs.map((log) => ({ id: log.id, logged_at: log.logged_at, created_at: log.created_at, type: 'bowel' as const })),
      ...symptomLogs.map((log) => ({ id: log.id, logged_at: log.logged_at, created_at: log.created_at, type: 'symptom' as const })),
      ...medLogs.map((log) => ({ id: log.id, logged_at: log.taken_at ?? undefined, created_at: log.created_at, type: 'medication' as const, was_taken: log.was_taken })),
    ].sort(
      (a, b) =>
        new Date(b.logged_at ?? b.created_at).getTime() -
        new Date(a.logged_at ?? a.created_at).getTime()
    );
  }, [bowelLogs, foodLogs, medLogs, symptomLogs]);

  const statCells = [
    { label: 'Meals', value: String(foodLogs.length), color: C.info, icon: { symbol: 'fork.knife', fallback: 'restaurant-outline' as const } },
    { label: 'Bowel', value: String(bowelLogs.length), color: C.success, icon: { symbol: 'drop.fill', fallback: 'water-outline' as const } },
    { label: 'Symptoms', value: symptomLogs.length > 0 ? String(symptomLogs.length) : '—', color: C.warning, icon: { symbol: 'waveform.path.ecg', fallback: 'pulse-outline' as const } },
    { label: 'Meds', value: medLogs.length > 0 ? `${medLogs.filter((item) => item.was_taken).length}/${medLogs.length}` : '—', color: C.primary, icon: { symbol: 'pill.fill', fallback: 'medkit-outline' as const } },
  ] as const;

  function openLog(tab?: string) {
    if (tab) {
      router.push(`/(tabs)/log?tab=${tab}` as never);
      return;
    }
    router.push('/(tabs)/log' as never);
  }

  if (loading) {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: 'transparent' }}>
        <ActivityIndicator size="large" color={C.primary} />
      </View>
    );
  }

  return (
    <View style={{ flex: 1 }}>
      <QuickLogSheet visible={showQuickSheet} onClose={() => setShowQuickSheet(false)} onSelect={(tab) => openLog(tab)} />

      <ScrollView
        style={{ flex: 1 }}
        contentContainerStyle={{ paddingBottom: 160 + Math.max(insets.bottom, 12) }}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={() => {
              setRefreshing(true);
              load();
            }}
            tintColor={C.primary}
          />
        }
        showsVerticalScrollIndicator={false}
      >
        <NavHeader
          name={profile?.display_name ?? null}
          topInset={insets.top}
          onProfilePress={() => router.push('/(tabs)/profile' as never)}
        />

        <HeroCard risk={risk} foodCount={foodLogs.length} bowelCount={bowelLogs.length} />

        <SectionTitle title="Today at a Glance" />
        <StatStrip
          cells={statCells as any}
          onPressCell={(label) => {
            selectionHaptic();
            if (label === 'Meals' || label === 'Bowel' || label === 'Symptoms') {
              openLog(label.toLowerCase() === 'meals' ? 'food' : label.toLowerCase() as 'bowel' | 'symptoms');
              return;
            }
            openLog('meds');
          }}
        />

        <SectionTitle title="Quick Log" />
        <QuickActions onPress={openLog} />

        {timeline.length > 0 ? (
          <>
            <SectionTitle title="Today's Timeline" />
            {timeline.map((entry) => (
              <TimelineEntry key={`${entry.type}-${entry.id}`} entry={entry} />
            ))}
          </>
        ) : (
          <View style={{ alignItems: 'center', paddingHorizontal: 20, paddingTop: 18 }}>
            <AppCard style={{ width: 92, height: 92, alignItems: 'center', justifyContent: 'center' }} intensity={50}>
              <AppIcon symbol="clipboard" fallback="clipboard-outline" size={36} tintColor={C.primary} />
            </AppCard>
            <Text style={{ marginTop: 18, fontSize: 22, fontWeight: '700', color: C.textPrimary, letterSpacing: -0.4 }}>
              Nothing logged today
            </Text>
            <Text style={{ marginTop: 8, fontSize: 15, lineHeight: 22, fontWeight: '500', color: C.textSecondary, textAlign: 'center' }}>
              Use Quick Log or the floating button to capture meals, symptoms, and bowel activity.
            </Text>
          </View>
        )}
      </ScrollView>

      <PressScale
        onPress={() => {
          impactLightHaptic();
          setShowQuickSheet(true);
        }}
        style={{
          position: 'absolute',
          right: 24,
          bottom: 98 + Math.max(insets.bottom, 12),
        }}
      >
        <AppCard style={{ width: 60, height: 60, borderRadius: 30, overflow: 'hidden' }} intensity={60}>
          <LinearGradient
            colors={[C.gradientBrandStart, C.gradientBrandEnd]}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
            style={{ position: 'absolute', inset: 0 }}
          />
          <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
            <AppIcon symbol="plus" fallback="add" size={26} tintColor={C.onGradient} />
          </View>
        </AppCard>
      </PressScale>
    </View>
  );
}
