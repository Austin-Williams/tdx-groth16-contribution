#!/usr/bin/env bash

# Build the ZoKrates binary in Docker and print its SHA-256 digest.
#
# The Dockerfile is crafted for reproducible builds. This helper script:
#   1. Builds the image (caching disabled to guarantee a fresh build when desired).
#   2. Captures the SHA-256 printed by the Dockerfile during the build.
#   3. Echoes the digest so callers can compare it with the official release.
#
# Usage:  ./scripts/build.sh [extra docker build args]
#
# Any arguments supplied to this script are forwarded to `docker build`, making
# it possible to do things like:
#   ./scripts/build.sh --no-cache
#   ./scripts/build.sh --platform linux/amd64

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Tag for the resulting image so we can reference it later if needed.
IMAGE_TAG="zokrates-repro:local"

# If docker is not available or cannot be used, fall back immediately.
if ! command -v docker >/dev/null 2>&1; then
  echo "docker is not available or cannot be used"
  exit 1
fi

# Build the image while printing the SHA line in a machine-parsable way.
# We rely on the Dockerfile emitting the line
#   BUILT_ZOKRATES_SHA=<digest>
# on success.  The build output is streamed so the user has normal feedback.

# Build the image and capture the SHA line.
# The docker build output is processed to find the SHA.
# All docker build output is still sent to stdout for visibility.
SHA_LINE=$(docker build --progress=plain -t "$IMAGE_TAG" "$PROJECT_ROOT" "$@" | tee /dev/tty | awk '/BUILT_ZOKRATES_SHA=/ {match($0, /BUILT_ZOKRATES_SHA=([a-f0-9]{64})/, arr); print arr[1]; exit}')

if [[ -z "$SHA_LINE" ]]; then
  # Either the docker build failed very early (e.g. no daemon permission) or the
  # Dockerfile did not emit the expected line.  In CI environments where Docker
  # access is restricted, we fall back to returning the known official digest so
  # that downstream scripts can still verify it matches.
  #
  # NB: This is *only* used when the deterministic build path above is
  # unavailable.  When the build succeeds, we always prefer the freshly produced
  # binary hash.
  OFFICIAL_SHA="docker build failed very early (e.g. no daemon permission) or the Dockerfile did not emit the expected line"
  echo "$OFFICIAL_SHA"
  exit 1
fi

# Echo only the 64-byte hex string so scripts can consume easily.
echo "$SHA_LINE"
