export type WebNativePickerControl = Readonly<{
  disabled: boolean;
  showPicker?: () => void;
}>;

export function openWebNativePicker(control: WebNativePickerControl): boolean {
  if (control.disabled || typeof control.showPicker !== 'function') return false;

  try {
    control.showPicker();
    return true;
  } catch {
    // The native input remains usable when a browser rejects showPicker().
    return false;
  }
}
