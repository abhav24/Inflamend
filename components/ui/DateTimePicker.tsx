import React from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Alert,
} from 'react-native';
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
  switch (mode) {
    case 'date':
      return '📅';
    case 'time':
      return '🕐';
    case 'datetime':
    default:
      return '📅';
  }
}

export function DateTimePicker({
  label,
  value,
  onChange, // eslint-disable-line @typescript-eslint/no-unused-vars
  mode = 'datetime',
  accessibilityLabel,
}: DateTimePickerProps) {
  // TODO: Wire up native date/time picker (e.g. @react-native-community/datetimepicker)
  // when the package is installed. For now, shows the formatted value with an alert.
  const handlePress = () => {
    Alert.alert(
      'Date Picker',
      'Date picker will be implemented — edit directly.',
      [{ text: 'OK' }]
    );
  };

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
});
