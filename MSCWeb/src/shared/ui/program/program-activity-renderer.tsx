import Link from "next/link";

import { Progress, StatusBadge, type StatusTone } from "@/shared/ui/status/status";
import { Surface } from "@/shared/ui/surfaces/surfaces";

export type ProgramActivityAudience = "participant" | "coach";

export type ProgramActivityStep = Readonly<{
  detail: string;
  href?: string;
  id: string;
  status: string;
  statusTone: StatusTone;
  title: string;
}>;

export type ProgramActivityDay = Readonly<{
  id: string;
  isFocused?: boolean;
  label: string;
  steps: readonly ProgramActivityStep[];
}>;

export type ProgramActivityModel = Readonly<{
  days: readonly ProgramActivityDay[];
  period: string;
  progress: number;
  title: string;
}>;

type ProgramActivityRendererProperties = Readonly<{
  audience: ProgramActivityAudience;
  model: ProgramActivityModel;
}>;

export function ProgramActivityRenderer({ audience, model }: ProgramActivityRendererProperties) {
  return (
    <div className="program-renderer" data-audience={audience}>
      <Surface className="program-renderer__header">
        <div aria-label="Cover program" className="program-renderer__cover" role="img" />
        <div>
          <p className="program-renderer__eyebrow">
            {audience === "participant" ? "Aktivitas program" : "Pemantauan program"}
          </p>
          <h2>{model.title}</h2>
          <p>{model.period}</p>
          <Progress label="Progres program" value={model.progress} />
        </div>
      </Surface>

      <section aria-labelledby="program-days-title">
        <h2 id="program-days-title">Hari program</h2>
        <div className="program-days">
          {model.days.map((day) => (
            <details className="program-day" key={day.id} open={day.isFocused}>
              <summary>
                <span>{day.label}</span>
                {day.isFocused ? <StatusBadge tone="info">Fokus</StatusBadge> : null}
              </summary>
              <div className="program-day__steps">
                {day.steps.map((step) => {
                  const content = (
                    <>
                      <span>
                        <strong>{step.title}</strong>
                        <span>{step.detail}</span>
                      </span>
                      <StatusBadge tone={step.statusTone}>{step.status}</StatusBadge>
                    </>
                  );
                  return step.href ? (
                    <Link className="program-step" href={step.href} key={step.id}>
                      {content}
                    </Link>
                  ) : (
                    <div className="program-step" key={step.id}>
                      {content}
                    </div>
                  );
                })}
              </div>
            </details>
          ))}
        </div>
      </section>
    </div>
  );
}
