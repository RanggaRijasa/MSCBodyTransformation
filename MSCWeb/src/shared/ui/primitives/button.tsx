import { cva, type VariantProps } from "class-variance-authority";
import type { ComponentProps } from "react";

import { cn } from "@/shared/ui/lib/cn";

export const buttonVariants = cva(
  "inline-flex min-h-11 min-w-11 appearance-none items-center justify-center gap-2 whitespace-normal rounded-control border-2 border-transparent px-4 py-2 text-center text-sm font-bold leading-tight transition-colors focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-ring/50 disabled:pointer-events-none disabled:opacity-60",
  {
    defaultVariants: {
      size: "default",
      variant: "primary",
    },
    variants: {
      size: {
        default: "min-h-11",
        icon: "size-11 min-h-11 min-w-11 rounded-full p-0",
      },
      variant: {
        accent:
          "bg-achievement text-achievement-foreground hover:bg-achievement/90 active:bg-achievement/85",
        destructive:
          "bg-destructive text-destructive-foreground hover:bg-destructive/90 active:bg-destructive/85",
        primary: "bg-primary text-primary-foreground hover:bg-primary/90 active:bg-primary/85",
        secondary:
          "border-primary bg-card text-primary hover:bg-muted hover:text-foreground active:bg-muted/80",
      },
    },
  },
);

export type ButtonProperties = ComponentProps<"button"> & VariantProps<typeof buttonVariants>;

export function Button({ className, size, variant, ...properties }: ButtonProperties) {
  return (
    <button
      className={cn(buttonVariants({ size, variant }), className)}
      data-slot="button"
      {...properties}
    />
  );
}
