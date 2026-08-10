import Image from "next/image";

import { AppIcon } from "@/shared/ui/icons/app-icon";

type MediaSurfaceProperties = Readonly<{
  alt: string;
  aspect?: "landscape" | "portrait" | "square";
  src?: string;
}>;

export function MediaSurface({ alt, aspect = "landscape", src }: MediaSurfaceProperties) {
  return (
    <figure className={`media-surface media-surface--${aspect}`}>
      {src ? (
        <Image alt={alt} fill sizes="(max-width: 768px) 100vw, 680px" src={src} unoptimized />
      ) : (
        <div aria-label={alt} className="media-surface__placeholder" role="img">
          <AppIcon name="content" />
        </div>
      )}
    </figure>
  );
}

export function MediaSkeleton({ label }: Readonly<{ label: string }>) {
  return <div aria-label={label} className="media-skeleton" role="status" />;
}
