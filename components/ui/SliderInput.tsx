import React, { useRef, useCallback } from 'react';
import {
  View,
  Text,
  PanResponder,
  StyleSheet,
  GestureResponderEvent,
  PanResponderGestureState,
} from 'react-native';
import { Colors } from '../../constants/colors';

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
  const trackWidth = useRef<number>(0);
  const startX = useRef<number>(0);
  const startValue = useRef<number>(value);

  const clamp = useCallback(
    (v: number) => Math.min(max, Math.max(min, v)),
    [min, max]
  );

  const valueFromX = useCallback(
    (x: number): number => {
      if (trackWidth.current === 0) return value;
      const ratio = x / trackWidth.current;
      const raw = min + ratio * (max - min);
      return clamp(Math.round(raw));
    },
    [min, max, value, clamp]
  );

  const panResponder = useRef(
    PanResponder.create({
      onStartShouldSetPanResponder: () => true,
      onMoveShouldSetPanResponder: () => true,
      onPanResponderGrant: (
        evt: GestureResponderEvent,
        _gs: PanResponderGestureState
      ) => {
        startX.current = evt.nativeEvent.locationX;
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
    })
  ).current;

  // Reattach grant so startValue is always current
  const panResponderLive = PanResponder.create({
    onStartShouldSetPanResponder: () => true,
    onMoveShouldSetPanResponder: () => true,
    onPanResponderGrant: (
      evt: GestureResponderEvent,
      _gs: PanResponderGestureState
    ) => {
      startX.current = evt.nativeEvent.locationX;
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

  const thumbLeft =
    max === min ? 0 : ((value - min) / (max - min)) * (trackWidth.current || 0) - 12;

  return (
    <View
      style={styles.container}
      accessibilityLabel={accessibilityLabel ?? label}
    >
      <View style={styles.labelRow}>
        <Text style={styles.label}>{label}</Text>
        {showValue && (
          <View style={styles.valueBadge}>
            <Text style={styles.valueText}>{value}</Text>
          </View>
        )}
      </View>
      <View style={styles.row}>
        <Text style={styles.minMax}>{min}</Text>
        <View
          style={styles.trackContainer}
          onLayout={(e) => {
            trackWidth.current = e.nativeEvent.layout.width;
          }}
          {...panResponderLive.panHandlers}
          accessible={false}
        >
          {/* Full track */}
          <View style={styles.track}>
            {/* Filled portion */}
            <View
              style={[
                styles.trackFill,
                { width: `${fillPercent}%` },
              ]}
            />
          </View>
          {/* Thumb */}
          <View
            style={[
              styles.thumb,
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
        <Text style={styles.minMax}>{max}</Text>
      </View>
    </View>
  );
}

const THUMB_SIZE = 24;

const styles = StyleSheet.create({
  container: {
    marginBottom: 16,
  },
  labelRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 10,
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    color: Colors.textPrimary,
    flex: 1,
  },
  valueBadge: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: Colors.primary,
    justifyContent: 'center',
    alignItems: 'center',
    marginLeft: 8,
  },
  valueText: {
    fontSize: 14,
    fontWeight: '700',
    color: Colors.white,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  minMax: {
    fontSize: 12,
    color: Colors.textSecondary,
    minWidth: 16,
    textAlign: 'center',
  },
  trackContainer: {
    flex: 1,
    height: THUMB_SIZE + 8,
    justifyContent: 'center',
  },
  track: {
    height: 6,
    backgroundColor: Colors.border,
    borderRadius: 3,
    overflow: 'hidden',
  },
  trackFill: {
    height: '100%',
    backgroundColor: Colors.primary,
    borderRadius: 3,
  },
  thumb: {
    position: 'absolute',
    width: THUMB_SIZE,
    height: THUMB_SIZE,
    borderRadius: THUMB_SIZE / 2,
    backgroundColor: Colors.white,
    borderWidth: 2.5,
    borderColor: Colors.primary,
    shadowColor: '#000',
    shadowOpacity: 0.15,
    shadowRadius: 4,
    shadowOffset: { width: 0, height: 2 },
    elevation: 3,
    top: (6 - THUMB_SIZE) / 2 + (THUMB_SIZE + 8 - 6) / 2 - THUMB_SIZE / 2,
  },
});
