import { useCallback } from 'react';
import { supabase } from '../lib/supabase';
import { useAuthStore } from '../store/authStore';
import { useSyncQueue } from './useSyncQueue';
import {
  FoodLog, FoodLogInput,
  BowelLog, BowelLogInput,
  SymptomLog, SymptomLogInput,
  MedicationLog, MedicationLogInput,
  Medication,
  SleepLog, SleepLogInput,
  MenstrualLog, MenstrualLogInput,
  WeightLog, WeightLogInput,
} from '../types';

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

async function readMany<T>(
  label: string,
  fn: () => PromiseLike<SupabaseResult<T[]>>
): Promise<T[]> {
  const data = await runQuery<T[]>(label, fn, { retries: READ_RETRIES });
  return data ?? [];
}

async function insertOne<T>(
  label: string,
  fn: () => PromiseLike<SupabaseResult<T>>
): Promise<T | null> {
  return runQuery<T>(label, fn);
}

function makeId() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    return (c === 'x' ? r : (r & 0x3) | 0x8).toString(16);
  });
}

export function useFoodLogs() {
  const userId = useAuthStore((s) => s.userId);
  const { enqueue } = useSyncQueue();

  const fetchToday = useCallback(async (): Promise<FoodLog[]> => {
    if (!userId) return [];
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    return readMany<FoodLog>('fetchTodayFood', () =>
      supabase
        .from('food_logs')
        .select('*')
        .eq('user_id', userId)
        .gte('logged_at', start.toISOString())
        .order('logged_at', { ascending: false })
    );
  }, [userId]);

  const fetchRange = useCallback(async (from: Date, to: Date): Promise<FoodLog[]> => {
    if (!userId) return [];
    return readMany<FoodLog>('fetchRangeFood', () =>
      supabase
        .from('food_logs')
        .select('*')
        .eq('user_id', userId)
        .gte('logged_at', from.toISOString())
        .lte('logged_at', to.toISOString())
        .order('logged_at', { ascending: false })
    );
  }, [userId]);

  const add = useCallback(async (input: FoodLogInput): Promise<FoodLog | null> => {
    if (!userId) return null;
    const record = { ...input, id: makeId(), user_id: userId, created_at: new Date().toISOString() };
    enqueue('food_logs', record);
    const data = await insertOne<FoodLog>('addFood', () =>
      supabase.from('food_logs').insert(record).select().single()
    );
    return data ?? (record as FoodLog);
  }, [userId, enqueue]);

  return { fetchToday, fetchRange, add };
}

export function useBowelLogs() {
  const userId = useAuthStore((s) => s.userId);
  const { enqueue } = useSyncQueue();

  const fetchToday = useCallback(async (): Promise<BowelLog[]> => {
    if (!userId) return [];
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    return readMany<BowelLog>('fetchTodayBowel', () =>
      supabase
        .from('bowel_logs')
        .select('*')
        .eq('user_id', userId)
        .gte('logged_at', start.toISOString())
        .order('logged_at', { ascending: false })
    );
  }, [userId]);

  const fetchRange = useCallback(async (from: Date, to: Date): Promise<BowelLog[]> => {
    if (!userId) return [];
    return readMany<BowelLog>('fetchRangeBowel', () =>
      supabase
        .from('bowel_logs')
        .select('*')
        .eq('user_id', userId)
        .gte('logged_at', from.toISOString())
        .lte('logged_at', to.toISOString())
        .order('logged_at', { ascending: false })
    );
  }, [userId]);

  const add = useCallback(async (input: BowelLogInput): Promise<BowelLog | null> => {
    if (!userId) return null;
    const record = { ...input, id: makeId(), user_id: userId, created_at: new Date().toISOString() };
    enqueue('bowel_logs', record);
    const data = await insertOne<BowelLog>('addBowel', () =>
      supabase.from('bowel_logs').insert(record).select().single()
    );
    return data ?? (record as BowelLog);
  }, [userId, enqueue]);

  return { fetchToday, fetchRange, add };
}

export function useSymptomLogs() {
  const userId = useAuthStore((s) => s.userId);
  const { enqueue } = useSyncQueue();

  const fetchToday = useCallback(async (): Promise<SymptomLog[]> => {
    if (!userId) return [];
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    return readMany<SymptomLog>('fetchTodaySymptom', () =>
      supabase
        .from('symptom_logs')
        .select('*')
        .eq('user_id', userId)
        .gte('logged_at', start.toISOString())
        .order('logged_at', { ascending: false })
    );
  }, [userId]);

  const fetchRange = useCallback(async (from: Date, to: Date): Promise<SymptomLog[]> => {
    if (!userId) return [];
    return readMany<SymptomLog>('fetchRangeSymptom', () =>
      supabase
        .from('symptom_logs')
        .select('*')
        .eq('user_id', userId)
        .gte('logged_at', from.toISOString())
        .lte('logged_at', to.toISOString())
        .order('logged_at', { ascending: false })
    );
  }, [userId]);

  const add = useCallback(async (input: SymptomLogInput): Promise<SymptomLog | null> => {
    if (!userId) return null;
    const record = { ...input, id: makeId(), user_id: userId, created_at: new Date().toISOString() };
    enqueue('symptom_logs', record);
    const data = await insertOne<SymptomLog>('addSymptom', () =>
      supabase.from('symptom_logs').insert(record).select().single()
    );
    return data ?? (record as SymptomLog);
  }, [userId, enqueue]);

  return { fetchToday, fetchRange, add };
}

