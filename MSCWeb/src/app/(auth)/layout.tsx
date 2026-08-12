import type { Metadata } from "next";
import type { ReactNode } from "react";

import "@/features/auth/styles/auth.css";
import "@/features/device-media/styles/device-media.css";

export const metadata: Metadata = {
  robots: { follow: false, index: false },
};

export default function AuthenticationLayout({ children }: Readonly<{ children: ReactNode }>) {
  return children;
}
