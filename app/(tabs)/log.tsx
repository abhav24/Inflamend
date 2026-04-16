import React, { useState, useEffect } from 'react';
import {
  View, Text, ScrollView, TouchableOpacity,
  TextInput, Switch, KeyboardAvoidingView,
  Platform, ActivityIndicator, Alert,
} from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { format } from 'date-fns';
import { Ionicons } from '@expo/vector-icons';

import {
  useFoodLogs, useBowelLogs, useSymptomLogs,
  useMedications, useMedicationLogs,
  useSleepLogs, useMenstrualLogs, useWeightLogs,
} from '../../hooks/useLogs';

import {
  BRISTOL_TYPES, MEAL_TYPES, MOOD_OPTIONS,
  FLOW_LEVELS, PAIN_LOCATIONS, MENSTRUAL_SYMPTOMS, SIDE_EFFECT_OPTIONS,
} from '../../constants';
import { useColors } from '../../constants/colors';
import { Medication, MealType, BloodAmount, Mood, FlowLevel } from '../../types';
import { SliderInput } from '../../components/ui/SliderInput';
import { TagSelector } from '../../components/ui/TagSelector';

// ─── Tab definitions ──────────────────────────────────────────────────────────

type TabKey = 'food' | 'bowel' | 'symptoms' | 'meds' | 'sleep' | 'cycle' | 'weight';

const TABS: { key: TabKey; label: string }[] = [
  { key: 'food',     label: 'Food'     },
  { key: 'bowel',    label: 'Bowel'    },
  { key: 'symptoms', label: 'Symptoms' },
  { key: 'meds',     label: 'Meds'     },
  { key: 'sleep',    label: 'Sleep'    },
  { key: 'cycle',    label: 'Cycle'    },
  { key: 'weight',   label: 'Weight'   },
];

// ─── Shared primitives ────────────────────────────────────────────────────────

function Card({ children, style }: { children: React.ReactNode; style?: object }) {
  const C = useColors();
  return (
    <View style={[{
      backgroundColor: C.surface, borderRadius: 16, padding: 16, marginBottom: 12,
      shadowColor: '#000',
      shadowOpacity: C.background === '#000000' ? 0 : 0.05,
      shadowRadius: 8, shadowOffset: { width: 0, height: 2 }, elevation: 2,
    }, style]}>
      {children}
    </View>
  );
}

function FieldLabel({ text }: { text: string }) {
  const C = useColors();
  return (
    <Text style={{
      fontSize: 11, fontWeight: '700', color: C.textMuted,
      textTransform: 'uppercase', letterSpacing: 0.5, marginBottom: 10,
    }}>
      {text}
    </Text>
  );
}

function CardDivider() {
  const C = useColors();
  return <View style={{ height: 0.5, backgroundColor: C.separator, marginVertical: 10 }} />;
}

function SuccessBanner() {
  const C = useColors();
  return (
    <View style={{ alignItems: 'center', justifyContent: 'center', paddingVertical: 64 }}>
      <View style={{
        width: 72, height: 72, borderRadius: 36,
        backgroundColor: C.success + '18',
        alignItems: 'center', justifyContent: 'center', marginBottom: 16,
      }}>
        <Ionicons name="checkmark" size={36} color={C.success} />
      </View>
      <Text style={{ fontSize: 22, fontWeight: '700', color: C.success }}>Logged!</Text>
    </View>
  );
}

function SubmitButton({ label, onPress, loading }: { label: string; onPress: () => void; loading: boolean }) {
  const C = useColors();
  return (
    <TouchableOpacity
      style={{
        backgroundColor: C.primary, borderRadius: 14, paddingVertical: 16,
        alignItems: 'center', marginBottom: 16,
        shadowColor: C.primary, shadowOpacity: 0.3, shadowRadius: 8,
        shadowOffset: { width: 0, height: 3 }, elevation: 4,
      }}
      onPress={onPress}
      disabled={loading}
    >
      {loading
        ? <ActivityIndicator color="#FFFFFF" />
        : <Text style={{ color: '#FFFFFF', fontSize: 16, fontWeight: '700' }}>{label}</Text>}
    </TouchableOpacity>
  );
}

function SegmentedButtons<T extends string>({
  options, value, onChange,
}: {
  options: readonly { value: T; label: string }[];
  value: T | null;
  onChange: (v: T) => void;
}) {
  const C = useColors();
  return (
    <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 6 }}>
      {options.map((opt) => {
        const active = value === opt.value;
        return (
          <TouchableOpacity
            key={opt.value}
            style={{
              paddingVertical: 8, paddingHorizontal: 14, borderRadius: 20,
              backgroundColor: active ? C.primary : C.background,
              borderWidth: 1.5, borderColor: active ? C.primary : C.border,
            }}
            onPress={() => onChange(opt.value)}
          >
            <Text style={{
              fontSize: 13, fontWeight: active ? '700' : '500',
              color: active ? '#FFFFFF' : C.textSecondary,
            }} numberOfLines={1}>
              {opt.label}
            </Text>
          </TouchableOpacity>
        );
      })}
    </View>
  );
}

