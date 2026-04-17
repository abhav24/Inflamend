import { useCallback } from 'react';
import { subDays } from 'date-fns';
import { supabase } from '../lib/supabase';
import { ENV } from '../lib/env';
import { useAuthStore } from '../store/authStore';
import { RiskIndicator } from '../types';
import { calculateRiskFromInputs } from '../lib/riskScoring';
import { getDemoCollection } from '../lib/demoData';

export function useRiskIndicator() {
  const userId = useAuthStore((state) => state.userId);
  const isDemoMode = ENV.DEMO_MODE;

  const calculate = useCallback(async (): Promise<RiskIndicator> => {
    if (!userId) return { score: 0, level: 'low', factors: [] };

    const now = new Date();
    const sevenDaysAgo = subDays(now, 7);

    if (isDemoMode) {
      const [bowels, symptoms, sleep, meds, foods] = await Promise.all([
        getDemoCollection('bowel_logs'),
        getDemoCollection('symptom_logs'),
        getDemoCollection('sleep_logs'),
        getDemoCollection('medication_logs'),
        getDemoCollection('food_logs'),
      ]);

      return calculateRiskFromInputs({
        bowels: bowels.filter((item) => new Date(item.logged_at) >= sevenDaysAgo),
        symptoms: symptoms.filter((item) => new Date(item.logged_at) >= sevenDaysAgo),
        sleep: sleep.filter((item) => new Date(`${item.date}T00:00:00`) >= sevenDaysAgo),
        meds: meds.filter((item) => new Date(item.created_at) >= sevenDaysAgo),
        foods: foods.filter((item) => new Date(item.logged_at) >= sevenDaysAgo),
      });
    }

    const after = sevenDaysAgo.toISOString();
    const [bowelRes, symptomRes, sleepRes, medRes, foodRes] = await Promise.all([
      supabase.from('bowel_logs').select('bristol_scale, urgency, blood_present, pain_during, logged_at').eq('user_id', userId).gte('logged_at', after),
      supabase.from('symptom_logs').select('pain_level, fatigue_level, stress_level, is_flare, logged_at').eq('user_id', userId).gte('logged_at', after),
      supabase.from('sleep_logs').select('quality, bathroom_wakings').eq('user_id', userId).gte('date', after.split('T')[0]),
      supabase.from('medication_logs').select('was_taken').eq('user_id', userId).gte('created_at', after),
      supabase.from('food_logs').select('is_trigger_food').eq('user_id', userId).gte('logged_at', after),
    ]);

    return calculateRiskFromInputs({
      bowels: bowelRes.data ?? [],
      symptoms: symptomRes.data ?? [],
      sleep: sleepRes.data ?? [],
      meds: medRes.data ?? [],
      foods: foodRes.data ?? [],
    });
  }, [isDemoMode, userId]);

  return { calculate };
}
