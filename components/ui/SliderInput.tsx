import React, { useEffect, useRef, useState } from 'react';
import { LayoutChangeEvent, StyleSheet, Text, View } from 'react-native';
import Slider from '@react-native-community/slider';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
} from 'react-native-reanimated';
import { LinearGradient } from 'expo-linear-gradient';
import { GlassSurface } from './DesignPrimitives';
import { useColors } from '../../constants/colors';
import { selectionHaptic } from '../../lib/haptics';

interface SliderInputProps {
  label: string;
  value: number;
  min: number;
  max: number;
  onChange: (value: number) => void;
  showValue?: boolean;
  accessibilityLabel?: string;
}

export function SliderInput({
  label,
  value,
  min,
  max,
  onChange,
  showValue = true,
  accessibilityLabel,
}: SliderInputProps) {
  const C = useColors();
  const [trackWidth, setTrackWidth] = useState(0);
  const lastHapticValue = useRef(value);
  const bubbleLift = useSharedValue(0);

  useEffect(() => {
    bubbleLift.value = withSpring(0, {
      damping: 20,
      stiffness: 220,
      mass: 0.8,
    });
  }, [bubbleLift]);

  const thumbOffset = trackWidth > 0 ? ((value - min) / Math.max(max - min, 1)) * trackWidth : 0;

  const bubbleStyle = useAnimatedStyle(() => ({
    transform: [{ translateY: bubbleLift.value }],
    opacity: showValue ? 1 : 0,
  }));

  function handleTrackLayout(event: LayoutChangeEvent) {
    setTrackWidth(event.nativeEvent.layout.width);
  }

  return (
    <View style={{ marginBottom: 8 }} accessibilityLabel={accessibilityLabel ?? label}>
      <View style={styles.headerRow}>
        <Text style={{ fontSize: 15, fontWeight: '600', color: C.textPrimary, letterSpacing: -0.24 }}>
          {label}
        </Text>
        {showValue ? (
          <Animated.View style={bubbleStyle}>
            <GlassSurface radius={16} intensity={56} style={{ minWidth: 44, paddingHorizontal: 12, paddingVertical: 8 }}>
              <Text style={{ fontSize: 15, fontWeight: '700', color: C.onGradient, textAlign: 'center' }}>{value}</Text>
            </GlassSurface>
          </Animated.View>
        ) : null}
      </View>

      <View style={styles.sliderRow}>
        <Text style={[styles.boundaryLabel, { color: C.textSecondary }]}>{min}</Text>
        <View style={{ flex: 1 }} onLayout={handleTrackLayout}>
          <View
            pointerEvents="none"
            style={[
              styles.trackShell,
              {
                backgroundColor: C.fillQuaternary,
                borderColor: C.glassBorder,
              },
            ]}
          >
            <LinearGradient
              colors={[C.gradientBrandStart, C.gradientBrandEnd]}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 0 }}
              style={[
                styles.trackFill,
                {
                  width: `${((value - min) / Math.max(max - min, 1)) * 100}%`,
                },
              ]}
            />
          </View>

          <Animated.View
            pointerEvents="none"
            style={[
              styles.thumbOverlay,
              {
                left: Math.max(0, thumbOffset - 18),
              },
            ]}
          >
            <GlassSurface radius={18} intensity={70} style={styles.thumbGlass}>
              <LinearGradient
                colors={[C.glassHighlight, 'transparent']}
                start={{ x: 0.5, y: 0 }}
                end={{ x: 0.5, y: 1 }}
                style={StyleSheet.absoluteFill}
              />
            </GlassSurface>
          </Animated.View>

          <Slider
            minimumValue={min}
            maximumValue={max}
            step={1}
            value={value}
            minimumTrackTintColor="transparent"
            maximumTrackTintColor="transparent"
            thumbTintColor="transparent"
            tapToSeek
            style={styles.nativeSlider}
            onSlidingStart={() => {
              bubbleLift.value = withSpring(-10, {
                damping: 20,
                stiffness: 240,
                mass: 0.8,
              });
            }}
            onValueChange={(nextValue) => {
              const rounded = Math.round(nextValue);
              if (rounded !== lastHapticValue.current) {
                selectionHaptic();
                lastHapticValue.current = rounded;
              }
              onChange(rounded);
            }}
            onSlidingComplete={(nextValue) => {
              bubbleLift.value = withSpring(0, {
                damping: 20,
                stiffness: 220,
                mass: 0.8,
              });
              onChange(Math.round(nextValue));
            }}
          />
        </View>
        <Text style={[styles.boundaryLabel, { color: C.textSecondary }]}>{max}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  headerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 12,
    gap: 12,
  },
  sliderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  boundaryLabel: {
    width: 18,
    textAlign: 'center',
    fontSize: 12,
    fontWeight: '600',
  },
  trackShell: {
    position: 'absolute',
    top: 18,
    left: 0,
    right: 0,
    height: 8,
    borderRadius: 999,
    borderWidth: 1,
    overflow: 'hidden',
  },
  trackFill: {
    height: '100%',
    borderRadius: 999,
  },
  nativeSlider: {
    height: 44,
    marginHorizontal: -14,
  },
  thumbOverlay: {
    position: 'absolute',
    top: 3,
    width: 36,
    height: 36,
  },
  thumbGlass: {
    width: 36,
    height: 36,
    shadowColor: '#000000',
    shadowOpacity: 0.16,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 6 },
    elevation: 6,
  },
});