export function useMedications() {
  const userId = useAuthStore((s) => s.userId);

  const fetchActive = useCallback(async (): Promise<Medication[]> => {
    if (!userId) return [];
    return readMany<Medication>('fetchMeds', () =>
      supabase
        .from('medications')
        .select('*')
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('name')
    );
  }, [userId]);

  const add = useCallback(async (med: Omit<Medication, 'id' | 'user_id' | 'created_at'>): Promise<Medication | null> => {
    if (!userId) return null;
    return insertOne<Medication>('addMed', () =>
      supabase
        .from('medications')
        .insert({ ...med, user_id: userId })
        .select()
        .single()
    );
  }, [userId]);

  const update = useCallback(async (id: string, updates: Partial<Medication>) => {
    const result = await runQuery<Medication>('updateMed', () =>
      supabase.from('medications').update(updates).eq('id', id).select().single()
    );
    const error = result === null ? new Error('Failed to update medication') : null;
    return { error };
  }, []);

  return { fetchActive, add, update };
}

export function useMedicationLogs() {
  const userId = useAuthStore((s) => s.userId);
  const { enqueue } = useSyncQueue();

  const fetchToday = useCallback(async (): Promise<MedicationLog[]> => {
    if (!userId) return [];
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    return readMany<MedicationLog>('fetchTodayMedLogs', () =>
      supabase
        .from('medication_logs')
        .select('*')
        .eq('user_id', userId)
        .gte('created_at', start.toISOString())
        .order('created_at', { ascending: false })
    );
  }, [userId]);

  const add = useCallback(async (input: MedicationLogInput): Promise<MedicationLog | null> => {
    if (!userId) return null;
    const record = { ...input, id: makeId(), user_id: userId, created_at: new Date().toISOString() };
    enqueue('medication_logs', record);
    const data = await insertOne<MedicationLog>('addMedLog', () =>
      supabase.from('medication_logs').insert(record).select().single()
    );
    return data ?? (record as MedicationLog);
  }, [userId, enqueue]);

  return { fetchToday, add };
}

export function useSleepLogs() {
  const userId = useAuthStore((s) => s.userId);
  const { enqueue } = useSyncQueue();

  const fetchRange = useCallback(async (from: Date, to: Date): Promise<SleepLog[]> => {
    if (!userId) return [];
    return readMany<SleepLog>('fetchRangeSleep', () =>
      supabase
        .from('sleep_logs')
        .select('*')
        .eq('user_id', userId)
        .gte('date', from.toISOString().split('T')[0])
        .lte('date', to.toISOString().split('T')[0])
        .order('date', { ascending: false })
    );
  }, [userId]);

  const add = useCallback(async (input: SleepLogInput): Promise<SleepLog | null> => {
    if (!userId) return null;
    const record = { ...input, id: makeId(), user_id: userId, created_at: new Date().toISOString() };
    enqueue('sleep_logs', record);
    const data = await insertOne<SleepLog>('addSleep', () =>
      supabase.from('sleep_logs').insert(record).select().single()
    );
    return data ?? (record as SleepLog);
  }, [userId, enqueue]);

  return { fetchRange, add };
}

export function useMenstrualLogs() {
  const userId = useAuthStore((s) => s.userId);
  const { enqueue } = useSyncQueue();

  const fetchRange = useCallback(async (from: Date, to: Date): Promise<MenstrualLog[]> => {
    if (!userId) return [];
    return readMany<MenstrualLog>('fetchRangeMenstrual', () =>
      supabase
        .from('menstrual_logs')
        .select('*')
        .eq('user_id', userId)
        .gte('date', from.toISOString().split('T')[0])
        .lte('date', to.toISOString().split('T')[0])
        .order('date', { ascending: false })
    );
  }, [userId]);

  const add = useCallback(async (input: MenstrualLogInput): Promise<MenstrualLog | null> => {
    if (!userId) return null;
    const record = { ...input, id: makeId(), user_id: userId, created_at: new Date().toISOString() };
    enqueue('menstrual_logs', record);
    const data = await insertOne<MenstrualLog>('addMenstrual', () =>
      supabase.from('menstrual_logs').insert(record).select().single()
    );
    return data ?? (record as MenstrualLog);
  }, [userId, enqueue]);

  return { fetchRange, add };
}

export function useWeightLogs() {
  const userId = useAuthStore((s) => s.userId);
  const { enqueue } = useSyncQueue();

  const fetchRange = useCallback(async (from: Date, to: Date): Promise<WeightLog[]> => {
    if (!userId) return [];
    return readMany<WeightLog>('fetchRangeWeight', () =>
      supabase
        .from('weight_logs')
        .select('*')
        .eq('user_id', userId)
        .gte('logged_at', from.toISOString())
        .lte('logged_at', to.toISOString())
        .order('logged_at', { ascending: false })
    );
  }, [userId]);

  const add = useCallback(async (input: WeightLogInput): Promise<WeightLog | null> => {
    if (!userId) return null;
    const record = { ...input, id: makeId(), user_id: userId, created_at: new Date().toISOString() };
    enqueue('weight_logs', record);
    const data = await insertOne<WeightLog>('addWeight', () =>
      supabase.from('weight_logs').insert(record).select().single()
    );
    return data ?? (record as WeightLog);
  }, [userId, enqueue]);

  return { fetchRange, add };
}