function SwitchRow({ label, value, onChange }: { label: string; value: boolean; onChange: (v: boolean) => void }) {
  const C = useColors();
  return (
    <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingVertical: 4, marginBottom: 4 }}>
      <Text style={{ fontSize: 15, fontWeight: '500', color: C.textPrimary, flex: 1 }}>{label}</Text>
      <Switch
        value={value} onValueChange={onChange}
        trackColor={{ false: C.border, true: C.primary + '80' }}
        thumbColor={value ? C.primary : C.textMuted}
      />
    </View>
  );
}

function StyledInput({ value, onChangeText, placeholder, multiline, minHeight, keyboardType, accessibilityLabel }: {
  value: string; onChangeText: (v: string) => void; placeholder: string;
  multiline?: boolean; minHeight?: number; keyboardType?: any; accessibilityLabel?: string;
}) {
  const C = useColors();
  return (
    <TextInput
      style={{
        borderWidth: 1.5, borderColor: C.border, borderRadius: 12,
        paddingHorizontal: 14, paddingVertical: 10,
        fontSize: 15, color: C.textPrimary, backgroundColor: C.background,
        marginBottom: 4, ...(minHeight ? { minHeight, textAlignVertical: 'top' as const } : {}),
      }}
      value={value} onChangeText={onChangeText}
      placeholder={placeholder} placeholderTextColor={C.placeholder}
      multiline={multiline} keyboardType={keyboardType}
      accessibilityLabel={accessibilityLabel}
    />
  );
}

// ─── Food Form ────────────────────────────────────────────────────────────────

function FoodForm() {
  const C = useColors();
  const { add } = useFoodLogs();
  const [mealType, setMealType]         = useState<MealType | null>(null);
  const [description, setDescription]   = useState('');
  const [waterMl, setWaterMl]           = useState('');
  const [calories, setCalories]         = useState('');
  const [protein, setProtein]           = useState('');
  const [carbs, setCarbs]               = useState('');
  const [fat, setFat]                   = useState('');
  const [fiber, setFiber]               = useState('');
  const [isTrigger, setIsTrigger]       = useState(false);
  const [isSafe, setIsSafe]             = useState(false);
  const [notes, setNotes]               = useState('');
  const [nutritionOpen, setNutritionOpen] = useState(false);
  const [loading, setLoading]           = useState(false);
  const [success, setSuccess]           = useState(false);

  const reset = () => {
    setMealType(null); setDescription(''); setWaterMl('');
    setCalories(''); setProtein(''); setCarbs(''); setFat(''); setFiber('');
    setIsTrigger(false); setIsSafe(false); setNotes(''); setNutritionOpen(false);
  };

  const handleSubmit = async () => {
    if (!mealType) { Alert.alert('Missing Field', 'Please select a meal type.'); return; }
    if (!description.trim()) { Alert.alert('Missing Field', 'Please describe what you ate.'); return; }
    setLoading(true);
    await add({
      meal_type: mealType, description: description.trim(),
      logged_at: new Date().toISOString(), photo_url: null,
      calories: calories ? parseFloat(calories) : null,
      protein_g: protein ? parseFloat(protein) : null,
      carbs_g: carbs ? parseFloat(carbs) : null,
      fat_g: fat ? parseFloat(fat) : null,
      fiber_g: fiber ? parseFloat(fiber) : null,
      water_ml: waterMl ? parseFloat(waterMl) : null,
      is_trigger_food: isTrigger, is_safe_food: isSafe,
      notes: notes.trim() || null,
    });
    setLoading(false); setSuccess(true);
    setTimeout(() => { setSuccess(false); reset(); }, 1500);
  };

  if (success) return <SuccessBanner />;

  return (
    <>
      <Card>
        <FieldLabel text="Meal Type" />
        <SegmentedButtons options={MEAL_TYPES} value={mealType} onChange={setMealType} />
      </Card>

      <Card>
        <FieldLabel text="What did you eat?" />
        <StyledInput value={description} onChangeText={setDescription}
          placeholder="Describe your meal..." multiline minHeight={80}
          accessibilityLabel="Food description" />
      </Card>

      <Card>
        <FieldLabel text="Water (ml)" />
        <StyledInput value={waterMl} onChangeText={setWaterMl}
          placeholder="e.g. 250" keyboardType="numeric" accessibilityLabel="Water in ml" />
      </Card>

      <Card>
        <TouchableOpacity
          style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}
          onPress={() => setNutritionOpen(v => !v)}
        >
          <Text style={{ fontSize: 15, fontWeight: '600', color: C.textPrimary }}>Nutrition (optional)</Text>
          <Ionicons name={nutritionOpen ? 'chevron-up' : 'chevron-down'} size={16} color={C.textMuted} />
        </TouchableOpacity>
        {nutritionOpen && (
          <View style={{ marginTop: 12, gap: 8 }}>
            {[
              { label: 'Calories', value: calories, set: setCalories },
              { label: 'Protein (g)', value: protein, set: setProtein },
              { label: 'Carbs (g)', value: carbs, set: setCarbs },
              { label: 'Fat (g)', value: fat, set: setFat },
              { label: 'Fiber (g)', value: fiber, set: setFiber },
            ].map(({ label, value, set }) => (
              <View key={label}>
                <FieldLabel text={label} />
                <StyledInput value={value} onChangeText={set}
                  placeholder="0" keyboardType="numeric" accessibilityLabel={label} />
              </View>
            ))}
          </View>
        )}
      </Card>

      <Card>
        <SwitchRow label="Trigger food?" value={isTrigger} onChange={setIsTrigger} />
        <CardDivider />
        <SwitchRow label="Safe food?" value={isSafe} onChange={setIsSafe} />
      </Card>

      <Card>
        <FieldLabel text="Notes (optional)" />
        <StyledInput value={notes} onChangeText={setNotes}
          placeholder="Any additional notes..." multiline minHeight={70}
          accessibilityLabel="Food notes" />
      </Card>

      <Card>
        <Text style={{ fontSize: 13, color: C.textMuted }}>
          Logged at: {format(new Date(), 'h:mm a, MMM d yyyy')}
        </Text>
      </Card>

      <SubmitButton label="Log Food" onPress={handleSubmit} loading={loading} />
    </>
  );
}

