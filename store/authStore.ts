import { create } from 'zustand';
import { Session, User } from '@supabase/supabase-js';
import { Profile } from '../types';

interface AuthState {
  session: Session | null;
  user: User | null;
  userId: string | null;
  profile: Profile | null;
  isLoading: boolean;
  setSession: (session: Session | null) => void;
  setProfile: (profile: Profile | null) => void;
  setDemoProfile: (profile: Profile, userId: string) => void;
  setLoading: (loading: boolean) => void;
  clear: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  session: null,
  user: null,
  userId: null,
  profile: null,
  isLoading: true,
  setSession: (session) =>
    set({ session, user: session?.user ?? null, userId: session?.user?.id ?? null }),
  setProfile: (profile) => set({ profile }),
  setDemoProfile: (profile, userId) => set({ profile, userId, session: null, user: null }),
  setLoading: (isLoading) => set({ isLoading }),
  clear: () => set({ session: null, user: null, userId: null, profile: null }),
}));
