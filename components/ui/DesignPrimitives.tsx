import React, { useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Platform,
  Pressable,
  StyleProp,
  StyleSheet,
  Text,
  TextInput,
  TextInputProps,
  TextStyle,
  View,
  ViewStyle,
} from 'react-native';
import Animated, {
  interpolateColor,
  useAnimatedStyle,
  useSharedValue,
  withSpring,
} from 'react-native-reanimated';
import { BlurView } from 'expo-blur';
import { LinearGradient } from 'expo-linear-gradient';
import { SymbolView } from 'expo-symbols';
import { Ionicons } from '@expo/vector-icons';
import { useColors } from '../../constants/colors';
import { impactLightHaptic, selectionHaptic } from '../../lib/haptics';

type IoniconName = React.ComponentProps<typeof Ionicons>['name'];
type SymbolName = React.ComponentProps<typeof SymbolView>['name'];

function springConfig() {
  return {
    damping: 22,
    stiffness: 260,
    mass: 0.8,
  } as const;
}

function textTracking(size: number) {
  if (size >= 34) return -0.5;
  if (size >= 28) return -0.4;
  if (size >= 17) return -0.24;
  return -0.08;
}

export function AppIcon({
  symbol,
  fallback,
  size = 20,
  tintColor,
  selected,
  weight = 'semibold',
}: {
  symbol: SymbolName;
  fallback: IoniconName;
  size?: number;
  tintColor: string;
  selected?: boolean;
  weight?: React.ComponentProps<typeof SymbolView>['weight'];
}) {
  const scale = useSharedValue(1);

  useEffect(() => {
    scale.value = selected ? 0.92 : 1;
    scale.value = withSpring(selected ? 1.08 : 1, springConfig());
  }, [scale, selected]);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));

  return (
    <Animated.View style={animatedStyle}>
      {Platform.OS === 'ios' ? (
        <SymbolView
          name={symbol}
          size={size}
          tintColor={tintColor}
          type="hierarchical"
          weight={weight}
          fallback={<Ionicons name={fallback} size={size} color={tintColor} />}
        />
      ) : (
        <Ionicons name={fallback} size={size} color={tintColor} />
      )}
    </Animated.View>
  );
}

export function GlassSurface({
  children,
  style,
  radius = 22,
  intensity = 46,
  tint,
}: {
  children?: React.ReactNode;
  style?: StyleProp<ViewStyle>;
  radius?: number;
  intensity?: number;
  tint?: React.ComponentProps<typeof BlurView>['tint'];
}) {
  const C = useColors();
  const surfaceTint = tint ?? (C.isDark ? 'systemChromeMaterialDark' : 'systemChromeMaterialLight');

  return (
    <View
      style={[
        {
          borderRadius: radius,
          overflow: 'hidden',
          borderCurve: 'continuous',
          backgroundColor: Platform.OS === 'ios' ? 'transparent' : C.surface,
        },
        style,
      ]}
    >
      {Platform.OS === 'ios' ? (
        <BlurView
          intensity={intensity}
          tint={surfaceTint}
          style={StyleSheet.absoluteFill}
        />
      ) : (
        <View style={[StyleSheet.absoluteFill, { backgroundColor: C.surface }]} />
      )}
      <LinearGradient
        colors={[C.glassHighlight, 'transparent']}
        start={{ x: 0.5, y: 0 }}
        end={{ x: 0.5, y: 1 }}
        style={[StyleSheet.absoluteFill, { opacity: 0.22 }]}
      />
      <View
        pointerEvents="none"
        style={[
          StyleSheet.absoluteFill,
          {
            borderRadius: radius,
            borderCurve: 'continuous',
            borderWidth: 1,
            borderColor: C.glassBorder,
          },
        ]}
      />
      {children}
    </View>
  );
}

export function GlassSheet({
  children,
  style,
}: {
  children: React.ReactNode;
  style?: StyleProp<ViewStyle>;
}) {
  return (
    <GlassSurface radius={28} intensity={80} style={style}>
      {children}
    </GlassSurface>
  );
}

export function PressScale({
  children,
  onPress,
  style,
  disabled,
  haptic = true,
}: {
  children: React.ReactNode;
  onPress?: () => void;
  style?: StyleProp<ViewStyle>;
  disabled?: boolean;
  haptic?: boolean;
}) {
  const scale = useSharedValue(1);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));

  return (
    <Pressable
      disabled={disabled}
      onPressIn={() => {
        scale.value = withSpring(0.96, springConfig());
      }}
      onPressOut={() => {
        scale.value = withSpring(1, springConfig());
      }}
      onPress={() => {
        if (haptic) selectionHaptic();
        onPress?.();
      }}
    >
      <Animated.View style={[style, animatedStyle]}>{children}</Animated.View>
    </Pressable>
  );
}

