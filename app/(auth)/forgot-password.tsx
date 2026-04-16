import { useState } from 'react';
import {
  View, Text, TextInput, TouchableOpacity,
  StyleSheet, KeyboardAvoidingView, Platform, Alert,
} from 'react-native';
import { useRouter } from 'expo-router';
import { supabase } from '../../lib/supabase';
import { Colors } from '../../constants/colors';
import { Theme } from '../../constants/theme';
import { AppCard, PrimaryButton, SectionHeader } from '../../components/ui/DesignPrimitives';

export default function ForgotPasswordScreen() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [sent, setSent] = useState(false);
  const [error, setError] = useState('');

  async function handleReset() {
    if (!email.trim()) { setError('Email is required'); return; }
    setError('');
    setLoading(true);
    const { error: err } = await supabase.auth.resetPasswordForEmail(email.trim());
    setLoading(false);
    if (err) {
      Alert.alert('Error', err.message);
    } else {
      setSent(true);
    }
  }

  if (sent) {
    return (
      <View style={styles.container}>
        <View style={styles.inner}>
          <SectionHeader title="Check your email" subtitle="A password reset link has been sent." />
          <AppCard style={styles.card}>
            <Text style={styles.body}>We sent a reset link to {email}.</Text>
            <PrimaryButton title="Back to Login" onPress={() => router.replace('/(auth)/login')} />
          </AppCard>
        </View>
      </View>
    );
  }

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <View style={styles.inner}>
        <TouchableOpacity onPress={() => router.back()} style={styles.back}>
          <Text style={styles.backText}>Back</Text>
        </TouchableOpacity>
        <SectionHeader title="Reset password" subtitle="Enter your email to receive a reset link." />
        <AppCard style={styles.card}>
          <Text style={styles.label}>Email</Text>
          <TextInput
            style={[styles.input, error && styles.inputError]}
            value={email} onChangeText={setEmail}
            placeholder="you@example.com"
            keyboardType="email-address" autoCapitalize="none"
            accessibilityLabel="Email address"
          />
          {error ? <Text style={styles.errorText}>{error}</Text> : null}

          <PrimaryButton title="Send Reset Link" onPress={handleReset} loading={loading} />
        </AppCard>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.background },
  inner: { flex: 1, paddingHorizontal: 20, paddingTop: 56 },
  card: {
    padding: Theme.spacing.lg,
  },
  back: { marginBottom: 24 },
  backText: { color: Colors.primary, fontSize: 16 },
  body: { fontSize: 15, color: Colors.textSecondary, marginBottom: 24, lineHeight: 22 },
  label: { fontSize: 14, fontWeight: '600', color: Colors.textPrimary, marginBottom: 4 },
  input: {
    borderWidth: 1, borderColor: Colors.border, borderRadius: 10,
    paddingHorizontal: 14, paddingVertical: 12, fontSize: 16,
    backgroundColor: Colors.white, color: Colors.textPrimary,
  },
  inputError: { borderColor: Colors.danger },
  errorText: { fontSize: 12, color: Colors.danger, marginTop: 4 },
});
