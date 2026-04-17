import { useEffect, useMemo, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  Switch,
  Text,
  View,
} from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { format } from 'date-fns';
import {
  BRISTOL_TYPES,
  FLOW_LEVELS,
  MEAL_TYPES,
  MENSTRUAL_SYMPTOMS,
  MOOD_OPTIONS,
  PAIN_LOCATIONS,
  SIDE_EFFECT_OPTIONS,
} from '../../constants';
import { useColors } from '../../constants/colors';
import {
  BloodAmount,
  FlowLevel,
  MealType,
  Medication,
  Mood,
} from '../../types';
import {
  useBowelLogs,
  useFoodLogs,
  useMedicationLogs,
  useMedications,
  useMenstrualLogs,
  useSleepLogs,
  useSymptomLogs,
  useWeightLogs,
} from '../../hooks/useLogs';
import { DateTimePicker } from '../../components/ui/DateTimePicker';
import {
  AppCard,
  AppIcon,
  GlassTextInput,
  PressScale,
} from '../../components/ui/DesignPrimitives';
import { SliderInput } from '../../components/ui/SliderInput';
import { TagSelector } from '../../components/ui/TagSelector';
import { impactLightHaptic, selectionHaptic, successHaptic } from '../../lib/haptics';

type TabKey = 'food' | 'bowel' | 'symptoms' | 'meds' | 'sleep' | 'cycle' | 'weight';

const TABS: { key: TabKey; label: string; symbol: React.ComponentProps<typeof AppIcon>['symbol']; fallback: React.ComponentProps<typeof AppIcon>['fallback'] }[] = [
  { key: 'food', label: 'Food', symbol: 'fork.knife', fallback: 'restaurant-outline' },
  { key: 'bowel', label: 'Bowel', symbol: 'drop.fill', fallback: 'water-outline' },
  { key: 'symptoms', label: 'Symptoms', symbol: 'waveform.path.ecg', fallback: 'pulse-outline' },
  { key: 'meds', label: 'Meds', symbol: 'pill.fill', fallback: 'medkit-outline' },
  { key: 'sleep', label: 'Sleep', symbol: 'bed.double.fill', fallback: 'moon-outline' },
  { key: 'cycle', label: 'Cycle', symbol: 'calendar', fallback: 'calendar-outline' },
  { key: 'weight', label: 'Weight', symbol: 'scalemass.fill', fallback: 'barbell-outline' },
];

function FieldLabel({ text }: { text: string }) {
  const C = useColors();
  return (
    <Text style={{ marginBottom: 10, fontSize: 12, fontWeight: '700', color: C.textMuted, textTransform: 'uppercase', letterSpacing: 0.32 }}>
      {text}
    </Text>
  );
}

function CardDivider() {
  const C = useColors();
  return <View style={{ height: 1, backgroundColor: C.separator, marginVertical: 14 }} />;
}

function SuccessState({ title }: { title: string }) {
  const C = useColors();
  return (
    <View style={{ alignItems: 'center', justifyContent: 'center', paddingVertical: 72 }}>
      <AppCard style={{ width: 78, height: 78, alignItems: 'center', justifyContent: 'center' }} intensity={56}>
        <AppIcon symbol="checkmark" fallback="checkmark" size={28} tintColor={C.success} />
      </AppCard>
      <Text style={{ marginTop: 18, fontSize: 24, fontWeight: '800', color: C.textPrimary, letterSpacing: -0.4 }}>
        {title}
      </Text>
      <Text style={{ marginTop: 6, fontSize: 15, fontWeight: '500', color: C.textSecondary }}>
        Saved to your timeline.
      </Text>
    </View>
  );
}

function SubmitButton({
  label,
  loading,
  onPress,
}: {
  label: string;
  loading: boolean;
  onPress: () => void;
}) {
  const C = useColors();
  return (
    <PressScale
      disabled={loading}
      onPress={() => {
        impactLightHaptic();
        onPress();
      }}
    >
      <AppCard style={{ marginBottom: 16, overflow: 'hidden' }} intensity={56}>
        <View style={{ backgroundColor: C.primary, alignItems: 'center', justifyContent: 'center', minHeight: 56 }}>
          {loading ? (
            <ActivityIndicator color={C.onGradient} />
          ) : (
            <Text style={{ fontSize: 17, fontWeight: '700', color: C.onGradient, letterSpacing: -0.24 }}>
              {label}
            </Text>
          )}
        </View>
      </AppCard>
    </PressScale>
  );
}

