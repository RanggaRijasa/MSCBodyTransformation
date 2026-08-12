#!/bin/sh
set -eu

source_icon="assets/brand/AppIcon-Default.png"
output_directory="public/icons"
maskable_source="/private/tmp/mscweb-maskable-source-512.png"

mkdir -p "$output_directory"

sips -z 192 192 "$source_icon" --out "$output_directory/icon-192.png" >/dev/null
sips -z 512 512 "$source_icon" --out "$output_directory/icon-512.png" >/dev/null
sips -z 180 180 "$source_icon" --out "$output_directory/apple-touch-icon.png" >/dev/null
sips -z 48 48 "$source_icon" --out "$output_directory/favicon-48.png" >/dev/null
sips -z 32 32 "$source_icon" --out "$output_directory/favicon-32.png" >/dev/null
sips -z 16 16 "$source_icon" --out "$output_directory/favicon-16.png" >/dev/null

# A 288 px square fits within the mandatory 80%-diameter circular safe zone.
sips -z 288 288 "$source_icon" --out "$maskable_source" >/dev/null
sips -p 512 512 --padColor 000000 "$maskable_source" --out "$output_directory/icon-maskable-512.png" >/dev/null
sips -z 192 192 "$output_directory/icon-maskable-512.png" --out "$output_directory/icon-maskable-192.png" >/dev/null
