import { useState } from 'react';
import {
  View, Text, TouchableOpacity, ScrollView, Switch,
  Alert,
} from 'react-native';
import { useRouter } from 'expo-router';
import * as Notifications from 'expo-notifications';
import { supabase } from '../../lib/supabase';
import { useAuthStore } from '../../store/authStore';
import { useColors } from '../../constants/colors';
import { DiagnosisType } from '../../types';
import { Theme } from '../../constants/theme';
import { AppCard, IconBadge, PrimaryButton } from '../../components/ui/DesignPrimitives';
import { SafeAreaView } from 'react-native-safe-area-context';

const STEPS = ['welcome', 'diagnosis', 'cycle', 'notifications'] as const;
type Step = typeof STEPS[number];

const DIAGNOSIS_OPTIONS: { value: DiagnosisType; label: string }[] = [
  { value: 'crohns', label: "Crohn's Disease" },
  { value: 'ulcerative_colitis', label: 'Ulcerative Colitis' },
  { value: 'ibd_unspecified', label: 'IBD (Unspecified)' },
  { value: 'other', label: 'Other / Not diagnosed' },
];

export default function OnboardingScreen() {
  const C = useColors();
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

  const styles = {
    container: { flex: 1, backgroundColor: C.background },
    dots: { flexDirection: 'row' as const, justifyContent: 'center' as const, gap: 8, paddingTop: 14 },
    dot: { width: 8, height: 8, borderRadius: 4, backgroundColor: C.border },
    dotActive: { backgroundColor: C.primary, width: 24 },
    content: { flexGrow: 1, paddingHorizontal: 20, paddingTop: 16 },
    stepCard: {
      padding: Theme.spacing.xl,
      backgroundColor: C.surface,
      borderWidth: 1,
      borderColor: C.glassBorder,
    },
    title: { fontSize: 26, fontWeight: '700' as const, color: C.textPrimary, marginBottom: 12 },
    body: { fontSize: 16, color: C.textSecondary, lineHeight: 24, marginTop: 12, marginBottom: 24 },
    options: { gap: 12 },
    option: {
      borderWidth: 1.2,
      borderColor: C.glassBorder,
      borderRadius: 12,
      paddingVertical: 14,
      paddingHorizontal: 16,
      backgroundColor: C.surfaceMuted,
    },
    optionSelected: { borderColor: C.primary, backgroundColor: C.primary + '20' },
    optionText: { fontSize: 16, color: C.textPrimary },
    optionTextSelected: { color: C.primary, fontWeight: '600' as const },
    switchRow: {
      flexDirection: 'row' as const,
      alignItems: 'center' as const,
      justifyContent: 'space-between' as const,
      backgroundColor: C.surfaceMuted,
      borderRadius: 12,
      paddingVertical: 16,
      paddingHorizontal: 16,
      borderWidth: 1,
      borderColor: C.glassBorder,
    },
    switchLabel: { fontSize: 16, color: C.textPrimary },
    footer: { flexDirection: 'row' as const, paddingHorizontal: 24, paddingBottom: 20, paddingTop: 8, gap: 12 },
    backBtn: {
      flex: 1,
      borderWidth: 1.5,
      borderColor: C.glassBorder,
      borderRadius: 12,
      paddingVertical: 14,
      alignItems: 'center' as const,
      backgroundColor: C.surfaceMuted,
    },
    backBtnText: { fontSize: 16, color: C.textSecondary, fontWeight: '600' as const },
    nextBtnWrap: {
      flex: 2,
      borderRadius: 12,
      justifyContent: 'center' as const,
    },
    nextBtnFull: { flex: 1 },
  };

  return (
    <SafeAreaView style={styles.container} edges={['top', 'bottom']}>
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
                trackColor={{ false: C.border, true: C.primary }}
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
    </SafeAreaView>
  );
}