function ChipGroup<T extends string>({
  options,
  value,
  onChange,
}: {
  options: readonly { value: T; label: string }[];
  value: T | null;
  onChange: (value: T) => void;
}) {
  const C = useColors();
  return (
    <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8 }}>
      {options.map((option) => {
        const active = option.value === value;
        return (
          <PressScale
            key={option.value}
            onPress={() => {
              selectionHaptic();
              onChange(option.value);
            }}
          >
            <View
              style={{
                paddingHorizontal: 14,
                paddingVertical: 9,
                borderRadius: 18,
                borderWidth: 1,
                borderColor: active ? C.primary : C.glassBorder,
                backgroundColor: active ? C.primary : C.fillTertiary,
              }}
            >
              <Text style={{ fontSize: 13, fontWeight: active ? '700' : '500', color: active ? C.onGradient : C.textSecondary, letterSpacing: -0.08 }}>
                {option.label}
              </Text>
            </View>
          </PressScale>
        );
      })}
    </View>
  );
}

function SwitchRow({
  label,
  value,
  onChange,
}: {
  label: string;
  value: boolean;
  onChange: (value: boolean) => void;
}) {
  const C = useColors();
  return (
    <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 12 }}>
      <Text style={{ flex: 1, fontSize: 16, fontWeight: '500', color: C.textPrimary, letterSpacing: -0.24 }}>
        {label}
      </Text>
      <Switch
        value={value}
        onValueChange={(nextValue) => {
          impactLightHaptic();
          onChange(nextValue);
        }}
        trackColor={{ false: C.border, true: C.primary }}
      />
    </View>
  );
}

function FormCard({ children }: { children: React.ReactNode }) {
  return <AppCard style={{ marginBottom: 14, padding: 16 }} intensity={46}>{children}</AppCard>;
}

function FoodForm() {
  const { add } = useFoodLogs();
  const [mealType, setMealType] = useState<MealType | null>(null);
  const [loggedAt, setLoggedAt] = useState(new Date());
  const [description, setDescription] = useState('');
  const [waterMl, setWaterMl] = useState('');
  const [notes, setNotes] = useState('');
  const [isTrigger, setIsTrigger] = useState(false);
  const [isSafe, setIsSafe] = useState(false);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  async function handleSubmit() {
    if (!mealType) {
      Alert.alert('Missing Meal Type', 'Select a meal type first.');
      return;
    }
    if (!description.trim()) {
      Alert.alert('Missing Description', 'Describe what you ate.');
      return;
    }

    setLoading(true);
    const result = await add({
      meal_type: mealType,
      description: description.trim(),
      logged_at: loggedAt.toISOString(),
      photo_url: null,
      calories: null,
      protein_g: null,
      carbs_g: null,
      fat_g: null,
      fiber_g: null,
      water_ml: waterMl ? Number(waterMl) : null,
      is_trigger_food: isTrigger,
      is_safe_food: isSafe,
      notes: notes.trim() || null,
    });
    setLoading(false);

    if (!result) {
      Alert.alert('Could Not Save', 'Your food log could not be saved.');
      return;
    }

    successHaptic();
    setSuccess(true);
    setTimeout(() => {
      setSuccess(false);
      setMealType(null);
      setDescription('');
      setWaterMl('');
      setNotes('');
      setIsTrigger(false);
      setIsSafe(false);
      setLoggedAt(new Date());
    }, 900);
  }

  if (success) return <SuccessState title="Food logged" />;

  return (
    <>
      <FormCard>
        <FieldLabel text="Meal Type" />
        <ChipGroup options={MEAL_TYPES} value={mealType} onChange={setMealType} />
      </FormCard>

      <FormCard>
        <FieldLabel text="Description" />
        <GlassTextInput value={description} onChangeText={setDescription} placeholder="Describe your meal..." multiline inputStyle={{ minHeight: 90, textAlignVertical: 'top' }} />
      </FormCard>

      <FormCard>
        <DateTimePicker label="Logged At" value={loggedAt} onChange={setLoggedAt} mode="datetime" />
        <FieldLabel text="Water (ml)" />
        <GlassTextInput value={waterMl} onChangeText={setWaterMl} placeholder="e.g. 250" keyboardType="number-pad" />
      </FormCard>

      <FormCard>
        <SwitchRow label="Trigger food?" value={isTrigger} onChange={setIsTrigger} />
        <CardDivider />
        <SwitchRow label="Safe food?" value={isSafe} onChange={setIsSafe} />
      </FormCard>

      <FormCard>
        <FieldLabel text="Notes" />
        <GlassTextInput value={notes} onChangeText={setNotes} placeholder="Anything else worth noting?" multiline inputStyle={{ minHeight: 80, textAlignVertical: 'top' }} />
      </FormCard>

      <SubmitButton label="Log Food" loading={loading} onPress={handleSubmit} />
    </>
  );
}

