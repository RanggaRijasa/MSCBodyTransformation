export type PublicProgramSource = Readonly<{
  id: string;
  title: string;
  scheduleLabel: string;
  summary: string;
  privateEnrollmentCount?: number;
}>;

export type PublicCoachSource = Readonly<{
  id: string;
  displayName: string;
  publicSummary: string;
  isApproved: boolean;
  isVisible: boolean;
  privateEmail?: string;
}>;

export type PublicProgramTeaser = Readonly<{
  id: string;
  scheduleLabel: string;
  summary: string;
  title: string;
}>;

export type PublicCoachTeaser = Readonly<{
  displayName: string;
  id: string;
  publicSummary: string;
}>;

export function allowPublicProgram(source: PublicProgramSource): PublicProgramTeaser {
  return {
    id: source.id,
    scheduleLabel: source.scheduleLabel,
    summary: source.summary,
    title: source.title,
  };
}

export function allowPublicCoach(source: PublicCoachSource): PublicCoachTeaser | undefined {
  if (!source.isApproved || !source.isVisible) return undefined;
  return {
    displayName: source.displayName,
    id: source.id,
    publicSummary: source.publicSummary,
  };
}
