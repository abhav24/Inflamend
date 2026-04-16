import React from 'react';
import {
  View,
  Text,
  TouchableOpacity,
} from 'react-native';
import { useColors } from '../../constants/colors';

interface TagOption {
  id: string;
  label: string;
}

interface TagSelectorProps {
  options: TagOption[];
  selected: string[];
  onChange: (selected: string[]) => void;
  label?: string;
}

export function TagSelector({
  options,
  selected,
  onChange,
  label,
}: TagSelectorProps) {
  const C = useColors();

  const toggle = (id: string) => {
    if (selected.includes(id)) {
      onChange(selected.filter((s) => s !== id));
    } else {
      onChange([...selected, id]);
    }
  };

  return (
    <View style={{ marginBottom: 16 }}>
      {label ? (
        <Text style={{ fontSize: 14, fontWeight: '600', color: C.textPrimary, marginBottom: 8 }}>
          {label}
        </Text>
      ) : null}
      <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8 }}>
        {options.map((opt) => {
          const isSelected = selected.includes(opt.id);
          return (
            <TouchableOpacity
              key={opt.id}
              style={{
                paddingVertical: 7,
                paddingHorizontal: 14,
                borderRadius: 20,
                borderWidth: 1.2,
                borderColor: isSelected ? C.primary : C.glassBorder,
                backgroundColor: isSelected ? C.primary : C.surfaceMuted,
              }}
              onPress={() => toggle(opt.id)}
              activeOpacity={0.7}
              accessibilityRole="checkbox"
              accessibilityState={{ checked: isSelected }}
              accessibilityLabel={opt.label}
            >
              <Text style={{
                fontSize: 13,
                fontWeight: isSelected ? '600' : '500',
                color: isSelected ? '#FFFFFF' : C.textSecondary,
              }}>
                {opt.label}
              </Text>
            </TouchableOpacity>
          );
        })}
      </View>
    </View>
  );
}
