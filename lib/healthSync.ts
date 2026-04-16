import { Platform } from 'react-native';
import { supabase } from './supabase';
import { ENV } from './env';
import { HealthMetric } from '../types';

type HealthPermissionResult = {
  supported: boolean;
  granted: boolean;
  message: string;
};

type SyncResult = {
  synced: number;
  skipped: number;
  message: string;
};

export type HealthSyncDiagnostic = {
  metric: HealthMetric;
  sampleCount: number;
  lastStatus: 'idle' | 'syncing' | 'success' | 'error';
  lastError: string | null;
  lastCursor: string | null;
  lastSyncedAt: string | null;
  updatedAt: string | null;
};

type AppleHealthModule = {
  Constants?: {
    Permissions?: Record<string, string>;
  };
  initHealthKit?: (permissions: unknown, callback: (error?: string) => void) => void;
  getDailyStepCountSamples?: (options: Record<string, unknown>, callback: (error?: string, samples?: unknown[]) => void) => void;
  getHeartRateSamples?: (options: Record<string, unknown>, callback: (error?: string, samples?: unknown[]) => void) => void;
  getSleepSamples?: (options: Record<string, unknown>, callback: (error?: string, samples?: unknown[]) => void) => void;
  getActiveEnergyBurned?: (options: Record<string, unknown>, callback: (error?: string, samples?: unknown[]) => void) => void;
  getActiveEnergyBurnedSamples?: (options: Record<string, unknown>, callback: (error?: string, samples?: unknown[]) => void) => void;
};

type HealthSyncRow = {
  metric: HealthMetric;
  last_status?: 'idle' | 'syncing' | 'success' | 'error';
  last_error?: string | null;
  last_cursor: string | null;
  last_synced_at?: string | null;
  updated_at?: string | null;
};

type NormalizedSample = {
  metric: HealthMetric;
  value: number;
  unit: string;
  observed_at: string;
  metadata: Record<string, unknown>;
};

const METRICS: HealthMetric[] = ['steps', 'heart_rate', 'sleep_hours', 'active_energy_kcal'];

export const HEALTH_METRICS = METRICS;

function getAppleHealthModule(): AppleHealthModule | null {
  if (Platform.OS !== 'ios') return null;
  try {
    // Optional dependency; loaded lazily to keep Android/web safe.
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const mod = require('react-native-health');
    return mod?.default ?? mod;
  } catch {
    return null;
  }
}

function asRecord(value: unknown): Record<string, unknown> {
  if (value && typeof value === 'object') return value as Record<string, unknown>;
  return {};
}

function asNumber(value: unknown): number | null {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string') {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function toISOStringSafe(value: unknown): string | null {
  if (typeof value !== 'string' || !value) return null;
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed.toISOString();
}

function computeLookbackCursor(): string {
  const now = Date.now();
  const lookbackMs = ENV.HEALTH_SYNC_LOOKBACK_DAYS * 24 * 60 * 60 * 1000;
  return new Date(now - lookbackMs).toISOString();
}

function chunk<T>(items: T[], size: number): T[][] {
  if (size <= 0) return [items];
  const result: T[][] = [];
  for (let i = 0; i < items.length; i += size) {
    result.push(items.slice(i, i + size));
  }
  return result;
}

async function readSyncState(userId: string): Promise<Record<HealthMetric, string | null>> {
  const result: Record<HealthMetric, string | null> = {
    steps: null,
    heart_rate: null,
    sleep_hours: null,
    active_energy_kcal: null,
  };

  const { data, error } = await supabase
    .from('health_sync_state')
    .select('metric,last_cursor')
    .eq('user_id', userId)
    .eq('provider', 'apple_health');

  if (error) {
    console.warn('readSyncState', error.message);
    return result;
  }

  for (const row of (data ?? []) as HealthSyncRow[]) {
    if (METRICS.includes(row.metric)) {
      result[row.metric] = row.last_cursor;
    }
  }

  return result;
}

