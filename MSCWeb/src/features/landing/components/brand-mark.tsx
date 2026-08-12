import Image from "next/image";

type BrandMarkProperties = Readonly<{
  compact?: boolean;
  eager?: boolean;
}>;

export function BrandMark({ compact = false, eager = false }: BrandMarkProperties) {
  return (
    <span className="marketing-wordmark__content">
      <Image
        alt=""
        className="marketing-wordmark__icon"
        height={44}
        loading={eager ? "eager" : "lazy"}
        src="/icons/app-icon-192.png"
        width={44}
      />
      {compact ? null : <strong>Body Transformation</strong>}
    </span>
  );
}
