import { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Platform,
  Modal,
} from 'react-native';
import RNDateTimePicker, { DateTimePickerEvent } from '@react-native-community/datetimepicker';
import { format } from 'date-fns';
import { Colors } from '../../constants/colors';

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

function modeIcon(mode: PickerMode): string {
  return mode === 'time' ? '🕐' : '📅';
}

export function DateTimePicker({
  label,
  value,
  onChange,
  mode = 'datetime',
  accessibilityLabel,
}: DateTimePickerProps) {
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
    <View style={styles.container}>
      <Text style={styles.label}>{label}</Text>
      <TouchableOpacity
        style={styles.pill}
        onPress={handlePress}
        activeOpacity={0.75}
        accessibilityLabel={accessibilityLabel ?? label}
        accessibilityRole="button"
        accessibilityHint="Tap to change"
      >
        <Text style={styles.icon}>{modeIcon(mode)}</Text>
        <View style={styles.textBlock}>
          <Text style={styles.valueText}>{formatValue(value, mode)}</Text>
          <Text style={styles.hint}>Tap to change</Text>
        </View>
        <Text style={styles.chevron}>›</Text>
      </TouchableOpacity>

      {Platform.OS === 'ios' ? (
        <Modal visible={show} transparent animationType="slide">
          <View style={styles.modalOverlay}>
            <View style={styles.modalSheet}>
              <View style={styles.modalHeader}>
                <Text style={styles.modalTitle}>
                  {mode === 'datetime'
                    ? phase === 'date' ? 'Select Date' : 'Select Time'
                    : mode === 'time' ? 'Select Time' : 'Select Date'}
                </Text>
                <TouchableOpacity onPress={handleDone}>
                  <Text style={styles.doneBtn}>
                    {mode === 'datetime' && phase === 'date' ? 'Next →' : 'Done'}
                  </Text>
                </TouchableOpacity>
              </View>
              <RNDateTimePicker
                value={phase === 'time' ? tempDate : value}
                mode={pickerMode}
                display="spinner"
                onChange={handleChange}
                style={styles.picker}
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

const styles = StyleSheet.create({
  container: {
    marginBottom: 16,
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    color: Colors.textPrimary,
    marginBottom: 6,
  },
  pill: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.primaryLight,
    borderRadius: 12,
    paddingVertical: 12,
    paddingHorizontal: 14,
    borderWidth: 1,
    borderColor: Colors.primary + '40',
  },
  icon: {
    fontSize: 18,
    marginRight: 10,
  },
  textBlock: {
    flex: 1,
  },
  valueText: {
    fontSize: 15,
    fontWeight: '600',
    color: Colors.primary,
  },
  hint: {
    fontSize: 11,
    color: Colors.textSecondary,
    marginTop: 1,
  },
  chevron: {
    fontSize: 20,
    color: Colors.primary,
    fontWeight: '300',
    marginLeft: 6,
  },
  modalOverlay: {
    flex: 1,
    justifyContent: 'flex-end',
    backgroundColor: 'rgba(0,0,0,0.3)',
  },
  modalSheet: {
    backgroundColor: Colors.white,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    paddingBottom: 32,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 14,
    borderBottomWidth: 1,
    borderBottomColor: Colors.border,
  },
  modalTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  doneBtn: {
    fontSize: 16,
    fontWeight: '600',
    color: Colors.primary,
  },
  picker: {
    width: '100%',
  },
});
