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
    const { data, error } = await supabase
      .from('food_logs')
      .select('*')
      .eq('user_id', userId)
      .gte('logged_at', start.toISOString())
      .order('logged_at', { ascending: false });
    if (error) { console.error('fetchTodayFood', error); return []; }
    return data ?? [];
  }, [userId]);

  const fetchRange = useCallback(async (from: Date, to: Date): Promise<FoodLog[]> => {
    if (!userId) return [];
    const { data, error } = await supabase
      .from('food_logs')
      .select('*')
      .eq('user_id', userId)
      .gte('logged_at', from.toISOString())
      .lte('logged_at', to.toISOString())
      .order('logged_at', { ascending: false });
    if (error) { console.error('fetchRangeFood', error); return []; }
    return data ?? [];
  }, [userId]);

  const add = useCallback(async (input: FoodLogInput): Promise<FoodLog | null> => {
    if (!userId) return null;
    const record = { ...input, id: makeId(), user_id: userId, created_at: new Date().toISOString() };
    enqueue('food_logs', record);
    const { data, error } = await supabase.from('food_logs').insert(record).select().single();
    if (error) { console.error('addFood', error); return record as FoodLog; }
    return data;
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
    const { data, error } = await supabase
      .from('bowel_logs')
      .select('*')
      .eq('user_id', userId)
      .gte('logged_at', start.toISOString())
      .order('logged_at', { ascending: false });
    if (error) { console.error('fetchTodayBowel', error); return []; }
    return data ?? [];
  }, [userId]);

  const fetchRange = useCallback(async (from: Date, to: Date): Promise<BowelLog[]> => {
    if (!userId) return [];
    const { data, error } = await supabase
      .from('bowel_logs')
      .select('*')
      .eq('user_id', userId)
      .gte('logged_at', from.toISOString())
      .lte('logged_at', to.toISOString())
      .order('logged_at', { ascending: false });
    if (error) { console.error('fetchRangeBowel', error); return []; }
    return data ?? [];
  }, [userId]);

  const add = useCallback(async (input: BowelLogInput): Promise<BowelLog | null> => {
    if (!userId) return null;
    const record = { ...input, id: makeId(), user_id: userId, created_at: new Date().toISOString() };
    enqueue('bowel_logs', record);
    const { data, error } = await supabase.from('bowel_logs').insert(record).select().single();
    if (error) { console.error('addBowel', error); return record as BowelLog; }
    return data;
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
    const { data, error } = await supabase
      .from('symptom_logs')
      .select('*')
      .eq('user_id', userId)
      .gte('logged_at', start.toISOString())
      .order('logged_at', { ascending: false });
    if (error) { console.error('fetchTodaySymptom', error); return []; }
    return data ?? [];
  }, [userId]);

  const fetchRange = useCallback(async (from: Date, to: Date): Promise<SymptomLog[]> => {
    if (!userId) return [];
    const { data, error } = await supabase
      .from('symptom_logs')
      .select('*')
      .eq('user_id', userId)
      .gte('logged_at', from.toISOString())
      .lte('logged_at', to.toISOString())
      .order('logged_at', { ascending: false });
    if (error) { console.error('fetchRangeSymptom', error); return []; }
    return data ?? [];
  }, [userId]);

  const add = useCallback(async (input: SymptomLogInput): Promise<SymptomLog | null> => {
    if (!userId) return null;
    const record = { ...input, id: makeId(), user_id: userId, created_at: new Date().toISOString() };
    enqueue('symptom_logs', record);
    const { data, error } = await supabase.from('symptom_logs').insert(record).select().single();
    if (error) { console.error('addSymptom', error); return record as SymptomLog; }
    return data;
  }, [userId, enqueue]);

  return { fetchToday, fetchRange, add };
}

