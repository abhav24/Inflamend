import { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  Platform,
  Modal,
} from 'react-native';
import RNDateTimePicker, { DateTimePickerEvent } from '@react-native-community/datetimepicker';
import { format } from 'date-fns';
import { Ionicons } from '@expo/vector-icons';
import { useColors } from '../../constants/colors';

type PickerMode = 'date' | 'time' | 'datetime';

interface DateTimePickerProps {
  label: string;
  value: Date;
  onChange: (date: Date) => void;
  mode?: PickerMode;
  accessibilityLabel?: string;
}

function formatValue(date: Date, mode: PickerMode): string {
  switch (mode) {
    case 'date':
      return format(date, 'MMMM d, yyyy');
    case 'time':
      return format(date, 'h:mm a');
    case 'datetime':
    default:
      return format(date, 'MMM d, yyyy • h:mm a');
  }
}

function modeIcon(mode: PickerMode): React.ComponentProps<typeof Ionicons>['name'] {
  return mode === 'time' ? 'time-outline' : 'calendar-outline';
}

export function DateTimePicker({
  label,
  value,
  onChange,
  mode = 'datetime',
  accessibilityLabel,
}: DateTimePickerProps) {
  const C = useColors();
  const [show, setShow] = useState(false);
  // For datetime on iOS we need two passes: first date, then time
  const [phase, setPhase] = useState<'date' | 'time'>('date');
  const [tempDate, setTempDate] = useState(value);

  function handlePress() {
    setTempDate(value);
    setPhase('date');
    setShow(true);
  }

  function handleChange(_event: DateTimePickerEvent, selected?: Date) {
    if (!selected) {
      setShow(false);
      return;
    }

    if (Platform.OS !== 'ios') {
      setShow(false);
      onChange(selected);
      return;
    }

    // iOS spinner — stay open
    if (mode === 'datetime') {
      if (phase === 'date') {
        setTempDate(selected);
        setPhase('time');
      } else {
        // Merge date part from tempDate with time part from selected
        const merged = new Date(tempDate);
        merged.setHours(selected.getHours(), selected.getMinutes(), 0, 0);
        onChange(merged);
        setShow(false);
        setPhase('date');
      }
    } else {
      onChange(selected);
    }
  }

  function handleDone() {
    if (mode === 'datetime' && phase === 'date') {
      setPhase('time');
    } else {
      setShow(false);
      setPhase('date');
    }
  }

  const pickerMode = mode === 'datetime' ? phase : mode;

  return (
    <View style={{ marginBottom: 16 }}>
      <Text style={{ fontSize: 14, fontWeight: '600', color: C.textPrimary, marginBottom: 6 }}>{label}</Text>
      <TouchableOpacity
        style={{
          flexDirection: 'row',
          alignItems: 'center',
          backgroundColor: C.surfaceMuted,
          borderRadius: 12,
          paddingVertical: 12,
          paddingHorizontal: 14,
          borderWidth: 1,
          borderColor: C.glassBorder,
        }}
        onPress={handlePress}
        activeOpacity={0.75}
        accessibilityLabel={accessibilityLabel ?? label}
        accessibilityRole="button"
        accessibilityHint="Tap to change"
      >
        <Ionicons name={modeIcon(mode)} size={18} color={C.primary} style={{ marginRight: 10 }} />
        <View style={{ flex: 1 }}>
          <Text style={{ fontSize: 15, fontWeight: '600', color: C.textPrimary }}>{formatValue(value, mode)}</Text>
          <Text style={{ fontSize: 11, color: C.textSecondary, marginTop: 1 }}>Tap to change</Text>
        </View>
        <Ionicons name="chevron-forward" size={16} color={C.primary} style={{ marginLeft: 6 }} />
      </TouchableOpacity>

      {Platform.OS === 'ios' ? (
        <Modal visible={show} transparent animationType="slide">
          <View style={{
            flex: 1,
            justifyContent: 'flex-end',
            backgroundColor: 'rgba(0,0,0,0.3)',
          }}>
            <View style={{
              backgroundColor: C.surface,
              borderTopLeftRadius: 20,
              borderTopRightRadius: 20,
              borderWidth: 1,
              borderColor: C.glassBorder,
              paddingBottom: 32,
            }}>
              <View style={{
                flexDirection: 'row',
                justifyContent: 'space-between',
                alignItems: 'center',
                paddingHorizontal: 20,
                paddingVertical: 14,
                borderBottomWidth: 1,
                borderBottomColor: C.border,
              }}>
                <Text style={{ fontSize: 16, fontWeight: '600', color: C.textPrimary }}>
                  {mode === 'datetime'
                    ? phase === 'date' ? 'Select Date' : 'Select Time'
                    : mode === 'time' ? 'Select Time' : 'Select Date'}
                </Text>
                <TouchableOpacity onPress={handleDone}>
                  <Text style={{ fontSize: 16, fontWeight: '600', color: C.primary }}>
                    {mode === 'datetime' && phase === 'date' ? 'Next →' : 'Done'}
                  </Text>
                </TouchableOpacity>
              </View>
              <RNDateTimePicker
                value={phase === 'time' ? tempDate : value}
                mode={pickerMode}
                display="spinner"
                onChange={handleChange}
                style={{ width: '100%' }}
              />
            </View>
          </View>
        </Modal>
      ) : (
        show && (
          <RNDateTimePicker
            value={value}
            mode={pickerMode}
            display="default"
            onChange={handleChange}
          />
        )
      )}
    </View>
  );
}
