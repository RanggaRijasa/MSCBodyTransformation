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

const dayFormatter = new Intl.DateTimeFormat(INDONESIAN_LOCALE, {
  day: 'numeric',
  timeZone: 'Asia/Makassar',
});

const dayMonthFormatter = new Intl.DateTimeFormat(INDONESIAN_LOCALE, {
  day: 'numeric',
  month: 'long',
  timeZone: 'Asia/Makassar',
});

export function formatProgramDateRange(startsOn: string, endsOn: string): string {
  const start = dateFromKey(startsOn);
  const end = dateFromKey(endsOn);
  const sameYear = start.getUTCFullYear() === end.getUTCFullYear();
  const sameMonth = sameYear && start.getUTCMonth() === end.getUTCMonth();

  if (startsOn === endsOn) return dateFormatter.format(start);
  if (sameMonth) return `${dayFormatter.format(start)}–${dateFormatter.format(end)}`;
  if (sameYear) return `${dayMonthFormatter.format(start)}–${dateFormatter.format(end)}`;
  return `${dateFormatter.format(start)}–${dateFormatter.format(end)}`;
}

export function formatWeight(kilograms: number): string {
  return `${weightFormatter.format(kilograms)} kg`;
}

function dateFromKey(value: string): Date {
  return new Date(`${value}T12:00:00Z`);
}
