import { useCallback, useEffect, useMemo, useState } from 'react';
import { ActivityIndicator, ScrollView, Text, View } from 'react-native';
import { eachDayOfInterval, format, startOfDay, subDays } from 'date-fns';
import { useBowelLogs, useFoodLogs, useSymptomLogs } from '../../hooks/useLogs';
import { BowelLog, FoodLog, SymptomLog } from '../../types';
import { useColors } from '../../constants/colors';
import {
  AppCard,
  AppIcon,
  GlassSurface,
  PressScale,
  SpringSegmentedControl,
} from '../../components/ui/DesignPrimitives';
import { selectionHaptic } from '../../lib/haptics';

type Range = '7d' | '30d';

interface DayPoint {
  x: string;
  y: number;
}

function averagePainByDay(logs: SymptomLog[], days: Date[]): DayPoint[] {
  const sums: Record<string, { total: number; count: number }> = {};
  for (const day of days) {
    sums[format(day, 'yyyy-MM-dd')] = { total: 0, count: 0 };
  }
  for (const log of logs) {
    const key = format(startOfDay(new Date(log.logged_at)), 'yyyy-MM-dd');
    if (sums[key]) {
      sums[key].total += log.pain_level;
      sums[key].count += 1;
    }
  }
  return days.map((day) => {
    const key = format(day, 'yyyy-MM-dd');
    const entry = sums[key];
    return {
      x: format(day, 'M/d'),
      y: entry.count > 0 ? Math.round((entry.total / entry.count) * 10) / 10 : 0,
    };
  });
}

function bowelCountByDay(logs: BowelLog[], days: Date[]): DayPoint[] {
  const counts: Record<string, number> = {};
  for (const day of days) {
    counts[format(day, 'yyyy-MM-dd')] = 0;
  }
  for (const log of logs) {
    const key = format(startOfDay(new Date(log.logged_at)), 'yyyy-MM-dd');
    if (counts[key] !== undefined) counts[key] += 1;
  }
  return days.map((day) => ({
    x: format(day, 'M/d'),
    y: counts[format(day, 'yyyy-MM-dd')],
  }));
}

function HeatCell({
  date,
  pain,
  onPress,
}: {
  date: Date;
  pain: number | null;
  onPress: () => void;
}) {
  const C = useColors();
  const backgroundColor =
    pain == null ? C.fillQuaternary : pain <= 3 ? C.riskLow : pain <= 6 ? C.warning : C.riskHigh;

  return (
    <PressScale onPress={onPress}>
      <GlassSurface radius={12} intensity={44} style={{ width: 42, height: 42 }}>
        <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor }}>
          <Text style={{ fontSize: 11, fontWeight: '700', color: C.onGradient }}>{format(date, 'd')}</Text>
        </View>
      </GlassSurface>
    </PressScale>
  );
}

function BarChart({
  points,
  color,
}: {
  points: DayPoint[];
  color: string;
}) {
  const C = useColors();
  const maxY = Math.max(...points.map((point) => point.y), 1);

  return (
    <View style={{ marginTop: 12 }}>
      <View style={{ height: 132, flexDirection: 'row', alignItems: 'flex-end', gap: 4 }}>
        {points.map((point) => (
          <View key={point.x} style={{ flex: 1, alignItems: 'center', justifyContent: 'flex-end' }}>
            <View
              style={{
                width: '72%',
                minHeight: point.y > 0 ? 8 : 4,
                height: `${Math.max((point.y / maxY) * 100, point.y > 0 ? 8 : 4)}%`,
                borderRadius: 999,
                backgroundColor: point.y > 0 ? color : C.fillQuaternary,
              }}
            />
          </View>
        ))}
      </View>
      <View style={{ flexDirection: 'row', marginTop: 8 }}>
        {points.map((point, index) => (
          <Text key={point.x} style={{ flex: 1, textAlign: 'center', fontSize: 10, color: C.textMuted }}>
            {index === 0 || index === points.length - 1 || index === Math.floor(points.length / 2) ? point.x : ''}
          </Text>
        ))}
      </View>
    </View>
  );
}