const BLOOD_AMOUNT_OPTIONS: { value: BloodAmount; label: string }[] = [
  { value: 'none', label: 'None' },
  { value: 'trace', label: 'Trace' },
  { value: 'moderate', label: 'Moderate' },
  { value: 'significant', label: 'Significant' },
];

function BowelForm() {
  const C = useColors();
  const { add } = useBowelLogs();
  const [loggedAt, setLoggedAt] = useState(new Date());
  const [bristolScale, setBristolScale] = useState<number | null>(null);
  const [urgency, setUrgency] = useState(1);
  const [bloodPresent, setBloodPresent] = useState(false);
  const [bloodAmount, setBloodAmount] = useState<BloodAmount>('none');
  const [mucusPresent, setMucusPresent] = useState(false);
  const [painDuring, setPainDuring] = useState(0);
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  async function handleSubmit() {
    if (!bristolScale) {
      Alert.alert('Missing Bristol Type', 'Pick the type that best matches.');
      return;
    }

    setLoading(true);
    const result = await add({
      logged_at: loggedAt.toISOString(),
      bristol_scale: bristolScale,
      urgency,
      blood_present: bloodPresent,
      blood_amount: bloodPresent ? bloodAmount : 'none',
      mucus_present: mucusPresent,
      pain_during: painDuring,
      notes: notes.trim() || null,
    });
    setLoading(false);

    if (!result) {
      Alert.alert('Could Not Save', 'Your bowel log could not be saved.');
      return;
    }

    successHaptic();
    setSuccess(true);
    setTimeout(() => {
      setSuccess(false);
      setLoggedAt(new Date());
      setBristolScale(null);
      setUrgency(1);
      setBloodPresent(false);
      setBloodAmount('none');
      setMucusPresent(false);
      setPainDuring(0);
      setNotes('');
    }, 900);
  }

  if (success) return <SuccessState title="Bowel logged" />;

  return (
    <>
      <FormCard>
        <DateTimePicker label="Logged At" value={loggedAt} onChange={setLoggedAt} mode="datetime" />
      </FormCard>

      <FormCard>
        <FieldLabel text="Bristol Stool Scale" />
        {BRISTOL_TYPES.map((item) => {
          const active = bristolScale === item.scale;
          return (
            <PressScale key={item.scale} onPress={() => setBristolScale(item.scale)}>
              <View style={{ flexDirection: 'row', alignItems: 'center', padding: 12, marginBottom: 8, borderRadius: 18, borderWidth: 1, borderColor: active ? C.primary : C.glassBorder, backgroundColor: active ? `${C.primary}14` : C.fillTertiary }}>
                <View style={{ width: 30, height: 30, borderRadius: 15, alignItems: 'center', justifyContent: 'center', backgroundColor: active ? C.primary : C.fillQuaternary }}>
                  <Text style={{ fontSize: 13, fontWeight: '800', color: active ? C.onGradient : C.textSecondary }}>{item.scale}</Text>
                </View>
                <View style={{ flex: 1, marginLeft: 12 }}>
                  <Text style={{ fontSize: 15, fontWeight: '700', color: active ? C.primary : C.textPrimary, letterSpacing: -0.24 }}>
                    {item.name}
                  </Text>
                  <Text style={{ marginTop: 2, fontSize: 12, color: C.textSecondary }}>{item.description}</Text>
                </View>
              </View>
            </PressScale>
          );
        })}
      </FormCard>

      <FormCard>
        <SliderInput label="Urgency" value={urgency} min={1} max={5} onChange={setUrgency} />
        <CardDivider />
        <SliderInput label="Pain During" value={painDuring} min={0} max={10} onChange={setPainDuring} />
      </FormCard>

      <FormCard>
        <SwitchRow label="Blood present?" value={bloodPresent} onChange={setBloodPresent} />
        {bloodPresent ? (
          <>
            <CardDivider />
            <FieldLabel text="Blood Amount" />
            <ChipGroup options={BLOOD_AMOUNT_OPTIONS} value={bloodAmount} onChange={setBloodAmount} />
          </>
        ) : null}
        <CardDivider />
        <SwitchRow label="Mucus present?" value={mucusPresent} onChange={setMucusPresent} />
      </FormCard>

      <FormCard>
        <FieldLabel text="Notes" />
        <GlassTextInput value={notes} onChangeText={setNotes} placeholder="Optional notes..." multiline inputStyle={{ minHeight: 80, textAlignVertical: 'top' }} />
      </FormCard>

      <SubmitButton label="Log Bowel Movement" loading={loading} onPress={handleSubmit} />
    </>
  );
}

