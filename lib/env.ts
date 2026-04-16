function required(name: string, value: string | undefined): string {
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

function numberWithDefault(raw: string | undefined, fallback: number): number {
  if (!raw) return fallback;
  const parsed = Number(raw);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function booleanWithDefault(raw: string | undefined, fallback: boolean): boolean {
  if (!raw) return fallback;
  const normalized = raw.trim().toLowerCase();
  if (['1', 'true', 'yes', 'on'].includes(normalized)) return true;
  if (['0', 'false', 'no', 'off'].includes(normalized)) return false;
  return fallback;
}

const RAW_SUPABASE_URL = process.env.EXPO_PUBLIC_SUPABASE_URL;
const RAW_SUPABASE_ANON_KEY = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY;
const RAW_HEALTH_SYNC_BATCH_SIZE = process.env.EXPO_PUBLIC_HEALTH_SYNC_BATCH_SIZE;
const RAW_HEALTH_SYNC_LOOKBACK_DAYS = process.env.EXPO_PUBLIC_HEALTH_SYNC_LOOKBACK_DAYS;
const RAW_DEMO_MODE = process.env.EXPO_PUBLIC_DEMO_MODE;

const demoMode = booleanWithDefault(RAW_DEMO_MODE, false);

export const ENV = {
  DEMO_MODE: demoMode,
  SUPABASE_URL: demoMode
    ? RAW_SUPABASE_URL ?? 'https://demo.invalid'
    : required('EXPO_PUBLIC_SUPABASE_URL', RAW_SUPABASE_URL),
  SUPABASE_ANON_KEY: demoMode
    ? RAW_SUPABASE_ANON_KEY ?? 'demo-anon-key'
    : required('EXPO_PUBLIC_SUPABASE_ANON_KEY', RAW_SUPABASE_ANON_KEY),
  HEALTH_SYNC_BATCH_SIZE: numberWithDefault(RAW_HEALTH_SYNC_BATCH_SIZE, 200),
  HEALTH_SYNC_LOOKBACK_DAYS: numberWithDefault(RAW_HEALTH_SYNC_LOOKBACK_DAYS, 30),
};
