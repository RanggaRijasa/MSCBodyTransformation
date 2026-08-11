import Image from "next/image";

type BrandMarkProperties = Readonly<{
  compact?: boolean;
}>;

export function BrandMark({ compact = false }: BrandMarkProperties) {
  return (
    <span className="marketing-wordmark__content">
      <Image
        alt=""
        className="marketing-wordmark__icon"
        height={44}
        loading="eager"
        src="/icons/app-icon-192.png"
        width={44}
      />
      {compact ? null : <strong>Body Transformation</strong>}
    </span>
  );
}
