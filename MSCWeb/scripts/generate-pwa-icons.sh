#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
  echo "Penggunaan: scripts/generate-pwa-icons.sh /path/to/source-1024.png" >&2
  exit 64
fi

source_icon="$1"
script_directory="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
project_directory="$(dirname -- "$script_directory")"
output_directory="$project_directory/public/icons"
maskable_source="$(mktemp /private/tmp/mscweb-maskable.XXXXXX.png)"

trap 'rm -f "$maskable_source"' EXIT

if [ ! -f "$source_icon" ]; then
  echo "Source icon tidak ditemukan: $source_icon" >&2
  exit 66
fi

mkdir -p "$output_directory"
sips -z 192 192 "$source_icon" --out "$output_directory/app-icon-192.png" >/dev/null
sips -z 512 512 "$source_icon" --out "$output_directory/app-icon-512.png" >/dev/null
sips -z 180 180 "$source_icon" --out "$output_directory/apple-touch-icon.png" >/dev/null
sips -z 410 410 "$source_icon" --out "$maskable_source" >/dev/null
sips -p 512 512 --padColor 000000 "$maskable_source" --out "$output_directory/app-icon-maskable-512.png" >/dev/null

echo "PWA icons dibuat di $output_directory"
