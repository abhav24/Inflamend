import React from 'react';
import { View, Text, TouchableOpacity, ActivityIndicator, ViewStyle } from 'react-native';
import { useColors } from '../../constants/colors';

// ─── Card ─────────────────────────────────────────────────────────────────────

export function AppCard({ children, style }: { children: React.ReactNode; style?: ViewStyle }) {
  const C = useColors();
  return (
    <View
      style={[
        {
          backgroundColor: C.surface,
          borderRadius: 16,
          borderWidth: 1,
          borderColor: C.glassBorder,
          shadowColor: '#0F172A',
          shadowOpacity: C.background === '#000000' ? 0.22 : 0.12,
          shadowRadius: 18,
          shadowOffset: { width: 0, height: 8 },
          elevation: 6,
        },
        style,
      ]}
    >
      {children}
    </View>
  );
}

// ─── User Avatar ──────────────────────────────────────────────────────────────

const AVATAR_PALETTE = [
  '#6366F1', '#8B5CF6', '#10B981',
  '#3B82F6', '#EC4899', '#F97316', '#14B8A6',
];

function avatarBg(name: string): string {
  const hash = name.split('').reduce((acc, ch) => (acc * 31 + ch.charCodeAt(0)) & 0x7fffffff, 0);
  return AVATAR_PALETTE[hash % AVATAR_PALETTE.length];
}

function initials(name: string): string {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
  return name.slice(0, 2).toUpperCase();
}

export function UserAvatar({ name, size = 44 }: { name: string; size?: number }) {
  const bg = avatarBg(name || 'U');
  const fontSize = Math.round(size * 0.38);
  return (
    <View
      style={{
        width: size, height: size, borderRadius: size / 2,
        backgroundColor: bg, alignItems: 'center', justifyContent: 'center',
      }}
    >
      <Text style={{ fontSize, lineHeight: size, color: '#FFFFFF', fontWeight: '700', textAlign: 'center' }}>
        {initials(name || 'U')}
      </Text>
    </View>
  );
}

// ─── Icon Badge ───────────────────────────────────────────────────────────────

export function IconBadge({
  label,
  tone = 'primary',
  size = 32,
}: {
  label: string;
  tone?: 'primary' | 'secondary' | 'success' | 'warning' | 'danger';
  size?: number;
}) {
  const C = useColors();
  const tones = {
    primary:   { bg: C.primaryLight, fg: C.primary },
    secondary: { bg: C.primary + '18', fg: C.secondary },
    success:   { bg: C.success + '18', fg: C.success },
    warning:   { bg: C.warning + '18', fg: C.warning },
    danger:    { bg: C.danger + '18',  fg: C.danger },
  } as const;
  const { bg, fg } = tones[tone];
  return (
    <View
      style={{
        width: size, height: size,
        borderRadius: Math.round(size * 0.28),
        backgroundColor: bg, alignItems: 'center', justifyContent: 'center',
      }}
    >
      <Text style={{ color: fg, fontSize: Math.max(11, Math.round(size * 0.34)), fontWeight: '700' }}>
        {label}
      </Text>
    </View>
  );
}

// ─── Section Header ───────────────────────────────────────────────────────────

export function SectionHeader({
  title,
  subtitle,
  actionLabel,
  onAction,
}: {
  title: string;
  subtitle?: string;
  actionLabel?: string;
  onAction?: () => void;
}) {
  const C = useColors();
  return (
    <View style={{ flexDirection: 'row', alignItems: 'center', marginBottom: 14 }}>
      <View style={{ flex: 1 }}>
        <Text style={{ fontSize: 20, fontWeight: '700', color: C.textPrimary }}>{title}</Text>
        {subtitle ? (
          <Text style={{ marginTop: 2, fontSize: 13, color: C.textSecondary }}>{subtitle}</Text>
        ) : null}
      </View>
      {actionLabel && onAction ? (
        <TouchableOpacity onPress={onAction} activeOpacity={0.7}>
          <Text style={{ fontSize: 14, fontWeight: '600', color: C.primary }}>{actionLabel}</Text>
        </TouchableOpacity>
      ) : null}
    </View>
  );
}

// ─── Primary Button ───────────────────────────────────────────────────────────

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
  const C = useColors();
  const isDisabled = Boolean(disabled || loading);
  return (
    <TouchableOpacity
      style={[
        {
          backgroundColor: C.primary,
          borderWidth: 1,
          borderColor: C.glassBorder,
          borderRadius: 14,
          height: 54,
          alignItems: 'center',
          justifyContent: 'center',
          shadowColor: C.primary,
          shadowOpacity: 0.3,
          shadowRadius: 16,
          shadowOffset: { width: 0, height: 8 },
          elevation: 6,
        },
        isDisabled && { opacity: 0.65 },
      ]}
      onPress={onPress}
      disabled={isDisabled}
      activeOpacity={0.82}
    >
      {loading ? (
        <ActivityIndicator color="#FFFFFF" />
      ) : (
        <Text style={{ color: '#FFFFFF', fontSize: 16, fontWeight: '700', letterSpacing: 0.2 }}>
          {title}
        </Text>
      )}
    </TouchableOpacity>
  );
}
