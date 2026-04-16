import { useColorScheme } from 'react-native';

const lightPalette = {
  // Brand
  primary: '#6366F1',
  primaryDark: '#4F46E5',
  secondary: '#8B5CF6',
  primaryLight: '#EEF2FF',
  danger: '#EF4444',
  warning: '#F59E0B',
  success: '#10B981',
  info: '#38BDF8',

  // Gradients
  gradientBrandStart: '#6366F1',
  gradientBrandEnd: '#8B5CF6',
  gradientOceanStart: '#3BBDF9',
  gradientOceanEnd: '#6366F1',

  // Risk
  riskLow: '#10B981',
  riskMedium: '#F59E0B',
  riskHigh: '#EF4444',

  // Surfaces
  white: '#FFFFFF',
  background: '#F4F6FB',
  surface: 'rgba(255,255,255,0.82)',
  surfaceMuted: 'rgba(255,255,255,0.64)',
  surfaceSecondary: 'rgba(247,249,255,0.74)',
  border: 'rgba(99,102,241,0.16)',
  glassBorder: 'rgba(255,255,255,0.6)',
  glassOverlay: 'rgba(255,255,255,0.42)',
  navGlass: 'rgba(255,255,255,0.74)',
  separator: 'rgba(60,60,67,0.12)',

  // Text
  textPrimary: '#12131A',
  textSecondary: '#6B7280',
  textMuted: '#9CA3AF',
  placeholder: '#C7C7CC',

  // Mood
  moodGreat: '#22C55E',
  moodGood: '#84CC16',
  moodOkay: '#F59E0B',
  moodBad: '#F97316',
  moodTerrible: '#EF4444',
};

const darkPalette = {
  // Brand (slightly brighter for dark bg)
  primary: '#7C7FF7',
  primaryDark: '#6366F1',
  secondary: '#A78BFA',
  primaryLight: '#1E1B4B',
  danger: '#FF6B6B',
  warning: '#FBBF24',
  success: '#34D399',
  info: '#60BDFF',

  // Gradients (same — brand gradient works on dark)
  gradientBrandStart: '#6366F1',
  gradientBrandEnd: '#8B5CF6',
  gradientOceanStart: '#3BBDF9',
  gradientOceanEnd: '#6366F1',

  // Risk
  riskLow: '#34D399',
  riskMedium: '#FBBF24',
  riskHigh: '#FF6B6B',

  // Surfaces
  white: '#1C1C1E',
  background: '#000000',
  surface: 'rgba(28,28,30,0.74)',
  surfaceMuted: 'rgba(28,28,30,0.62)',
  surfaceSecondary: 'rgba(44,44,46,0.7)',
  border: 'rgba(124,127,247,0.28)',
  glassBorder: 'rgba(255,255,255,0.14)',
  glassOverlay: 'rgba(255,255,255,0.08)',
  navGlass: 'rgba(28,28,30,0.78)',
  separator: 'rgba(84,84,88,0.65)',

  // Text
  textPrimary: '#FFFFFF',
  textSecondary: '#ABABAB',
  textMuted: '#636366',
  placeholder: '#636366',

  // Mood
  moodGreat: '#34D399',
  moodGood: '#A3E635',
  moodOkay: '#FBBF24',
  moodBad: '#FB923C',
  moodTerrible: '#FF6B6B',
};

export type AppColors = typeof lightPalette;

/** Static light-mode palette — backward-compat for module-level StyleSheet.create */
export const Colors: AppColors = lightPalette;

/** Reactive hook — returns dark or light palette based on system appearance */
export function useColors(): AppColors {
  const scheme = useColorScheme();
  return scheme === 'dark' ? (darkPalette as AppColors) : lightPalette;
}
