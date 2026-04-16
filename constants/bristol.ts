export interface BristolType {
  scale: number;
  name: string;
  description: string;
  badge: string;
}

export const BRISTOL_TYPES: BristolType[] = [
  {
    scale: 1,
    name: 'Separate hard lumps',
    description: 'Hard to pass, like nuts',
  badge: 'T1',
  },
  {
    scale: 2,
    name: 'Lumpy sausage',
    description: 'Sausage-shaped but lumpy',
  badge: 'T2',
  },
  {
    scale: 3,
    name: 'Cracked sausage',
    description: 'Sausage with surface cracks',
  badge: 'T3',
  },
  {
    scale: 4,
    name: 'Smooth sausage',
    description: 'Smooth, soft — ideal',
  badge: 'T4',
  },
  {
    scale: 5,
    name: 'Soft blobs',
    description: 'Soft blobs with clear edges',
  badge: 'T5',
  },
  {
    scale: 6,
    name: 'Fluffy pieces',
    description: 'Fluffy with ragged edges, mushy',
  badge: 'T6',
  },
  {
    scale: 7,
    name: 'Watery',
    description: 'Entirely liquid, no solid pieces',
    badge: 'T7',
  },
];
