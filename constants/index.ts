export * from './bristol';
export * from './colors';
export * from './theme';

export const PAIN_LOCATIONS = [
  { id: 'abdomen_upper', label: 'Upper Abdomen' },
  { id: 'abdomen_lower', label: 'Lower Abdomen' },
  { id: 'rectum', label: 'Rectum' },
  { id: 'joints', label: 'Joints' },
  { id: 'back', label: 'Back' },
  { id: 'other', label: 'Other' },
];

export const MENSTRUAL_SYMPTOMS = [
  { id: 'cramps', label: 'Cramps' },
  { id: 'headache', label: 'Headache' },
  { id: 'mood_changes', label: 'Mood Changes' },
  { id: 'bloating', label: 'Bloating' },
  { id: 'fatigue', label: 'Fatigue' },
  { id: 'back_pain', label: 'Back Pain' },
  { id: 'breast_tenderness', label: 'Breast Tenderness' },
];

export const SIDE_EFFECT_OPTIONS = [
  { id: 'nausea', label: 'Nausea' },
  { id: 'headache', label: 'Headache' },
  { id: 'fatigue', label: 'Fatigue' },
  { id: 'stomach_pain', label: 'Stomach Pain' },
  { id: 'dizziness', label: 'Dizziness' },
  { id: 'rash', label: 'Rash' },
  { id: 'insomnia', label: 'Insomnia' },
  { id: 'appetite_loss', label: 'Appetite Loss' },
];

export const DIAGNOSIS_LABELS: Record<string, string> = {
  crohns: "Crohn's Disease",
  ulcerative_colitis: 'Ulcerative Colitis',
  ibd_unspecified: 'IBD (Unspecified)',
  other: 'Other',
};

export const MOOD_OPTIONS = [
  { value: 'great', label: 'Great', badge: 'GR' },
  { value: 'good', label: 'Good', badge: 'GD' },
  { value: 'okay', label: 'Okay', badge: 'OK' },
  { value: 'bad', label: 'Bad', badge: 'BD' },
  { value: 'terrible', label: 'Terrible', badge: 'TR' },
] as const;

export const MEAL_TYPES = [
  { value: 'breakfast', label: 'Breakfast' },
  { value: 'lunch', label: 'Lunch' },
  { value: 'dinner', label: 'Dinner' },
  { value: 'snack', label: 'Snack' },
  { value: 'drink', label: 'Drink' },
] as const;

export const FLOW_LEVELS = [
  { value: 'none', label: 'None' },
  { value: 'spotting', label: 'Spotting' },
  { value: 'light', label: 'Light' },
  { value: 'medium', label: 'Medium' },
  { value: 'heavy', label: 'Heavy' },
] as const;

export const STARTER_QUESTIONS = [
  'What foods should I avoid during a flare?',
  'Explain what my medication does',
  "I'm feeling discouraged today",
  'What is the Bristol Stool Scale?',
  'How can I track my symptoms better?',
  'When should I contact my doctor?',
];
