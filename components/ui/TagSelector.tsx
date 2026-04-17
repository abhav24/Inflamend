import React from 'react';
import { Text, View } from 'react-native';
import { PressScale } from './DesignPrimitives';
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

export function TagSelector({ options, selected, onChange, label }: TagSelectorProps) {
  const C = useColors();

  const toggle = (id: string) => {
    if (selected.includes(id)) {
      onChange(selected.filter((item) => item !== id));
    } else {
      onChange([...selected, id]);
    }
  };

  return (
    <View style={{ marginBottom: 4 }}>
      {label ? (
        <Text style={{ fontSize: 15, fontWeight: '600', color: C.textPrimary, marginBottom: 10, letterSpacing: -0.24 }}>
          {label}
        </Text>
      ) : null}
      <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8 }}>
        {options.map((option) => {
          const active = selected.includes(option.id);
          return (
            <PressScale key={option.id} onPress={() => toggle(option.id)}>
              <View
                style={{
                  paddingVertical: 9,
                  paddingHorizontal: 14,
                  borderRadius: 18,
                  borderWidth: 1,
                  borderColor: active ? C.primary : C.glassBorder,
                  backgroundColor: active ? C.primary : C.fillTertiary,
                }}
              >
                <Text
                  style={{
                    fontSize: 13,
                    fontWeight: active ? '700' : '500',
                    color: active ? C.onGradient : C.textSecondary,
                    letterSpacing: -0.08,
                  }}
                >
                  {option.label}
                </Text>
              </View>
            </PressScale>
          );
        })}
      </View>
    </View>
  );
}
