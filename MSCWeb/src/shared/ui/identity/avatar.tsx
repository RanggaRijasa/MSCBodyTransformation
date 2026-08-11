import Image from "next/image";

import { AppIcon } from "@/shared/ui/icons/app-icon";

type AvatarProperties = Readonly<{
  imageUrl?: string;
  name: string;
  size?: number;
}>;

export function Avatar({ imageUrl, name, size = 52 }: AvatarProperties) {
  return (
    <span
      aria-label={name}
      className="avatar"
      role="img"
      style={{ "--avatar-size": `${size}px` } as React.CSSProperties}
    >
      {imageUrl ? (
        <Image alt="" height={size} src={imageUrl} unoptimized width={size} />
      ) : (
        <AppIcon name="person" />
      )}
    </span>
  );
}
