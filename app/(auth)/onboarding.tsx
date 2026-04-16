import { useState } from 'react';
import {
  View, Text, TouchableOpacity, StyleSheet, ScrollView, Switch,
  Alert,
} from 'react-native';
import { useRouter } from 'expo-router';
import * as Notifications from 'expo-notifications';
import { supabase } from '../../lib/supabase';
import { useAuthStore } from '../../store/authStore';
import { Colors } from '../../constants/colors';
import { DiagnosisType } from '../../types';
import { Theme } from '../../constants/theme';
import { AppCard, IconBadge, PrimaryButton } from '../../components/ui/DesignPrimitives';

const STEPS = ['welcome', 'diagnosis', 'cycle', 'notifications'] as const;
type Step = typeof STEPS[number];

const DIAGNOSIS_OPTIONS: { value: DiagnosisType; label: string }[] = [
  { value: 'crohns', label: "Crohn's Disease" },
  { value: 'ulcerative_colitis', label: 'Ulcerative Colitis' },
  { value: 'ibd_unspecified', label: 'IBD (Unspecified)' },
  { value: 'other', label: 'Other / Not diagnosed' },
];

export default function OnboardingScreen() {
  const router = useRouter();
  const { user, setProfile } = useAuthStore();
  const [step, setStep] = useState<Step>('welcome');
  const [diagnosis, setDiagnosis] = useState<DiagnosisType | null>(null);
  const [tracksCycle, setTracksCycle] = useState(false);
  const [saving, setSaving] = useState(false);

  const stepIndex = STEPS.indexOf(step);

  async function handleFinish() {
    if (!user) return;
    setSaving(true);

    // Request notification permissions
    const { status } = await Notifications.requestPermissionsAsync();
    console.log('Notification permission:', status);

    // Save profile
    const { data, error } = await supabase
      .from('profiles')
      .update({
        diagnosis_type: diagnosis,
        tracks_menstrual_cycle: tracksCycle,
      })
      .eq('id', user.id)
      .select()
      .single();

    setSaving(false);
    if (error) {
      Alert.alert('Error', 'Could not save your profile. Please try again.');
      return;
    }
    setProfile(data);
    router.replace('/(tabs)/home');
  }

  function next() {
    const nextIndex = stepIndex + 1;
    if (nextIndex < STEPS.length) setStep(STEPS[nextIndex]);
    else handleFinish();
  }

  function back() {
    if (stepIndex > 0) setStep(STEPS[stepIndex - 1]);
  }

  return (
    <View style={styles.container}>
      {/* Progress dots */}
      <View style={styles.dots}>
        {STEPS.map((s, i) => (
          <View key={s} style={[styles.dot, i === stepIndex && styles.dotActive]} />
        ))}
      </View>

      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        {step === 'welcome' && (
          <AppCard style={styles.stepCard}>
            <IconBadge label="IN" size={52} />
            <Text style={styles.title}>Welcome to Inflamend</Text>
            <Text style={styles.body}>
              Your personal IBD management companion. Track your symptoms, food, medications,
              and more — all in one place. Let’s get you set up in just a few steps.
            </Text>
          </AppCard>
        )}

        {step === 'diagnosis' && (
          <AppCard style={styles.stepCard}>
            <Text style={styles.title}>What’s your diagnosis?</Text>
            <Text style={styles.body}>This helps personalize your experience. You can change it later.</Text>
            <View style={styles.options}>
              {DIAGNOSIS_OPTIONS.map((opt) => (
                <TouchableOpacity
                  key={opt.value}
                  style={[styles.option, diagnosis === opt.value && styles.optionSelected]}
                  onPress={() => setDiagnosis(opt.value)}
                  accessibilityLabel={opt.label}
                  accessibilityState={{ selected: diagnosis === opt.value }}
                >
                  <Text style={[styles.optionText, diagnosis === opt.value && styles.optionTextSelected]}>
                    {opt.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </AppCard>
        )}

        {step === 'cycle' && (
          <AppCard style={styles.stepCard}>
            <Text style={styles.title}>Menstrual Cycle Tracking</Text>
            <Text style={styles.body}>
              Many people with IBD notice symptom changes during their cycle. Would you like
              to track this to find patterns?
            </Text>
            <View style={styles.switchRow}>
              <Text style={styles.switchLabel}>Track menstrual cycle</Text>
              <Switch
                value={tracksCycle}
                onValueChange={setTracksCycle}
                trackColor={{ true: Colors.primary }}
                accessibilityLabel="Track menstrual cycle toggle"
              />
            </View>
          </AppCard>
        )}

        {step === 'notifications' && (
          <AppCard style={styles.stepCard}>
            <IconBadge label="NT" tone="secondary" size={52} />
            <Text style={styles.title}>Medication Reminders</Text>
            <Text style={styles.body}>
              Allow notifications so Inflamend can remind you to take your medications
              and log your daily symptoms. You can change this in Settings anytime.
            </Text>
          </AppCard>
        )}
      </ScrollView>

      <View style={styles.footer}>
        {stepIndex > 0 && (
          <TouchableOpacity style={styles.backBtn} onPress={back}>
            <Text style={styles.backBtnText}>Back</Text>
          </TouchableOpacity>
        )}
        <View style={[styles.nextBtnWrap, !stepIndex && styles.nextBtnFull]}>
          <PrimaryButton
            title={step === 'notifications' ? 'Get Started' : 'Continue'}
            onPress={next}
            loading={saving}
          />
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.background },
  dots: { flexDirection: 'row', justifyContent: 'center', gap: 8, paddingTop: 60 },
  dot: { width: 8, height: 8, borderRadius: 4, backgroundColor: Colors.border },
  dotActive: { backgroundColor: Colors.primary, width: 24 },
  content: { flexGrow: 1, paddingHorizontal: 20, paddingTop: 20 },
  stepCard: {
    padding: Theme.spacing.xl,
  },
  title: { fontSize: 26, fontWeight: '700', color: Colors.textPrimary, marginBottom: 12 },
  body: { fontSize: 16, color: Colors.textSecondary, lineHeight: 24, marginTop: 12, marginBottom: 24 },
  options: { gap: 12 },
  option: {
    borderWidth: 1.5, borderColor: Colors.border, borderRadius: 12,
    paddingVertical: 14, paddingHorizontal: 16, backgroundColor: Colors.white,
  },
  optionSelected: { borderColor: Colors.primary, backgroundColor: Colors.primaryLight },
  optionText: { fontSize: 16, color: Colors.textPrimary },
  optionTextSelected: { color: Colors.primary, fontWeight: '600' },
  switchRow: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    backgroundColor: Colors.white, borderRadius: 12,
    paddingVertical: 16, paddingHorizontal: 16,
    borderWidth: 1, borderColor: Colors.border,
  },
  switchLabel: { fontSize: 16, color: Colors.textPrimary },
  footer: { flexDirection: 'row', paddingHorizontal: 24, paddingBottom: 40, gap: 12 },
  backBtn: {
    flex: 1, borderWidth: 1.5, borderColor: Colors.border, borderRadius: 12,
    paddingVertical: 14, alignItems: 'center',
  },
  backBtnText: { fontSize: 16, color: Colors.textSecondary, fontWeight: '600' },
  nextBtnWrap: {
    flex: 2, backgroundColor: Colors.primary, borderRadius: 12,
    justifyContent: 'center',
  },
  nextBtnFull: { flex: 1 },
});