export async function getHealthSyncDiagnostics(userId: string): Promise<HealthSyncDiagnostic[]> {
  const defaultByMetric: Record<HealthMetric, HealthSyncDiagnostic> = {
    steps: {
      metric: 'steps',
      sampleCount: 0,
      lastStatus: 'idle',
      lastError: null,
      lastCursor: null,
      lastSyncedAt: null,
      updatedAt: null,
    },
    heart_rate: {
      metric: 'heart_rate',
      sampleCount: 0,
      lastStatus: 'idle',
      lastError: null,
      lastCursor: null,
      lastSyncedAt: null,
      updatedAt: null,
    },
    sleep_hours: {
      metric: 'sleep_hours',
      sampleCount: 0,
      lastStatus: 'idle',
      lastError: null,
      lastCursor: null,
      lastSyncedAt: null,
      updatedAt: null,
    },
    active_energy_kcal: {
      metric: 'active_energy_kcal',
      sampleCount: 0,
      lastStatus: 'idle',
      lastError: null,
      lastCursor: null,
      lastSyncedAt: null,
      updatedAt: null,
    },
  };

  const [stateRes, counts] = await Promise.all([
    supabase
      .from('health_sync_state')
      .select('metric,last_status,last_error,last_cursor,last_synced_at,updated_at')
      .eq('user_id', userId)
      .eq('provider', 'apple_health'),
    Promise.all(
      METRICS.map(async (metric) => {
        const { count } = await supabase
          .from('health_samples')
          .select('*', { count: 'exact', head: true })
          .eq('user_id', userId)
          .eq('metric', metric)
          .eq('source', 'apple_health');
        return [metric, count ?? 0] as const;
      })
    ),
  ]);

  if (stateRes.error) {
    console.warn('getHealthSyncDiagnostics.state', stateRes.error.message);
  }

  for (const row of (stateRes.data ?? []) as HealthSyncRow[]) {
    if (!METRICS.includes(row.metric)) continue;
    defaultByMetric[row.metric] = {
      ...defaultByMetric[row.metric],
      lastStatus: row.last_status ?? 'idle',
      lastError: row.last_error ?? null,
      lastCursor: row.last_cursor ?? null,
      lastSyncedAt: row.last_synced_at ?? null,
      updatedAt: row.updated_at ?? null,
    };
  }

  for (const [metric, count] of counts) {
    defaultByMetric[metric] = {
      ...defaultByMetric[metric],
      sampleCount: count,
    };
  }

  return METRICS.map((metric) => defaultByMetric[metric]);
}

async function upsertHealthSyncState(
  userId: string,
  metric: HealthMetric,
  status: 'syncing' | 'success' | 'error',
  options?: { error?: string; cursor?: string | null }
) {
  const payload: Record<string, unknown> = {
    user_id: userId,
    provider: 'apple_health',
    metric,
    last_status: status,
    last_error: options?.error ?? null,
  };

  if (status === 'success') {
    payload.last_synced_at = new Date().toISOString();
  }

  if (typeof options?.cursor === 'string') {
    payload.last_cursor = options.cursor;
  }

  await supabase.from('health_sync_state').upsert({
    ...payload,
  }, { onConflict: 'user_id,provider,metric' });
}

function normalizeSteps(raw: unknown): NormalizedSample | null {
  const sample = asRecord(raw);
  const value = asNumber(sample.value) ?? asNumber(sample.steps);
  const observedAt = toISOStringSafe(sample.endDate) ?? toISOStringSafe(sample.startDate);
  if (value === null || observedAt === null) return null;
  return {
    metric: 'steps',
    value,
    unit: 'count',
    observed_at: observedAt,
    metadata: { source_name: sample.sourceName ?? null },
  };
}

function normalizeHeartRate(raw: unknown): NormalizedSample | null {
  const sample = asRecord(raw);
  const value = asNumber(sample.value);
  const observedAt = toISOStringSafe(sample.startDate) ?? toISOStringSafe(sample.endDate);
  if (value === null || observedAt === null) return null;
  return {
    metric: 'heart_rate',
    value,
    unit: 'bpm',
    observed_at: observedAt,
    metadata: { source_name: sample.sourceName ?? null },
  };
}

function normalizeSleep(raw: unknown): NormalizedSample | null {
  const sample = asRecord(raw);
  const start = toISOStringSafe(sample.startDate);
  const end = toISOStringSafe(sample.endDate);
  if (!start || !end) return null;

  const durationHours = (new Date(end).getTime() - new Date(start).getTime()) / (1000 * 60 * 60);
  if (!Number.isFinite(durationHours) || durationHours <= 0) return null;

  return {
    metric: 'sleep_hours',
    value: Number(durationHours.toFixed(4)),
    unit: 'hours',
    observed_at: end,
    metadata: {
      start_date: start,
      sleep_value: sample.value ?? null,
      source_name: sample.sourceName ?? null,
    },
  };
}

function normalizeActiveEnergy(raw: unknown): NormalizedSample | null {
  const sample = asRecord(raw);
  const value = asNumber(sample.value);
  const observedAt = toISOStringSafe(sample.endDate) ?? toISOStringSafe(sample.startDate);
  if (value === null || observedAt === null) return null;
  return {
    metric: 'active_energy_kcal',
    value,
    unit: 'kcal',
    observed_at: observedAt,
    metadata: { source_name: sample.sourceName ?? null },
  };
}

function resolveSyncMethod(health: AppleHealthModule, metric: HealthMetric) {
  const mapping: Record<HealthMetric, string[]> = {
    steps: ['getDailyStepCountSamples'],
    heart_rate: ['getHeartRateSamples'],
    sleep_hours: ['getSleepSamples'],
    active_energy_kcal: ['getActiveEnergyBurned', 'getActiveEnergyBurnedSamples'],
  };

  for (const methodName of mapping[metric]) {
    const candidate = (health as Record<string, unknown>)[methodName];
    if (typeof candidate === 'function') {
      return candidate as (options: Record<string, unknown>, callback: (error?: string, samples?: unknown[]) => void) => void;
    }
  }
  return null;
}