// ─── Bowel Form ───────────────────────────────────────────────────────────────

const BLOOD_AMOUNT_OPTIONS: { value: BloodAmount; label: string }[] = [
  { value: 'none', label: 'None' },
  { value: 'trace', label: 'Trace' },
  { value: 'moderate', label: 'Moderate' },
  { value: 'significant', label: 'Significant' },
];

function BowelForm() {
  const C = useColors();
  const { add } = useBowelLogs();
  const [bristolScale, setBristolScale] = useState<number | null>(null);
  const [urgency, setUrgency]           = useState(1);
  const [bloodPresent, setBloodPresent] = useState(false);
  const [bloodAmount, setBloodAmount]   = useState<BloodAmount>('none');
  const [mucusPresent, setMucusPresent] = useState(false);
  const [painDuring, setPainDuring]     = useState(0);
  const [notes, setNotes]               = useState('');
  const [loading, setLoading]           = useState(false);
  const [success, setSuccess]           = useState(false);

  const reset = () => {
    setBristolScale(null); setUrgency(1); setBloodPresent(false);
    setBloodAmount('none'); setMucusPresent(false); setPainDuring(0); setNotes('');
  };

  const handleSubmit = async () => {
    if (!bristolScale) { Alert.alert('Missing Field', 'Please select a Bristol Scale type.'); return; }
    setLoading(true);
    await add({
      logged_at: new Date().toISOString(), bristol_scale: bristolScale,
      urgency, blood_present: bloodPresent,
      blood_amount: bloodPresent ? bloodAmount : 'none',
      mucus_present: mucusPresent, pain_during: painDuring,
      notes: notes.trim() || null,
    });
    setLoading(false); setSuccess(true);
    setTimeout(() => { setSuccess(false); reset(); }, 1500);
  };

  if (success) return <SuccessBanner />;

  return (
    <>
      <Card>
        <FieldLabel text="Bristol Stool Scale" />
        <Text style={{ fontSize: 12, color: C.textSecondary, marginBottom: 12, marginTop: -6 }}>
          Select the type that best matches
        </Text>
        {BRISTOL_TYPES.map((bt) => {
          const selected = bristolScale === bt.scale;
          return (
            <TouchableOpacity
              key={bt.scale}
              style={{
                flexDirection: 'row', alignItems: 'center', padding: 12,
                borderRadius: 12, borderWidth: 1.5,
                borderColor: selected ? C.primary : C.border,
                marginBottom: 8,
                backgroundColor: selected ? C.primary + '10' : C.background,
              }}
              onPress={() => setBristolScale(bt.scale)}
            >
              <View style={{
                width: 30, height: 30, borderRadius: 15,
                backgroundColor: selected ? C.primary : C.border,
                justifyContent: 'center', alignItems: 'center', marginRight: 10,
              }}>
                <Text style={{ fontSize: 13, fontWeight: '700', color: selected ? '#FFF' : C.textSecondary }}>
                  {bt.scale}
                </Text>
              </View>
              <View style={{
                width: 28, height: 28, borderRadius: 8,
                backgroundColor: selected ? C.primary + '20' : C.border + '60',
                alignItems: 'center', justifyContent: 'center', marginRight: 10,
              }}>
                <Text style={{ fontSize: 11, fontWeight: '700', color: selected ? C.primary : C.textMuted }}>
                  {bt.badge}
                </Text>
              </View>
              <View style={{ flex: 1 }}>
                <Text style={{ fontSize: 13, fontWeight: '600', color: selected ? C.primary : C.textPrimary }}>
                  {bt.name}
                </Text>
                <Text style={{ fontSize: 11, color: C.textMuted, marginTop: 1 }}>{bt.description}</Text>
              </View>
              {selected && <Ionicons name="checkmark-circle" size={20} color={C.primary} />}
            </TouchableOpacity>
          );
        })}
      </Card>

      <Card>
        <SliderInput label="Urgency" value={urgency} min={1} max={5} onChange={setUrgency}
          accessibilityLabel="Urgency level 1 to 5" />
      </Card>

      <Card>
        <SwitchRow label="Blood present?" value={bloodPresent} onChange={setBloodPresent} />
        {bloodPresent && (
          <View style={{ marginTop: 12 }}>
            <FieldLabel text="Blood Amount" />
            <View style={{ gap: 8 }}>
              {BLOOD_AMOUNT_OPTIONS.map((opt) => {
                const active = bloodAmount === opt.value;
                return (
                  <TouchableOpacity
                    key={opt.value}
                    style={{
                      flexDirection: 'row', alignItems: 'center', padding: 10,
                      borderRadius: 10, borderWidth: 1.5,
                      borderColor: active ? C.primary : C.border,
                      backgroundColor: active ? C.primary + '10' : C.background,
                    }}
                    onPress={() => setBloodAmount(opt.value)}
                  >
                    <View style={{
                      width: 20, height: 20, borderRadius: 10, borderWidth: 2,
                      borderColor: active ? C.primary : C.border,
                      justifyContent: 'center', alignItems: 'center', marginRight: 10,
                    }}>
                      {active && <View style={{ width: 10, height: 10, borderRadius: 5, backgroundColor: C.primary }} />}
                    </View>
                    <Text style={{
                      fontSize: 14, fontWeight: active ? '600' : '400',
                      color: active ? C.primary : C.textSecondary,
                    }}>
                      {opt.label}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>
          </View>
        )}
        <CardDivider />
        <SwitchRow label="Mucus present?" value={mucusPresent} onChange={setMucusPresent} />
      </Card>

      <Card>
        <SliderInput label="Pain During (0–10)" value={painDuring} min={0} max={10} onChange={setPainDuring}
          accessibilityLabel="Pain during bowel movement 0 to 10" />
      </Card>

      <Card>
        <FieldLabel text="Notes (optional)" />
        <StyledInput value={notes} onChangeText={setNotes}
          placeholder="Any additional notes..." multiline minHeight={70} accessibilityLabel="Bowel notes" />
      </Card>

      <SubmitButton label="Log Bowel Movement" onPress={handleSubmit} loading={loading} />
    </>
  );
}

// ─── Symptoms Form ────────────────────────────────────────────────────────────

function SymptomsForm() {
  const C = useColors();
  const { add } = useSymptomLogs();
  const [painLevel, setPainLevel]         = useState(0);
  const [painLocation, setPainLocation]   = useState<string[]>([]);
  const [fatigueLevel, setFatigueLevel]   = useState(0);
  const [nauseaLevel, setNauseaLevel]     = useState(0);
  const [bloatingLevel, setBloatingLevel] = useState(0);
  const [stressLevel, setStressLevel]     = useState(0);
  const [mood, setMood]                   = useState<Mood | null>(null);
  const [isFlare, setIsFlare]             = useState(false);
  const [notes, setNotes]                 = useState('');
  const [loading, setLoading]             = useState(false);
  const [success, setSuccess]             = useState(false);

  const reset = () => {
    setPainLevel(0); setPainLocation([]); setFatigueLevel(0);
    setNauseaLevel(0); setBloatingLevel(0); setStressLevel(0);
    setMood(null); setIsFlare(false); setNotes('');
  };

  const handleSubmit = async () => {
    setLoading(true);
    await add({
      logged_at: new Date().toISOString(),
      pain_level: painLevel, pain_location: painLocation,
      fatigue_level: fatigueLevel, nausea_level: nauseaLevel,
      bloating_level: bloatingLevel, stress_level: stressLevel,
      mood, is_flare: isFlare, notes: notes.trim() || null,
    });
    setLoading(false); setSuccess(true);
    setTimeout(() => { setSuccess(false); reset(); }, 1500);
  };

  if (success) return <SuccessBanner />;

  return (
    <>
      <Card>
        <SliderInput label="Pain Level" value={painLevel} min={0} max={10} onChange={setPainLevel}
          accessibilityLabel="Pain level 0 to 10" />
        <CardDivider />
        <TagSelector options={PAIN_LOCATIONS} selected={painLocation} onChange={setPainLocation} label="Pain Location" />
      </Card>

      <Card>
        <SliderInput label="Fatigue Level" value={fatigueLevel} min={0} max={10} onChange={setFatigueLevel} accessibilityLabel="Fatigue level" />
        <CardDivider />
        <SliderInput label="Nausea Level" value={nauseaLevel} min={0} max={10} onChange={setNauseaLevel} accessibilityLabel="Nausea level" />
        <CardDivider />
        <SliderInput label="Bloating Level" value={bloatingLevel} min={0} max={10} onChange={setBloatingLevel} accessibilityLabel="Bloating level" />
        <CardDivider />
        <SliderInput label="Stress Level" value={stressLevel} min={0} max={10} onChange={setStressLevel} accessibilityLabel="Stress level" />
      </Card>

      <Card>
        <FieldLabel text="Mood" />
        <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8 }}>
          {MOOD_OPTIONS.map((opt) => {
            const active = mood === opt.value;
            return (
              <TouchableOpacity
                key={opt.value}
                style={{
                  paddingHorizontal: 14, paddingVertical: 8, borderRadius: 20,
                  backgroundColor: active ? C.primary : C.background,
                  borderWidth: 1.5, borderColor: active ? C.primary : C.border,
                }}
                onPress={() => setMood(opt.value as Mood)}
              >
                <Text style={{
                  fontSize: 13, fontWeight: active ? '700' : '500',
                  color: active ? '#FFFFFF' : C.textSecondary,
                }}>
                  {opt.label}
                </Text>
              </TouchableOpacity>
            );
          })}
        </View>
      </Card>

      <Card>
        <SwitchRow label="Currently in a flare?" value={isFlare} onChange={setIsFlare} />
      </Card>

      <Card>
        <FieldLabel text="Notes (optional)" />
        <StyledInput value={notes} onChangeText={setNotes}
          placeholder="Any additional notes..." multiline minHeight={70} accessibilityLabel="Symptom notes" />
      </Card>

      <SubmitButton label="Log Symptoms" onPress={handleSubmit} loading={loading} />
    </>
  );
}

// ─── Meds Form ────────────────────────────────────────────────────────────────

function MedsForm() {
  const C = useColors();
  const { fetchActive, add: addMed } = useMedications();
  const { add: addMedLog }           = useMedicationLogs();
  const [meds, setMeds]              = useState<Medication[]>([]);
  const [checkedIds, setCheckedIds]  = useState<Set<string>>(new Set());
  const [sideEffects, setSideEffects] = useState<string[]>([]);
  const [notes, setNotes]            = useState('');
  const [loadingMeds, setLoadingMeds] = useState(true);
  const [loading, setLoading]        = useState(false);
  const [success, setSuccess]        = useState(false);
  const [showAddForm, setShowAddForm] = useState(false);
  const [newMedName, setNewMedName]  = useState('');
  const [newMedDosage, setNewMedDosage] = useState('');
  const [addingMed, setAddingMed]    = useState(false);

  useEffect(() => {
    fetchActive().then((data) => { setMeds(data); setLoadingMeds(false); });
  }, [fetchActive]);

  const toggleMed = (id: string) => {
    setCheckedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id); else next.add(id);
      return next;
    });
  };

  const reset = () => {
    setCheckedIds(new Set()); setSideEffects([]); setNotes('');
    setShowAddForm(false); setNewMedName(''); setNewMedDosage('');
  };

  const handleAddMed = async () => {
    if (!newMedName.trim()) { Alert.alert('Missing Field', 'Please enter a medication name.'); return; }
    setAddingMed(true);
    const result = await addMed({
      name: newMedName.trim(), dosage: newMedDosage.trim() || null,
      dosage_unit: null, frequency: null, time_of_day: [],
      is_active: true, start_date: null, end_date: null,
    });
    if (result) setMeds((prev) => [...prev, result]);
    setNewMedName(''); setNewMedDosage(''); setShowAddForm(false); setAddingMed(false);
  };

  const handleSubmit = async () => {
    setLoading(true);
    const now = new Date().toISOString();
    await Promise.all(meds.map((med) =>
      addMedLog({
        medication_name: med.name, dosage: med.dosage, dosage_unit: med.dosage_unit,
        scheduled_time: null, taken_at: checkedIds.has(med.id) ? now : null,
        was_taken: checkedIds.has(med.id), side_effects: sideEffects,
        notes: notes.trim() || null,
      }),
    ));
    setLoading(false); setSuccess(true);
    setTimeout(() => { setSuccess(false); reset(); }, 1500);
  };

  if (success) return <SuccessBanner />;

  return (
    <>
      <Card>
        <FieldLabel text="Today's Medications" />
        {loadingMeds ? (
          <ActivityIndicator color={C.primary} style={{ marginVertical: 16 }} />
        ) : meds.length === 0 ? (
          <Text style={{ fontSize: 14, color: C.textMuted, textAlign: 'center', paddingVertical: 12 }}>
            No active medications. Add one below.
          </Text>
        ) : (
          meds.map((med) => {
            const checked = checkedIds.has(med.id);
            return (
              <TouchableOpacity
                key={med.id}
                style={{
                  flexDirection: 'row', alignItems: 'center', padding: 12,
                  borderRadius: 12, borderWidth: 1.5,
                  borderColor: checked ? C.secondary : C.border,
                  marginBottom: 8,
                  backgroundColor: checked ? C.secondary + '10' : C.background,
                }}
                onPress={() => toggleMed(med.id)}
              >
                <View style={{
                  width: 24, height: 24, borderRadius: 6, borderWidth: 2,
                  borderColor: checked ? C.secondary : C.border,
                  backgroundColor: checked ? C.secondary : 'transparent',
                  justifyContent: 'center', alignItems: 'center', marginRight: 12,
                }}>
                  {checked && <Ionicons name="checkmark" size={14} color="#FFF" />}
                </View>
                <View style={{ flex: 1 }}>
                  <Text style={{ fontSize: 14, fontWeight: '600', color: C.textPrimary }}>{med.name}</Text>
                  {med.dosage ? (
                    <Text style={{ fontSize: 12, color: C.textMuted, marginTop: 2 }}>
                      {med.dosage}{med.dosage_unit ? ' ' + med.dosage_unit : ''}
                    </Text>
                  ) : null}
                </View>
              </TouchableOpacity>
            );
          })
        )}
        <TouchableOpacity
          style={{
            marginTop: 8, paddingVertical: 10, alignItems: 'center',
            borderRadius: 10, borderWidth: 1.5, borderColor: C.primary,
            borderStyle: 'dashed',
          }}
          onPress={() => setShowAddForm(v => !v)}
        >
          <Text style={{ fontSize: 14, color: C.primary, fontWeight: '600' }}>
            {showAddForm ? 'Cancel' : '+ Add Medication'}
          </Text>
        </TouchableOpacity>
        {showAddForm && (
          <View style={{ marginTop: 12, padding: 12, backgroundColor: C.background, borderRadius: 12 }}>
            <FieldLabel text="Medication Name" />
            <StyledInput value={newMedName} onChangeText={setNewMedName}
              placeholder="e.g. Mesalamine" accessibilityLabel="New medication name" />
            <FieldLabel text="Dosage (optional)" />
            <StyledInput value={newMedDosage} onChangeText={setNewMedDosage}
              placeholder="e.g. 400mg" accessibilityLabel="New medication dosage" />
            <TouchableOpacity
              style={{
                backgroundColor: C.primary, borderRadius: 10,
                paddingVertical: 10, alignItems: 'center', marginTop: 4,
              }}
              onPress={handleAddMed} disabled={addingMed}
            >
              {addingMed
                ? <ActivityIndicator color="#FFF" />
                : <Text style={{ color: '#FFF', fontWeight: '700', fontSize: 14 }}>Save Medication</Text>}
            </TouchableOpacity>
          </View>
        )}
      </Card>

      <Card>
        <TagSelector options={SIDE_EFFECT_OPTIONS} selected={sideEffects} onChange={setSideEffects} label="Side Effects (optional)" />
      </Card>

      <Card>
        <FieldLabel text="Notes (optional)" />
        <StyledInput value={notes} onChangeText={setNotes}
          placeholder="Any notes about your medications..." multiline minHeight={70} accessibilityLabel="Medication notes" />
      </Card>

      <SubmitButton label="Log Medications" onPress={handleSubmit} loading={loading} />
    </>
  );
}

