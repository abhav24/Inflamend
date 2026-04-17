import { useColorScheme } from 'react-native';

const lightPalette = {
  isDark: false,

  // Brand
  primary: '#5A67F5',
  primaryDark: '#4350E8',
  secondary: '#8D8AF8',
  primaryLight: '#EEF1FF',
  danger: '#F25F5C',
  warning: '#F4A62A',
  success: '#31C48D',
  info: '#46B5FF',

  // Gradients
  gradientBrandStart: '#6A74FF',
  gradientBrandEnd: '#8F83FF',
  gradientOceanStart: '#67D3FF',
  gradientOceanEnd: '#6174FF',
  meshStart: '#FCFBF7',
  meshEnd: '#E6EBFF',
  meshAccent: '#F4E7FF',

  // Risk
  riskLow: '#31C48D',
  riskMedium: '#F4A62A',
  riskHigh: '#F25F5C',

  // Surfaces
  white: '#FFFFFF',
  background: '#F5F5FA',
  surface: 'rgba(255,255,255,0.74)',
  surfaceMuted: 'rgba(255,255,255,0.58)',
  surfaceSecondary: 'rgba(246,248,255,0.66)',
  border: 'rgba(89,104,245,0.14)',
  glassBorder: 'rgba(255,255,255,0.56)',
  glassOverlay: 'rgba(255,255,255,0.34)',
  glassHighlight: 'rgba(255,255,255,0.75)',
  navGlass: 'rgba(255,255,255,0.8)',
  separator: 'rgba(60,60,67,0.18)',
  fillTertiary: 'rgba(255,255,255,0.34)',
  fillQuaternary: 'rgba(255,255,255,0.18)',
  scrim: 'rgba(0,0,0,0.28)',
  onGradient: '#FFFFFF',

  // Text
  textPrimary: '#151824',
  textSecondary: '#697284',
  textMuted: '#98A0B0',
  placeholder: '#A7AFBF',

  // Mood
  moodGreat: '#22C55E',
  moodGood: '#84CC16',
  moodOkay: '#F59E0B',
  moodBad: '#F97316',
  moodTerrible: '#EF4444',
};

const darkPalette = {
  isDark: true,

  // Brand
  primary: '#7D86FF',
  primaryDark: '#6470FF',
  secondary: '#A39DFF',
  primaryLight: '#1C2346',
  danger: '#FF7672',
  warning: '#FFC453',
  success: '#47D9A1',
  info: '#6BC9FF',

  // Gradients
  gradientBrandStart: '#707BFF',
  gradientBrandEnd: '#9B8FFF',
  gradientOceanStart: '#58C9FF',
  gradientOceanEnd: '#6270FF',
  meshStart: '#05060B',
  meshEnd: '#101633',
  meshAccent: '#1B1440',

  // Risk
  riskLow: '#47D9A1',
  riskMedium: '#FFC453',
  riskHigh: '#FF7672',

  // Surfaces
  white: '#FFFFFF',
  background: '#06070D',
  surface: 'rgba(17,20,30,0.74)',
  surfaceMuted: 'rgba(22,25,36,0.6)',
  surfaceSecondary: 'rgba(30,34,48,0.68)',
  border: 'rgba(125,134,255,0.18)',
  glassBorder: 'rgba(255,255,255,0.14)',
  glassOverlay: 'rgba(255,255,255,0.08)',
  glassHighlight: 'rgba(255,255,255,0.08)',
  navGlass: 'rgba(10,12,20,0.82)',
  separator: 'rgba(84,84,88,0.42)',
  fillTertiary: 'rgba(255,255,255,0.12)',
  fillQuaternary: 'rgba(255,255,255,0.08)',
  scrim: 'rgba(0,0,0,0.55)',
  onGradient: '#FFFFFF',

  // Text
  textPrimary: '#F8F9FF',
  textSecondary: '#B0B8CB',
  textMuted: '#7D8597',
  placeholder: '#697285',

  // Mood
  moodGreat: '#34D399',
  moodGood: '#A3E635',
  moodOkay: '#FBBF24',
  moodBad: '#FB923C',
  moodTerrible: '#FF6B6B',
};

export type AppColors = typeof lightPalette;

export const Colors: AppColors = lightPalette;

export function useColors(): AppColors {
  const scheme = useColorScheme();
  return scheme === 'dark' ? (darkPalette as AppColors) : lightPalette;
}