function SymptomsForm() {
  const { add } = useSymptomLogs();
  const [loggedAt, setLoggedAt] = useState(new Date());
  const [painLevel, setPainLevel] = useState(0);
  const [painLocation, setPainLocation] = useState<string[]>([]);
  const [fatigueLevel, setFatigueLevel] = useState(0);
  const [nauseaLevel, setNauseaLevel] = useState(0);
  const [bloatingLevel, setBloatingLevel] = useState(0);
  const [stressLevel, setStressLevel] = useState(0);
  const [mood, setMood] = useState<Mood | null>(null);
  const [isFlare, setIsFlare] = useState(false);
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  async function handleSubmit() {
    setLoading(true);
    const result = await add({
      logged_at: loggedAt.toISOString(),
      pain_level: painLevel,
      pain_location: painLocation,
      fatigue_level: fatigueLevel,
      nausea_level: nauseaLevel,
      bloating_level: bloatingLevel,
      stress_level: stressLevel,
      mood,
      is_flare: isFlare,
      notes: notes.trim() || null,
    });
    setLoading(false);

    if (!result) {
      Alert.alert('Could Not Save', 'Your symptom log could not be saved.');
      return;
    }

    successHaptic();
    setSuccess(true);
    setTimeout(() => {
      setSuccess(false);
      setLoggedAt(new Date());
      setPainLevel(0);
      setPainLocation([]);
      setFatigueLevel(0);
      setNauseaLevel(0);
      setBloatingLevel(0);
      setStressLevel(0);
      setMood(null);
      setIsFlare(false);
      setNotes('');
    }, 900);
  }

  if (success) return <SuccessState title="Symptoms logged" />;

  return (
    <>
      <FormCard>
        <DateTimePicker label="Logged At" value={loggedAt} onChange={setLoggedAt} mode="datetime" />
      </FormCard>

      <FormCard>
        <SliderInput label="Pain Level" value={painLevel} min={0} max={10} onChange={setPainLevel} />
        <CardDivider />
        <TagSelector options={PAIN_LOCATIONS} selected={painLocation} onChange={setPainLocation} label="Pain Location" />
      </FormCard>

      <FormCard>
        <SliderInput label="Fatigue" value={fatigueLevel} min={0} max={10} onChange={setFatigueLevel} />
        <CardDivider />
        <SliderInput label="Nausea" value={nauseaLevel} min={0} max={10} onChange={setNauseaLevel} />
        <CardDivider />
        <SliderInput label="Bloating" value={bloatingLevel} min={0} max={10} onChange={setBloatingLevel} />
        <CardDivider />
        <SliderInput label="Stress" value={stressLevel} min={0} max={10} onChange={setStressLevel} />
      </FormCard>

      <FormCard>
        <FieldLabel text="Mood" />
        <ChipGroup options={MOOD_OPTIONS as any} value={mood} onChange={setMood} />
        <CardDivider />
        <SwitchRow label="Currently in a flare?" value={isFlare} onChange={setIsFlare} />
      </FormCard>

      <FormCard>
        <FieldLabel text="Notes" />
        <GlassTextInput value={notes} onChangeText={setNotes} placeholder="Optional notes..." multiline inputStyle={{ minHeight: 80, textAlignVertical: 'top' }} />
      </FormCard>

      <SubmitButton label="Log Symptoms" loading={loading} onPress={handleSubmit} />
    </>
  );
}