async function fetchMetricSamples(
  health: AppleHealthModule,
  metric: HealthMetric,
  startDateIso: string,
  endDateIso: string
): Promise<NormalizedSample[]> {
  const method = resolveSyncMethod(health, metric);
  if (!method) {
    throw new Error(`Health bridge method missing for metric: ${metric}`);
  }

  const options = {
    startDate: startDateIso,
    endDate: endDateIso,
    ascending: true,
    includeManuallyAdded: true,
  };

  const rawSamples = await new Promise<unknown[]>((resolve, reject) => {
    method(options, (error?: string, samples?: unknown[]) => {
      if (error) {
        reject(new Error(error));
        return;
      }
      resolve(samples ?? []);
    });
  });

  const normalizer: Record<HealthMetric, (sample: unknown) => NormalizedSample | null> = {
    steps: normalizeSteps,
    heart_rate: normalizeHeartRate,
    sleep_hours: normalizeSleep,
    active_energy_kcal: normalizeActiveEnergy,
  };

  return rawSamples
    .map(normalizer[metric])
    .filter((sample): sample is NormalizedSample => sample !== null)
    .sort((a, b) => new Date(a.observed_at).getTime() - new Date(b.observed_at).getTime());
}

async function writeSamples(userId: string, samples: NormalizedSample[]): Promise<number> {
  if (samples.length === 0) return 0;

  const batches = chunk(samples, ENV.HEALTH_SYNC_BATCH_SIZE);
  let synced = 0;

  for (const batch of batches) {
    const { error } = await supabase.from('health_samples').upsert(
      batch.map((sample) => ({
        user_id: userId,
        metric: sample.metric,
        value: sample.value,
        unit: sample.unit,
        observed_at: sample.observed_at,
        source: 'apple_health',
        metadata: sample.metadata,
      })),
      { onConflict: 'user_id,metric,observed_at,source' }
    );

    if (error) {
      throw new Error(error.message);
    }

    synced += batch.length;
  }

  return synced;
}

export async function requestAppleHealthPermissions(userId: string): Promise<HealthPermissionResult> {
  const health = getAppleHealthModule();
  if (!health) {
    return {
      supported: false,
      granted: false,
      message: 'Apple Health bridge is not installed yet. Add react-native-health and iOS HealthKit capability.',
    };
  }

  const permissions = health.Constants?.Permissions;
  if (!permissions || !health.initHealthKit) {
    return {
      supported: false,
      granted: false,
      message: 'Apple Health module is available but missing required APIs.',
    };
  }

  const permissionConfig = {
    permissions: {
      read: [
        permissions.StepCount,
        permissions.HeartRate,
        permissions.SleepAnalysis,
        permissions.ActiveEnergyBurned,
      ].filter(Boolean),
      write: [] as string[],
    },
  };

  return new Promise((resolve) => {
    health.initHealthKit?.(permissionConfig, async (error?: string) => {
      if (error) {
        await supabase
          .from('app_settings')
          .upsert({ user_id: userId, health_sync_enabled: false }, { onConflict: 'user_id' });
        resolve({ supported: true, granted: false, message: `Permission denied: ${error}` });
        return;
      }

      await supabase
        .from('app_settings')
        .upsert({ user_id: userId, health_sync_enabled: true }, { onConflict: 'user_id' });
      resolve({ supported: true, granted: true, message: 'Apple Health permissions granted.' });
    });
  });
}

export async function syncAppleHealthData(userId: string): Promise<SyncResult> {
  const health = getAppleHealthModule();
  if (!health) {
    return {
      synced: 0,
      skipped: 0,
      message: 'Health sync not available on this platform/build yet.',
    };
  }

  try {
    const nowIso = new Date().toISOString();
    const syncState = await readSyncState(userId);
    let synced = 0;
    let skipped = 0;

    for (const metric of METRICS) {
      const cursor = syncState[metric] ?? computeLookbackCursor();
      await upsertHealthSyncState(userId, metric, 'syncing', { cursor });

      try {
        const samples = await fetchMetricSamples(health, metric, cursor, nowIso);
        synced += await writeSamples(userId, samples);

        const latestCursor = samples.length > 0
          ? samples[samples.length - 1].observed_at
          : cursor;

        await upsertHealthSyncState(userId, metric, 'success', { cursor: latestCursor });
      } catch (error: any) {
        skipped += 1;
        await upsertHealthSyncState(userId, metric, 'error', {
          error: error?.message ?? `Failed syncing ${metric}`,
          cursor,
        });
      }
    }

    return {
      synced,
      skipped,
      message:
        skipped > 0
          ? `Health sync completed with ${synced} sample(s) synced and ${skipped} metric(s) skipped.`
          : `Health sync completed: ${synced} sample(s) synced across ${METRICS.length} metrics.`,
    };
  } catch (error: any) {
    const message = error?.message ?? 'Unexpected health sync error.';
    for (const metric of METRICS) {
      await upsertHealthSyncState(userId, metric, 'error', { error: message });
    }
    return { synced: 0, skipped: 0, message };
  }
}
