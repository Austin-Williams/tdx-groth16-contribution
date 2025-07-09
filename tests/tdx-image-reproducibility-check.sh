#!/usr/bin/env bash
# tests/reproducibility.sh – verifies bit-for-bit reproducibility of build-tdx-image.sh
#
# Builds the image twice and compares SHA-256 digests of:
#   1. tdx-rootfs.tar.gz  (exported rootfs)
#   2. disk.raw           (ext4 disk image)
#   3. tdx-image.tar.gz   (final GCP upload package)
# Prints per-artefact result and exits non-zero on any mismatch.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

build_once() {
  echo "[repro-test] Running build-tdx-image.sh ($1) …" >&2
  ./scripts/build-tdx-image.sh >/dev/null
  # Capture SHA-256 of each artefact in fixed order
  sha256sum tdx-rootfs.tar.gz disk.raw tdx-image.tar.gz | awk '{print $1}' | paste -sd ' ' -
}

read -r root1 raw1 img1 <<< "$(build_once first)"
read -r root2 raw2 img2 <<< "$(build_once second)"

printf 'first  : %s %s %s\n' "$root1" "$raw1" "$img1"
printf 'second : %s %s %s\n' "$root2" "$raw2" "$img2"

ok=0
compare() {
  local a="$1" b="$2" label="$3"
  if [[ "$a" == "$b" ]]; then
    echo " ✔ $label reproducible"
  else
    echo " ✘ $label differs" >&2
    ok=1
  fi
}

compare "$root1" "$root2" "tdx-rootfs.tar.gz"
compare "$raw1"  "$raw2"  "disk.raw"
compare "$img1"  "$img2"  "tdx-image.tar.gz"

exit $ok
