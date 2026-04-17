import { useCallback } from 'react';
import { supabase } from '../lib/supabase';
import { ENV } from '../lib/env';
import { useAuthStore } from '../store/authStore';
import { useSyncQueue } from './useSyncQueue';
import {
  BowelLog,
  BowelLogInput,
  FoodLog,
  FoodLogInput,
  Medication,
  MedicationLog,
  MedicationLogInput,
  MenstrualLog,
  MenstrualLogInput,
  SleepLog,
  SleepLogInput,
  SymptomLog,
  SymptomLogInput,
  WeightLog,
  WeightLogInput,
} from '../types';
import {
  appendDemoRecord,
  getDemoCollection,
  setDemoCollection,
} from '../lib/demoData';

const QUERY_TIMEOUT_MS = 10_000;
const READ_RETRIES = 1;

type SupabaseResult<T> = {
  data: T | null;
  error: { message?: string } | null;
};

async function withTimeout<T>(promise: PromiseLike<T>, timeoutMs: number, label: string): Promise<T> {
  let timer: ReturnType<typeof setTimeout> | null = null;
  const timeout = new Promise<never>((_, reject) => {
    timer = setTimeout(() => reject(new Error(`${label} timed out after ${timeoutMs}ms`)), timeoutMs);
  });

  try {
    return await Promise.race([Promise.resolve(promise), timeout]);
  } finally {
    if (timer) clearTimeout(timer);
  }
}

async function runQuery<T>(
  label: string,
  fn: () => PromiseLike<SupabaseResult<T>>,
  options?: { retries?: number; timeoutMs?: number }
): Promise<T | null> {
  const retries = options?.retries ?? 0;
  const timeoutMs = options?.timeoutMs ?? QUERY_TIMEOUT_MS;

  for (let attempt = 0; attempt <= retries; attempt += 1) {
    try {
      const result = await withTimeout(fn(), timeoutMs, label);
      if (result.error) throw new Error(result.error.message ?? `${label} failed`);
      return result.data;
    } catch (error) {
      const isLast = attempt === retries;
      if (isLast) {
        console.error(label, error);
        return null;
      }
    }
  }

  return null;
}

async function readMany<T>(label: string, fn: () => PromiseLike<SupabaseResult<T[]>>): Promise<T[]> {
  const data = await runQuery<T[]>(label, fn, { retries: READ_RETRIES });
  return data ?? [];
}

async function insertOne<T>(label: string, fn: () => PromiseLike<SupabaseResult<T>>): Promise<T | null> {
  return runQuery<T>(label, fn);
}

function makeId() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (char) => {
    const random = (Math.random() * 16) | 0;
    return (char === 'x' ? random : (random & 0x3) | 0x8).toString(16);
  });
}

function sortByDateDesc<T extends { created_at: string }>(items: T[], getDate?: (item: T) => string) {
  return [...items].sort((a, b) => {
    const aTime = new Date(getDate ? getDate(a) : a.created_at).getTime();
    const bTime = new Date(getDate ? getDate(b) : b.created_at).getTime();
    return bTime - aTime;
  });
}

function isWithinDay(value: string, dayStart: Date) {
  return new Date(value).getTime() >= dayStart.getTime();
}

function isWithinRange(value: string, from: Date, to: Date) {
  const timestamp = new Date(value).getTime();
  return timestamp >= from.getTime() && timestamp <= to.getTime();
}

function isDateWithinRange(value: string, from: Date, to: Date) {
  const timestamp = new Date(`${value}T00:00:00`).getTime();
  return timestamp >= new Date(from.toDateString()).getTime() && timestamp <= new Date(to.toDateString()).getTime();
}

