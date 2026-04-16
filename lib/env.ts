function required(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

function numberWithDefault(name: string, fallback: number): number {
  const raw = process.env[name];
  if (!raw) return fallback;
  const parsed = Number(raw);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function booleanWithDefault(name: string, fallback: boolean): boolean {
  const raw = process.env[name];
  if (!raw) return fallback;
  const normalized = raw.trim().toLowerCase();
  if (['1', 'true', 'yes', 'on'].includes(normalized)) return true;
  if (['0', 'false', 'no', 'off'].includes(normalized)) return false;
  return fallback;
}

const demoMode = booleanWithDefault('EXPO_PUBLIC_DEMO_MODE', false);

export const ENV = {
  DEMO_MODE: demoMode,
  SUPABASE_URL: demoMode
    ? process.env.EXPO_PUBLIC_SUPABASE_URL ?? 'https://demo.invalid'
    : required('EXPO_PUBLIC_SUPABASE_URL'),
  SUPABASE_ANON_KEY: demoMode
    ? process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY ?? 'demo-anon-key'
    : required('EXPO_PUBLIC_SUPABASE_ANON_KEY'),
  HEALTH_SYNC_BATCH_SIZE: numberWithDefault('EXPO_PUBLIC_HEALTH_SYNC_BATCH_SIZE', 200),
  HEALTH_SYNC_LOOKBACK_DAYS: numberWithDefault('EXPO_PUBLIC_HEALTH_SYNC_LOOKBACK_DAYS', 30),
};
