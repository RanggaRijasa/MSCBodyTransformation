import react from "@vitejs/plugin-react";
import { fileURLToPath, URL } from "node:url";
import { defineConfig } from "vite";

export default defineConfig({
  publicDir: fileURLToPath(new URL("../public", import.meta.url)),
  root: fileURLToPath(new URL("./roles", import.meta.url)),
  plugins: [react()],
  resolve: {
    alias: [
      {
        find: "next/link",
        replacement: fileURLToPath(new URL("./shims/next-link.tsx", import.meta.url)),
      },
      {
        find: "next/image",
        replacement: fileURLToPath(new URL("./shims/next-image.tsx", import.meta.url)),
      },
      {
        find: "next/navigation",
        replacement: fileURLToPath(new URL("./shims/next-navigation.ts", import.meta.url)),
      },
      {
        find: "@",
        replacement: fileURLToPath(new URL("../src", import.meta.url)),
      },
    ],
  },
  server: {
    host: "127.0.0.1",
    port: 4174,
    strictPort: true,
  },
});
