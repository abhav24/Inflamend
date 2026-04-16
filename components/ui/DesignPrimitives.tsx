import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ActivityIndicator, ViewStyle } from 'react-native';
import { Colors } from '../../constants/colors';
import { Theme } from '../../constants/theme';

export function AppCard({ children, style }: { children: React.ReactNode; style?: ViewStyle }) {
  return <View style={[styles.card, style]}>{children}</View>;
}

export function IconBadge({
  label,
  tone = 'primary',
  size = 32,
}: {
  label: string;
  tone?: 'primary' | 'secondary' | 'success' | 'warning' | 'danger';
  size?: number;
}) {
  const tones = {
    primary: { bg: Colors.primaryLight, fg: Colors.primary },
    secondary: { bg: '#F3EEFF', fg: Colors.secondary },
    success: { bg: '#EAFBF5', fg: Colors.success },
    warning: { bg: '#FFF8EC', fg: Colors.warning },
    danger: { bg: '#FEEFEF', fg: Colors.danger },
  } as const;
  const selected = tones[tone];

  return (
    <View
      style={[
        styles.iconBadge,
        {
          width: size,
          height: size,
          borderRadius: Math.round(size * 0.28),
          backgroundColor: selected.bg,
        },
      ]}
    >
      <Text style={[styles.iconBadgeText, { color: selected.fg, fontSize: Math.max(11, Math.round(size * 0.34)) }]}>
        {label}
      </Text>
    </View>
  );
}

export function SectionHeader({
  title,
  subtitle,
}: {
  title: string;
  subtitle?: string;
}) {
  return (
    <View style={styles.sectionHeader}>
      <Text style={styles.sectionTitle}>{title}</Text>
      {subtitle ? <Text style={styles.sectionSubtitle}>{subtitle}</Text> : null}
    </View>
  );
}

export function PrimaryButton({
  title,
  onPress,
  loading,
  disabled,
}: {
  title: string;
  onPress: () => void;
  loading?: boolean;
  disabled?: boolean;
}) {
  const isDisabled = Boolean(disabled || loading);

  return (
    <TouchableOpacity
      style={[styles.primaryButton, isDisabled && styles.primaryButtonDisabled]}
      onPress={onPress}
      disabled={isDisabled}
      activeOpacity={0.85}
    >
      <View style={styles.primaryButtonOverlay} />
      {loading ? (
        <ActivityIndicator color={Colors.white} />
      ) : (
        <Text style={styles.primaryButtonText}>{title}</Text>
      )}
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: Colors.white,
    borderRadius: Theme.radius.lg,
    borderWidth: 1,
    borderColor: Colors.border,
    ...Theme.shadow.card,
  },
  iconBadge: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconBadgeText: {
    fontWeight: '700',
  },
  sectionHeader: {
    marginBottom: 16,
  },
  sectionTitle: {
    fontSize: 22,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  sectionSubtitle: {
    marginTop: 2,
    fontSize: 13,
    color: Colors.textSecondary,
  },
  primaryButton: {
    backgroundColor: Colors.primaryDark,
    borderRadius: 14,
    height: 54,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
    ...Theme.shadow.card,
  },
  primaryButtonOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: Colors.secondary,
    opacity: 0.25,
  },
  primaryButtonDisabled: {
    opacity: 0.7,
  },
  primaryButtonText: {
    color: Colors.white,
    fontSize: 16,
    fontWeight: '700',
  },
});
