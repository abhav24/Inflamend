import { useEffect } from 'react';
import { Stack, useRouter, useSegments } from 'expo-router';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { supabase } from '../lib/supabase';
import { useAuthStore } from '../store/authStore';
import { useSyncQueue } from '../hooks/useSyncQueue';
import NetInfo from '@react-native-community/netinfo';

export default function RootLayout() {
  const { setSession, setProfile, setLoading } = useAuthStore();
  const { flush, getPendingCount } = useSyncQueue();
  const router = useRouter();
  const segments = useSegments();

  useEffect(() => {
    supabase.auth.getSession().then(async ({ data: { session } }) => {
      setSession(session);
      if (session?.user) {
        const { data } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', session.user.id)
          .single();
        setProfile(data);
      }
      setLoading(false);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (_event, session) => {
      setSession(session);
      if (session?.user) {
        const { data } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', session.user.id)
          .single();
        setProfile(data);
      } else {
        setProfile(null);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  // Route protection
  useEffect(() => {
    const { isLoading, session } = useAuthStore.getState();
    if (isLoading) return;
    const inAuthGroup = segments[0] === '(auth)';
    if (!session && !inAuthGroup) {
      router.replace('/(auth)/login');
    } else if (session && inAuthGroup) {
      router.replace('/(tabs)/home');
    }
  }, [useAuthStore((s) => s.session), useAuthStore((s) => s.isLoading)]);

  // Background sync when online
  useEffect(() => {
    getPendingCount();
    const unsub = NetInfo.addEventListener((state) => {
      if (state.isConnected) flush();
    });
    return () => unsub();
  }, []);

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <Stack screenOptions={{ headerShown: false }} />
    </GestureHandlerRootView>
  );
}