export function useFoodLogs() {
  const userId = useAuthStore((state) => state.userId);
  const { enqueue } = useSyncQueue();
  const isDemoMode = ENV.DEMO_MODE;

  const fetchToday = useCallback(async (): Promise<FoodLog[]> => {
    if (!userId) return [];
    if (isDemoMode) {
      const start = new Date();
      start.setHours(0, 0, 0, 0);
      const demoLogs = await getDemoCollection('food_logs');
      return sortByDateDesc(demoLogs.filter((log) => isWithinDay(log.logged_at, start)), (log) => log.logged_at);
    }
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    return readMany<FoodLog>('fetchTodayFood', () =>
      supabase.from('food_logs').select('*').eq('user_id', userId).gte('logged_at', start.toISOString()).order('logged_at', { ascending: false })
    );
  }, [isDemoMode, userId]);

  const fetchRange = useCallback(async (from: Date, to: Date): Promise<FoodLog[]> => {
    if (!userId) return [];
    if (isDemoMode) {
      const demoLogs = await getDemoCollection('food_logs');
      return sortByDateDesc(demoLogs.filter((log) => isWithinRange(log.logged_at, from, to)), (log) => log.logged_at);
    }
    return readMany<FoodLog>('fetchRangeFood', () =>
      supabase.from('food_logs').select('*').eq('user_id', userId).gte('logged_at', from.toISOString()).lte('logged_at', to.toISOString()).order('logged_at', { ascending: false })
    );
  }, [isDemoMode, userId]);

  const add = useCallback(async (input: FoodLogInput): Promise<FoodLog | null> => {
    if (!userId) return null;
    const record: FoodLog = { ...input, id: makeId(), user_id: userId, created_at: new Date().toISOString() };
    if (isDemoMode) {
      return appendDemoRecord('food_logs', record);
    }
    enqueue('food_logs', record as unknown as Record<string, unknown>);
    const data = await insertOne<FoodLog>('addFood', () => supabase.from('food_logs').insert(record).select().single());
    return data ?? record;
  }, [enqueue, isDemoMode, userId]);

  return { fetchToday, fetchRange, add };
}

export function useBowelLogs() {
  const userId = useAuthStore((state) => state.userId);
  const { enqueue } = useSyncQueue();
  const isDemoMode = ENV.DEMO_MODE;

  const fetchToday = useCallback(async (): Promise<BowelLog[]> => {
    if (!userId) return [];
    if (isDemoMode) {
      const start = new Date();
      start.setHours(0, 0, 0, 0);
      const demoLogs = await getDemoCollection('bowel_logs');
      return sortByDateDesc(demoLogs.filter((log) => isWithinDay(log.logged_at, start)), (log) => log.logged_at);
    }
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    return readMany<BowelLog>('fetchTodayBowel', () =>
      supabase.from('bowel_logs').select('*').eq('user_id', userId).gte('logged_at', start.toISOString()).order('logged_at', { ascending: false })
    );
  }, [isDemoMode, userId]);

  const fetchRange = useCallback(async (from: Date, to: Date): Promise<BowelLog[]> => {
    if (!userId) return [];
    if (isDemoMode) {
      const demoLogs = await getDemoCollection('bowel_logs');
      return sortByDateDesc(demoLogs.filter((log) => isWithinRange(log.logged_at, from, to)), (log) => log.logged_at);
    }
    return readMany<BowelLog>('fetchRangeBowel', () =>
      supabase.from('bowel_logs').select('*').eq('user_id', userId).gte('logged_at', from.toISOString()).lte('logged_at', to.toISOString()).order('logged_at', { ascending: false })
    );
  }, [isDemoMode, userId]);

  const add = useCallback(async (input: BowelLogInput): Promise<BowelLog | null> => {
    if (!userId) return null;
    const record: BowelLog = { ...input, id: makeId(), user_id: userId, created_at: new Date().toISOString() };
    if (isDemoMode) {
      return appendDemoRecord('bowel_logs', record);
    }
    enqueue('bowel_logs', record as unknown as Record<string, unknown>);
    const data = await insertOne<BowelLog>('addBowel', () => supabase.from('bowel_logs').insert(record).select().single());
    return data ?? record;
  }, [enqueue, isDemoMode, userId]);

  return { fetchToday, fetchRange, add };
}

