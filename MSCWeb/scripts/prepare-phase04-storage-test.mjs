import { readFile, writeFile } from "node:fs/promises";

const [sourcePath, destinationPath] = process.argv.slice(2);
if (!sourcePath || !destinationPath) {
  throw new Error("source dan destination test SQL wajib diisi");
}

const source = await readFile(sourcePath, "utf8");
const originalAssertion = `select extensions.is(
  (
    select count(*)::bigint
    from storage.objects
    where bucket_id = 'question-photos'
  ),
  1::bigint,
  'Admin can read private question media'
);`;
const isolatedAssertion = `select extensions.ok(
  (
    select exists (
      select 1
      from storage.objects
      where bucket_id = 'question-photos'
        and name = '00000000-0000-0000-0000-000000000011/'
          || '50000000-0000-0000-0000-000000000001/'
          || '60000000-0000-0000-0000-000000000001/'
          || '40000000-0000-0000-0000-000000000001/'
          || '90000000-0000-0000-0000-000000000001.jpg'
    )
  ),
  'Admin can read the private question media created by this transaction'
);`;

if (!source.includes(originalAssertion)) {
  throw new Error("assertion upstream berubah; audit isolasi Phase 04 wajib diperbarui");
}

await writeFile(destinationPath, source.replace(originalAssertion, isolatedAssertion), {
  encoding: "utf8",
  flag: "w",
  mode: 0o600,
});
