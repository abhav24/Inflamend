// ─── Auth & Profile ────────────────────────────────────────────────────────

export type DiagnosisType =
  | 'crohns'
  | 'ulcerative_colitis'
  | 'ibd_unspecified'
  | 'other';

export interface Profile {
  id: string;
  display_name: string | null;
  date_of_birth: string | null;
  diagnosis_type: DiagnosisType | null;
  diagnosis_date: string | null;
  tracks_menstrual_cycle: boolean;
  created_at: string;
  updated_at: string;
}

export type HealthMetric = 'steps' | 'heart_rate' | 'sleep_hours' | 'active_energy_kcal';

export interface AppSettings {
  user_id: string;
  timezone: string;
  preferred_weight_unit: 'kg' | 'lb';
  health_sync_enabled: boolean;
  created_at: string;
  updated_at: string;
}

export interface HealthSample {
  id: string;
  user_id: string;
  metric: HealthMetric;
  value: number;
  unit: string;
  observed_at: string;
  source: string;
  metadata: Record<string, unknown>;
  created_at: string;
}

export interface HealthSyncState {
  id: string;
  user_id: string;
  provider: 'apple_health';
  metric: HealthMetric;
  last_synced_at: string | null;
  last_cursor: string | null;
  last_status: 'idle' | 'syncing' | 'success' | 'error';
  last_error: string | null;
  updated_at: string;
}

// ─── Food Log ───────────────────────────────────────────────────────────────

export type MealType = 'breakfast' | 'lunch' | 'dinner' | 'snack' | 'drink';

export interface FoodLog {
  id: string;
  user_id: string;
  logged_at: string;
  meal_type: MealType;
  description: string;
  photo_url: string | null;
  calories: number | null;
  protein_g: number | null;
  carbs_g: number | null;
  fat_g: number | null;
  fiber_g: number | null;
  water_ml: number | null;
  is_trigger_food: boolean;
  is_safe_food: boolean;
  notes: string | null;
  created_at: string;
}

export type FoodLogInput = Omit<FoodLog, 'id' | 'user_id' | 'created_at'>;

// ─── Bowel Log ──────────────────────────────────────────────────────────────

export type BloodAmount = 'none' | 'trace' | 'moderate' | 'significant';

export interface BowelLog {
  id: string;
  user_id: string;
  logged_at: string;
  bristol_scale: number; // 1-7
  urgency: number; // 1-5
  blood_present: boolean;
  blood_amount: BloodAmount;
  mucus_present: boolean;
  pain_during: number; // 0-10
  notes: string | null;
  created_at: string;
}

export type BowelLogInput = Omit<BowelLog, 'id' | 'user_id' | 'created_at'>;

// ─── Symptom Log ────────────────────────────────────────────────────────────

export type Mood = 'great' | 'good' | 'okay' | 'bad' | 'terrible';

export interface SymptomLog {
  id: string;
  user_id: string;
  logged_at: string;
  pain_level: number; // 0-10
  pain_location: string[];
  fatigue_level: number; // 0-10
  nausea_level: number; // 0-10
  bloating_level: number; // 0-10
  stress_level: number; // 0-10
  mood: Mood | null;
  is_flare: boolean;
  notes: string | null;
  created_at: string;
}

export type SymptomLogInput = Omit<SymptomLog, 'id' | 'user_id' | 'created_at'>;

// ─── Medication ─────────────────────────────────────────────────────────────

export interface Medication {
  id: string;
  user_id: string;
  name: string;
  dosage: string | null;
  dosage_unit: string | null;
  frequency: string | null;
  time_of_day: string[];
  is_active: boolean;
  start_date: string | null;
  end_date: string | null;
  created_at: string;
}

export interface MedicationLog {
  id: string;
  user_id: string;
  medication_name: string;
  dosage: string | null;
  dosage_unit: string | null;
  scheduled_time: string | null;
  taken_at: string | null;
  was_taken: boolean;
  side_effects: string[];
  notes: string | null;
  created_at: string;
}

export type MedicationLogInput = Omit<MedicationLog, 'id' | 'user_id' | 'created_at'>;

// ─── Sleep Log ──────────────────────────────────────────────────────────────

export interface SleepLog {
  id: string;
  user_id: string;
  date: string;
  bedtime: string;
  wake_time: string;
  duration_minutes: number | null;
  quality: number; // 1-5
  night_wakings: number;
  bathroom_wakings: number;
  notes: string | null;
  created_at: string;
}

export type SleepLogInput = Omit<SleepLog, 'id' | 'user_id' | 'created_at'>;

// ─── Menstrual Log ──────────────────────────────────────────────────────────

export type FlowLevel = 'none' | 'spotting' | 'light' | 'medium' | 'heavy';

export interface MenstrualLog {
  id: string;
  user_id: string;
  date: string;
  cycle_day: number | null;
  flow: FlowLevel;
  symptoms: string[];
  notes: string | null;
  created_at: string;
}

export type MenstrualLogInput = Omit<MenstrualLog, 'id' | 'user_id' | 'created_at'>;

// ─── Weight Log ─────────────────────────────────────────────────────────────

export interface WeightLog {
  id: string;
  user_id: string;
  logged_at: string;
  weight_kg: number;
  notes: string | null;
  created_at: string;
}

export type WeightLogInput = Omit<WeightLog, 'id' | 'user_id' | 'created_at'>;

// ─── Chat ────────────────────────────────────────────────────────────────────

export type ChatRole = 'user' | 'assistant';

export interface ChatMessage {
  id: string;
  user_id: string;
  role: ChatRole;
  content: string;
  created_at: string;
}

// ─── Flare Event ────────────────────────────────────────────────────────────

export interface FlareEvent {
  id: string;
  user_id: string;
  started_at: string;
  ended_at: string | null;
  severity: number; // 1-10
  triggers_identified: string[];
  notes: string | null;
  created_at: string;
}

// ─── Risk Indicator ─────────────────────────────────────────────────────────

export type RiskLevel = 'low' | 'medium' | 'high';

export interface RiskIndicator {
  score: number; // 0-100
  level: RiskLevel;
  factors: string[];
}

// ─── Sync Queue ─────────────────────────────────────────────────────────────

export type SyncTableName =
  | 'food_logs'
  | 'bowel_logs'
  | 'symptom_logs'
  | 'medication_logs'
  | 'sleep_logs'
  | 'menstrual_logs'
  | 'weight_logs'
  | 'health_samples';

export interface SyncQueueItem {
  id: string;
  table: SyncTableName;
  data: Record<string, unknown>;
  created_at: string;
  retries: number;
}

// ─── Daily Summary ──────────────────────────────────────────────────────────

export interface DailySummary {
  date: string;
  meals_logged: number;
  bowel_movements: number;
  symptoms_logged: boolean;
  medications_taken: number;
  medications_total: number;
  is_flare_day: boolean;
  avg_pain: number | null;
  avg_fatigue: number | null;
}
