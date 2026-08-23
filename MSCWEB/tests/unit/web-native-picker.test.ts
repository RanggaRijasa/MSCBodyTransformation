import { describe, expect, it, vi } from 'vitest';

import { openWebNativePicker } from '../../src/features/admin/web-native-picker';

describe('web native date picker', () => {
  it('explicitly opens the browser picker for an enabled control', () => {
    const showPicker = vi.fn();

    expect(openWebNativePicker({ disabled: false, showPicker })).toBe(true);
    expect(showPicker).toHaveBeenCalledOnce();
  });

  it('does not open a disabled control', () => {
    const showPicker = vi.fn();

    expect(openWebNativePicker({ disabled: true, showPicker })).toBe(false);
    expect(showPicker).not.toHaveBeenCalled();
  });

  it('keeps the native fallback usable when showPicker is absent or rejected', () => {
    expect(openWebNativePicker({ disabled: false })).toBe(false);
    expect(openWebNativePicker({
      disabled: false,
      showPicker: () => { throw new Error('not_allowed'); },
    })).toBe(false);
  });
});