// ─── Sleep Form ───────────────────────────────────────────────────────────────

function SleepForm() {
  const C = useColors();
  const { add } = useSleepLogs();
  const [quality, setQuality]               = useState(0);
  const [nightWakings, setNightWakings]     = useState('');
  const [bathroomWakings, setBathroomWakings] = useState('');
  const [notes, setNotes]                   = useState('');
  const [loading, setLoading]               = useState(false);
  const [success, setSuccess]               = useState(false);

  const reset = () => { setQuality(0); setNightWakings(''); setBathroomWakings(''); setNotes(''); };

  const handleSubmit = async () => {
    setLoading(true);
    await add({
      date: format(new Date(), 'yyyy-MM-dd'),
      bedtime: new Date().toISOString(), wake_time: new Date().toISOString(),
      duration_minutes: null, quality: quality || 3,
      night_wakings: nightWakings ? parseInt(nightWakings, 10) : 0,
      bathroom_wakings: bathroomWakings ? parseInt(bathroomWakings, 10) : 0,
      notes: notes.trim() || null,
    });
    setLoading(false); setSuccess(true);
    setTimeout(() => { setSuccess(false); reset(); }, 1500);
  };

  if (success) return <SuccessBanner />;

  const QUALITY_LABELS = ['', 'Poor', 'Fair', 'Good', 'Great', 'Excellent'];

  return (
    <>
      <Card>
        <FieldLabel text="Sleep Quality" />
        <View style={{ flexDirection: 'row', gap: 8, marginTop: 4 }}>
          {[1, 2, 3, 4, 5].map((star) => (
            <TouchableOpacity key={star} onPress={() => setQuality(star)} style={{ padding: 4 }}>
              <Text style={{ fontSize: 32, color: quality >= star ? C.warning : C.border }}>★</Text>
            </TouchableOpacity>
          ))}
        </View>
        {quality > 0 && (
          <Text style={{ marginTop: 6, fontSize: 14, color: C.textSecondary, fontWeight: '500' }}>
            {QUALITY_LABELS[quality]}
          </Text>
        )}
      </Card>

      <Card>
        <Text style={{ fontSize: 13, color: C.textMuted, fontStyle: 'italic' }}>
          Duration will be calculated from bedtime and wake time.
        </Text>
      </Card>

      <Card>
        <FieldLabel text="Night Wakings" />
        <StyledInput value={nightWakings} onChangeText={setNightWakings}
          placeholder="0" keyboardType="number-pad" accessibilityLabel="Number of night wakings" />
        <FieldLabel text="Bathroom Wakings" />
        <StyledInput value={bathroomWakings} onChangeText={setBathroomWakings}
          placeholder="0" keyboardType="number-pad" accessibilityLabel="Number of bathroom wakings" />
      </Card>

      <Card>
        <FieldLabel text="Notes (optional)" />
        <StyledInput value={notes} onChangeText={setNotes}
          placeholder="Any notes about your sleep..." multiline minHeight={70} accessibilityLabel="Sleep notes" />
      </Card>

      <SubmitButton label="Log Sleep" onPress={handleSubmit} loading={loading} />
    </>
  );
}

