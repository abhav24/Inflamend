import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  TextInput,
  Switch,
  KeyboardAvoidingView,
  Platform,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { format } from 'date-fns';

import {
  useFoodLogs,
  useBowelLogs,
  useSymptomLogs,
  useMedications,
  useMedicationLogs,
  useSleepLogs,
  useMenstrualLogs,
  useWeightLogs,
} from '../../hooks/useLogs';

import {
  BRISTOL_TYPES,
  MEAL_TYPES,
  MOOD_OPTIONS,
  FLOW_LEVELS,
  PAIN_LOCATIONS,
  MENSTRUAL_SYMPTOMS,
  SIDE_EFFECT_OPTIONS,
} from '../../constants';
import { Colors } from '../../constants/colors';
import { Medication, MealType, BloodAmount, Mood, FlowLevel } from '../../types';
import { SliderInput } from '../../components/ui/SliderInput';
import { TagSelector } from '../../components/ui/TagSelector';

// ─── Types ───────────────────────────────────────────────────────────────────

type TabKey = 'food' | 'bowel' | 'symptoms' | 'meds' | 'sleep' | 'cycle' | 'weight';

const TABS: { key: TabKey; label: string; emoji: string }[] = [
  { key: 'food', label: 'Food', emoji: '🍽️' },
  { key: 'bowel', label: 'Bowel', emoji: '🚽' },
  { key: 'symptoms', label: 'Symptoms', emoji: '🩺' },
  { key: 'meds', label: 'Meds', emoji: '💊' },
  { key: 'sleep', label: 'Sleep', emoji: '😴' },
  { key: 'cycle', label: 'Cycle', emoji: '🌸' },
  { key: 'weight', label: 'Weight', emoji: '⚖️' },
];

// ─── Shared UI Helpers ───────────────────────────────────────────────────────

function SectionCard({ children, style }: { children: React.ReactNode; style?: object }) {
  return <View style={[sharedStyles.card, style]}>{children}</View>;
}

function FieldLabel({ text }: { text: string }) {
  return <Text style={sharedStyles.fieldLabel}>{text}</Text>;
}

function Divider() {
  return <View style={sharedStyles.divider} />;
}

function SuccessBanner() {
  return (
    <View style={sharedStyles.successBanner}>
      <Text style={sharedStyles.successCheck}>✓</Text>
      <Text style={sharedStyles.successText}>Logged!</Text>
    </View>
  );
}

function SubmitButton({
  label,
  onPress,
  loading,
}: {
  label: string;
  onPress: () => void;
  loading: boolean;
}) {
  return (
    <TouchableOpacity
      style={sharedStyles.submitBtn}
      onPress={onPress}
      disabled={loading}
      accessibilityRole="button"
      accessibilityLabel={label}
    >
      {loading ? (
        <ActivityIndicator color={Colors.white} />
      ) : (
        <Text style={sharedStyles.submitBtnText}>{label}</Text>
      )}
    </TouchableOpacity>
  );
}