export function useSymptomLogs() {
  const userId = useAuthStore((state) => state.userId);
  const { enqueue } = useSyncQueue();
  const isDemoMode = ENV.DEMO_MODE;

  const fetchToday = useCallback(async (): Promise<SymptomLog[]> => {
    if (!userId) return [];
    if (isDemoMode) {
      const start = new Date();
      start.setHours(0, 0, 0, 0);
      const demoLogs = await getDemoCollection('symptom_logs');
      return sortByDateDesc(demoLogs.filter((log) => isWithinDay(log.logged_at, start)), (log) => log.logged_at);
    }
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    return readMany<SymptomLog>('fetchTodaySymptom', () =>
      supabase.from('symptom_logs').select('*').eq('user_id', userId).gte('logged_at', start.toISOString()).order('logged_at', { ascending: false })
    );
  }, [isDemoMode, userId]);

  const fetchRange = useCallback(async (from: Date, to: Date): Promise<SymptomLog[]> => {
    if (!userId) return [];
    if (isDemoMode) {
      const demoLogs = await getDemoCollection('symptom_logs');
      return sortByDateDesc(demoLogs.filter((log) => isWithinRange(log.logged_at, from, to)), (log) => log.logged_at);
    }
    return readMany<SymptomLog>('fetchRangeSymptom', () =>
      supabase.from('symptom_logs').select('*').eq('user_id', userId).gte('logged_at', from.toISOString()).lte('logged_at', to.toISOString()).order('logged_at', { ascending: false })
    );
  }, [isDemoMode, userId]);

  const add = useCallback(async (input: SymptomLogInput): Promise<SymptomLog | null> => {
    if (!userId) return null;
    const record: SymptomLog = { ...input, id: makeId(), user_id: userId, created_at: new Date().toISOString() };
    if (isDemoMode) {
      return appendDemoRecord('symptom_logs', record);
    }
    enqueue('symptom_logs', record as unknown as Record<string, unknown>);
    const data = await insertOne<SymptomLog>('addSymptom', () => supabase.from('symptom_logs').insert(record).select().single());
    return data ?? record;
  }, [enqueue, isDemoMode, userId]);

  return { fetchToday, fetchRange, add };
}

export function useMedications() {
  const userId = useAuthStore((state) => state.userId);
  const isDemoMode = ENV.DEMO_MODE;

  const fetchActive = useCallback(async (): Promise<Medication[]> => {
    if (!userId) return [];
    if (isDemoMode) {
      const meds = await getDemoCollection('medications');
      return meds.filter((medication) => medication.is_active).sort((a, b) => a.name.localeCompare(b.name));
    }
    return readMany<Medication>('fetchMeds', () =>
      supabase.from('medications').select('*').eq('user_id', userId).eq('is_active', true).order('name')
    );
  }, [isDemoMode, userId]);

  const add = useCallback(async (med: Omit<Medication, 'id' | 'user_id' | 'created_at'>): Promise<Medication | null> => {
    if (!userId) return null;
    const record: Medication = {
      ...med,
      id: makeId(),
      user_id: userId,
      created_at: new Date().toISOString(),
    };
    if (isDemoMode) {
      return appendDemoRecord('medications', record);
    }
    return insertOne<Medication>('addMed', () =>
      supabase.from('medications').insert({ ...med, user_id: userId }).select().single()
    );
  }, [isDemoMode, userId]);

  const update = useCallback(async (id: string, updates: Partial<Medication>) => {
    if (isDemoMode) {
      const meds = await getDemoCollection('medications');
      const next = meds.map((medication) =>
        medication.id === id ? { ...medication, ...updates } : medication
      );
      await setDemoCollection('medications', next);
      return { error: null };
    }
    const result = await runQuery<Medication>('updateMed', () =>
      supabase.from('medications').update(updates).eq('id', id).select().single()
    );
    const error = result === null ? new Error('Failed to update medication') : null;
    return { error };
  }, [isDemoMode]);

  return { fetchActive, add, update };
}

export function useMedicationLogs() {
  const userId = useAuthStore((state) => state.userId);
  const { enqueue } = useSyncQueue();
  const isDemoMode = ENV.DEMO_MODE;

  const fetchToday = useCallback(async (): Promise<MedicationLog[]> => {
    if (!userId) return [];
    if (isDemoMode) {
      const start = new Date();
      start.setHours(0, 0, 0, 0);
      const demoLogs = await getDemoCollection('medication_logs');
      return sortByDateDesc(demoLogs.filter((log) => isWithinDay(log.created_at, start)));
    }
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    return readMany<MedicationLog>('fetchTodayMedLogs', () =>
      supabase.from('medication_logs').select('*').eq('user_id', userId).gte('created_at', start.toISOString()).order('created_at', { ascending: false })
    );
  }, [isDemoMode, userId]);

  const add = useCallback(async (input: MedicationLogInput): Promise<MedicationLog | null> => {
    if (!userId) return null;
    const record: MedicationLog = { ...input, id: makeId(), user_id: userId, created_at: new Date().toISOString() };
    if (isDemoMode) {
      return appendDemoRecord('medication_logs', record);
    }
    enqueue('medication_logs', record as unknown as Record<string, unknown>);
    const data = await insertOne<MedicationLog>('addMedLog', () => supabase.from('medication_logs').insert(record).select().single());
    return data ?? record;
  }, [enqueue, isDemoMode, userId]);

  return { fetchToday, add };
}