export function useMedications() {
  const userId = useAuthStore((s) => s.userId);

  const fetchActive = useCallback(async (): Promise<Medication[]> => {
    if (!userId) return [];
    const { data, error } = await supabase
      .from('medications')
      .select('*')
      .eq('user_id', userId)
      .eq('is_active', true)
      .order('name');
    if (error) { console.error('fetchMeds', error); return []; }
    return data ?? [];
  }, [userId]);

  const add = useCallback(async (med: Omit<Medication, 'id' | 'user_id' | 'created_at'>): Promise<Medication | null> => {
    if (!userId) return null;
    const { data, error } = await supabase
      .from('medications')
      .insert({ ...med, user_id: userId })
      .select()
      .single();
    if (error) { console.error('addMed', error); return null; }
    return data;
  }, [userId]);

  const update = useCallback(async (id: string, updates: Partial<Medication>) => {
    const { error } = await supabase.from('medications').update(updates).eq('id', id);
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
    const { data, error } = await supabase
      .from('medication_logs')
      .select('*')
      .eq('user_id', userId)
      .gte('created_at', start.toISOString())
      .order('created_at', { ascending: false });
    if (error) { console.error('fetchTodayMedLogs', error); return []; }
    return data ?? [];
  }, [userId]);

  const add = useCallback(async (input: MedicationLogInput): Promise<MedicationLog | null> => {
    if (!userId) return null;
    const record = { ...input, id: makeId(), user_id: userId, created_at: new Date().toISOString() };
    enqueue('medication_logs', record);
    const { data, error } = await supabase.from('medication_logs').insert(record).select().single();
    if (error) { console.error('addMedLog', error); return record as MedicationLog; }
    return data;
  }, [userId, enqueue]);

  return { fetchToday, add };
}

export function useSleepLogs() {
  const userId = useAuthStore((s) => s.userId);
  const { enqueue } = useSyncQueue();

  const fetchRange = useCallback(async (from: Date, to: Date): Promise<SleepLog[]> => {
    if (!userId) return [];
    const { data, error } = await supabase
      .from('sleep_logs')
      .select('*')
      .eq('user_id', userId)
      .gte('date', from.toISOString().split('T')[0])
      .lte('date', to.toISOString().split('T')[0])
      .order('date', { ascending: false });
    if (error) { console.error('fetchRangeSleep', error); return []; }
    return data ?? [];
  }, [userId]);

  const add = useCallback(async (input: SleepLogInput): Promise<SleepLog | null> => {
    if (!userId) return null;
    const record = { ...input, id: makeId(), user_id: userId, created_at: new Date().toISOString() };
    enqueue('sleep_logs', record);
    const { data, error } = await supabase.from('sleep_logs').insert(record).select().single();
    if (error) { console.error('addSleep', error); return record as SleepLog; }
    return data;
  }, [userId, enqueue]);

  return { fetchRange, add };
}

export function useMenstrualLogs() {
  const userId = useAuthStore((s) => s.userId);
  const { enqueue } = useSyncQueue();

  const fetchRange = useCallback(async (from: Date, to: Date): Promise<MenstrualLog[]> => {
    if (!userId) return [];
    const { data, error } = await supabase
      .from('menstrual_logs')
      .select('*')
      .eq('user_id', userId)
      .gte('date', from.toISOString().split('T')[0])
      .lte('date', to.toISOString().split('T')[0])
      .order('date', { ascending: false });
    if (error) { console.error('fetchRangeMenstrual', error); return []; }
    return data ?? [];
  }, [userId]);

  const add = useCallback(async (input: MenstrualLogInput): Promise<MenstrualLog | null> => {
    if (!userId) return null;
    const record = { ...input, id: makeId(), user_id: userId, created_at: new Date().toISOString() };
    enqueue('menstrual_logs', record);
    const { data, error } = await supabase.from('menstrual_logs').insert(record).select().single();
    if (error) { console.error('addMenstrual', error); return record as MenstrualLog; }
    return data;
  }, [userId, enqueue]);

  return { fetchRange, add };
}

export function useWeightLogs() {
  const userId = useAuthStore((s) => s.userId);
  const { enqueue } = useSyncQueue();

  const fetchRange = useCallback(async (from: Date, to: Date): Promise<WeightLog[]> => {
    if (!userId) return [];
    const { data, error } = await supabase
      .from('weight_logs')
      .select('*')
      .eq('user_id', userId)
      .gte('logged_at', from.toISOString())
      .lte('logged_at', to.toISOString())
      .order('logged_at', { ascending: false });
    if (error) { console.error('fetchRangeWeight', error); return []; }
    return data ?? [];
  }, [userId]);

  const add = useCallback(async (input: WeightLogInput): Promise<WeightLog | null> => {
    if (!userId) return null;
    const record = { ...input, id: makeId(), user_id: userId, created_at: new Date().toISOString() };
    enqueue('weight_logs', record);
    const { data, error } = await supabase.from('weight_logs').insert(record).select().single();
    if (error) { console.error('addWeight', error); return record as WeightLog; }
    return data;
  }, [userId, enqueue]);

  return { fetchRange, add };
}
