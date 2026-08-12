import type { ComponentProps } from "react";

import { cn } from "@/shared/ui/lib/cn";

export function Textarea({ className, ...properties }: ComponentProps<"textarea">) {
  return (
    <textarea
      className={cn(
        "flex min-h-28 w-full resize-y rounded-control border border-input bg-background px-3 py-2 text-base text-foreground shadow-control outline-none placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-4 focus-visible:ring-ring/30 disabled:cursor-not-allowed disabled:opacity-60 aria-invalid:border-destructive aria-invalid:ring-4 aria-invalid:ring-destructive/20",
        className,
      )}
      data-slot="textarea"
      {...properties}
    />
  );
}