function MedsForm() {
  const C = useColors();
  const { fetchActive, add: addMedication } = useMedications();
  const { add: addMedicationLog } = useMedicationLogs();
  const [medications, setMedications] = useState<Medication[]>([]);
  const [selectedMedicationId, setSelectedMedicationId] = useState<string | null>(null);
  const [scheduledTime, setScheduledTime] = useState(new Date());
  const [newMedName, setNewMedName] = useState('');
  const [newMedDosage, setNewMedDosage] = useState('');
  const [sideEffects, setSideEffects] = useState<string[]>([]);
  const [notes, setNotes] = useState('');
  const [loadingList, setLoadingList] = useState(true);
  const [savingMedication, setSavingMedication] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [success, setSuccess] = useState(false);

  useEffect(() => {
    fetchActive().then((items) => {
      setMedications(items);
      setSelectedMedicationId(items[0]?.id ?? null);
      setLoadingList(false);
    });
  }, [fetchActive]);

  const selectedMedication = medications.find((item) => item.id === selectedMedicationId) ?? null;

  async function handleAddMedication() {
    if (!newMedName.trim()) {
      Alert.alert('Missing Medication Name', 'Enter the medication name first.');
      return;
    }
    setSavingMedication(true);
    const result = await addMedication({
      name: newMedName.trim(),
      dosage: newMedDosage.trim() || null,
      dosage_unit: null,
      frequency: null,
      time_of_day: [format(scheduledTime, 'HH:mm')],
      is_active: true,
      start_date: null,
      end_date: null,
    });
    setSavingMedication(false);
    if (!result) {
      Alert.alert('Could Not Save', 'Medication could not be created.');
      return;
    }
    setMedications((current) => [...current, result]);
    setSelectedMedicationId(result.id);
    setNewMedName('');
    setNewMedDosage('');
    successHaptic();
  }

  async function handleSubmit() {
    if (!selectedMedication) {
      Alert.alert('Select a Medication', 'Create or choose a medication first.');
      return;
    }
    setSubmitting(true);
    const result = await addMedicationLog({
      medication_name: selectedMedication.name,
      dosage: selectedMedication.dosage,
      dosage_unit: selectedMedication.dosage_unit,
      scheduled_time: format(scheduledTime, 'HH:mm'),
      taken_at: scheduledTime.toISOString(),
      was_taken: true,
      side_effects: sideEffects,
      notes: notes.trim() || null,
    });
    setSubmitting(false);

    if (!result) {
      Alert.alert('Could Not Save', 'Medication log could not be saved.');
      return;
    }

    successHaptic();
    setSuccess(true);
    setTimeout(() => {
      setSuccess(false);
      setSideEffects([]);
      setNotes('');
    }, 900);
  }

  if (success) return <SuccessState title="Medication logged" />;

  return (
    <>
      <FormCard>
        <FieldLabel text="Medication" />
        {loadingList ? (
          <ActivityIndicator color={C.primary} />
        ) : medications.length > 0 ? (
          <View style={{ gap: 8 }}>
            {medications.map((medication) => {
              const active = medication.id === selectedMedicationId;
              return (
                <PressScale key={medication.id} onPress={() => setSelectedMedicationId(medication.id)}>
                  <View style={{ padding: 13, borderRadius: 18, borderWidth: 1, borderColor: active ? C.primary : C.glassBorder, backgroundColor: active ? `${C.primary}14` : C.fillTertiary }}>
                    <Text style={{ fontSize: 15, fontWeight: '700', color: active ? C.primary : C.textPrimary, letterSpacing: -0.24 }}>
                      {medication.name}
                    </Text>
                    {medication.dosage ? <Text style={{ marginTop: 2, fontSize: 12, color: C.textSecondary }}>{medication.dosage}</Text> : null}
                  </View>
                </PressScale>
              );
            })}
          </View>
        ) : (
          <Text style={{ fontSize: 15, color: C.textSecondary }}>No medications yet. Add one below.</Text>
        )}
      </FormCard>

      <FormCard>
        <FieldLabel text="Add Medication" />
        <GlassTextInput value={newMedName} onChangeText={setNewMedName} placeholder="Medication name" />
        <View style={{ height: 10 }} />
        <GlassTextInput value={newMedDosage} onChangeText={setNewMedDosage} placeholder="Dose (optional)" />
        <View style={{ height: 10 }} />
        <DateTimePicker label="Preferred Time" value={scheduledTime} onChange={setScheduledTime} mode="time" />
        <SubmitButton label="Save Medication" loading={savingMedication} onPress={handleAddMedication} />
      </FormCard>

      <FormCard>
        <DateTimePicker label="Taken At" value={scheduledTime} onChange={setScheduledTime} mode="time" />
        <CardDivider />
        <TagSelector options={SIDE_EFFECT_OPTIONS} selected={sideEffects} onChange={setSideEffects} label="Side Effects" />
      </FormCard>

      <FormCard>
        <FieldLabel text="Notes" />
        <GlassTextInput value={notes} onChangeText={setNotes} placeholder="Optional notes..." multiline inputStyle={{ minHeight: 80, textAlignVertical: 'top' }} />
      </FormCard>

      <SubmitButton label="Log Medication" loading={submitting} onPress={handleSubmit} />
    </>
  );
}

