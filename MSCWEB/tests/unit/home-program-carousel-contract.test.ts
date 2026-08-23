import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

const homeRoute = readFileSync('src/app/app/home.tsx', 'utf8');

describe('home program carousel contract', () => {
  it('uses horizontal scrolling without redundant navigation controls', () => {
    expect(homeRoute).toContain('accessibilityLabel="Program yang diikuti"');
    expect(homeRoute).toContain('horizontal');
    expect(homeRoute).not.toContain('Program sebelumnya');
    expect(homeRoute).not.toContain('Program berikutnya');
    expect(homeRoute).not.toContain('carouselIndex');
    expect(homeRoute).not.toContain('carouselActions');
  });
});