export function AppCard({
  children,
  style,
  intensity = 46,
}: {
  children: React.ReactNode;
  style?: StyleProp<ViewStyle>;
  intensity?: number;
}) {
  const C = useColors();
  return (
    <GlassSurface
      intensity={intensity}
      style={[
        {
          borderRadius: 22,
          shadowColor: C.isDark ? '#000000' : '#1B2547',
          shadowOpacity: C.isDark ? 0.28 : 0.12,
          shadowRadius: 24,
          shadowOffset: { width: 0, height: 12 },
          elevation: 8,
        },
        style,
      ]}
    >
      {children}
    </GlassSurface>
  );
}

const AVATAR_PALETTE = ['#6A74FF', '#8F83FF', '#31C48D', '#46B5FF', '#EC4899', '#F59E0B', '#14B8A6'];

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
  const fontSize = Math.round(size * 0.34);

  return (
    <GlassSurface radius={size / 2} intensity={72} style={{ width: size, height: size }}>
      <LinearGradient
        colors={[bg, `${bg}CC`]}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={StyleSheet.absoluteFill}
      />
      <View style={styles.centerFill}>
        <Text
          style={{
            fontSize,
            lineHeight: fontSize + 2,
            color: '#FFFFFF',
            fontWeight: '800',
            letterSpacing: -0.3,
            textAlign: 'center',
          }}
        >
          {initials(name || 'U')}
        </Text>
      </View>
    </GlassSurface>
  );
}

export function IconBadge({
  label,
  tone = 'primary',
  size = 34,
}: {
  label: string;
  tone?: 'primary' | 'secondary' | 'success' | 'warning' | 'danger';
  size?: number;
}) {
  const C = useColors();
  const tones = {
    primary: { tint: C.primary, fill: `${C.primary}20` },
    secondary: { tint: C.secondary, fill: `${C.secondary}1E` },
    success: { tint: C.success, fill: `${C.success}20` },
    warning: { tint: C.warning, fill: `${C.warning}20` },
    danger: { tint: C.danger, fill: `${C.danger}20` },
  } as const;
  const { tint, fill } = tones[tone];

  return (
    <GlassSurface radius={Math.round(size * 0.34)} intensity={42} style={{ width: size, height: size }}>
      <View style={[styles.centerFill, { backgroundColor: fill }]}>
        <Text
          style={{
            color: tint,
            fontSize: Math.max(11, Math.round(size * 0.32)),
            fontWeight: '800',
            letterSpacing: -0.18,
          }}
        >
          {label}
        </Text>
      </View>
    </GlassSurface>
  );
}

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
    <View style={{ flexDirection: 'row', alignItems: 'flex-end', marginBottom: 16 }}>
      <View style={{ flex: 1 }}>
        <Text
          style={{
            fontSize: 28,
            fontWeight: '800',
            letterSpacing: textTracking(28),
            color: C.textPrimary,
          }}
        >
          {title}
        </Text>
        {subtitle ? (
          <Text
            style={{
              marginTop: 4,
              fontSize: 15,
              fontWeight: '500',
              letterSpacing: textTracking(15),
              color: C.textSecondary,
            }}
          >
            {subtitle}
          </Text>
        ) : null}
      </View>
      {actionLabel && onAction ? (
        <PressScale onPress={onAction}>
          <Text style={{ fontSize: 15, fontWeight: '600', color: C.primary }}>{actionLabel}</Text>
        </PressScale>
      ) : null}
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
  const C = useColors();
  const isDisabled = Boolean(disabled || loading);

  return (
    <PressScale
      onPress={() => {
        impactLightHaptic();
        onPress();
      }}
      disabled={isDisabled}
      style={isDisabled ? { opacity: 0.58 } : undefined}
    >
      <GlassSurface
        intensity={52}
        radius={18}
        style={{
          height: 56,
          shadowColor: C.primary,
          shadowOpacity: isDisabled ? 0 : 0.28,
          shadowRadius: 22,
          shadowOffset: { width: 0, height: 10 },
          elevation: isDisabled ? 0 : 8,
        }}
      >
        <LinearGradient
          colors={[C.gradientBrandStart, C.gradientBrandEnd]}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={StyleSheet.absoluteFill}
        />
        <LinearGradient
          colors={[C.glassHighlight, 'transparent']}
          start={{ x: 0.5, y: 0 }}
          end={{ x: 0.5, y: 1 }}
          style={[StyleSheet.absoluteFill, { opacity: 0.18 }]}
        />
        <View style={styles.centerFill}>
          {loading ? (
            <ActivityIndicator color={C.onGradient} />
          ) : (
            <Text
              style={{
                color: C.onGradient,
                fontSize: 17,
                fontWeight: '700',
                letterSpacing: textTracking(17),
              }}
            >
              {title}
            </Text>
          )}
        </View>
      </GlassSurface>
    </PressScale>
  );
}

