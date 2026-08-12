import { breakpointTokens } from './tokens';

export type LayoutClass = 'compact' | 'medium' | 'wide';

export function classifyLayout(width: number): LayoutClass {
  if (width < breakpointTokens.medium) {
    return 'compact';
  }

  if (width < breakpointTokens.wide) {
    return 'medium';
  }

  return 'wide';
}
