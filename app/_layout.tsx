import { useEffect } from 'react';
import { Stack, useRouter, useSegments } from 'expo-router';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { supabase } from '../lib/supabase';
import { ENV } from '../lib/env';
import { useAuthStore } from '../store/authStore';
import { useSyncQueue } from '../hooks/useSyncQueue';
import NetInfo from '@react-native-community/netinfo';
import { Profile } from '../types';

export default function RootLayout() {
  const { setSession, setProfile, setLoading } = useAuthStore();
  const session = useAuthStore((s) => s.session);
  const isLoading = useAuthStore((s) => s.isLoading);
  const { flush, getPendingCount } = useSyncQueue();
  const router = useRouter();
  const segments = useSegments();
  const isDemoMode = ENV.DEMO_MODE;

  useEffect(() => {
    if (isDemoMode) {
      const demoProfile: Profile = {
        id: 'demo-local-profile',
        display_name: 'Bob',
        date_of_birth: null,
        diagnosis_type: null,
        diagnosis_date: null,
        tracks_menstrual_cycle: false,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      };

      setSession(null);
      setProfile(demoProfile);
      setLoading(false);
      return;
    }

    supabase.auth.getSession().then(async ({ data: { session: s } }) => {
      setSession(s);
      if (s?.user) {
        try {
          const { data } = await supabase
            .from('profiles')
            .select('*')
            .eq('id', s.user.id)
            .single();
          setProfile(data);
        } catch (error) {
          console.error('Failed to load initial profile', error);
          setProfile(null);
        }
      }
      setLoading(false);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (_event, s) => {
      setSession(s);
      if (s?.user) {
        try {
          const { data } = await supabase
            .from('profiles')
            .select('*')
            .eq('id', s.user.id)
            .single();
          setProfile(data);
        } catch (error) {
          console.error('Failed to load auth-change profile', error);
          setProfile(null);
        }
      } else {
        setProfile(null);
      }
    });

    return () => subscription.unsubscribe();
  }, [isDemoMode, setSession, setProfile, setLoading]);

  useEffect(() => {
    if (isLoading) return;
    const inAuthGroup = segments[0] === '(auth)';
    const inTabsGroup = segments[0] === '(tabs)';

    if (isDemoMode) {
      if (!inTabsGroup) {
        router.replace('/(tabs)/home');
      }
      return;
    }

    if (!session && !inAuthGroup) {
      router.replace('/(auth)/login');
    } else if (session && inAuthGroup) {
      router.replace('/(tabs)/home');
    }
  }, [session, isLoading, segments, router, isDemoMode]);

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