export function GlassTextInput({
  style,
  focusedStyle,
  inputStyle,
  onFocus,
  onBlur,
  ...props
}: TextInputProps & {
  style?: StyleProp<ViewStyle>;
  focusedStyle?: StyleProp<ViewStyle>;
  inputStyle?: StyleProp<TextStyle>;
}) {
  const C = useColors();
  const [focused, setFocused] = useState(false);
  const glow = useSharedValue(0);

  useEffect(() => {
    glow.value = withSpring(focused ? 1 : 0, springConfig());
  }, [focused, glow]);

  const animatedStyle = useAnimatedStyle(() => ({
    shadowColor: C.primary,
    shadowOpacity: glow.value * (C.isDark ? 0.26 : 0.18),
    shadowRadius: 18,
    shadowOffset: { width: 0, height: 8 },
    borderColor: interpolateColor(glow.value, [0, 1], [C.glassBorder, C.primary]),
  }));

  return (
    <Animated.View
      style={[
        animatedStyle,
        {
          borderWidth: 1,
          borderRadius: 18,
          borderCurve: 'continuous',
          overflow: 'hidden',
        },
        style,
        focused ? focusedStyle : undefined,
      ]}
    >
      <GlassSurface intensity={42} radius={18}>
        <TextInput
          {...props}
          onFocus={(event) => {
            setFocused(true);
            onFocus?.(event);
          }}
          onBlur={(event) => {
            setFocused(false);
            onBlur?.(event);
          }}
          placeholderTextColor={props.placeholderTextColor ?? C.placeholder}
          style={[
            {
              color: C.textPrimary,
              fontSize: 17,
              fontWeight: '500',
              letterSpacing: textTracking(17),
              paddingHorizontal: 16,
              paddingVertical: 14,
              minHeight: 54,
            },
            inputStyle,
          ]}
        />
      </GlassSurface>
    </Animated.View>
  );
}

export function SpringSegmentedControl<T extends string>({
  options,
  value,
  onChange,
  style,
}: {
  options: readonly { value: T; label: string }[];
  value: T;
  onChange: (value: T) => void;
  style?: StyleProp<ViewStyle>;
}) {
  const C = useColors();
  const [width, setWidth] = useState(0);
  const segmentWidth = width > 0 ? width / options.length : 0;
  const selectedIndex = Math.max(
    0,
    options.findIndex((option) => option.value === value)
  );
  const x = useSharedValue(0);

  useEffect(() => {
    x.value = withSpring(segmentWidth * selectedIndex, springConfig());
  }, [segmentWidth, selectedIndex, x]);

  const indicatorStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: x.value }],
  }));

  return (
    <GlassSurface
      radius={18}
      intensity={54}
      style={[{ padding: 4 }, style]}
    >
      <View onLayout={(event) => setWidth(event.nativeEvent.layout.width)} style={{ flexDirection: 'row' }}>
        {segmentWidth > 0 ? (
          <Animated.View
            pointerEvents="none"
            style={[
              indicatorStyle,
              {
                position: 'absolute',
                left: 0,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                padding: 0,
              },
            ]}
          >
            <GlassSurface intensity={64} radius={14} style={{ flex: 1, backgroundColor: C.fillTertiary }} />
          </Animated.View>
        ) : null}
        {options.map((option) => {
          const active = option.value === value;
          return (
            <PressScale
              key={option.value}
              onPress={() => onChange(option.value)}
              style={{ flex: 1 }}
            >
              <View
                style={{
                  alignItems: 'center',
                  justifyContent: 'center',
                  minHeight: 40,
                  paddingHorizontal: 12,
                }}
              >
                <Text
                  style={{
                    color: active ? C.textPrimary : C.textSecondary,
                    fontSize: 15,
                    fontWeight: active ? '700' : '500',
                    letterSpacing: textTracking(15),
                  }}
                >
                  {option.label}
                </Text>
              </View>
            </PressScale>
          );
        })}
      </View>
    </GlassSurface>
  );
}

const styles = StyleSheet.create({
  centerFill: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