// ─── Cycle Form ───────────────────────────────────────────────────────────────

function CycleForm() {
  const { add } = useMenstrualLogs();
  const [flow, setFlow]         = useState<FlowLevel | null>(null);
  const [cycleDay, setCycleDay] = useState('');
  const [symptoms, setSymptoms] = useState<string[]>([]);
  const [notes, setNotes]       = useState('');
  const [loading, setLoading]   = useState(false);
  const [success, setSuccess]   = useState(false);

  const reset = () => { setFlow(null); setCycleDay(''); setSymptoms([]); setNotes(''); };

  const handleSubmit = async () => {
    setLoading(true);
    await add({
      date: format(new Date(), 'yyyy-MM-dd'),
      cycle_day: cycleDay ? parseInt(cycleDay, 10) : null,
      flow: flow ?? 'none', symptoms, notes: notes.trim() || null,
    });
    setLoading(false); setSuccess(true);
    setTimeout(() => { setSuccess(false); reset(); }, 1500);
  };

  if (success) return <SuccessBanner />;

  return (
    <>
      <Card>
        <FieldLabel text="Flow Level" />
        <SegmentedButtons options={FLOW_LEVELS} value={flow} onChange={setFlow} />
      </Card>

      <Card>
        <FieldLabel text="Cycle Day (optional)" />
        <StyledInput value={cycleDay} onChangeText={setCycleDay}
          placeholder="e.g. 14" keyboardType="number-pad" accessibilityLabel="Cycle day" />
      </Card>

      <Card>
        <TagSelector options={MENSTRUAL_SYMPTOMS} selected={symptoms} onChange={setSymptoms} label="Symptoms" />
      </Card>

      <Card>
        <FieldLabel text="Notes (optional)" />
        <StyledInput value={notes} onChangeText={setNotes}
          placeholder="Any additional notes..." multiline minHeight={70} accessibilityLabel="Cycle notes" />
      </Card>

      <SubmitButton label="Log Cycle" onPress={handleSubmit} loading={loading} />
    </>
  );
}

