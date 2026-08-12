import { useWindowDimensions } from 'react-native';

import { classifyLayout, type LayoutClass } from '@/shared/design/responsive-layout';

export function useResponsiveLayout(): LayoutClass {
  const { width } = useWindowDimensions();
  return classifyLayout(width);
}
