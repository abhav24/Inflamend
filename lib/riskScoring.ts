import { RiskIndicator, RiskLevel } from '../types';

export type RiskInputs = {
  bowels: Array<{ bristol_scale: number; urgency: number; blood_present: boolean }>;
  symptoms: Array<{ pain_level: number; fatigue_level: number; stress_level: number; is_flare: boolean }>;
  sleep: Array<{ quality: number; bathroom_wakings: number }>;
  meds: Array<{ was_taken: boolean }>;
  foods: Array<{ is_trigger_food: boolean }>;
};

export function calculateRiskFromInputs(inputs: RiskInputs): RiskIndicator {
  let score = 0;
  const factors: string[] = [];

  // Bowel analysis (0-35)
  if (inputs.bowels.length > 0) {
    const abnormal = inputs.bowels.filter((b) => b.bristol_scale < 3 || b.bristol_scale > 5).length;
    const pct = abnormal / inputs.bowels.length;
    if (pct > 0.5) {
      score += 20;
      factors.push('Irregular bowel movements');
    } else if (pct > 0.3) {
      score += 10;
      factors.push('Some irregular bowel movements');
    }

    if (inputs.bowels.some((b) => b.blood_present)) {
      score += 10;
      factors.push('Blood reported in stool');
    }

    const avgUrgency = inputs.bowels.reduce((sum, row) => sum + row.urgency, 0) / inputs.bowels.length;
    if (avgUrgency > 3.5) {
      score += 5;
      factors.push('High urgency');
    }
  }

  // Symptom analysis (0-45)
  if (inputs.symptoms.length > 0) {
    const avgPain = inputs.symptoms.reduce((sum, row) => sum + row.pain_level, 0) / inputs.symptoms.length;
    const avgFatigue = inputs.symptoms.reduce((sum, row) => sum + row.fatigue_level, 0) / inputs.symptoms.length;
    const avgStress = inputs.symptoms.reduce((sum, row) => sum + row.stress_level, 0) / inputs.symptoms.length;
    const inFlare = inputs.symptoms.some((row) => row.is_flare);

    if (avgPain >= 6) {
      score += 15;
      factors.push('High pain levels');
    } else if (avgPain >= 4) {
      score += 8;
      factors.push('Moderate pain levels');
    }

    if (avgFatigue >= 6) {
      score += 8;
      factors.push('High fatigue');
    }

    if (avgStress >= 7) {
      score += 7;
      factors.push('High stress levels');
    }

    if (inFlare) {
      score += 15;
      factors.push('Currently in a flare');
    }
  }

  // Sleep analysis (0-20)
  if (inputs.sleep.length > 0) {
    const avgQuality = inputs.sleep.reduce((sum, row) => sum + row.quality, 0) / inputs.sleep.length;
    const avgBathroom = inputs.sleep.reduce((sum, row) => sum + row.bathroom_wakings, 0) / inputs.sleep.length;

    if (avgQuality < 2.5) {
      score += 10;
      factors.push('Poor sleep quality');
    } else if (avgQuality < 3.5) {
      score += 5;
      factors.push('Fair sleep quality');
    }

    if (avgBathroom > 2) {
      score += 10;
      factors.push('Frequent nighttime bathroom trips');
    }
  }

  // Medication adherence (0-10)
  if (inputs.meds.length > 0) {
    const missed = inputs.meds.filter((m) => !m.was_taken).length;
    const missedPct = missed / inputs.meds.length;
    if (missedPct > 0.3) {
      score += 10;
      factors.push('Missed medications');
    }
  }

  // Trigger foods (0-10)
  if (inputs.foods.length > 0) {
    const triggerCount = inputs.foods.filter((f) => f.is_trigger_food).length;
    if (triggerCount >= 3) {
      score += 10;
      factors.push('Multiple trigger foods consumed');
    } else if (triggerCount >= 1) {
      score += 5;
      factors.push('Trigger foods consumed');
    }
  }

  const capped = Math.min(score, 100);
  let level: RiskLevel = 'low';
  if (capped >= 60) level = 'high';
  else if (capped >= 30) level = 'medium';

  return { score: capped, level, factors };
}