export default function InsightsScreen() {
  const C = useColors();
  const [range, setRange] = useState<Range>('7d');
  const [loading, setLoading] = useState(true);
  const [symptomLogs, setSymptomLogs] = useState<SymptomLog[]>([]);
  const [bowelLogs, setBowelLogs] = useState<BowelLog[]>([]);
  const [foodLogs, setFoodLogs] = useState<FoodLog[]>([]);
  const [selectedHeatDay, setSelectedHeatDay] = useState<{ label: string; pain: number | null } | null>(null);
  const { fetchRange: fetchSymptomRange } = useSymptomLogs();
  const { fetchRange: fetchBowelRange } = useBowelLogs();
  const { fetchRange: fetchFoodRange } = useFoodLogs();

  const loadData = useCallback(async (currentRange: Range) => {
    setLoading(true);
    const days = currentRange === '7d' ? 7 : 30;
    const to = new Date();
    const from = subDays(to, days - 1);
    const [symptoms, bowels, foods] = await Promise.all([
      fetchSymptomRange(from, to),
      fetchBowelRange(from, to),
      fetchFoodRange(from, to),
    ]);
    setSymptomLogs(symptoms);
    setBowelLogs(bowels);
    setFoodLogs(foods);
    setLoading(false);
  }, [fetchBowelRange, fetchFoodRange, fetchSymptomRange]);

  useEffect(() => {
    loadData(range);
  }, [loadData, range]);

  const days = useMemo(
    () =>
      eachDayOfInterval({
        start: subDays(new Date(), (range === '7d' ? 7 : 30) - 1),
        end: new Date(),
      }),
    [range]
  );

  const symptomPoints = useMemo(() => averagePainByDay(symptomLogs, days), [days, symptomLogs]);
  const bowelPoints = useMemo(() => bowelCountByDay(bowelLogs, days), [bowelLogs, days]);
  const topTriggers = useMemo(() => {
    const counts: Record<string, number> = {};
    for (const food of foodLogs.filter((item) => item.is_trigger_food)) {
      const key = food.description.trim().toLowerCase();
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return Object.entries(counts).sort((a, b) => b[1] - a[1]).slice(0, 5);
  }, [foodLogs]);

  const heatmapDays = useMemo(() => eachDayOfInterval({ start: subDays(new Date(), 29), end: new Date() }), []);
  const painByDay = useMemo(() => {
    const result: Record<string, number | null> = {};
    for (const day of heatmapDays) result[format(day, 'yyyy-MM-dd')] = null;
    for (const log of symptomLogs) {
      const key = format(startOfDay(new Date(log.logged_at)), 'yyyy-MM-dd');
      if (!(key in result)) continue;
      result[key] = result[key] == null ? log.pain_level : Math.round(((result[key] as number) + log.pain_level) / 2);
    }
    return result;
  }, [heatmapDays, symptomLogs]);

  return (
    <ScrollView style={{ flex: 1 }} contentContainerStyle={{ paddingBottom: 120 }} showsVerticalScrollIndicator={false}>
      <View style={{ paddingTop: 58, paddingHorizontal: 20, paddingBottom: 18 }}>
        <Text style={{ fontSize: 32, fontWeight: '800', color: C.textPrimary, letterSpacing: -0.5 }}>
          Insights
        </Text>
        <Text style={{ marginTop: 4, fontSize: 15, fontWeight: '500', color: C.textSecondary, letterSpacing: -0.24 }}>
          Your trends, triggers, and symptom load.
        </Text>
      </View>

      <View style={{ paddingHorizontal: 20, marginBottom: 18 }}>
        <SpringSegmentedControl
          options={[
            { value: '7d' as const, label: '7 Days' },
            { value: '30d' as const, label: '30 Days' },
          ]}
          value={range}
          onChange={(nextRange) => {
            selectionHaptic();
            setRange(nextRange);
          }}
        />
      </View>

      {loading ? (
        <View style={{ paddingTop: 80, alignItems: 'center' }}>
          <ActivityIndicator size="large" color={C.primary} />
          <Text style={{ marginTop: 12, fontSize: 15, color: C.textSecondary }}>Loading your data…</Text>
        </View>
      ) : (
        <>
          <AppCard style={{ marginHorizontal: 20, marginBottom: 16, padding: 18 }}>
            <Text style={{ fontSize: 20, fontWeight: '700', color: C.textPrimary, letterSpacing: -0.4 }}>
              Symptom Trends
            </Text>
            <Text style={{ marginTop: 3, fontSize: 13, color: C.textSecondary }}>Average pain per day</Text>
            {symptomPoints.some((point) => point.y > 0) ? (
              <BarChart points={symptomPoints} color={C.primary} />
            ) : (
              <View style={{ paddingVertical: 28, alignItems: 'center' }}>
                <AppIcon symbol="waveform.path.ecg" fallback="pulse-outline" size={28} tintColor={C.primary} />
                <Text style={{ marginTop: 12, fontSize: 14, color: C.textSecondary }}>No symptom data for this period</Text>
              </View>
            )}
          </AppCard>

          <AppCard style={{ marginHorizontal: 20, marginBottom: 16, padding: 18 }}>
            <Text style={{ fontSize: 20, fontWeight: '700', color: C.textPrimary, letterSpacing: -0.4 }}>
              Bowel Frequency
            </Text>
            <Text style={{ marginTop: 3, fontSize: 13, color: C.textSecondary }}>Count per day</Text>
            {bowelPoints.some((point) => point.y > 0) ? (
              <BarChart points={bowelPoints} color={C.info} />
            ) : (
              <View style={{ paddingVertical: 28, alignItems: 'center' }}>
                <AppIcon symbol="drop.fill" fallback="water-outline" size={28} tintColor={C.info} />
                <Text style={{ marginTop: 12, fontSize: 14, color: C.textSecondary }}>No bowel data for this period</Text>
              </View>
            )}
          </AppCard>

          <AppCard style={{ marginHorizontal: 20, marginBottom: 16, padding: 18 }}>
            <Text style={{ fontSize: 20, fontWeight: '700', color: C.textPrimary, letterSpacing: -0.4 }}>
              Potential Triggers
            </Text>
            <Text style={{ marginTop: 3, fontSize: 13, color: C.textSecondary }}>Foods you marked as triggers</Text>
            {topTriggers.length > 0 ? (
              <View style={{ marginTop: 14, gap: 10 }}>
                {topTriggers.map(([food, count]) => (
                  <GlassSurface key={food} radius={18} intensity={40} style={{ padding: 14 }}>
                    <View style={{ flexDirection: 'row', alignItems: 'center' }}>
                      <View style={{ width: 10, height: 10, borderRadius: 5, backgroundColor: C.danger, marginRight: 10 }} />
                      <Text style={{ flex: 1, fontSize: 15, lineHeight: 20, color: C.textSecondary }}>
                        <Text style={{ fontWeight: '700', color: C.textPrimary }}>
                          {food.charAt(0).toUpperCase() + food.slice(1)}
                        </Text>{' '}
                        showed up {count} {count === 1 ? 'time' : 'times'}.
                      </Text>
                    </View>
                  </GlassSurface>
                ))}
              </View>
            ) : (
              <View style={{ paddingVertical: 28, alignItems: 'center' }}>
                <AppIcon symbol="leaf.fill" fallback="leaf-outline" size={28} tintColor={C.success} />
                <Text style={{ marginTop: 12, fontSize: 14, color: C.textSecondary }}>No trigger foods logged yet</Text>
              </View>
            )}
          </AppCard>

          <AppCard style={{ marginHorizontal: 20, marginBottom: 16, padding: 18 }}>
            <Text style={{ fontSize: 20, fontWeight: '700', color: C.textPrimary, letterSpacing: -0.4 }}>
              Pain Heatmap
            </Text>
            <Text style={{ marginTop: 3, fontSize: 13, color: C.textSecondary }}>
              Last 30 days. Tap a day for detail.
            </Text>
            <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 6, marginTop: 14 }}>
              {heatmapDays.map((day) => {
                const key = format(day, 'yyyy-MM-dd');
                const pain = painByDay[key];
                return (
                  <HeatCell
                    key={key}
                    date={day}
                    pain={pain}
                    onPress={() => {
                      selectionHaptic();
                      setSelectedHeatDay({
                        label: format(day, 'MMMM d'),
                        pain,
                      });
                    }}
                  />
                );
              })}
            </View>
            {selectedHeatDay ? (
              <GlassSurface radius={18} intensity={52} style={{ marginTop: 14, padding: 14 }}>
                <Text style={{ fontSize: 15, fontWeight: '700', color: C.textPrimary }}>
                  {selectedHeatDay.label}
                </Text>
                <Text style={{ marginTop: 4, fontSize: 13, color: C.textSecondary }}>
                  {selectedHeatDay.pain == null ? 'No symptom data recorded.' : `Average pain level: ${selectedHeatDay.pain}/10`}
                </Text>
              </GlassSurface>
            ) : null}
          </AppCard>
        </>
      )}
    </ScrollView>
  );
}
