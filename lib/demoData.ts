import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  BowelLog,
  ChatMessage,
  FoodLog,
  Medication,
  MedicationLog,
  MenstrualLog,
  Profile,
  SleepLog,
  SymptomLog,
  WeightLog,
} from '../types';

const PREFIX = '@inflamend/demo/';
const PROFILE_KEY = `${PREFIX}profile`;

type DemoCollections = {
  food_logs: FoodLog[];
  bowel_logs: BowelLog[];
  symptom_logs: SymptomLog[];
  medications: Medication[];
  medication_logs: MedicationLog[];
  sleep_logs: SleepLog[];
  menstrual_logs: MenstrualLog[];
  weight_logs: WeightLog[];
  chat_messages: ChatMessage[];
};

type DemoKey = keyof DemoCollections;

function collectionKey(key: DemoKey) {
  return `${PREFIX}${key}`;
}

async function readJson<T>(key: string, fallback: T): Promise<T> {
  try {
    const raw = await AsyncStorage.getItem(key);
    return raw ? (JSON.parse(raw) as T) : fallback;
  } catch {
    return fallback;
  }
}

async function writeJson<T>(key: string, value: T): Promise<void> {
  await AsyncStorage.setItem(key, JSON.stringify(value));
}

export async function getDemoProfile(fallback: Profile): Promise<Profile> {
  return readJson(PROFILE_KEY, fallback);
}

export async function setDemoProfile(profile: Profile): Promise<void> {
  await writeJson(PROFILE_KEY, profile);
}

export async function getDemoCollection<K extends DemoKey>(key: K): Promise<DemoCollections[K]> {
  return readJson(collectionKey(key), [] as DemoCollections[K]);
}

export async function setDemoCollection<K extends DemoKey>(
  key: K,
  value: DemoCollections[K]
): Promise<void> {
  await writeJson(collectionKey(key), value);
}

export async function appendDemoRecord<K extends DemoKey>(
  key: K,
  record: DemoCollections[K][number]
): Promise<DemoCollections[K][number]> {
  const current = await getDemoCollection(key);
  const next = [...current, record] as DemoCollections[K];
  await setDemoCollection(key, next);
  return record;
}
