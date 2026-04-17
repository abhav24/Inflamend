import { useState } from 'react';
import { Modal, Platform, Text, TouchableOpacity, View } from 'react-native';
import RNDateTimePicker, { DateTimePickerEvent } from '@react-native-community/datetimepicker';
import { format } from 'date-fns';
import { useColors } from '../../constants/colors';
import { AppIcon, GlassSheet, PressScale } from './DesignPrimitives';
import { selectionHaptic } from '../../lib/haptics';

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
    default:
      return format(date, 'MMM d, yyyy • h:mm a');
  }
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
  const [phase, setPhase] = useState<'date' | 'time'>('date');
  const [tempDate, setTempDate] = useState(value);

  function open() {
    selectionHaptic();
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
      onChange(selected);
      setShow(false);
      return;
    }

    if (mode === 'datetime') {
      if (phase === 'date') {
        setTempDate(selected);
        return;
      }
      const merged = new Date(tempDate);
      merged.setHours(selected.getHours(), selected.getMinutes(), 0, 0);
      onChange(merged);
      return;
    }

    onChange(selected);
  }

  function handleDone() {
    selectionHaptic();
    if (mode === 'datetime' && phase === 'date') {
      setPhase('time');
      return;
    }
    setShow(false);
    setPhase('date');
  }

  const pickerMode = mode === 'datetime' ? phase : mode;
  const pickerValue = mode === 'datetime' && phase === 'time' ? tempDate : value;

  return (
    <View style={{ marginBottom: 16 }}>
      <Text style={{ fontSize: 15, fontWeight: '600', color: C.textPrimary, marginBottom: 8, letterSpacing: -0.24 }}>
        {label}
      </Text>
      <PressScale onPress={open}>
        <GlassSheet style={{ borderRadius: 18 }}>
          <View
            style={{
              flexDirection: 'row',
              alignItems: 'center',
              paddingHorizontal: 16,
              paddingVertical: 14,
            }}
          >
            <AppIcon
              symbol={mode === 'time' ? 'clock.fill' : 'calendar'}
              fallback={mode === 'time' ? 'time-outline' : 'calendar-outline'}
              size={18}
              tintColor={C.primary}
            />
            <View style={{ flex: 1, marginLeft: 12 }}>
              <Text style={{ fontSize: 17, fontWeight: '600', color: C.textPrimary, letterSpacing: -0.24 }}>
                {formatValue(value, mode)}
              </Text>
              <Text style={{ fontSize: 13, fontWeight: '500', color: C.textSecondary, marginTop: 2 }}>
                Tap to change
              </Text>
            </View>
            <AppIcon symbol="chevron.right" fallback="chevron-forward" size={15} tintColor={C.primary} />
          </View>
        </GlassSheet>
      </PressScale>

      {Platform.OS === 'ios' ? (
        <Modal visible={show} transparent animationType="fade" onRequestClose={() => setShow(false)}>
          <View style={{ flex: 1, justifyContent: 'flex-end', backgroundColor: C.scrim, padding: 12 }}>
            <GlassSheet style={{ paddingBottom: 26 }}>
              <View
                style={{
                  flexDirection: 'row',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  paddingHorizontal: 20,
                  paddingVertical: 16,
                  borderBottomWidth: 1,
                  borderBottomColor: C.separator,
                }}
              >
                <Text style={{ fontSize: 20, fontWeight: '700', color: C.textPrimary, letterSpacing: -0.4 }}>
                  {mode === 'datetime'
                    ? phase === 'date'
                      ? 'Select Date'
                      : 'Select Time'
                    : mode === 'time'
                      ? 'Select Time'
                      : 'Select Date'}
                </Text>
                <TouchableOpacity onPress={handleDone}>
                  <Text style={{ fontSize: 17, fontWeight: '700', color: C.primary }}>
                    {mode === 'datetime' && phase === 'date' ? 'Next' : 'Done'}
                  </Text>
                </TouchableOpacity>
              </View>
              <RNDateTimePicker
                value={pickerValue}
                mode={pickerMode}
                display="spinner"
                onChange={handleChange}
                style={{ width: '100%' }}
              />
            </GlassSheet>
          </View>
        </Modal>
      ) : (
        show ? (
          <RNDateTimePicker
            value={pickerValue}
            mode={pickerMode}
            display="default"
            onChange={handleChange}
          />
        ) : null
      )}
    </View>
  );
}