export function useSleepLogs() {
  const userId = useAuthStore((state) => state.userId);
  const { enqueue } = useSyncQueue();
  const isDemoMode = ENV.DEMO_MODE;

  const fetchRange = useCallback(async (from: Date, to: Date): Promise<SleepLog[]> => {
    if (!userId) return [];
    if (isDemoMode) {
      const demoLogs = await getDemoCollection('sleep_logs');
      return sortByDateDesc(demoLogs.filter((log) => isDateWithinRange(log.date, from, to)), (log) => log.date);
    }
    return readMany<SleepLog>('fetchRangeSleep', () =>
      supabase.from('sleep_logs').select('*').eq('user_id', userId).gte('date', from.toISOString().split('T')[0]).lte('date', to.toISOString().split('T')[0]).order('date', { ascending: false })
    );
  }, [isDemoMode, userId]);

  const add = useCallback(async (input: SleepLogInput): Promise<SleepLog | null> => {
    if (!userId) return null;
    const record: SleepLog = { ...input, id: makeId(), user_id: userId, created_at: new Date().toISOString() };
    if (isDemoMode) {
      return appendDemoRecord('sleep_logs', record);
    }
    enqueue('sleep_logs', record as unknown as Record<string, unknown>);
    const data = await insertOne<SleepLog>('addSleep', () => supabase.from('sleep_logs').insert(record).select().single());
    return data ?? record;
  }, [enqueue, isDemoMode, userId]);

  return { fetchRange, add };
}

export function useMenstrualLogs() {
  const userId = useAuthStore((state) => state.userId);
  const { enqueue } = useSyncQueue();
  const isDemoMode = ENV.DEMO_MODE;

  const fetchRange = useCallback(async (from: Date, to: Date): Promise<MenstrualLog[]> => {
    if (!userId) return [];
    if (isDemoMode) {
      const demoLogs = await getDemoCollection('menstrual_logs');
      return sortByDateDesc(demoLogs.filter((log) => isDateWithinRange(log.date, from, to)), (log) => log.date);
    }
    return readMany<MenstrualLog>('fetchRangeMenstrual', () =>
      supabase.from('menstrual_logs').select('*').eq('user_id', userId).gte('date', from.toISOString().split('T')[0]).lte('date', to.toISOString().split('T')[0]).order('date', { ascending: false })
    );
  }, [isDemoMode, userId]);

  const add = useCallback(async (input: MenstrualLogInput): Promise<MenstrualLog | null> => {
    if (!userId) return null;
    const record: MenstrualLog = { ...input, id: makeId(), user_id: userId, created_at: new Date().toISOString() };
    if (isDemoMode) {
      return appendDemoRecord('menstrual_logs', record);
    }
    enqueue('menstrual_logs', record as unknown as Record<string, unknown>);
    const data = await insertOne<MenstrualLog>('addMenstrual', () => supabase.from('menstrual_logs').insert(record).select().single());
    return data ?? record;
  }, [enqueue, isDemoMode, userId]);

  return { fetchRange, add };
}

export function useWeightLogs() {
  const userId = useAuthStore((state) => state.userId);
  const { enqueue } = useSyncQueue();
  const isDemoMode = ENV.DEMO_MODE;

  const fetchRange = useCallback(async (from: Date, to: Date): Promise<WeightLog[]> => {
    if (!userId) return [];
    if (isDemoMode) {
      const demoLogs = await getDemoCollection('weight_logs');
      return sortByDateDesc(demoLogs.filter((log) => isWithinRange(log.logged_at, from, to)), (log) => log.logged_at);
    }
    return readMany<WeightLog>('fetchRangeWeight', () =>
      supabase.from('weight_logs').select('*').eq('user_id', userId).gte('logged_at', from.toISOString()).lte('logged_at', to.toISOString()).order('logged_at', { ascending: false })
    );
  }, [isDemoMode, userId]);

  const add = useCallback(async (input: WeightLogInput): Promise<WeightLog | null> => {
    if (!userId) return null;
    const record: WeightLog = { ...input, id: makeId(), user_id: userId, created_at: new Date().toISOString() };
    if (isDemoMode) {
      return appendDemoRecord('weight_logs', record);
    }
    enqueue('weight_logs', record as unknown as Record<string, unknown>);
    const data = await insertOne<WeightLog>('addWeight', () => supabase.from('weight_logs').insert(record).select().single());
    return data ?? record;
  }, [enqueue, isDemoMode, userId]);

  return { fetchRange, add };
}