function SleepForm() {
  const C = useColors();
  const { add } = useSleepLogs();
  const [bedtime, setBedtime] = useState(new Date());
  const [wakeTime, setWakeTime] = useState(new Date(Date.now() + 8 * 60 * 60 * 1000));
  const [quality, setQuality] = useState(3);
  const [nightWakings, setNightWakings] = useState('');
  const [bathroomWakings, setBathroomWakings] = useState('');
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  const durationMinutes = Math.max(0, Math.round((wakeTime.getTime() - bedtime.getTime()) / 60000));

  async function handleSubmit() {
    setLoading(true);
    const result = await add({
      date: format(bedtime, 'yyyy-MM-dd'),
      bedtime: bedtime.toISOString(),
      wake_time: wakeTime.toISOString(),
      duration_minutes: durationMinutes,
      quality,
      night_wakings: nightWakings ? Number(nightWakings) : 0,
      bathroom_wakings: bathroomWakings ? Number(bathroomWakings) : 0,
      notes: notes.trim() || null,
    });
    setLoading(false);

    if (!result) {
      Alert.alert('Could Not Save', 'Your sleep log could not be saved.');
      return;
    }

    successHaptic();
    setSuccess(true);
    setTimeout(() => {
      setSuccess(false);
      setBedtime(new Date());
      setWakeTime(new Date(Date.now() + 8 * 60 * 60 * 1000));
      setQuality(3);
      setNightWakings('');
      setBathroomWakings('');
      setNotes('');
    }, 900);
  }

  if (success) return <SuccessState title="Sleep logged" />;

  return (
    <>
      <FormCard>
        <DateTimePicker label="Bedtime" value={bedtime} onChange={setBedtime} mode="datetime" />
        <DateTimePicker label="Wake Time" value={wakeTime} onChange={setWakeTime} mode="datetime" />
        <Text style={{ fontSize: 14, color: C.textSecondary }}>
          Duration: {Math.floor(durationMinutes / 60)}h {durationMinutes % 60}m
        </Text>
      </FormCard>

      <FormCard>
        <SliderInput label="Sleep Quality" value={quality} min={1} max={5} onChange={setQuality} />
        <CardDivider />
        <FieldLabel text="Night Wakings" />
        <GlassTextInput value={nightWakings} onChangeText={setNightWakings} placeholder="0" keyboardType="number-pad" />
        <View style={{ height: 10 }} />
        <FieldLabel text="Bathroom Wakings" />
        <GlassTextInput value={bathroomWakings} onChangeText={setBathroomWakings} placeholder="0" keyboardType="number-pad" />
      </FormCard>

      <FormCard>
        <FieldLabel text="Notes" />
        <GlassTextInput value={notes} onChangeText={setNotes} placeholder="Optional notes..." multiline inputStyle={{ minHeight: 80, textAlignVertical: 'top' }} />
      </FormCard>

      <SubmitButton label="Log Sleep" loading={loading} onPress={handleSubmit} />
    </>
  );
}

