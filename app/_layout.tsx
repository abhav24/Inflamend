import { useEffect } from 'react';
import { Stack, useRouter, useSegments } from 'expo-router';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { supabase } from '../lib/supabase';
import { useAuthStore } from '../store/authStore';
import { useSyncQueue } from '../hooks/useSyncQueue';
import NetInfo from '@react-native-community/netinfo';

export default function RootLayout() {
  const { setSession, setProfile, setLoading } = useAuthStore();
  const session = useAuthStore((s) => s.session);
  const isLoading = useAuthStore((s) => s.isLoading);
  const { flush, getPendingCount } = useSyncQueue();
  const router = useRouter();
  const segments = useSegments();

  useEffect(() => {
    supabase.auth.getSession().then(async ({ data: { session: s } }) => {
      setSession(s);
      if (s?.user) {
        const { data } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', s.user.id)
          .single();
        setProfile(data);
      }
      setLoading(false);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (_event, s) => {
      setSession(s);
      if (s?.user) {
        const { data } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', s.user.id)
          .single();
        setProfile(data);
      } else {
        setProfile(null);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  // Route protection — runs when auth state resolves
  useEffect(() => {
    if (isLoading) return;
    const inAuthGroup = segments[0] === '(auth)';
    if (!session && !inAuthGroup) {
      router.replace('/(auth)/login');
    } else if (session && inAuthGroup) {
      router.replace('/(tabs)/home');
    }
  }, [session, isLoading, segments]);

  // Background sync when online
  useEffect(() => {
    getPendingCount();
    const unsub = NetInfo.addEventListener((state) => {
      if (state.isConnected) flush();
    });
    return () => unsub();
  }, [flush, getPendingCount]);

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <Stack screenOptions={{ headerShown: false }} />
    </GestureHandlerRootView>
  );
}
