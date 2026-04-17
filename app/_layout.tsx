import { useEffect } from 'react';
import { Platform, StyleSheet, View } from 'react-native';
import { Stack, useRouter, useSegments } from 'expo-router';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { LinearGradient } from 'expo-linear-gradient';
import { StatusBar } from 'expo-status-bar';
import NetInfo from '@react-native-community/netinfo';
import { supabase } from '../lib/supabase';
import { ENV } from '../lib/env';
import { Profile } from '../types';
import { useColors } from '../constants/colors';
import { useAuthStore } from '../store/authStore';
import { useSyncQueue } from '../hooks/useSyncQueue';
import { getDemoProfile, setDemoProfile } from '../lib/demoData';

const DEMO_PROFILE_ID = 'demo-local-profile';
const DEMO_USER_ID = 'demo-local-user';

export default function RootLayout() {
  const C = useColors();
  const { setSession, setProfile, setDemoProfile: setDemoState, setLoading } = useAuthStore();
  const session = useAuthStore((s) => s.session);
  const isLoading = useAuthStore((s) => s.isLoading);
  const { flush, getPendingCount } = useSyncQueue();
  const router = useRouter();
  const segments = useSegments();
  const isDemoMode = ENV.DEMO_MODE;

  useEffect(() => {
    if (isDemoMode) {
      const now = new Date().toISOString();
      const fallbackProfile: Profile = {
        id: DEMO_PROFILE_ID,
        display_name: 'Bob',
        date_of_birth: null,
        diagnosis_type: null,
        diagnosis_date: null,
        tracks_menstrual_cycle: false,
        created_at: now,
        updated_at: now,
      };

      getDemoProfile(fallbackProfile)
        .then(async (profile) => {
          const hydrated = {
            ...fallbackProfile,
            ...profile,
            id: DEMO_PROFILE_ID,
          };
          setDemoState(hydrated, DEMO_USER_ID);
          await setDemoProfile(hydrated);
          setLoading(false);
        })
        .catch(() => {
          setDemoState(fallbackProfile, DEMO_USER_ID);
          setLoading(false);
        });
      return;
    }

    supabase.auth.getSession().then(async ({ data: { session: s } }) => {
      setSession(s);
      if (s?.user) {
        try {
          const { data } = await supabase.from('profiles').select('*').eq('id', s.user.id).single();
          setProfile(data);
        } catch (error) {
          console.error('Failed to load initial profile', error);
          setProfile(null);
        }
      }
      setLoading(false);
    });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (_event, s) => {
      setSession(s);
      if (s?.user) {
        try {
          const { data } = await supabase.from('profiles').select('*').eq('id', s.user.id).single();
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
  }, [isDemoMode, setDemoState, setLoading, setProfile, setSession]);

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

  useEffect(() => {
    getPendingCount();
    const unsub = NetInfo.addEventListener((state) => {
      if (state.isConnected) flush();
    });
    return () => unsub();
  }, [flush, getPendingCount]);

  return (
    <GestureHandlerRootView style={styles.root}>
      <View pointerEvents="none" style={StyleSheet.absoluteFill}>
        <LinearGradient
          colors={[C.meshStart, C.meshAccent, C.meshEnd]}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={StyleSheet.absoluteFill}
        />
        <LinearGradient
          colors={C.isDark ? ['rgba(103,116,255,0.16)', 'transparent'] : ['rgba(255,255,255,0.55)', 'transparent']}
          start={{ x: 0.15, y: 0 }}
          end={{ x: 0.85, y: 0.5 }}
          style={[StyleSheet.absoluteFill, { opacity: Platform.OS === 'ios' ? 1 : 0.8 }]}
        />
      </View>

      <StatusBar style={C.isDark ? 'light' : 'dark'} />

      <Stack
        screenOptions={{
          headerShown: false,
          animation: 'default',
          contentStyle: { backgroundColor: 'transparent' },
        }}
      />
    </GestureHandlerRootView>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
  },
});
