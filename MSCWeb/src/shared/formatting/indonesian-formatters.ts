const indonesianLocale = "id-ID";

export const formatNumber = new Intl.NumberFormat(indonesianLocale);

export const formatPercentage = new Intl.NumberFormat(indonesianLocale, {
  style: "percent",
  maximumFractionDigits: 1,
});

export const formatCurrencyIDR = new Intl.NumberFormat(indonesianLocale, {
  style: "currency",
  currency: "IDR",
  maximumFractionDigits: 0,
});

export const formatWeightKilograms = new Intl.NumberFormat(indonesianLocale, {
  minimumFractionDigits: 1,
  maximumFractionDigits: 2,
  style: "unit",
  unit: "kilogram",
  unitDisplay: "short",
});

export function createProgramDateFormatter(timeZone: string) {
  return new Intl.DateTimeFormat(indonesianLocale, {
    dateStyle: "long",
    timeZone,
  });
}

export function createProgramDateTimeFormatter(timeZone: string) {
  return new Intl.DateTimeFormat(indonesianLocale, {
    dateStyle: "medium",
    timeStyle: "short",
    timeZone,
  });
}

export function formatProgramDate(date: string, timeZone: string): string {
  return createProgramDateFormatter(timeZone).format(new Date(`${date}T12:00:00Z`));
}

export function programTimezoneLabel(timeZone: string): string {
  if (timeZone === "Asia/Jakarta") return "WIB";
  if (timeZone === "Asia/Makassar") return "WITA";
  if (timeZone === "Asia/Jayapura") return "WIT";
  return timeZone;
}
