import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTypeScript from "eslint-config-next/typescript";

const supabaseRestrictions = {
  patterns: [
    {
      group: ["@supabase/*", "@/infrastructure/supabase/*"],
      message: "Akses Supabase hanya melalui repository/composition boundary.",
    },
  ],
};

export default defineConfig([
  ...nextVitals,
  ...nextTypeScript,
  {
    files: ["src/app/**/*.{ts,tsx}", "src/features/**/*.{ts,tsx}", "src/shared/**/*.{ts,tsx}"],
    rules: {
      "no-restricted-imports": ["error", supabaseRestrictions],
    },
  },
  {
    files: ["src/domain/**/*.{ts,tsx}"],
    rules: {
      "no-restricted-imports": [
        "error",
        {
          patterns: [
            ...supabaseRestrictions.patterns,
            {
              group: ["react", "react/*", "next", "next/*", "@/features/*"],
              message: "Domain harus portable dan bebas framework/provider.",
            },
          ],
        },
      ],
    },
  },
  globalIgnores([".next/**", "coverage/**", "playwright-report/**", "test-results/**"]),
]);