// ─── Weight Form ──────────────────────────────────────────────────────────────

const WEIGHT_UNITS = [
  { value: 'kg' as const, label: 'kg' },
  { value: 'lbs' as const, label: 'lbs' },
];

function WeightForm() {
  const C = useColors();
  const { add } = useWeightLogs();
  const [weight, setWeight] = useState('');
  const [unit, setUnit]     = useState<'kg' | 'lbs'>('kg');
  const [notes, setNotes]   = useState('');
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  const reset = () => { setWeight(''); setUnit('kg'); setNotes(''); };

  const handleSubmit = async () => {
    const parsed = parseFloat(weight);
    if (!weight || isNaN(parsed) || parsed <= 0) {
      Alert.alert('Invalid Weight', 'Please enter a valid positive weight.'); return;
    }
    const weightKg = unit === 'lbs' ? parsed * 0.453592 : parsed;
    setLoading(true);
    await add({
      logged_at: new Date().toISOString(),
      weight_kg: parseFloat(weightKg.toFixed(3)),
      notes: notes.trim() || null,
    });
    setLoading(false); setSuccess(true);
    setTimeout(() => { setSuccess(false); reset(); }, 1500);
  };

  if (success) return <SuccessBanner />;

  return (
    <>
      <Card>
        <FieldLabel text="Weight" />
        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 10 }}>
          <View style={{ flex: 1 }}>
            <StyledInput value={weight} onChangeText={setWeight}
              placeholder="0.0" keyboardType="decimal-pad" accessibilityLabel="Weight value" />
          </View>
          <SegmentedButtons options={WEIGHT_UNITS} value={unit} onChange={setUnit} />
        </View>
        {weight && !isNaN(parseFloat(weight)) && parseFloat(weight) > 0 && unit === 'lbs' && (
          <Text style={{ marginTop: 6, fontSize: 12, color: C.textMuted }}>
            ≈ {(parseFloat(weight) * 0.453592).toFixed(1)} kg
          </Text>
        )}
      </Card>

      <Card>
        <FieldLabel text="Notes (optional)" />
        <StyledInput value={notes} onChangeText={setNotes}
          placeholder="Any notes..." multiline minHeight={70} accessibilityLabel="Weight notes" />
      </Card>

      <SubmitButton label="Log Weight" onPress={handleSubmit} loading={loading} />
    </>
  );
}

