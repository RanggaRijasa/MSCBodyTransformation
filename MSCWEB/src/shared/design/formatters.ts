const INDONESIAN_LOCALE = 'id-ID';

export const numberFormatter = new Intl.NumberFormat(INDONESIAN_LOCALE);
export const percentFormatter = new Intl.NumberFormat(INDONESIAN_LOCALE, {
  style: 'percent',
  maximumFractionDigits: 1,
});
export const rupiahFormatter = new Intl.NumberFormat(INDONESIAN_LOCALE, {
  style: 'currency',
  currency: 'IDR',
  maximumFractionDigits: 0,
});
export const weightFormatter = new Intl.NumberFormat(INDONESIAN_LOCALE, {
  minimumFractionDigits: 0,
  maximumFractionDigits: 1,
});
export const dateFormatter = new Intl.DateTimeFormat(INDONESIAN_LOCALE, {
  day: 'numeric',
  month: 'long',
  year: 'numeric',
  timeZone: 'Asia/Makassar',
});

export function formatWeight(kilograms: number): string {
  return `${weightFormatter.format(kilograms)} kg`;
}
