import { useCallback } from 'react';
import { subDays } from 'date-fns';
import { supabase } from '../lib/supabase';
import { useAuthStore } from '../store/authStore';
import { RiskIndicator } from '../types';
import { calculateRiskFromInputs } from '../lib/riskScoring';

export function useRiskIndicator() {
  const userId = useAuthStore((s) => s.userId);

  const calculate = useCallback(async (): Promise<RiskIndicator> => {
    if (!userId) return { score: 0, level: 'low', factors: [] };

    const now = new Date();
    const sevenDaysAgo = subDays(now, 7).toISOString();

    const [bowelRes, symptomRes, sleepRes, medRes, foodRes] = await Promise.all([
      supabase
        .from('bowel_logs')
        .select('bristol_scale, urgency, blood_present, pain_during, logged_at')
        .eq('user_id', userId)
        .gte('logged_at', sevenDaysAgo),
      supabase
        .from('symptom_logs')
        .select('pain_level, fatigue_level, stress_level, is_flare, logged_at')
        .eq('user_id', userId)
        .gte('logged_at', sevenDaysAgo),
      supabase
        .from('sleep_logs')
        .select('quality, bathroom_wakings')
        .eq('user_id', userId)
        .gte('date', sevenDaysAgo.split('T')[0]),
      supabase
        .from('medication_logs')
        .select('was_taken')
        .eq('user_id', userId)
        .gte('created_at', sevenDaysAgo),
      supabase
        .from('food_logs')
        .select('is_trigger_food')
        .eq('user_id', userId)
        .gte('logged_at', sevenDaysAgo),
    ]);

    return calculateRiskFromInputs({
      bowels: bowelRes.data ?? [],
      symptoms: symptomRes.data ?? [],
      sleep: sleepRes.data ?? [],
      meds: medRes.data ?? [],
      foods: foodRes.data ?? [],
    });
  }, [userId]);

  return { calculate };
}
