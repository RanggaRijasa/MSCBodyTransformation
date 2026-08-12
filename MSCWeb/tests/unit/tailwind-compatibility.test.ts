import { readFileSync } from "node:fs";
import { resolve } from "node:path";

import tailwindcss from "@tailwindcss/postcss";
import postcss from "postcss";
import { describe, expect, it } from "vitest";

type PackageManifest = Readonly<{
  scripts?: Readonly<Record<string, string>>;
  dependencies?: Readonly<Record<string, string>>;
  devDependencies?: Readonly<Record<string, string>>;
}>;

type ShadcnConfig = Readonly<{
  style: string;
  rsc: boolean;
  tsx: boolean;
  tailwind: Readonly<{
    config: string;
    css: string;
  }>;
  aliases: Readonly<Record<string, string>>;
  iconLibrary?: string;
}>;

const projectRoot = process.cwd();

function readProjectFile(path: string) {
  return readFileSync(resolve(projectRoot, path), "utf8");
}

function readJson<T>(path: string) {
  return JSON.parse(readProjectFile(path)) as T;
}

function escapeRegularExpression(value: string) {
  return value.replace(/[.*+?^${}()|[\]\\]/gu, "\\$&");
}

describe("Tailwind dan shadcn compatibility contract", () => {
  it("memakai Tailwind tanpa Preflight atau source non-production", () => {
    const css = readProjectFile("src/styles/tailwind-compatibility.css");

    expect(css).toContain("@layer theme, base, components, utilities;");
    expect(css).toContain('@import "tailwindcss/theme.css" layer(theme);');
    expect(css).toContain('@import "tailwindcss/utilities.css" layer(utilities) source(none);');
    expect(css).toContain('@source "../";');
    expect(css).not.toMatch(/@source\s+["'][^"']*(?:development|tests)[^"']*["']/u);
    expect(css).not.toMatch(/@import\s+["']tailwindcss["']/u);
    expect(css).not.toMatch(/preflight/iu);
    expect(css).not.toMatch(/shadcn\/tailwind\.css/iu);
    expect(css).not.toMatch(/(?:^|\s)(?::root|body|html)\s*\{/mu);
    expect(css).not.toContain("@layer base {");
  });

  it("mengompilasi entry nyata dan hanya menghasilkan utility literal", async () => {
    const entryPath = resolve(projectRoot, "src/styles/tailwind-compatibility.css");
    const literalSentinelUtility = "z-[117]";
    const dynamicForbiddenUtility = "z-[911]";
    const source = `${readProjectFile("src/styles/tailwind-compatibility.css")}\n@source inline("${literalSentinelUtility}");\n`;

    const result = await postcss([tailwindcss()]).process(source, { from: entryPath });

    expect(result.warnings()).toEqual([]);
    expect(result.css).toContain(".z-\\[117\\]");
    expect(result.css).not.toContain(".z-\\[911\\]");
    expect(result.css).not.toContain(dynamicForbiddenUtility);
    expect(result.css).not.toMatch(/(?:^|[}])\s*(?:html|body)\s*(?:,|\{)/mu);
    expect(result.css).not.toMatch(
      /\*[^{}]*\{[^{}]*(?:box-sizing|margin:\s*0|padding:\s*0|border:\s*0)/mu,
    );
    expect(result.css).not.toContain("box-sizing: border-box");
    expect(result.css).not.toContain("border: 0 solid");
  });

  it("mengunci Base UI, RSC, TypeScript, dan alias shared UI", () => {
    const config = readJson<ShadcnConfig>("components.json");

    expect(config).toMatchObject({
      style: "base-nova",
      rsc: true,
      tsx: true,
      tailwind: {
        config: "",
        css: "src/styles/tailwind-compatibility.css",
      },
      aliases: {
        components: "@/shared/ui",
        utils: "@/shared/ui/lib/cn",
        ui: "@/shared/ui/primitives",
        lib: "@/shared/ui/lib",
        hooks: "@/shared/ui/hooks",
      },
    });
    expect(config.iconLibrary).toBeUndefined();
  });

  it("mengunci dependency minimum pada versi exact", () => {
    const manifest = readJson<PackageManifest>("package.json");

    expect(manifest.scripts?.build).toBe("next build --webpack");
    expect(manifest.scripts?.verify).toContain("pnpm run build");
    expect(manifest.scripts?.verify).not.toMatch(/(?:^|&&\s*)next build(?:\s|&&|$)/u);
    expect(manifest.dependencies).toMatchObject({
      "@base-ui/react": "1.7.0",
      "class-variance-authority": "0.7.1",
      clsx: "2.1.1",
      "tailwind-merge": "3.6.0",
    });
    expect(manifest.devDependencies).toMatchObject({
      "@tailwindcss/postcss": "4.3.3",
      postcss: "8.5.26",
      tailwindcss: "4.3.3",
    });

    const forbiddenPackages = ["shadcn", "lucide-react", "tw-animate-css", "geist"];
    const directPackages = {
      ...manifest.dependencies,
      ...manifest.devDependencies,
    };
    const lock = readProjectFile("pnpm-lock.yaml");

    for (const packageName of forbiddenPackages) {
      expect(directPackages).not.toHaveProperty(packageName);
      const escapedName = escapeRegularExpression(packageName);
      expect(lock).not.toMatch(new RegExp(`(?:^|\\n) {6}${escapedName}:`, "u"));
      expect(lock).not.toMatch(new RegExp(`(?:^|\\n) {2}["']?${escapedName}@[^\\n]*:`, "u"));
    }
  });
});
