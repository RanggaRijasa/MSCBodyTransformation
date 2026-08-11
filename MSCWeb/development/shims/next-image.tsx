/* eslint-disable @next/next/no-img-element -- Shim khusus gallery Vite, bukan source production. */
import type { ImgHTMLAttributes } from "react";

type DevelopmentImageProperties = Readonly<
  Omit<ImgHTMLAttributes<HTMLImageElement>, "src"> & {
    alt: string;
    fill?: boolean;
    src: string;
    unoptimized?: boolean;
  }
>;

export default function DevelopmentImage({
  alt,
  fill,
  src,
  style,
  unoptimized: _unoptimized,
  ...properties
}: DevelopmentImageProperties) {
  void _unoptimized;

  return (
    <img
      {...properties}
      alt={alt}
      src={src}
      style={
        fill ? { ...style, height: "100%", inset: 0, position: "absolute", width: "100%" } : style
      }
    />
  );
}
