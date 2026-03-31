import { useEffect, useState, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  ActivityIndicator,
} from 'react-native';
import { useBowelLogs, useSymptomLogs, useFoodLogs } from '../../hooks/useLogs';
import { Colors } from '../../constants/colors';
import { subDays, format, eachDayOfInterval, startOfDay } from 'date-fns';
import { BowelLog, FoodLog, SymptomLog } from '../../types';

type Range = '7d' | '30d';

interface DayPoint {
  x: string;
  y: number;
}

function avgPainByDay(logs: SymptomLog[], days: Date[]): DayPoint[] {
  const sums: Record<string, { total: number; count: number }> = {};
  for (const day of days) {
    sums[format(day, 'yyyy-MM-dd')] = { total: 0, count: 0 };
  }
  for (const log of logs) {
    const key = format(startOfDay(new Date(log.logged_at)), 'yyyy-MM-dd');
    if (sums[key] !== undefined) {
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
    if (counts[key] !== undefined) {
      counts[key] += 1;
    }
  }
  return days.map((day) => ({
    x: format(day, 'M/d'),
    y: counts[format(day, 'yyyy-MM-dd')],
  }));
}

function heatmapColor(avgPain: number | null): string {
  if (avgPain === null) return Colors.border;
  if (avgPain <= 3) return Colors.riskLow;
  if (avgPain <= 6) return Colors.warning;
  return Colors.riskHigh;
}

// ─── Simple chart components (no external charting library needed) ──────────

function SimpleLineChart({ points, maxY, color }: { points: DayPoint[]; maxY: number; color: string }) {
  if (points.length === 0) return null;
  const CHART_HEIGHT = 120;
  const CHART_BAR_WIDTH = 100 / points.length;

  return (
    <View style={{ height: CHART_HEIGHT + 24, marginTop: 8 }}>
      <View style={{ flex: 1, flexDirection: 'row', alignItems: 'flex-end', gap: 2 }}>
        {points.map((p, i) => {
          const heightPct = maxY > 0 ? (p.y / maxY) : 0;
          const barH = Math.max(heightPct * CHART_HEIGHT, p.y > 0 ? 4 : 2);
          return (
            <View key={i} style={{ flex: 1, alignItems: 'center', justifyContent: 'flex-end', height: CHART_HEIGHT }}>
              <View style={{ width: '70%', height: barH, backgroundColor: p.y > 0 ? color : Colors.border, borderRadius: 3, opacity: 0.85 }} />
            </View>
          );
        })}
      </View>
      <View style={{ flexDirection: 'row', marginTop: 4 }}>
        {points.map((p, i) => (
          <Text key={i} style={{ flex: 1, fontSize: 8, color: Colors.textMuted, textAlign: 'center' }} numberOfLines={1}>
            {i === 0 || i === points.length - 1 || i === Math.floor(points.length / 2) ? p.x : ''}
          </Text>
        ))}
      </View>
    </View>
  );
}

function SimpleBarChart({ points, color }: { points: DayPoint[]; color: string }) {
  if (points.length === 0) return null;
  const CHART_HEIGHT = 120;
  const maxY = Math.max(...points.map((p) => p.y), 1);

  return (
    <View style={{ height: CHART_HEIGHT + 24, marginTop: 8 }}>
      <View style={{ flex: 1, flexDirection: 'row', alignItems: 'flex-end', gap: 2 }}>
        {points.map((p, i) => {
          const barH = Math.max((p.y / maxY) * CHART_HEIGHT, p.y > 0 ? 4 : 2);
          return (
            <View key={i} style={{ flex: 1, alignItems: 'center', justifyContent: 'flex-end', height: CHART_HEIGHT }}>
              <View style={{ width: '70%', height: barH, backgroundColor: p.y > 0 ? color : Colors.border, borderRadius: 3 }} />
            </View>
          );
        })}
      </View>
      <View style={{ flexDirection: 'row', marginTop: 4 }}>
        {points.map((p, i) => (
          <Text key={i} style={{ flex: 1, fontSize: 8, color: Colors.textMuted, textAlign: 'center' }} numberOfLines={1}>
            {i === 0 || i === points.length - 1 || i === Math.floor(points.length / 2) ? p.x : ''}
          </Text>
        ))}
      </View>
    </View>
  );
}

export default function InsightsScreen() {
  const [range, setRange] = useState<Range>('7d');
  const [loading, setLoading] = useState(true);

  const [symptomLogs, setSymptomLogs] = useState<SymptomLog[]>([]);
  const [bowelLogs, setBowelLogs] = useState<BowelLog[]>([]);
  const [foodLogs, setFoodLogs] = useState<FoodLog[]>([]);

  const { fetchRange: fetchSymptomRange } = useSymptomLogs();
  const { fetchRange: fetchBowelRange } = useBowelLogs();
  const { fetchRange: fetchFoodRange } = useFoodLogs();

  const loadData = useCallback(async (r: Range) => {
    setLoading(true);
    const days = r === '7d' ? 7 : 30;
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
  }, [fetchSymptomRange, fetchBowelRange, fetchFoodRange]);

  useEffect(() => {
    loadData(range);
  }, [range]);

  const days = eachDayOfInterval({
    start: subDays(new Date(), (range === '7d' ? 7 : 30) - 1),
    end: new Date(),
  });

  const symptomPoints = avgPainByDay(symptomLogs, days);
  const bowelPoints = bowelCountByDay(bowelLogs, days);

  const hasSymptomData = symptomPoints.some((p) => p.y > 0);
  const hasBowelData = bowelPoints.some((p) => p.y > 0);

  // Trigger food analysis
  const triggerFoods = foodLogs.filter((f) => f.is_trigger_food);
  const triggerCounts: Record<string, number> = {};
  for (const food of triggerFoods) {
    const key = food.description.trim().toLowerCase();
    triggerCounts[key] = (triggerCounts[key] ?? 0) + 1;
  }
  const topTriggers = Object.entries(triggerCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5);

  // Heatmap (last 30 days)
  const heatmapDays = eachDayOfInterval({ start: subDays(new Date(), 29), end: new Date() });
  const painByDayMap: Record<string, number | null> = {};
  for (const day of heatmapDays) {
    painByDayMap[format(day, 'yyyy-MM-dd')] = null;
  }
  for (const log of symptomLogs) {
    const key = format(startOfDay(new Date(log.logged_at)), 'yyyy-MM-dd');
    if (key in painByDayMap) {
      const current = painByDayMap[key];
      if (current === null) {
        painByDayMap[key] = log.pain_level;
      } else {
        painByDayMap[key] = (current + log.pain_level) / 2;
      }
    }
  }

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Insights</Text>
        <Text style={styles.headerSubtitle}>Your health trends at a glance</Text>
      </View>

      {/* Range Toggle */}
      <View style={styles.rangeToggle}>
        <TouchableOpacity
          style={[styles.rangeButton, range === '7d' && styles.rangeButtonActive]}
          onPress={() => setRange('7d')}
          activeOpacity={0.8}
        >
          <Text style={[styles.rangeButtonText, range === '7d' && styles.rangeButtonTextActive]}>7 Days</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.rangeButton, range === '30d' && styles.rangeButtonActive]}
          onPress={() => setRange('30d')}
          activeOpacity={0.8}
        >
          <Text style={[styles.rangeButtonText, range === '30d' && styles.rangeButtonTextActive]}>30 Days</Text>
        </TouchableOpacity>
      </View>

      {loading ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={Colors.primary} />
          <Text style={styles.loadingText}>Loading your data...</Text>
        </View>
      ) : (
        <>
          {/* Symptom Trends */}
          <View style={styles.card}>
            <Text style={styles.cardTitle}>Symptom Trends</Text>
            <Text style={styles.cardSubtitle}>Average pain level per day (0–10)</Text>
            {hasSymptomData ? (
              <SimpleLineChart points={symptomPoints} maxY={10} color={Colors.primary} />
            ) : (
              <View style={styles.noDataContainer}>
                <Text style={styles.noDataEmoji}>📊</Text>
                <Text style={styles.noDataText}>No symptom data for this period</Text>
              </View>
            )}
          </View>

          {/* Bowel Movement Frequency */}
          <View style={styles.card}>
            <Text style={styles.cardTitle}>Bowel Movement Frequency</Text>
            <Text style={styles.cardSubtitle}>Count per day</Text>
            {hasBowelData ? (
              <SimpleBarChart points={bowelPoints} color={Colors.info} />
            ) : (
              <View style={styles.noDataContainer}>
                <Text style={styles.noDataEmoji}>🚽</Text>
                <Text style={styles.noDataText}>No bowel movement data for this period</Text>
              </View>
            )}
          </View>

          {/* Potential Triggers */}
          <View style={styles.card}>
            <Text style={styles.cardTitle}>Potential Triggers</Text>
            <Text style={styles.cardSubtitle}>Foods you marked as triggers</Text>
            {topTriggers.length > 0 ? (
              <>
                {topTriggers.map(([food, count]) => (
                  <View key={food} style={styles.triggerRow}>
                    <View style={styles.triggerDot} />
                    <Text style={styles.triggerText}>
                      You logged{' '}
                      <Text style={styles.triggerFoodName}>
                        {food.charAt(0).toUpperCase() + food.slice(1)}
                      </Text>{' '}
                      {count} {count === 1 ? 'time' : 'times'} this period
                    </Text>
                  </View>
                ))}
              </>
            ) : (
              <View style={styles.noDataContainer}>
                <Text style={styles.noDataEmoji}>✅</Text>
                <Text style={styles.noDataText}>No trigger foods logged yet</Text>
              </View>
            )}
          </View>

          {/* Calendar Heatmap */}
          <View style={styles.card}>
            <Text style={styles.cardTitle}>Pain Heatmap</Text>
            <Text style={styles.cardSubtitle}>Last 30 days — {format(subDays(new Date(), 29), 'MMMM d')} to {format(new Date(), 'MMMM d')}</Text>
            <View style={styles.heatmapGrid}>
              {heatmapDays.map((day) => {
                const key = format(day, 'yyyy-MM-dd');
                const pain = painByDayMap[key] ?? null;
                const color = heatmapColor(pain);
                return (
                  <View key={key} style={[styles.heatmapCell, { backgroundColor: color }]}>
                    <Text style={styles.heatmapDayText}>{format(day, 'd')}</Text>
                  </View>
                );
              })}
            </View>
            <View style={styles.heatmapLegend}>
              <View style={styles.legendItem}>
                <View style={[styles.legendDot, { backgroundColor: Colors.riskLow }]} />
                <Text style={styles.legendText}>Low (0-3)</Text>
              </View>
              <View style={styles.legendItem}>
                <View style={[styles.legendDot, { backgroundColor: Colors.warning }]} />
                <Text style={styles.legendText}>Moderate (4-6)</Text>
              </View>
              <View style={styles.legendItem}>
                <View style={[styles.legendDot, { backgroundColor: Colors.riskHigh }]} />
                <Text style={styles.legendText}>High (7-10)</Text>
              </View>
              <View style={styles.legendItem}>
                <View style={[styles.legendDot, { backgroundColor: Colors.border }]} />
                <Text style={styles.legendText}>No data</Text>
              </View>
            </View>
          </View>
        </>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  content: {
    paddingBottom: 40,
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
  rangeToggle: {
    flexDirection: 'row',
    margin: 20,
    backgroundColor: Colors.border,
    borderRadius: 10,
    padding: 3,
  },
  rangeButton: {
    flex: 1,
    paddingVertical: 8,
    alignItems: 'center',
    borderRadius: 8,
  },
  rangeButtonActive: {
    backgroundColor: Colors.white,
    shadowColor: '#000',
    shadowOpacity: 0.1,
    shadowRadius: 3,
    elevation: 2,
  },
  rangeButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: Colors.textSecondary,
  },
  rangeButtonTextActive: {
    color: Colors.textPrimary,
  },
  loadingContainer: {
    alignItems: 'center',
    paddingVertical: 60,
  },
  loadingText: {
    fontSize: 14,
    color: Colors.textSecondary,
    marginTop: 12,
  },
  card: {
    backgroundColor: Colors.white,
    borderRadius: 16,
    marginHorizontal: 20,
    marginBottom: 16,
    padding: 16,
    shadowColor: '#000',
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  cardTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: Colors.textPrimary,
    marginBottom: 2,
  },
  cardSubtitle: {
    fontSize: 12,
    color: Colors.textSecondary,
    marginBottom: 12,
  },
  noDataContainer: {
    alignItems: 'center',
    paddingVertical: 28,
  },
  noDataEmoji: {
    fontSize: 36,
    marginBottom: 8,
  },
  noDataText: {
    fontSize: 14,
    color: Colors.textSecondary,
  },
  triggerRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: Colors.background,
  },
  triggerDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: Colors.danger,
    marginTop: 5,
    marginRight: 10,
    flexShrink: 0,
  },
  triggerText: {
    fontSize: 14,
    color: Colors.textSecondary,
    flex: 1,
    lineHeight: 20,
  },
  triggerFoodName: {
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  heatmapGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 5,
    marginBottom: 14,
  },
  heatmapCell: {
    width: 36,
    height: 36,
    borderRadius: 6,
    justifyContent: 'center',
    alignItems: 'center',
  },
  heatmapDayText: {
    fontSize: 10,
    color: Colors.white,
    fontWeight: '600',
  },
  heatmapLegend: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
  legendItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  legendDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
  },
  legendText: {
    fontSize: 11,
    color: Colors.textSecondary,
  },
});
