import { useCallback } from 'react';
import { subDays } from 'date-fns';
import { supabase } from '../lib/supabase';
import { useAuthStore } from '../store/authStore';
import { RiskIndicator, RiskLevel } from '../types';

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

    let score = 0;
    const factors: string[] = [];

    // Bowel analysis (0-30 pts)
    const bowels = bowelRes.data ?? [];
    if (bowels.length > 0) {
      const abnormal = bowels.filter((b) => b.bristol_scale < 3 || b.bristol_scale > 5).length;
      const pct = abnormal / bowels.length;
      if (pct > 0.5) { score += 20; factors.push('Irregular bowel movements'); }
      else if (pct > 0.3) { score += 10; factors.push('Some irregular bowel movements'); }

      const hasBlood = bowels.some((b) => b.blood_present);
      if (hasBlood) { score += 10; factors.push('Blood reported in stool'); }

      const avgUrgency = bowels.reduce((s, b) => s + b.urgency, 0) / bowels.length;
      if (avgUrgency > 3.5) { score += 5; factors.push('High urgency'); }
    }

    // Symptom analysis (0-30 pts)
    const symptoms = symptomRes.data ?? [];
    if (symptoms.length > 0) {
      const avgPain = symptoms.reduce((s, b) => s + b.pain_level, 0) / symptoms.length;
      const avgFatigue = symptoms.reduce((s, b) => s + b.fatigue_level, 0) / symptoms.length;
      const avgStress = symptoms.reduce((s, b) => s + b.stress_level, 0) / symptoms.length;
      const inFlare = symptoms.some((s) => s.is_flare);

      if (avgPain >= 6) { score += 15; factors.push('High pain levels'); }
      else if (avgPain >= 4) { score += 8; factors.push('Moderate pain levels'); }

      if (avgFatigue >= 6) { score += 8; factors.push('High fatigue'); }
      if (avgStress >= 7) { score += 7; factors.push('High stress levels'); }
      if (inFlare) { score += 15; factors.push('Currently in a flare'); }
    }

    // Sleep analysis (0-20 pts)
    const sleep = sleepRes.data ?? [];
    if (sleep.length > 0) {
      const avgQuality = sleep.reduce((s, b) => s + b.quality, 0) / sleep.length;
      const avgBathroom = sleep.reduce((s, b) => s + b.bathroom_wakings, 0) / sleep.length;
      if (avgQuality < 2.5) { score += 10; factors.push('Poor sleep quality'); }
      else if (avgQuality < 3.5) { score += 5; factors.push('Fair sleep quality'); }
      if (avgBathroom > 2) { score += 10; factors.push('Frequent nighttime bathroom trips'); }
    }

    // Medication adherence (0-10 pts)
    const meds = medRes.data ?? [];
    if (meds.length > 0) {
      const missed = meds.filter((m) => !m.was_taken).length;
      const missedPct = missed / meds.length;
      if (missedPct > 0.3) { score += 10; factors.push('Missed medications'); }
    }

    // Trigger foods (0-10 pts)
    const foods = foodRes.data ?? [];
    if (foods.length > 0) {
      const triggerCount = foods.filter((f) => f.is_trigger_food).length;
      if (triggerCount >= 3) { score += 10; factors.push('Multiple trigger foods consumed'); }
      else if (triggerCount >= 1) { score += 5; factors.push('Trigger foods consumed'); }
    }

    const capped = Math.min(score, 100);
    let level: RiskLevel = 'low';
    if (capped >= 60) level = 'high';
    else if (capped >= 30) level = 'medium';

    return { score: capped, level, factors };
  }, [userId]);

  return { calculate };
}
