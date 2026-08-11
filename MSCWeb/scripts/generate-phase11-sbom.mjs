import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const webRoot = new URL("../", import.meta.url).pathname;
const dependencyTree = JSON.parse(
  execFileSync("corepack", ["pnpm", "list", "--prod", "--json", "--depth", "Infinity"], {
    cwd: webRoot,
    encoding: "utf8",
  }),
)[0];
const packages = new Map();

function collect(dependencies = {}) {
  for (const dependency of Object.values(dependencies)) {
    let metadata = {};
    try {
      metadata = JSON.parse(readFileSync(join(dependency.path, "package.json"), "utf8"));
    } catch {
      // Missing metadata remains explicit in the generated inventory.
    }
    const name = dependency.name ?? metadata.name ?? "unknown-package";
    const version = dependency.version ?? metadata.version ?? "0.0.0-unknown";
    const key = `${name}@${version}`;
    if (!packages.has(key)) {
      const license = typeof metadata.license === "string" ? metadata.license : "NOASSERTION";
      packages.set(key, { license, name, version });
    }
    collect(dependency.dependencies);
  }
}
collect(dependencyTree.dependencies);

const lockDigest = createHash("sha256")
  .update(readFileSync(join(webRoot, "pnpm-lock.yaml")))
  .digest("hex");
const spdxPackages = [...packages.values()]
  .sort((left, right) =>
    `${left.name}@${left.version}`.localeCompare(`${right.name}@${right.version}`),
  )
  .map((entry, index) => ({
    SPDXID: `SPDXRef-Package-${index + 1}`,
    downloadLocation: "NOASSERTION",
    externalRefs: [
      {
        referenceCategory: "PACKAGE-MANAGER",
        referenceLocator: `pkg:npm/${encodeURIComponent(entry.name)}@${entry.version}`,
        referenceType: "purl",
      },
    ],
    filesAnalyzed: false,
    licenseConcluded: "NOASSERTION",
    licenseDeclared: entry.license,
    name: entry.name,
    versionInfo: entry.version,
  }));
const document = {
  SPDXID: "SPDXRef-DOCUMENT",
  creationInfo: {
    created: "2026-08-11T00:00:00Z",
    creators: ["Tool: MSCWeb scripts/generate-phase11-sbom.mjs"],
  },
  dataLicense: "CC0-1.0",
  documentNamespace: `https://msc.invalid/spdx/phase11/${lockDigest}`,
  name: "MSCWeb Phase 11 production dependency inventory",
  packages: spdxPackages,
  relationships: spdxPackages.map((entry) => ({
    relatedSpdxElement: entry.SPDXID,
    relationshipType: "DESCRIBES",
    spdxElementId: "SPDXRef-DOCUMENT",
  })),
  spdxVersion: "SPDX-2.3",
};
writeFileSync(
  join(webRoot, "docs/security/PHASE_11_SPDX_SBOM.json"),
  `${JSON.stringify(document, null, 2)}\n`,
);
console.log(`SPDX SBOM Phase 11: ${spdxPackages.length} paket production.`);