function SegmentedButtons<T extends string>({
  options,
  value,
  onChange,
}: {
  options: readonly { value: T; label: string }[];
  value: T | null;
  onChange: (v: T) => void;
}) {
  return (
    <View style={sharedStyles.segmentedRow}>
      {options.map((opt) => {
        const active = value === opt.value;
        return (
          <TouchableOpacity
            key={opt.value}
            style={[sharedStyles.segmentBtn, active && sharedStyles.segmentBtnActive]}
            onPress={() => onChange(opt.value)}
            accessibilityRole="button"
            accessibilityState={{ selected: active }}
          >
            <Text
              style={[sharedStyles.segmentText, active && sharedStyles.segmentTextActive]}
              numberOfLines={1}
            >
              {opt.label}
            </Text>
          </TouchableOpacity>
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
  onChange: (v: boolean) => void;
}) {
  return (
    <View style={sharedStyles.switchRow}>
      <Text style={sharedStyles.switchLabel}>{label}</Text>
      <Switch
        value={value}
        onValueChange={onChange}
        trackColor={{ false: Colors.border, true: Colors.primary + '60' }}
        thumbColor={value ? Colors.primary : Colors.textMuted}
      />
    </View>
  );
}

function styledInput(extra?: object) {
  return [sharedStyles.textInput, extra ?? {}];
}

// ─── Food Form ───────────────────────────────────────────────────────────────

function FoodForm() {
  const { add } = useFoodLogs();
  const [mealType, setMealType] = useState<MealType | null>(null);
  const [description, setDescription] = useState('');
  const [waterMl, setWaterMl] = useState('');
  const [calories, setCalories] = useState('');
  const [protein, setProtein] = useState('');
  const [carbs, setCarbs] = useState('');
  const [fat, setFat] = useState('');
  const [fiber, setFiber] = useState('');
  const [isTrigger, setIsTrigger] = useState(false);
  const [isSafe, setIsSafe] = useState(false);
  const [notes, setNotes] = useState('');
  const [nutritionOpen, setNutritionOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  const resetForm = () => {
    setMealType(null);
    setDescription('');
    setWaterMl('');
    setCalories('');
    setProtein('');
    setCarbs('');
    setFat('');
    setFiber('');
    setIsTrigger(false);
    setIsSafe(false);
    setNotes('');
    setNutritionOpen(false);
  };

  const handleSubmit = async () => {
    if (!mealType) {
      Alert.alert('Missing Field', 'Please select a meal type.');
      return;
    }
    if (!description.trim()) {
      Alert.alert('Missing Field', 'Please describe what you ate.');
      return;
    }
    setLoading(true);
    await add({
      meal_type: mealType,
      description: description.trim(),
      logged_at: new Date().toISOString(),
      photo_url: null,
      calories: calories ? parseFloat(calories) : null,
      protein_g: protein ? parseFloat(protein) : null,
      carbs_g: carbs ? parseFloat(carbs) : null,
      fat_g: fat ? parseFloat(fat) : null,
      fiber_g: fiber ? parseFloat(fiber) : null,
      water_ml: waterMl ? parseFloat(waterMl) : null,
      is_trigger_food: isTrigger,
      is_safe_food: isSafe,
      notes: notes.trim() || null,
    });
    setLoading(false);
    setSuccess(true);
    setTimeout(() => {
      setSuccess(false);
      resetForm();
    }, 1500);
  };

  if (success) return <SuccessBanner />;

  return (
    <>
      <SectionCard>
        <FieldLabel text="Meal Type *" />
        <SegmentedButtons options={MEAL_TYPES} value={mealType} onChange={setMealType} />
      </SectionCard>

      <Divider />

      <SectionCard>
        <FieldLabel text="What did you eat? *" />
        <TextInput
          style={styledInput({ minHeight: 80 })}
          value={description}
          onChangeText={setDescription}
          placeholder="Describe your meal..."
          placeholderTextColor={Colors.placeholder}
          multiline
          textAlignVertical="top"
          accessibilityLabel="Food description"
        />
      </SectionCard>

      <SectionCard>
        <FieldLabel text="Water (ml)" />
        <TextInput
          style={styledInput()}
          value={waterMl}
          onChangeText={setWaterMl}
          placeholder="e.g. 250"
          placeholderTextColor={Colors.placeholder}
          keyboardType="numeric"
          accessibilityLabel="Water in ml"
        />
      </SectionCard>

      <SectionCard>
        <TouchableOpacity
          style={sharedStyles.collapsibleHeader}
          onPress={() => setNutritionOpen((v) => !v)}
          accessibilityRole="button"
          accessibilityState={{ expanded: nutritionOpen }}
        >
          <Text style={sharedStyles.collapsibleTitle}>Nutrition (optional)</Text>
          <Text style={sharedStyles.collapsibleChevron}>{nutritionOpen ? '▲' : '▼'}</Text>
        </TouchableOpacity>
        {nutritionOpen && (
          <View style={{ marginTop: 12 }}>
            {[
              { label: 'Calories', value: calories, set: setCalories },
              { label: 'Protein (g)', value: protein, set: setProtein },
              { label: 'Carbs (g)', value: carbs, set: setCarbs },
              { label: 'Fat (g)', value: fat, set: setFat },
              { label: 'Fiber (g)', value: fiber, set: setFiber },
            ].map(({ label, value, set }) => (
              <View key={label} style={{ marginBottom: 12 }}>
                <FieldLabel text={label} />
                <TextInput
                  style={styledInput()}
                  value={value}
                  onChangeText={set}
                  placeholder="0"
                  placeholderTextColor={Colors.placeholder}
                  keyboardType="numeric"
                  accessibilityLabel={label}
                />
              </View>
            ))}
          </View>
        )}
      </SectionCard>

      <Divider />

      <SectionCard>
        <SwitchRow label="Trigger food?" value={isTrigger} onChange={setIsTrigger} />
        <SwitchRow label="Safe food?" value={isSafe} onChange={setIsSafe} />
      </SectionCard>

      <SectionCard>
        <FieldLabel text="Notes (optional)" />
        <TextInput
          style={styledInput({ minHeight: 70 })}
          value={notes}
          onChangeText={setNotes}
          placeholder="Any additional notes..."
          placeholderTextColor={Colors.placeholder}
          multiline
          textAlignVertical="top"
          accessibilityLabel="Food notes"
        />
      </SectionCard>

      <SectionCard>
        <Text style={sharedStyles.timestampText}>
          Logged at: {format(new Date(), 'h:mm a, MMM d yyyy')}
        </Text>
      </SectionCard>

      <SubmitButton label="Log Food" onPress={handleSubmit} loading={loading} />
    </>
  );
}

// ─── Bowel Form ──────────────────────────────────────────────────────────────

const BLOOD_AMOUNT_OPTIONS: { value: BloodAmount; label: string }[] = [
  { value: 'none', label: 'None' },
  { value: 'trace', label: 'Trace' },
  { value: 'moderate', label: 'Moderate' },
  { value: 'significant', label: 'Significant' },
];

function BowelForm() {
  const { add } = useBowelLogs();
  const [bristolScale, setBristolScale] = useState<number | null>(null);
  const [urgency, setUrgency] = useState(1);
  const [bloodPresent, setBloodPresent] = useState(false);
  const [bloodAmount, setBloodAmount] = useState<BloodAmount>('none');
  const [mucusPresent, setMucusPresent] = useState(false);
  const [painDuring, setPainDuring] = useState(0);
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  const resetForm = () => {
    setBristolScale(null);
    setUrgency(1);
    setBloodPresent(false);
    setBloodAmount('none');
    setMucusPresent(false);
    setPainDuring(0);
    setNotes('');
  };

  const handleSubmit = async () => {
    if (!bristolScale) {
      Alert.alert('Missing Field', 'Please select a Bristol Scale type.');
      return;
    }
    setLoading(true);
    await add({
      logged_at: new Date().toISOString(),
      bristol_scale: bristolScale,
      urgency,
      blood_present: bloodPresent,
      blood_amount: bloodPresent ? bloodAmount : 'none',
      mucus_present: mucusPresent,
      pain_during: painDuring,
      notes: notes.trim() || null,
    });
    setLoading(false);
    setSuccess(true);
    setTimeout(() => {
      setSuccess(false);
      resetForm();
    }, 1500);
  };

  if (success) return <SuccessBanner />;

  return (
    <>
      <SectionCard>
        <FieldLabel text="Bristol Stool Scale *" />
        <Text style={sharedStyles.subLabel}>Select the type that best matches</Text>
        {BRISTOL_TYPES.map((bt) => {
          const selected = bristolScale === bt.scale;
          return (
            <TouchableOpacity
              key={bt.scale}
              style={[bristolStyles.card, selected && bristolStyles.cardSelected]}
              onPress={() => setBristolScale(bt.scale)}
              accessibilityRole="radio"
              accessibilityState={{ checked: selected }}
              accessibilityLabel={`Type ${bt.scale}: ${bt.name}`}
            >
              <View style={bristolStyles.scaleCircle}>
                <Text style={[bristolStyles.scaleNum, selected && bristolStyles.scaleNumSelected]}>
                  {bt.scale}
                </Text>
              </View>
              <Text style={bristolStyles.emoji}>{bt.emoji}</Text>
              <View style={bristolStyles.textBlock}>
                <Text style={[bristolStyles.name, selected && bristolStyles.nameSelected]}>
                  {bt.name}
                </Text>
                <Text style={bristolStyles.desc}>{bt.description}</Text>
              </View>
              {selected && <Text style={bristolStyles.checkmark}>✓</Text>}
            </TouchableOpacity>
          );
        })}
      </SectionCard>

      <Divider />

      <SectionCard>
        <SliderInput
          label="Urgency"
          value={urgency}
          min={1}
          max={5}
          onChange={setUrgency}
          accessibilityLabel="Urgency level 1 to 5"
        />
      </SectionCard>

      <SectionCard>
        <SwitchRow label="Blood present?" value={bloodPresent} onChange={setBloodPresent} />
        {bloodPresent && (
          <View style={{ marginTop: 12 }}>
            <FieldLabel text="Blood Amount" />
            <View style={sharedStyles.radioGroup}>
              {BLOOD_AMOUNT_OPTIONS.map((opt) => {
                const active = bloodAmount === opt.value;
                return (
                  <TouchableOpacity
                    key={opt.value}
                    style={[sharedStyles.radioOption, active && sharedStyles.radioOptionActive]}
                    onPress={() => setBloodAmount(opt.value)}
                    accessibilityRole="radio"
                    accessibilityState={{ checked: active }}
                  >
                    <View style={[sharedStyles.radioCircle, active && sharedStyles.radioCircleActive]}>
                      {active && <View style={sharedStyles.radioDot} />}
                    </View>
                    <Text style={[sharedStyles.radioLabel, active && sharedStyles.radioLabelActive]}>
                      {opt.label}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>
          </View>
        )}
        <Divider />
        <SwitchRow label="Mucus present?" value={mucusPresent} onChange={setMucusPresent} />
      </SectionCard>

      <SectionCard>
        <SliderInput
          label="Pain During (0–10)"
          value={painDuring}
          min={0}
          max={10}
          onChange={setPainDuring}
          accessibilityLabel="Pain during bowel movement 0 to 10"
        />
      </SectionCard>

      <SectionCard>
        <FieldLabel text="Notes (optional)" />
        <TextInput
          style={styledInput({ minHeight: 70 })}
          value={notes}
          onChangeText={setNotes}
          placeholder="Any additional notes..."
          placeholderTextColor={Colors.placeholder}
          multiline
          textAlignVertical="top"
          accessibilityLabel="Bowel notes"
        />
      </SectionCard>

      <SubmitButton label="Log Bowel Movement" onPress={handleSubmit} loading={loading} />
    </>
  );
}

const bristolStyles = StyleSheet.create({
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 12,
    borderRadius: 10,
    borderWidth: 1.5,
    borderColor: Colors.border,
    marginBottom: 8,
    backgroundColor: Colors.background,
  },
  cardSelected: {
    borderColor: Colors.primary,
    backgroundColor: Colors.primaryLight,
  },
  scaleCircle: {
    width: 30,
    height: 30,
    borderRadius: 15,
    backgroundColor: Colors.border,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 8,
  },
  scaleNum: {
    fontSize: 13,
    fontWeight: '700',
    color: Colors.textSecondary,
  },
  scaleNumSelected: {
    color: Colors.primary,
  },
  emoji: {
    fontSize: 22,
    marginRight: 10,
  },
  textBlock: {
    flex: 1,
  },
  name: {
    fontSize: 13,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  nameSelected: {
    color: Colors.primary,
  },
  desc: {
    fontSize: 11,
    color: Colors.textSecondary,
    marginTop: 1,
  },
  checkmark: {
    fontSize: 16,
    color: Colors.primary,
    fontWeight: '700',
    marginLeft: 6,
  },
});

// ─── Symptoms Form ───────────────────────────────────────────────────────────

function SymptomsForm() {
  const { add } = useSymptomLogs();
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

  const resetForm = () => {
    setPainLevel(0);
    setPainLocation([]);
    setFatigueLevel(0);
    setNauseaLevel(0);
    setBloatingLevel(0);
    setStressLevel(0);
    setMood(null);
    setIsFlare(false);
    setNotes('');
  };

  const handleSubmit = async () => {
    setLoading(true);
    await add({
      logged_at: new Date().toISOString(),
      pain_level: painLevel,
      pain_location: painLocation,
      fatigue_level: fatigueLevel,
      nausea_level: nauseaLevel,
      bloating_level: bloatingLevel,
      stress_level: stressLevel,
      mood: mood,
      is_flare: isFlare,
      notes: notes.trim() || null,
    });
    setLoading(false);
    setSuccess(true);
    setTimeout(() => {
      setSuccess(false);
      resetForm();
    }, 1500);
  };

  if (success) return <SuccessBanner />;

  return (
    <>
      <SectionCard>
        <SliderInput
          label="Pain Level"
          value={painLevel}
          min={0}
          max={10}
          onChange={setPainLevel}
          accessibilityLabel="Pain level 0 to 10"
        />
        <TagSelector
          options={PAIN_LOCATIONS}
          selected={painLocation}
          onChange={setPainLocation}
          label="Pain Location"
        />
      </SectionCard>

      <Divider />

      <SectionCard>
        <SliderInput
          label="Fatigue Level"
          value={fatigueLevel}
          min={0}
          max={10}
          onChange={setFatigueLevel}
          accessibilityLabel="Fatigue level 0 to 10"
        />
        <SliderInput
          label="Nausea Level"
          value={nauseaLevel}
          min={0}
          max={10}
          onChange={setNauseaLevel}
          accessibilityLabel="Nausea level 0 to 10"
        />
        <SliderInput
          label="Bloating Level"
          value={bloatingLevel}
          min={0}
          max={10}
          onChange={setBloatingLevel}
          accessibilityLabel="Bloating level 0 to 10"
        />
        <SliderInput
          label="Stress Level"
          value={stressLevel}
          min={0}
          max={10}
          onChange={setStressLevel}
          accessibilityLabel="Stress level 0 to 10"
        />
      </SectionCard>

      <Divider />

      <SectionCard>
        <FieldLabel text="Mood" />
        <View style={moodStyles.row}>
          {MOOD_OPTIONS.map((opt) => {
            const active = mood === opt.value;
            return (
              <TouchableOpacity
                key={opt.value}
                style={[moodStyles.btn, active && moodStyles.btnActive]}
                onPress={() => setMood(opt.value as Mood)}
                accessibilityRole="button"
                accessibilityState={{ selected: active }}
                accessibilityLabel={opt.label}
              >
                <Text style={moodStyles.emoji}>{opt.emoji}</Text>
                <Text style={[moodStyles.label, active && moodStyles.labelActive]}>
                  {opt.label}
                </Text>
              </TouchableOpacity>
            );
          })}
        </View>
      </SectionCard>

      <Divider />

      <SectionCard>
        <SwitchRow label="Currently in a flare?" value={isFlare} onChange={setIsFlare} />
      </SectionCard>

      <SectionCard>
        <FieldLabel text="Notes (optional)" />
        <TextInput
          style={styledInput({ minHeight: 70 })}
          value={notes}
          onChangeText={setNotes}
          placeholder="Any additional notes..."
          placeholderTextColor={Colors.placeholder}
          multiline
          textAlignVertical="top"
          accessibilityLabel="Symptom notes"
        />
      </SectionCard>

      <SubmitButton label="Log Symptoms" onPress={handleSubmit} loading={loading} />
    </>
  );
}

const moodStyles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 4,
  },
  btn: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: 10,
    borderRadius: 10,
    borderWidth: 1.5,
    borderColor: Colors.border,
    marginHorizontal: 3,
    backgroundColor: Colors.background,
  },
  btnActive: {
    borderColor: Colors.primary,
    backgroundColor: Colors.primaryLight,
  },
  emoji: {
    fontSize: 22,
    marginBottom: 4,
  },
  label: {
    fontSize: 10,
    color: Colors.textSecondary,
    fontWeight: '500',
  },
  labelActive: {
    color: Colors.primary,
    fontWeight: '700',
  },
});

// ─── Meds Form ───────────────────────────────────────────────────────────────

function MedsForm() {
  const { fetchActive, add: addMed } = useMedications();
  const { add: addMedLog } = useMedicationLogs();
  const [meds, setMeds] = useState<Medication[]>([]);
  const [checkedIds, setCheckedIds] = useState<Set<string>>(new Set());
  const [sideEffects, setSideEffects] = useState<string[]>([]);
  const [notes, setNotes] = useState('');
  const [loadingMeds, setLoadingMeds] = useState(true);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [showAddForm, setShowAddForm] = useState(false);
  const [newMedName, setNewMedName] = useState('');
  const [newMedDosage, setNewMedDosage] = useState('');
  const [addingMed, setAddingMed] = useState(false);

  useEffect(() => {
    fetchActive().then((data) => {
      setMeds(data);
      setLoadingMeds(false);
    });
  }, [fetchActive]);

  const toggleMed = (id: string) => {
    setCheckedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const resetForm = () => {
    setCheckedIds(new Set());
    setSideEffects([]);
    setNotes('');
    setShowAddForm(false);
    setNewMedName('');
    setNewMedDosage('');
  };

  const handleAddMed = async () => {
    if (!newMedName.trim()) {
      Alert.alert('Missing Field', 'Please enter a medication name.');
      return;
    }
    setAddingMed(true);
    const result = await addMed({
      name: newMedName.trim(),
      dosage: newMedDosage.trim() || null,
      dosage_unit: null,
      frequency: null,
      time_of_day: [],
      is_active: true,
      start_date: null,
      end_date: null,
    });
    if (result) {
      setMeds((prev) => [...prev, result]);
    }
    setNewMedName('');
    setNewMedDosage('');
    setShowAddForm(false);
    setAddingMed(false);
  };

  const handleSubmit = async () => {
    if (checkedIds.size === 0 && meds.length > 0) {
      Alert.alert('No Meds Selected', 'Please mark at least one medication as taken, or skip if none were taken today.');
    }
    setLoading(true);
    const now = new Date().toISOString();
    const promises = meds.map((med) =>
      addMedLog({
        medication_name: med.name,
        dosage: med.dosage,
        dosage_unit: med.dosage_unit,
        scheduled_time: null,
        taken_at: checkedIds.has(med.id) ? now : null,
        was_taken: checkedIds.has(med.id),
        side_effects: sideEffects,
        notes: notes.trim() || null,
      })
    );
    await Promise.all(promises);
    setLoading(false);
    setSuccess(true);
    setTimeout(() => {
      setSuccess(false);
      resetForm();
    }, 1500);
  };

  if (success) return <SuccessBanner />;

  return (
    <>
      <SectionCard>
        <FieldLabel text="Today's Medications" />
        {loadingMeds ? (
          <ActivityIndicator color={Colors.primary} style={{ marginVertical: 16 }} />
        ) : meds.length === 0 ? (
          <Text style={sharedStyles.emptyText}>No active medications. Add one below.</Text>
        ) : (
          meds.map((med) => {
            const checked = checkedIds.has(med.id);
            return (
              <TouchableOpacity
                key={med.id}
                style={[medStyles.medCard, checked && medStyles.medCardChecked]}
                onPress={() => toggleMed(med.id)}
                accessibilityRole="checkbox"
                accessibilityState={{ checked }}
                accessibilityLabel={`${med.name}${med.dosage ? ', ' + med.dosage : ''}`}
              >
                <View style={[medStyles.checkbox, checked && medStyles.checkboxChecked]}>
                  {checked && <Text style={medStyles.checkmark}>✓</Text>}
                </View>
                <View style={medStyles.medInfo}>
                  <Text style={medStyles.medName}>{med.name}</Text>
                  {med.dosage ? (
                    <Text style={medStyles.medDosage}>{med.dosage}{med.dosage_unit ? ' ' + med.dosage_unit : ''}</Text>
                  ) : null}
                </View>
              </TouchableOpacity>
            );
          })
        )}
        <TouchableOpacity
          style={medStyles.addBtn}
          onPress={() => setShowAddForm((v) => !v)}
          accessibilityRole="button"
        >
          <Text style={medStyles.addBtnText}>
            {showAddForm ? '− Cancel' : '+ Add New Medication'}
          </Text>
        </TouchableOpacity>
        {showAddForm && (
          <View style={medStyles.addForm}>
            <FieldLabel text="Medication Name *" />
            <TextInput
              style={styledInput()}
              value={newMedName}
              onChangeText={setNewMedName}
              placeholder="e.g. Mesalamine"
              placeholderTextColor={Colors.placeholder}
              accessibilityLabel="New medication name"
            />
            <FieldLabel text="Dosage (optional)" />
            <TextInput
              style={styledInput()}
              value={newMedDosage}
              onChangeText={setNewMedDosage}
              placeholder="e.g. 400mg"
              placeholderTextColor={Colors.placeholder}
              accessibilityLabel="New medication dosage"
            />
            <TouchableOpacity
              style={medStyles.saveBtn}
              onPress={handleAddMed}
              disabled={addingMed}
              accessibilityRole="button"
            >
              {addingMed ? (
                <ActivityIndicator color={Colors.white} />
              ) : (
                <Text style={medStyles.saveBtnText}>Save Medication</Text>
              )}
            </TouchableOpacity>
          </View>
        )}
      </SectionCard>

      <Divider />

      <SectionCard>
        <TagSelector
          options={SIDE_EFFECT_OPTIONS}
          selected={sideEffects}
          onChange={setSideEffects}
          label="Side Effects (optional)"
        />
      </SectionCard>

      <SectionCard>
        <FieldLabel text="Notes (optional)" />
        <TextInput
          style={styledInput({ minHeight: 70 })}
          value={notes}
          onChangeText={setNotes}
          placeholder="Any notes about your medications..."
          placeholderTextColor={Colors.placeholder}
          multiline
          textAlignVertical="top"
          accessibilityLabel="Medication notes"
        />
      </SectionCard>

      <SubmitButton label="Log Medications" onPress={handleSubmit} loading={loading} />
    </>
  );
}

const medStyles = StyleSheet.create({
  medCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 12,
    borderRadius: 10,
    borderWidth: 1.5,
    borderColor: Colors.border,
    marginBottom: 8,
    backgroundColor: Colors.background,
  },
  medCardChecked: {
    borderColor: Colors.secondary,
    backgroundColor: Colors.secondary + '10',
  },
  checkbox: {
    width: 24,
    height: 24,
    borderRadius: 6,
    borderWidth: 2,
    borderColor: Colors.border,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  checkboxChecked: {
    backgroundColor: Colors.secondary,
    borderColor: Colors.secondary,
  },
  checkmark: {
    fontSize: 14,
    color: Colors.white,
    fontWeight: '700',
  },
  medInfo: {
    flex: 1,
  },
  medName: {
    fontSize: 14,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  medDosage: {
    fontSize: 12,
    color: Colors.textSecondary,
    marginTop: 2,
  },
  addBtn: {
    marginTop: 8,
    paddingVertical: 10,
    alignItems: 'center',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: Colors.primary,
    borderStyle: 'dashed',
  },
  addBtnText: {
    fontSize: 14,
    color: Colors.primary,
    fontWeight: '600',
  },
  addForm: {
    marginTop: 12,
    padding: 12,
    backgroundColor: Colors.background,
    borderRadius: 10,
  },
  saveBtn: {
    backgroundColor: Colors.primary,
    borderRadius: 8,
    paddingVertical: 10,
    alignItems: 'center',
    marginTop: 4,
  },
  saveBtnText: {
    color: Colors.white,
    fontWeight: '700',
    fontSize: 14,
  },
});

// ─── Sleep Form ──────────────────────────────────────────────────────────────

function SleepForm() {
  const { add } = useSleepLogs();
  const [quality, setQuality] = useState<number>(0);
  const [nightWakings, setNightWakings] = useState('');
  const [bathroomWakings, setBathroomWakings] = useState('');
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  const resetForm = () => {
    setQuality(0);
    setNightWakings('');
    setBathroomWakings('');
    setNotes('');
  };

  const handleSubmit = async () => {
    setLoading(true);
    const today = format(new Date(), 'yyyy-MM-dd');
    await add({
      date: today,
      bedtime: new Date().toISOString(),
      wake_time: new Date().toISOString(),
      duration_minutes: null,
      quality: quality || 3,
      night_wakings: nightWakings ? parseInt(nightWakings, 10) : 0,
      bathroom_wakings: bathroomWakings ? parseInt(bathroomWakings, 10) : 0,
      notes: notes.trim() || null,
    });
    setLoading(false);
    setSuccess(true);
    setTimeout(() => {
      setSuccess(false);
      resetForm();
    }, 1500);
  };

  if (success) return <SuccessBanner />;

  return (
    <>
      <SectionCard>
        <FieldLabel text="Sleep Quality" />
        <View style={sleepStyles.starsRow}>
          {[1, 2, 3, 4, 5].map((star) => (
            <TouchableOpacity
              key={star}
              onPress={() => setQuality(star)}
              accessibilityRole="button"
              accessibilityLabel={`${star} star${star !== 1 ? 's' : ''}`}
              accessibilityState={{ selected: quality >= star }}
              style={sleepStyles.starBtn}
            >
              <Text style={[sleepStyles.star, quality >= star && sleepStyles.starActive]}>
                ★
              </Text>
            </TouchableOpacity>
          ))}
        </View>
        {quality > 0 && (
          <Text style={sleepStyles.qualityLabel}>
            {['', 'Poor', 'Fair', 'Good', 'Great', 'Excellent'][quality]}
          </Text>
        )}
      </SectionCard>

      <Divider />

      <SectionCard>
        <Text style={sharedStyles.noteText}>
          Duration will be calculated from bedtime / wake time.
        </Text>
      </SectionCard>

      <SectionCard>
        <FieldLabel text="Night Wakings" />
        <TextInput
          style={styledInput()}
          value={nightWakings}
          onChangeText={setNightWakings}
          placeholder="0"
          placeholderTextColor={Colors.placeholder}
          keyboardType="number-pad"
          accessibilityLabel="Number of night wakings"
        />
        <FieldLabel text="Bathroom Wakings" />
        <TextInput
          style={styledInput()}
          value={bathroomWakings}
          onChangeText={setBathroomWakings}
          placeholder="0"
          placeholderTextColor={Colors.placeholder}
          keyboardType="number-pad"
          accessibilityLabel="Number of bathroom wakings"
        />
      </SectionCard>

      <SectionCard>
        <FieldLabel text="Notes (optional)" />
        <TextInput
          style={styledInput({ minHeight: 70 })}
          value={notes}
          onChangeText={setNotes}
          placeholder="Any notes about your sleep..."
          placeholderTextColor={Colors.placeholder}
          multiline
          textAlignVertical="top"
          accessibilityLabel="Sleep notes"
        />
      </SectionCard>

      <SubmitButton label="Log Sleep" onPress={handleSubmit} loading={loading} />
    </>
  );
}

const sleepStyles = StyleSheet.create({
  starsRow: {
    flexDirection: 'row',
    marginTop: 8,
    gap: 8,
  },
  starBtn: {
    padding: 4,
  },
  star: {
    fontSize: 32,
    color: Colors.border,
  },
  starActive: {
    color: Colors.warning,
  },
  qualityLabel: {
    marginTop: 6,
    fontSize: 14,
    color: Colors.textSecondary,
    fontWeight: '500',
  },
});

// ─── Cycle Form ──────────────────────────────────────────────────────────────

function CycleForm() {
  const { add } = useMenstrualLogs();
  const [flow, setFlow] = useState<FlowLevel | null>(null);
  const [cycleDay, setCycleDay] = useState('');
  const [symptoms, setSymptoms] = useState<string[]>([]);
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  const resetForm = () => {
    setFlow(null);
    setCycleDay('');
    setSymptoms([]);
    setNotes('');
  };

  const handleSubmit = async () => {
    setLoading(true);
    const today = format(new Date(), 'yyyy-MM-dd');
    await add({
      date: today,
      cycle_day: cycleDay ? parseInt(cycleDay, 10) : null,
      flow: flow ?? 'none',
      symptoms,
      notes: notes.trim() || null,
    });
    setLoading(false);
    setSuccess(true);
    setTimeout(() => {
      setSuccess(false);
      resetForm();
    }, 1500);
  };

  if (success) return <SuccessBanner />;

  return (
    <>
      <SectionCard>
        <FieldLabel text="Flow Level" />
        <SegmentedButtons options={FLOW_LEVELS} value={flow} onChange={setFlow} />
      </SectionCard>

      <SectionCard>
        <FieldLabel text="Cycle Day (optional)" />
        <TextInput
          style={styledInput()}
          value={cycleDay}
          onChangeText={setCycleDay}
          placeholder="e.g. 14"
          placeholderTextColor={Colors.placeholder}
          keyboardType="number-pad"
          accessibilityLabel="Cycle day"
        />
      </SectionCard>

      <Divider />

      <SectionCard>
        <TagSelector
          options={MENSTRUAL_SYMPTOMS}
          selected={symptoms}
          onChange={setSymptoms}
          label="Symptoms"
        />
      </SectionCard>

      <SectionCard>
        <FieldLabel text="Notes (optional)" />
        <TextInput
          style={styledInput({ minHeight: 70 })}
          value={notes}
          onChangeText={setNotes}
          placeholder="Any additional notes..."
          placeholderTextColor={Colors.placeholder}
          multiline
          textAlignVertical="top"
          accessibilityLabel="Cycle notes"
        />
      </SectionCard>

      <SubmitButton label="Log Cycle" onPress={handleSubmit} loading={loading} />
    </>
  );
}

// ─── Weight Form ─────────────────────────────────────────────────────────────

const WEIGHT_UNITS = [
  { value: 'kg' as const, label: 'kg' },
  { value: 'lbs' as const, label: 'lbs' },
];

function WeightForm() {
  const { add } = useWeightLogs();
  const [weight, setWeight] = useState('');
  const [unit, setUnit] = useState<'kg' | 'lbs'>('kg');
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  const resetForm = () => {
    setWeight('');
    setUnit('kg');
    setNotes('');
  };

  const handleSubmit = async () => {
    const parsed = parseFloat(weight);
    if (!weight || isNaN(parsed) || parsed <= 0) {
      Alert.alert('Invalid Weight', 'Please enter a valid positive weight.');
      return;
    }
    const weightKg = unit === 'lbs' ? parsed * 0.453592 : parsed;
    setLoading(true);
    await add({
      logged_at: new Date().toISOString(),
      weight_kg: parseFloat(weightKg.toFixed(3)),
      notes: notes.trim() || null,
    });
    setLoading(false);
    setSuccess(true);
    setTimeout(() => {
      setSuccess(false);
      resetForm();
    }, 1500);
  };

  if (success) return <SuccessBanner />;

  return (
    <>
      <SectionCard>
        <FieldLabel text="Weight" />
        <View style={weightStyles.row}>
          <TextInput
            style={[styledInput(), { flex: 1, marginRight: 10 }]}
            value={weight}
            onChangeText={setWeight}
            placeholder="0.0"
            placeholderTextColor={Colors.placeholder}
            keyboardType="decimal-pad"
            accessibilityLabel="Weight value"
          />
          <SegmentedButtons options={WEIGHT_UNITS} value={unit} onChange={setUnit} />
        </View>
        {weight && !isNaN(parseFloat(weight)) && parseFloat(weight) > 0 && unit === 'lbs' && (
          <Text style={weightStyles.convertedText}>
            ≈ {(parseFloat(weight) * 0.453592).toFixed(1)} kg
          </Text>
        )}
      </SectionCard>

      <SectionCard>
        <FieldLabel text="Notes (optional)" />
        <TextInput
          style={styledInput({ minHeight: 70 })}
          value={notes}
          onChangeText={setNotes}
          placeholder="Any notes..."
          placeholderTextColor={Colors.placeholder}
          multiline
          textAlignVertical="top"
          accessibilityLabel="Weight notes"
        />
      </SectionCard>

      <SubmitButton label="Log Weight" onPress={handleSubmit} loading={loading} />
    </>
  );
}

const weightStyles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  convertedText: {
    marginTop: 6,
    fontSize: 12,
    color: Colors.textSecondary,
  },
});

// ─── Main Log Screen ─────────────────────────────────────────────────────────

export default function LogScreen() {
  const params = useLocalSearchParams<{ tab?: string }>();
  const initialTab = (params.tab as TabKey) ?? 'food';
  const validTab = TABS.some((t) => t.key === initialTab) ? initialTab : 'food';
  const [activeTab, setActiveTab] = useState<TabKey>(validTab);

  // Update active tab if params change (e.g. deep link from Quick Log buttons)
  useEffect(() => {
    if (params.tab && TABS.some((t) => t.key === params.tab)) {
      setActiveTab(params.tab as TabKey);
    }
  }, [params.tab]);

  const renderForm = () => {
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
  };

  return (
    <KeyboardAvoidingView
      style={styles.flex}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      keyboardVerticalOffset={Platform.OS === 'ios' ? 88 : 0}
    >
      {/* Screen Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Log</Text>
        <Text style={styles.headerDate}>{format(new Date(), 'EEEE, MMMM d')}</Text>
      </View>

      {/* Tab Bar */}
      <View style={styles.tabBarWrapper}>
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.tabBar}
        >
          {TABS.map((tab) => {
            const active = activeTab === tab.key;
            return (
              <TouchableOpacity
                key={tab.key}
                style={[styles.tabBtn, active && styles.tabBtnActive]}
                onPress={() => setActiveTab(tab.key)}
                accessibilityRole="tab"
                accessibilityState={{ selected: active }}
                accessibilityLabel={tab.label}
              >
                <Text style={styles.tabEmoji}>{tab.emoji}</Text>
                <Text style={[styles.tabLabel, active && styles.tabLabelActive]}>
                  {tab.label}
                </Text>
              </TouchableOpacity>
            );
          })}
        </ScrollView>
      </View>

      {/* Form Content */}
      <ScrollView
        style={styles.flex}
        contentContainerStyle={styles.formContent}
        keyboardShouldPersistTaps="handled"
        showsVerticalScrollIndicator={false}
      >
        {renderForm()}
        <View style={{ height: 40 }} />
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

// ─── Shared Styles ───────────────────────────────────────────────────────────

const sharedStyles = StyleSheet.create({
  card: {
    backgroundColor: Colors.white,
    borderRadius: 14,
    padding: 16,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOpacity: 0.05,
    shadowRadius: 4,
    shadowOffset: { width: 0, height: 2 },
    elevation: 2,
  },
  fieldLabel: {
    fontSize: 14,
    fontWeight: '700',
    color: Colors.textPrimary,
    marginBottom: 8,
  },
  subLabel: {
    fontSize: 12,
    color: Colors.textSecondary,
    marginBottom: 10,
    marginTop: -4,
  },
  divider: {
    height: 1,
    backgroundColor: Colors.border,
    marginVertical: 4,
    marginBottom: 12,
  },
  textInput: {
    borderWidth: 1.5,
    borderColor: Colors.border,
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 15,
    color: Colors.textPrimary,
    backgroundColor: Colors.background,
    marginBottom: 4,
  },
  segmentedRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
  },
  segmentBtn: {
    paddingVertical: 7,
    paddingHorizontal: 12,
    borderRadius: 20,
    borderWidth: 1.5,
    borderColor: Colors.border,
    backgroundColor: Colors.background,
  },
  segmentBtnActive: {
    backgroundColor: Colors.primary,
    borderColor: Colors.primary,
  },
  segmentText: {
    fontSize: 13,
    fontWeight: '500',
    color: Colors.textSecondary,
  },
  segmentTextActive: {
    color: Colors.white,
    fontWeight: '700',
  },
  switchRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 4,
    marginBottom: 4,
  },
  switchLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: Colors.textPrimary,
    flex: 1,
  },
  submitBtn: {
    backgroundColor: Colors.primary,
    borderRadius: 14,
    paddingVertical: 16,
    alignItems: 'center',
    marginBottom: 16,
    shadowColor: Colors.primary,
    shadowOpacity: 0.3,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 3 },
    elevation: 4,
  },
  submitBtnText: {
    color: Colors.white,
    fontSize: 16,
    fontWeight: '700',
  },
  successBanner: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 60,
  },
  successCheck: {
    fontSize: 56,
    color: Colors.secondary,
    marginBottom: 12,
  },
  successText: {
    fontSize: 24,
    fontWeight: '700',
    color: Colors.secondary,
  },
  collapsibleHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  collapsibleTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  collapsibleChevron: {
    fontSize: 12,
    color: Colors.textSecondary,
  },
  radioGroup: {
    gap: 8,
  },
  radioOption: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 10,
    borderRadius: 8,
    borderWidth: 1.5,
    borderColor: Colors.border,
    backgroundColor: Colors.background,
  },
  radioOptionActive: {
    borderColor: Colors.primary,
    backgroundColor: Colors.primaryLight,
  },
  radioCircle: {
    width: 20,
    height: 20,
    borderRadius: 10,
    borderWidth: 2,
    borderColor: Colors.border,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 10,
  },
  radioCircleActive: {
    borderColor: Colors.primary,
  },
  radioDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: Colors.primary,
  },
  radioLabel: {
    fontSize: 14,
    fontWeight: '500',
    color: Colors.textSecondary,
  },
  radioLabelActive: {
    color: Colors.primary,
    fontWeight: '600',
  },
  timestampText: {
    fontSize: 13,
    color: Colors.textSecondary,
  },
  noteText: {
    fontSize: 13,
    color: Colors.textSecondary,
    fontStyle: 'italic',
  },
  emptyText: {
    fontSize: 14,
    color: Colors.textMuted,
    textAlign: 'center',
    paddingVertical: 12,
  },
});

