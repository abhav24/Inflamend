import { useEffect, useState } from 'react';
import {
  View, Text, TextInput,
  KeyboardAvoidingView, Platform, Alert,
} from 'react-native';
import { Link, useRouter } from 'expo-router';
import { supabase } from '../../lib/supabase';
import { ENV } from '../../lib/env';
import { useColors } from '../../constants/colors';
import { Theme } from '../../constants/theme';
import { AppCard, PrimaryButton, SectionHeader } from '../../components/ui/DesignPrimitives';
import { SafeAreaView } from 'react-native-safe-area-context';

export default function LoginScreen() {
  const C = useColors();
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState<{ email?: string; password?: string }>({});

  useEffect(() => {
    if (ENV.DEMO_MODE) {
      router.replace('/(tabs)/home');
    }
  }, [router]);

  function validate() {
    const e: typeof errors = {};
    if (!email.trim()) e.email = 'Email is required';
    else if (!/\S+@\S+\.\S+/.test(email)) e.email = 'Enter a valid email';
    if (!password) e.password = 'Password is required';
    setErrors(e);
    return Object.keys(e).length === 0;
  }

  async function handleLogin() {
    if (!validate()) return;
    setLoading(true);
    const { error } = await supabase.auth.signInWithPassword({ email: email.trim(), password });
    setLoading(false);
    if (error) {
      Alert.alert('Login failed', error.message);
    } else {
      router.replace('/(tabs)/home');
    }
  }

  const styles = {
    container: { flex: 1, backgroundColor: C.background },
    inner: { flex: 1, justifyContent: 'center' as const, paddingHorizontal: 20 },
    card: {
      padding: Theme.spacing.lg,
      backgroundColor: C.surface,
      borderWidth: 1,
      borderColor: C.glassBorder,
    },
    form: { gap: 8 },
    label: { fontSize: 14, fontWeight: '600' as const, color: C.textPrimary, marginTop: 8 },
    input: {
      borderWidth: 1,
      borderColor: C.border,
      borderRadius: 10,
      paddingHorizontal: 14,
      paddingVertical: 12,
      fontSize: 16,
      backgroundColor: C.surfaceMuted,
      color: C.textPrimary,
    },
    inputError: { borderColor: C.danger },
    errorText: { fontSize: 12, color: C.danger },
    link: { color: C.primary, fontSize: 14, textAlign: 'center' as const, marginTop: 12 },
    signupRow: { flexDirection: 'row' as const, justifyContent: 'center' as const, marginTop: 8 },
    mutedText: { fontSize: 14, color: C.textSecondary },
  };

  return (
    <SafeAreaView style={styles.container} edges={['top', 'bottom']}>
      <KeyboardAvoidingView
        style={styles.container}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <View style={styles.inner}>
          <SectionHeader title="Welcome back" subtitle="Sign in to continue your health tracking" />

          <AppCard style={styles.card}>
            <View style={styles.form}>
              <Text style={styles.label}>Email</Text>
              <TextInput
                style={[styles.input, errors.email && styles.inputError]}
                value={email}
                onChangeText={setEmail}
                placeholder="you@example.com"
                placeholderTextColor={C.placeholder}
                keyboardType="email-address"
                autoCapitalize="none"
                autoCorrect={false}
                accessibilityLabel="Email address"
              />
              {errors.email && <Text style={styles.errorText}>{errors.email}</Text>}

              <Text style={styles.label}>Password</Text>
              <TextInput
                style={[styles.input, errors.password && styles.inputError]}
                value={password}
                onChangeText={setPassword}
                placeholder="••••••••"
                placeholderTextColor={C.placeholder}
                secureTextEntry
                accessibilityLabel="Password"
              />
              {errors.password && <Text style={styles.errorText}>{errors.password}</Text>}

              <PrimaryButton title="Log In" onPress={handleLogin} loading={loading} />

              <Link href="/(auth)/forgot-password" style={styles.link}>
                Forgot password?
              </Link>

              <View style={styles.signupRow}>
                <Text style={styles.mutedText}>Don’t have an account? </Text>
                <Link href="/(auth)/signup" style={[styles.link, { marginTop: 0 }]}>Sign up</Link>
              </View>
            </View>
          </AppCard>
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}
