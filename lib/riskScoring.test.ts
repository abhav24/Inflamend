import { describe, expect, it } from 'vitest';
import { calculateRiskFromInputs } from './riskScoring';

describe('calculateRiskFromInputs', () => {
  it('returns low risk when no signals are present', () => {
    const result = calculateRiskFromInputs({
      bowels: [],
      symptoms: [],
      sleep: [],
      meds: [],
      foods: [],
    });

    expect(result.score).toBe(0);
    expect(result.level).toBe('low');
    expect(result.factors).toEqual([]);
  });

  it('returns medium risk with moderate symptom and food triggers', () => {
    const result = calculateRiskFromInputs({
      bowels: [
        { bristol_scale: 4, urgency: 2, blood_present: false },
        { bristol_scale: 6, urgency: 3, blood_present: false },
      ],
      symptoms: [
        { pain_level: 5, fatigue_level: 6, stress_level: 7, is_flare: false },
      ],
      sleep: [{ quality: 3, bathroom_wakings: 1 }],
      meds: [{ was_taken: true }, { was_taken: true }],
      foods: [{ is_trigger_food: true }],
    });

    expect(result.level).toBe('medium');
    expect(result.score).toBeGreaterThanOrEqual(30);
    expect(result.factors).toContain('Moderate pain levels');
    expect(result.factors).toContain('Trigger foods consumed');
  });

  it('caps score at 100 and returns high risk for severe signals', () => {
    const result = calculateRiskFromInputs({
      bowels: [
        { bristol_scale: 1, urgency: 5, blood_present: true },
        { bristol_scale: 7, urgency: 5, blood_present: false },
      ],
      symptoms: [
        { pain_level: 9, fatigue_level: 8, stress_level: 9, is_flare: true },
        { pain_level: 8, fatigue_level: 9, stress_level: 8, is_flare: true },
      ],
      sleep: [{ quality: 1, bathroom_wakings: 4 }],
      meds: [{ was_taken: false }, { was_taken: false }, { was_taken: true }],
      foods: [
        { is_trigger_food: true },
        { is_trigger_food: true },
        { is_trigger_food: true },
      ],
    });

    expect(result.level).toBe('high');
    expect(result.score).toBe(100);
    expect(result.factors).toContain('Currently in a flare');
    expect(result.factors).toContain('Missed medications');
  });
});