// ─── Main Log Screen ──────────────────────────────────────────────────────────

export default function LogScreen() {
  const C = useColors();
  const params     = useLocalSearchParams<{ tab?: string }>();
  const initialTab = (params.tab as TabKey) ?? 'food';
  const validTab   = TABS.some((t) => t.key === initialTab) ? initialTab : 'food';
  const [activeTab, setActiveTab] = useState<TabKey>(validTab);

  useEffect(() => {
    if (params.tab && TABS.some((t) => t.key === params.tab)) {
      setActiveTab(params.tab as TabKey);
    }
  }, [params.tab]);

  const renderForm = () => {
    switch (activeTab) {
      case 'food':     return <FoodForm />;
      case 'bowel':    return <BowelForm />;
      case 'symptoms': return <SymptomsForm />;
      case 'meds':     return <MedsForm />;
      case 'sleep':    return <SleepForm />;
      case 'cycle':    return <CycleForm />;
      case 'weight':   return <WeightForm />;
      default:         return null;
    }
  };

  return (
    <KeyboardAvoidingView
      style={{ flex: 1, backgroundColor: C.background }}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      keyboardVerticalOffset={Platform.OS === 'ios' ? 88 : 0}
    >
      {/* ── Header ── */}
      <View style={{
        paddingHorizontal: 20,
        paddingTop: Platform.OS === 'ios' ? 56 : 20,
        paddingBottom: 14,
        backgroundColor: C.surface,
        borderBottomWidth: 0.5, borderBottomColor: C.separator,
      }}>
        <Text style={{ fontSize: 28, fontWeight: '800', color: C.textPrimary }}>Log</Text>
        <Text style={{ fontSize: 13, color: C.textMuted, marginTop: 2 }}>
          {format(new Date(), 'EEEE, MMMM d')}
        </Text>
      </View>

      {/* ── Tab Chips ── */}
      <View style={{ backgroundColor: C.surface, borderBottomWidth: 0.5, borderBottomColor: C.separator }}>
        <ScrollView
          horizontal showsHorizontalScrollIndicator={false}
          contentContainerStyle={{ paddingHorizontal: 16, paddingVertical: 10, gap: 6 }}
        >
          {TABS.map((tab) => {
            const active = activeTab === tab.key;
            return (
              <TouchableOpacity
                key={tab.key}
                style={{
                  paddingVertical: 8, paddingHorizontal: 16, borderRadius: 20,
                  backgroundColor: active ? C.primary : C.background,
                  borderWidth: 1.5, borderColor: active ? C.primary : C.border,
                }}
                onPress={() => setActiveTab(tab.key)}
              >
                <Text style={{
                  fontSize: 13, fontWeight: active ? '700' : '500',
                  color: active ? '#FFFFFF' : C.textSecondary,
                }}>
                  {tab.label}
                </Text>
              </TouchableOpacity>
            );
          })}
        </ScrollView>
      </View>

      {/* ── Form ── */}
      <ScrollView
        style={{ flex: 1 }}
        contentContainerStyle={{ padding: 16, paddingBottom: 60 }}
        keyboardShouldPersistTaps="handled"
        showsVerticalScrollIndicator={false}
      >
        {renderForm()}
        <View style={{ height: 40 }} />
      </ScrollView>
    </KeyboardAvoidingView>
  );
}
