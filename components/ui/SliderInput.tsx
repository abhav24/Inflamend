import React, { useRef, useCallback } from 'react';
import {
  View,
  Text,
  PanResponder,
  GestureResponderEvent,
  PanResponderGestureState,
} from 'react-native';
import { useColors } from '../../constants/colors';

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
  const trackWidth = useRef<number>(0);
  const startValue = useRef<number>(value);

  const clamp = useCallback(
    (v: number) => Math.min(max, Math.max(min, v)),
    [min, max]
  );

  // Keep gesture handlers recreated with latest value/startValue.
  const panResponderLive = PanResponder.create({
    onStartShouldSetPanResponder: () => true,
    onMoveShouldSetPanResponder: () => true,
    onPanResponderGrant: (
      _evt: GestureResponderEvent,
      _gs: PanResponderGestureState
    ) => {
      startValue.current = value;
    },
    onPanResponderMove: (
      _evt: GestureResponderEvent,
      gs: PanResponderGestureState
    ) => {
      if (trackWidth.current === 0) return;
      const delta = gs.dx / trackWidth.current;
      const deltaValue = delta * (max - min);
      const newValue = clamp(Math.round(startValue.current + deltaValue));
      onChange(newValue);
    },
    onPanResponderRelease: (
      _evt: GestureResponderEvent,
      gs: PanResponderGestureState
    ) => {
      if (trackWidth.current === 0) return;
      const delta = gs.dx / trackWidth.current;
      const deltaValue = delta * (max - min);
      const newValue = clamp(Math.round(startValue.current + deltaValue));
      onChange(newValue);
    },
  });

  const fillPercent =
    max === min ? 0 : ((value - min) / (max - min)) * 100;

  return (
    <View
      style={{ marginBottom: 16 }}
      accessibilityLabel={accessibilityLabel ?? label}
    >
      <View style={{
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: 10,
      }}>
        <Text style={{ fontSize: 14, fontWeight: '600', color: C.textPrimary, flex: 1 }}>{label}</Text>
        {showValue && (
          <View style={{
            width: 36,
            height: 36,
            borderRadius: 18,
            backgroundColor: C.primary,
            justifyContent: 'center',
            alignItems: 'center',
            marginLeft: 8,
            borderWidth: 1,
            borderColor: C.glassBorder,
          }}>
            <Text style={{ fontSize: 14, fontWeight: '700', color: '#FFFFFF' }}>{value}</Text>
          </View>
        )}
      </View>
      <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
        <Text style={{ fontSize: 12, color: C.textSecondary, minWidth: 16, textAlign: 'center' }}>{min}</Text>
        <View
          style={{
            flex: 1,
            height: THUMB_SIZE + 8,
            justifyContent: 'center',
          }}
          onLayout={(e) => {
            trackWidth.current = e.nativeEvent.layout.width;
          }}
          {...panResponderLive.panHandlers}
          accessible={false}
        >
          {/* Full track */}
          <View style={{
            height: 6,
            backgroundColor: C.border,
            borderRadius: 3,
            overflow: 'hidden',
          }}>
            {/* Filled portion */}
            <View
              style={[
                {
                  height: '100%',
                  backgroundColor: C.primary,
                  borderRadius: 3,
                },
                { width: `${fillPercent}%` },
              ]}
            />
          </View>
          {/* Thumb */}
          <View
            style={[
              {
                position: 'absolute',
                width: THUMB_SIZE,
                height: THUMB_SIZE,
                borderRadius: THUMB_SIZE / 2,
                backgroundColor: C.surface,
                borderWidth: 2.5,
                borderColor: C.primary,
                shadowColor: '#000',
                shadowOpacity: 0.15,
                shadowRadius: 4,
                shadowOffset: { width: 0, height: 2 },
                elevation: 3,
                top: (6 - THUMB_SIZE) / 2 + (THUMB_SIZE + 8 - 6) / 2 - THUMB_SIZE / 2,
              },
              {
                left:
                  trackWidth.current > 0
                    ? ((value - min) / (max - min)) *
                        (trackWidth.current - 24)
                    : 0,
              },
            ]}
          />
        </View>
        <Text style={{ fontSize: 12, color: C.textSecondary, minWidth: 16, textAlign: 'center' }}>{max}</Text>
      </View>
    </View>
  );
}

const THUMB_SIZE = 24;
