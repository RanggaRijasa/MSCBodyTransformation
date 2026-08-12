import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

import { dateFormatter, formatWeight, numberFormatter, rupiahFormatter } from '@/shared/design/formatters';
import { breakpointTokens, componentTokens, darkSemanticTokens, lightSemanticTokens, primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { navigationByRole } from '@/shared/navigation/navigation-model';

describe('W01 design system contracts', () => {
  it('uses the specified responsive and interaction baselines', () => {
    expect(breakpointTokens).toEqual({ medium: 768, wide: 1200 });
    expect(componentTokens.minimumTouchTarget).toBe(44);
    expect(componentTokens.compactGutter).toBe(16);
    expect(typographyTokens.numericDisplay.fontVariant).toContain('tabular-nums');
  });

  it('keeps the web app palette bold and high-contrast', () => {
    expect(primitiveTokens.color.red).toBe('#D71920');
    expect(primitiveTokens.color.yellow).toBe('#FFD400');
    expect(lightSemanticTokens.background).toBe('#FFFFFF');
    expect(lightSemanticTokens.primaryText).toBe('#000000');
    expect(darkSemanticTokens.background).toBe('#000000');
    expect(darkSemanticTokens.primaryText).toBe('#FFFFFF');
  });

  it('formats product numbers with id-ID rather than manual decimal strings', () => {
    expect(numberFormatter.format(12_350)).toBe('12.350');
    expect(formatWeight(78.5)).toBe('78,5 kg');
    expect(rupiahFormatter.format(149_000)).toContain('149.000');
    expect(dateFormatter.format(new Date('2026-08-05T00:00:00+08:00'))).toContain('5 Agustus 2026');
  });

  it('preserves the exact role navigation destination sets', () => {
    expect(navigationByRole.guest.map(({ label }) => label)).toEqual(['Beranda', 'Program', 'Peringkat', 'Coach', 'Profil']);
    expect(navigationByRole.participant).toEqual(navigationByRole.guest);
    expect(navigationByRole.coach.map(({ label }) => label)).toEqual(['Dashboard', 'Program', 'Profil']);
    expect(navigationByRole.admin.map(({ label }) => label)).toEqual(['Dashboard', 'Program', 'Orang', 'Konten', 'Pengaturan']);
  });

  it('keeps all Phosphor imports behind MSCIcon', () => {
    const appShell = readFileSync('src/shared/navigation/AppShell.tsx', 'utf8');
    const primitives = readFileSync('src/shared/ui/primitives.tsx', 'utf8');
    const iconRegistry = readFileSync('src/shared/icons/MSCIcon.tsx', 'utf8');
    expect(appShell).not.toContain('phosphor-react-native');
    expect(primitives).not.toContain('phosphor-react-native');
    expect(iconRegistry).toContain('phosphor-react-native/src/icons/');
  });
});
