import { useEffect, useState } from 'react';
import { Session, User } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';
import { ENV } from '../lib/env';
import { Profile } from '../types';

export function useAuth() {
  const [session, setSession] = useState<Session | null>(null);
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (ENV.DEMO_MODE) {
      const now = new Date().toISOString();
      setSession(null);
      setUser(null);
      setProfile({
        id: 'demo-local-profile',
        display_name: 'Bob',
        date_of_birth: null,
        diagnosis_type: null,
        diagnosis_date: null,
        tracks_menstrual_cycle: false,
        created_at: now,
        updated_at: now,
      });
      setLoading(false);
      return;
    }

    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);
      if (session?.user) fetchProfile(session.user.id);
      else setLoading(false);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
      setUser(session?.user ?? null);
      if (session?.user) fetchProfile(session.user.id);
      else {
        setProfile(null);
        setLoading(false);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  async function fetchProfile(userId: string) {
    const { data } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();
    setProfile(data);
    setLoading(false);
  }

  async function signUp(email: string, password: string) {
    if (ENV.DEMO_MODE) return { data: null, error: null };
    const { data, error } = await supabase.auth.signUp({ email, password });
    return { data, error };
  }

  async function signIn(email: string, password: string) {
    if (ENV.DEMO_MODE) return { data: null, error: null };
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    return { data, error };
  }

  async function signOut() {
    if (ENV.DEMO_MODE) return;
    await supabase.auth.signOut();
  }

  async function resetPassword(email: string) {
    if (ENV.DEMO_MODE) return { error: null };
    const { error } = await supabase.auth.resetPasswordForEmail(email);
    return { error };
  }

  async function updateProfile(updates: Partial<Profile>) {
    if (!user) return { error: new Error('Not authenticated') };
    const { data, error } = await supabase
      .from('profiles')
      .update(updates)
      .eq('id', user.id)
      .select()
      .single();
    if (data) setProfile(data);
    return { data, error };
  }

  return {
    session,
    user,
    profile,
    loading,
    signUp,
    signIn,
    signOut,
    resetPassword,
    updateProfile,
    refetchProfile: () => user && fetchProfile(user.id),
  };
}
