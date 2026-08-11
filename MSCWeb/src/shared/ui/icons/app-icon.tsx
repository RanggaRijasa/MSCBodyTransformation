import type { SVGProps } from "react";

export type AppIconName =
  | "admin"
  | "back"
  | "check"
  | "chevron"
  | "close"
  | "coach"
  | "content"
  | "dashboard"
  | "error"
  | "filter"
  | "home"
  | "info"
  | "payment"
  | "people"
  | "person"
  | "program"
  | "ranking"
  | "settings"
  | "warning";

type AppIconProperties = Readonly<
  SVGProps<SVGSVGElement> & {
    name: AppIconName;
    variant?: "default" | "outline";
  }
>;

const paths: Record<AppIconName, string> = {
  admin:
    "M12 3 4 7v5c0 4.8 3.4 8.2 8 9 4.6-.8 8-4.2 8-9V7l-8-4Zm0 4.2 4 2V12c0 2.7-1.6 4.7-4 5.6C9.6 16.7 8 14.7 8 12V9.2l4-2Z",
  back: "m14.5 5-7 7 7 7",
  check: "m5 12 4 4L19 6",
  chevron: "m9 5 7 7-7 7",
  close: "M6 6l12 12M18 6 6 18",
  coach:
    "M12 3a4 4 0 1 0 0 8 4 4 0 0 0 0-8Zm-7 18c.5-4 3.1-6 7-6s6.5 2 7 6H5Zm14-10V8h-3V6h3V3h2v3h3v2h-3v3h-2Z",
  content:
    "M5 3h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2Zm1 14 3-4 2 2 3-4 4 6H6Z",
  dashboard: "M4 4h7v7H4V4Zm9 0h7v4h-7V4ZM4 13h7v7H4v-7Zm9-3h7v10h-7V10Z",
  error: "M12 3 2.8 20h18.4L12 3Zm0 5v6m0 3v.1",
  filter: "M4 6h16M7 12h10m-7 6h4",
  home: "m3 11 9-8 9 8v10h-6v-6H9v6H3V11Z",
  info: "M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20Zm0-11v6m0-10v.1",
  payment: "M3 6h18v12H3V6Zm0 4h18M7 15h4",
  people:
    "M8 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8Zm8-1a3 3 0 1 0 0-6m-14 17c.4-4.2 2.6-6 6-6s5.6 1.8 6 6H2Zm12-6c3.5.1 5.3 2 5.8 6H16",
  person: "M12 12a4.5 4.5 0 1 0 0-9 4.5 4.5 0 0 0 0 9Zm-8 9c.4-4.7 3.2-7 8-7s7.6 2.3 8 7H4Z",
  program: "M5 3h14v18H5V3Zm4 0v18m3-14h4m-4 4h4m-4 4h3",
  ranking: "M6 21v-8h4v8H6Zm8 0V9h4v12h-4ZM10 7l2-4 2 4-4 2-4-2 2-4 2 4Z",
  settings:
    "M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8Zm8.4 5.4 1.6 1.2-2 3.4-1.9-.8a8 8 0 0 1-2.1 1.2L15.8 21h-4l-.3-2.1a8 8 0 0 1-2.1-1.2l-1.9.8-2-3.4 1.6-1.2a8 8 0 0 1 0-2.5L5.5 10l2-3.4 1.9.8a8 8 0 0 1 2.1-1.2l.3-2.2h4l.3 2.2a8 8 0 0 1 2.1 1.2l1.9-.8 2 3.4-1.6 1.2a8 8 0 0 1 0 2.2Z",
  warning: "M12 3 2.8 20h18.4L12 3Zm0 5v6m0 3v.1",
};

const stroked = new Set<AppIconName>([
  "back",
  "check",
  "close",
  "error",
  "filter",
  "info",
  "warning",
]);

const outlinePaths: Partial<Record<AppIconName, string>> = {
  coach:
    "M15 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M8.5 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8M19 8v6M22 11h-6",
  dashboard: "M3 3h7v7H3V3Zm11 0h7v5h-7V3Zm0 9h7v9h-7v-9ZM3 14h7v7H3v-7Z",
  home: "m3 11 9-8 9 8v10h-6v-6H9v6H3V11Z",
  payment: "M12 16V4m-5 5 5-5 5 5M5 20h14",
  people:
    "M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75",
  program: "M9 5h6M9 12h6m-6 4h6M7 3h10a2 2 0 0 1 2 2v16H5V5a2 2 0 0 1 2-2Z",
  ranking: "M4 20v-7m6 7V8m6 12V4m6 16H2",
};

export function AppIcon({ name, variant = "default", ...properties }: AppIconProperties) {
  const path = variant === "outline" ? (outlinePaths[name] ?? paths[name]) : paths[name];
  const usesStroke = variant === "outline" || stroked.has(name);

  return (
    <svg
      aria-hidden="true"
      focusable="false"
      viewBox="0 0 24 24"
      {...properties}
      fill={usesStroke ? "none" : "currentColor"}
      stroke={usesStroke ? "currentColor" : "none"}
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth={usesStroke ? (variant === "outline" ? 1.8 : 2) : undefined}
    >
      <path d={path} />
    </svg>
  );
}