function CycleForm() {
  const { add } = useMenstrualLogs();
  const [date, setDate] = useState(new Date());
  const [flow, setFlow] = useState<FlowLevel | null>(null);
  const [cycleDay, setCycleDay] = useState('');
  const [symptoms, setSymptoms] = useState<string[]>([]);
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  async function handleSubmit() {
    setLoading(true);
    const result = await add({
      date: format(date, 'yyyy-MM-dd'),
      cycle_day: cycleDay ? Number(cycleDay) : null,
      flow: flow ?? 'none',
      symptoms,
      notes: notes.trim() || null,
    });
    setLoading(false);

    if (!result) {
      Alert.alert('Could Not Save', 'Your cycle log could not be saved.');
      return;
    }

    successHaptic();
    setSuccess(true);
    setTimeout(() => {
      setSuccess(false);
      setDate(new Date());
      setFlow(null);
      setCycleDay('');
      setSymptoms([]);
      setNotes('');
    }, 900);
  }

  if (success) return <SuccessState title="Cycle logged" />;

  return (
    <>
      <FormCard>
        <DateTimePicker label="Date" value={date} onChange={setDate} mode="date" />
        <CardDivider />
        <FieldLabel text="Phase / Flow" />
        <ChipGroup options={FLOW_LEVELS} value={flow} onChange={setFlow} />
      </FormCard>

      <FormCard>
        <FieldLabel text="Cycle Day" />
        <GlassTextInput value={cycleDay} onChangeText={setCycleDay} placeholder="Optional" keyboardType="number-pad" />
        <CardDivider />
        <TagSelector options={MENSTRUAL_SYMPTOMS} selected={symptoms} onChange={setSymptoms} label="Symptoms" />
      </FormCard>

      <FormCard>
        <FieldLabel text="Notes" />
        <GlassTextInput value={notes} onChangeText={setNotes} placeholder="Optional notes..." multiline inputStyle={{ minHeight: 80, textAlignVertical: 'top' }} />
      </FormCard>

      <SubmitButton label="Log Cycle" loading={loading} onPress={handleSubmit} />
    </>
  );
}

const WEIGHT_UNITS = [
  { value: 'kg' as const, label: 'kg' },
  { value: 'lbs' as const, label: 'lbs' },
];

function WeightForm() {
  const C = useColors();
  const { add } = useWeightLogs();
  const [loggedAt, setLoggedAt] = useState(new Date());
  const [weight, setWeight] = useState('');
  const [unit, setUnit] = useState<'kg' | 'lbs'>('kg');
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  async function handleSubmit() {
    const parsed = Number(weight);
    if (!weight || Number.isNaN(parsed) || parsed <= 0) {
      Alert.alert('Invalid Weight', 'Enter a valid positive weight.');
      return;
    }

    const normalizedWeight = unit === 'lbs' ? parsed * 0.453592 : parsed;
    setLoading(true);
    const result = await add({
      logged_at: loggedAt.toISOString(),
      weight_kg: Number(normalizedWeight.toFixed(3)),
      notes: notes.trim() || null,
    });
    setLoading(false);

    if (!result) {
      Alert.alert('Could Not Save', 'Your weight log could not be saved.');
      return;
    }

    successHaptic();
    setSuccess(true);
    setTimeout(() => {
      setSuccess(false);
      setLoggedAt(new Date());
      setWeight('');
      setUnit('kg');
      setNotes('');
    }, 900);
  }

  if (success) return <SuccessState title="Weight logged" />;

  return (
    <>
      <FormCard>
        <DateTimePicker label="Logged At" value={loggedAt} onChange={setLoggedAt} mode="datetime" />
        <CardDivider />
        <FieldLabel text="Weight" />
        <GlassTextInput value={weight} onChangeText={setWeight} placeholder="0.0" keyboardType="decimal-pad" />
        <View style={{ height: 10 }} />
        <ChipGroup options={WEIGHT_UNITS} value={unit} onChange={setUnit} />
        {weight && !Number.isNaN(Number(weight)) && unit === 'lbs' ? (
          <Text style={{ marginTop: 10, fontSize: 13, color: C.textSecondary }}>
            ≈ {(Number(weight) * 0.453592).toFixed(1)} kg
          </Text>
        ) : null}
      </FormCard>

      <FormCard>
        <FieldLabel text="Notes" />
        <GlassTextInput value={notes} onChangeText={setNotes} placeholder="Optional notes..." multiline inputStyle={{ minHeight: 80, textAlignVertical: 'top' }} />
      </FormCard>

      <SubmitButton label="Log Weight" loading={loading} onPress={handleSubmit} />
    </>
  );
}

