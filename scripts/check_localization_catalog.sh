#!/bin/sh

set -eu

catalog_path="${1:-MSCBodyTransformation/Resources/Localizable.xcstrings}"

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq diperlukan untuk memeriksa localization catalog." >&2
    exit 2
fi

if [ ! -f "$catalog_path" ]; then
    echo "Error: localization catalog tidak ditemukan: $catalog_path" >&2
    exit 2
fi

missing_keys="$(
    jq -r '
        .strings
        | to_entries[]
        | select(
            (.value.localizations.id.stringUnit.value // "")
            | length == 0
        )
        | select(
            .key
            | test("^[a-z][a-z0-9_-]*(\\.[a-z0-9_-]+)+$")
        )
        | .key
    ' "$catalog_path"
)"

if [ -n "$missing_keys" ]; then
    echo "Localization key berikut belum memiliki copy Bahasa Indonesia:" >&2
    echo "$missing_keys" >&2
    exit 1
fi

echo "Localization catalog valid: seluruh machine key memiliki copy Bahasa Indonesia."
