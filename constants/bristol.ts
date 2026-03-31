export interface BristolType {
  scale: number;
  name: string;
  description: string;
  emoji: string;
}

export const BRISTOL_TYPES: BristolType[] = [
  {
    scale: 1,
    name: 'Separate hard lumps',
    description: 'Hard to pass, like nuts',
    emoji: '🪨',
  },
  {
    scale: 2,
    name: 'Lumpy sausage',
    description: 'Sausage-shaped but lumpy',
    emoji: '🌰',
  },
  {
    scale: 3,
    name: 'Cracked sausage',
    description: 'Sausage with surface cracks',
    emoji: '🌭',
  },
  {
    scale: 4,
    name: 'Smooth sausage',
    description: 'Smooth, soft — ideal',
    emoji: '✅',
  },
  {
    scale: 5,
    name: 'Soft blobs',
    description: 'Soft blobs with clear edges',
    emoji: '💧',
  },
  {
    scale: 6,
    name: 'Fluffy pieces',
    description: 'Fluffy with ragged edges, mushy',
    emoji: '🌊',
  },
  {
    scale: 7,
    name: 'Watery',
    description: 'Entirely liquid, no solid pieces',
    emoji: '💦',
  },
];
