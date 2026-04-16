import { useState } from 'react';
import {
  View, Text, TextInput,
  KeyboardAvoidingView, Platform, Alert, ScrollView,
} from 'react-native';
import { Link, useRouter } from 'expo-router';
import { supabase } from '../../lib/supabase';
import { useColors } from '../../constants/colors';
import { Theme } from '../../constants/theme';
import { AppCard, PrimaryButton, SectionHeader } from '../../components/ui/DesignPrimitives';
import { SafeAreaView } from 'react-native-safe-area-context';

export default function SignupScreen() {
  const C = useColors();
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});

  function validate() {
    const e: Record<string, string> = {};
    if (!email.trim()) e.email = 'Email is required';
    else if (!/\S+@\S+\.\S+/.test(email)) e.email = 'Enter a valid email';
    if (!password) e.password = 'Password is required';
    else if (password.length < 6) e.password = 'Password must be at least 6 characters';
    if (!confirm) e.confirm = 'Please confirm your password';
    else if (confirm !== password) e.confirm = 'Passwords do not match';
    setErrors(e);
    return Object.keys(e).length === 0;
  }

  async function handleSignup() {
    if (!validate()) return;
    setLoading(true);
    const { error } = await supabase.auth.signUp({ email: email.trim(), password });
    setLoading(false);
    if (error) {
      Alert.alert('Sign up failed', error.message);
    } else {
      router.replace('/(auth)/onboarding');
    }
  }

  const styles = {
    container: { flex: 1, backgroundColor: C.background },
    inner: { flexGrow: 1, justifyContent: 'center' as const, paddingHorizontal: 20, paddingVertical: 24 },
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
    link: { color: C.primary, fontSize: 14 },
    row: { flexDirection: 'row' as const, justifyContent: 'center' as const, marginTop: 12 },
    mutedText: { fontSize: 14, color: C.textSecondary },
  };

  return (
    <SafeAreaView style={styles.container} edges={['top', 'bottom']}>
      <KeyboardAvoidingView
        style={styles.container}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <ScrollView contentContainerStyle={styles.inner} keyboardShouldPersistTaps="handled" showsVerticalScrollIndicator={false}>
          <SectionHeader title="Create account" subtitle="Start tracking your gut health" />

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
                placeholder="At least 6 characters"
                placeholderTextColor={C.placeholder}
                secureTextEntry
                accessibilityLabel="Password"
              />
              {errors.password && <Text style={styles.errorText}>{errors.password}</Text>}

              <Text style={styles.label}>Confirm Password</Text>
              <TextInput
                style={[styles.input, errors.confirm && styles.inputError]}
                value={confirm}
                onChangeText={setConfirm}
                placeholder="••••••••"
                placeholderTextColor={C.placeholder}
                secureTextEntry
                accessibilityLabel="Confirm password"
              />
              {errors.confirm && <Text style={styles.errorText}>{errors.confirm}</Text>}

              <PrimaryButton title="Create Account" onPress={handleSignup} loading={loading} />

              <View style={styles.row}>
                <Text style={styles.mutedText}>Already have an account? </Text>
                <Link href="/(auth)/login" style={styles.link}>Log in</Link>
              </View>
            </View>
          </AppCard>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}
