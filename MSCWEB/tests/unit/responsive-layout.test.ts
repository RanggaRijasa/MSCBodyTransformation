import { describe, expect, it } from 'vitest';

import { classifyLayout } from '@/shared/design/responsive-layout';

describe('classifyLayout', () => {
  it('mempertahankan navigasi compact pada lebar 320 px', () => {
    expect(classifyLayout(320)).toBe('compact');
  });

  it('beralih pada batas medium dan wide yang stabil', () => {
    expect(classifyLayout(767)).toBe('compact');
    expect(classifyLayout(768)).toBe('medium');
    expect(classifyLayout(1199)).toBe('medium');
    expect(classifyLayout(1200)).toBe('wide');
  });
});
