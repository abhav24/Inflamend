import { useCallback } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { supabase } from '../lib/supabase';
import { useSyncStore } from '../store/syncStore';
import { SyncQueueItem, SyncTableName } from '../types';

const QUEUE_KEY = '@inflamend/sync_queue';

async function readQueue(): Promise<SyncQueueItem[]> {
  try {
    const raw = await AsyncStorage.getItem(QUEUE_KEY);
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

async function writeQueue(items: SyncQueueItem[]): Promise<void> {
  await AsyncStorage.setItem(QUEUE_KEY, JSON.stringify(items));
}

export function useSyncQueue() {
  const { setStatus, setPendingCount, setLastSyncedAt } = useSyncStore();

  const enqueue = useCallback(async (table: SyncTableName, data: Record<string, unknown>) => {
    const queue = await readQueue();
    const item: SyncQueueItem = {
      id: data.id as string,
      table,
      data,
      created_at: new Date().toISOString(),
      retries: 0,
    };
    const updated = [...queue, item];
    await writeQueue(updated);
    setPendingCount(updated.length);
  }, [setPendingCount]);

  const flush = useCallback(async () => {
    const queue = await readQueue();
    if (queue.length === 0) return;

    setStatus('syncing');
    const remaining: SyncQueueItem[] = [];

    for (const item of queue) {
      try {
        const { error } = await supabase.from(item.table).upsert(item.data);
        if (error) {
          console.warn(`Sync failed for ${item.table}:`, error.message);
          remaining.push({ ...item, retries: item.retries + 1 });
        }
      } catch (err) {
        console.warn('Sync network error:', err);
        remaining.push({ ...item, retries: item.retries + 1 });
      }
    }

    // Drop items that have failed too many times
    const filtered = remaining.filter((i) => i.retries < 5);
    await writeQueue(filtered);
    setPendingCount(filtered.length);
    setLastSyncedAt(new Date().toISOString());
    setStatus(filtered.length > 0 ? 'error' : 'idle');
  }, [setStatus, setPendingCount, setLastSyncedAt]);

  const getPendingCount = useCallback(async () => {
    const queue = await readQueue();
    setPendingCount(queue.length);
    return queue.length;
  }, [setPendingCount]);

  return { enqueue, flush, getPendingCount };
}