export default function LogScreen() {
  const C = useColors();
  const params = useLocalSearchParams<{ tab?: string }>();
  const initialTab = useMemo(() => {
    const candidate = params.tab as TabKey | undefined;
    return candidate && TABS.some((tab) => tab.key === candidate) ? candidate : 'food';
  }, [params.tab]);
  const [activeTab, setActiveTab] = useState<TabKey>(initialTab);

  useEffect(() => {
    if (params.tab && TABS.some((tab) => tab.key === params.tab)) {
      setActiveTab(params.tab as TabKey);
    }
  }, [params.tab]);

  function renderForm() {
    switch (activeTab) {
      case 'food':
        return <FoodForm />;
      case 'bowel':
        return <BowelForm />;
      case 'symptoms':
        return <SymptomsForm />;
      case 'meds':
        return <MedsForm />;
      case 'sleep':
        return <SleepForm />;
      case 'cycle':
        return <CycleForm />;
      case 'weight':
        return <WeightForm />;
      default:
        return null;
    }
  }

  return (
    <KeyboardAvoidingView
      style={{ flex: 1, backgroundColor: 'transparent' }}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      keyboardVerticalOffset={Platform.OS === 'ios' ? 88 : 0}
    >
      <View style={{ paddingHorizontal: 20, paddingTop: Platform.OS === 'ios' ? 58 : 20, paddingBottom: 14 }}>
        <Text style={{ fontSize: 32, fontWeight: '800', color: C.textPrimary, letterSpacing: -0.5 }}>
          Log
        </Text>
        <Text style={{ marginTop: 4, fontSize: 15, fontWeight: '500', color: C.textSecondary, letterSpacing: -0.24 }}>
          {format(new Date(), 'EEEE, MMMM d')}
        </Text>
      </View>

      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ paddingHorizontal: 16, paddingBottom: 6, gap: 8 }}>
        {TABS.map((tab) => {
          const active = activeTab === tab.key;
          return (
            <PressScale
              key={tab.key}
              onPress={() => {
                selectionHaptic();
                setActiveTab(tab.key);
              }}
            >
              <AppCard style={{ paddingHorizontal: 14, paddingVertical: 10, backgroundColor: active ? `${C.primary}1C` : undefined }} intensity={active ? 58 : 46}>
                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
                  <AppIcon symbol={tab.symbol} fallback={tab.fallback} size={16} tintColor={active ? C.primary : C.textSecondary} />
                  <Text style={{ fontSize: 13, fontWeight: active ? '700' : '500', color: active ? C.primary : C.textSecondary, letterSpacing: -0.08 }}>
                    {tab.label}
                  </Text>
                </View>
              </AppCard>
            </PressScale>
          );
        })}
      </ScrollView>

      <ScrollView
        style={{ flex: 1 }}
        contentContainerStyle={{ padding: 16, paddingBottom: 100 }}
        keyboardShouldPersistTaps="handled"
        showsVerticalScrollIndicator={false}
      >
        {renderForm()}
      </ScrollView>
    </KeyboardAvoidingView>
  );
}
