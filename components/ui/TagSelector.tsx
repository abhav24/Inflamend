import React from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
} from 'react-native';
import { Colors } from '../../constants/colors';

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
  const toggle = (id: string) => {
    if (selected.includes(id)) {
      onChange(selected.filter((s) => s !== id));
    } else {
      onChange([...selected, id]);
    }
  };

  return (
    <View style={styles.container}>
      {label ? <Text style={styles.label}>{label}</Text> : null}
      <View style={styles.tagRow}>
        {options.map((opt) => {
          const isSelected = selected.includes(opt.id);
          return (
            <TouchableOpacity
              key={opt.id}
              style={[styles.tag, isSelected && styles.tagSelected]}
              onPress={() => toggle(opt.id)}
              activeOpacity={0.7}
              accessibilityRole="checkbox"
              accessibilityState={{ checked: isSelected }}
              accessibilityLabel={opt.label}
            >
              <Text
                style={[styles.tagText, isSelected && styles.tagTextSelected]}
              >
                {opt.label}
              </Text>
            </TouchableOpacity>
          );
        })}
      </View>
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
    marginBottom: 8,
  },
  tagRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  tag: {
    paddingVertical: 7,
    paddingHorizontal: 14,
    borderRadius: 20,
    borderWidth: 1.5,
    borderColor: Colors.border,
    backgroundColor: Colors.white,
  },
  tagSelected: {
    backgroundColor: Colors.primary,
    borderColor: Colors.primary,
  },
  tagText: {
    fontSize: 13,
    fontWeight: '500',
    color: Colors.textSecondary,
  },
  tagTextSelected: {
    color: Colors.white,
    fontWeight: '600',
  },
});