const styles = StyleSheet.create({
  flex: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  header: {
    paddingHorizontal: 20,
    paddingTop: Platform.OS === 'ios' ? 56 : 20,
    paddingBottom: 12,
    backgroundColor: Colors.white,
    borderBottomWidth: 1,
    borderBottomColor: Colors.border,
  },
  headerTitle: {
    fontSize: 22,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  headerDate: {
    fontSize: 12,
    color: Colors.textSecondary,
    marginTop: 2,
  },
  tabBarWrapper: {
    backgroundColor: Colors.white,
    borderBottomWidth: 1,
    borderBottomColor: Colors.border,
  },
  tabBar: {
    paddingHorizontal: 12,
    paddingVertical: 10,
    gap: 6,
  },
  tabBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 7,
    paddingHorizontal: 14,
    borderRadius: 20,
    borderWidth: 1.5,
    borderColor: Colors.border,
    backgroundColor: Colors.background,
    gap: 5,
  },
  tabBtnActive: {
    backgroundColor: Colors.primary,
    borderColor: Colors.primary,
  },
  tabEmoji: {
    fontSize: 15,
  },
  tabLabel: {
    fontSize: 13,
    fontWeight: '600',
    color: Colors.textSecondary,
  },
  tabLabelActive: {
    color: Colors.white,
  },
  formContent: {
    padding: 16,
    paddingBottom: 60,
  },
});
