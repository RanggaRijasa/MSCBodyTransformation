import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";

import "./globals.css";
import { SessionSynchronizer } from "@/features/auth/components/session-synchronizer";
import { PwaRuntimeProvider } from "@/features/pwa-runtime/components/pwa-runtime-provider";
import { getSiteOrigin } from "@/shared/config/site-url";

export const metadata: Metadata = {
  metadataBase: getSiteOrigin(),
  title: {
    default: "MSC Body Transformation",
    template: "%s · MSC Body Transformation",
  },
  description: "Program transformasi tubuh dengan aktivitas terarah dan dukungan Coach.",
  applicationName: "MSC Body Transformation",
  appleWebApp: {
    capable: true,
    statusBarStyle: "black-translucent",
    title: "MSC Body",
  },
  formatDetection: {
    telephone: false,
  },
  icons: {
    apple: "/icons/apple-touch-icon.png",
    icon: [
      { url: "/icons/favicon-32.png", sizes: "32x32", type: "image/png" },
      { url: "/icons/app-icon-192.png", sizes: "192x192", type: "image/png" },
      { url: "/icons/app-icon-512.png", sizes: "512x512", type: "image/png" },
    ],
  },
};

export const viewport: Viewport = {
  colorScheme: "light dark",
  viewportFit: "cover",
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#f7f7f8" },
    { media: "(prefers-color-scheme: dark)", color: "#0d0d0f" },
  ],
};

type RootLayoutProperties = Readonly<{
  children: ReactNode;
}>;

export default function RootLayout({ children }: RootLayoutProperties) {
  return (
    <html data-scroll-behavior="smooth" lang="id-ID">
      <body>
        <PwaRuntimeProvider>
          {children}
          <SessionSynchronizer />
        </PwaRuntimeProvider>
      </body>
    </html>
  );
}
