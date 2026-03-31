import { useState } from 'react';
import {
  View, Text, TextInput, TouchableOpacity,
  StyleSheet, KeyboardAvoidingView, Platform, Alert, ActivityIndicator,
} from 'react-native';
import { useRouter } from 'expo-router';
import { supabase } from '../../lib/supabase';
import { Colors } from '../../constants/colors';

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
          <Text style={styles.title}>Check Your Email</Text>
          <Text style={styles.body}>
            We've sent a password reset link to {email}. Check your inbox.
          </Text>
          <TouchableOpacity style={styles.button} onPress={() => router.replace('/(auth)/login')}>
            <Text style={styles.buttonText}>Back to Login</Text>
          </TouchableOpacity>
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
          <Text style={styles.backText}>← Back</Text>
        </TouchableOpacity>
        <Text style={styles.title}>Reset Password</Text>
        <Text style={styles.body}>Enter your email to receive a reset link.</Text>

        <Text style={styles.label}>Email</Text>
        <TextInput
          style={[styles.input, error && styles.inputError]}
          value={email} onChangeText={setEmail}
          placeholder="you@example.com"
          keyboardType="email-address" autoCapitalize="none"
          accessibilityLabel="Email address"
        />
        {error ? <Text style={styles.errorText}>{error}</Text> : null}

        <TouchableOpacity style={styles.button} onPress={handleReset} disabled={loading}>
          {loading
            ? <ActivityIndicator color={Colors.white} />
            : <Text style={styles.buttonText}>Send Reset Link</Text>
          }
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.background },
  inner: { flex: 1, paddingHorizontal: 24, paddingTop: 60 },
  back: { marginBottom: 24 },
  backText: { color: Colors.primary, fontSize: 16 },
  title: { fontSize: 24, fontWeight: '700', color: Colors.textPrimary, marginBottom: 8 },
  body: { fontSize: 15, color: Colors.textSecondary, marginBottom: 24, lineHeight: 22 },
  label: { fontSize: 14, fontWeight: '600', color: Colors.textPrimary, marginBottom: 4 },
  input: {
    borderWidth: 1, borderColor: Colors.border, borderRadius: 10,
    paddingHorizontal: 14, paddingVertical: 12, fontSize: 16,
    backgroundColor: Colors.white, color: Colors.textPrimary,
  },
  inputError: { borderColor: Colors.danger },
  errorText: { fontSize: 12, color: Colors.danger, marginTop: 4 },
  button: {
    backgroundColor: Colors.primary, borderRadius: 10,
    paddingVertical: 14, alignItems: 'center', marginTop: 16,
  },
  buttonText: { color: Colors.white, fontSize: 16, fontWeight: '600' },
});
