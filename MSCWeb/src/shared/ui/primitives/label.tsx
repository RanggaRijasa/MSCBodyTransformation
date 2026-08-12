import type { ComponentProps } from "react";

import { cn } from "@/shared/ui/lib/cn";

export function Label({ className, ...properties }: ComponentProps<"label">) {
  return (
    <label
      className={cn("text-sm font-bold leading-none text-foreground", className)}
      data-slot="label"
      {...properties}
    />
  );
}
