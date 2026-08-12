import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./tests/development",
  fullyParallel: false,
  reporter: process.env.CI ? "dot" : "list",
  use: {
    baseURL: "http://127.0.0.1:4174",
    locale: "id-ID",
    trace: "retain-on-first-failure",
  },
  webServer: {
    command: "vite --config development/roles.vite.config.ts",
    url: "http://127.0.0.1:4174",
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    { name: "webkit", use: { ...devices["Desktop Safari"] } },
  ],
});
