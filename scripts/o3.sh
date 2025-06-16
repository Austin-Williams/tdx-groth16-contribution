#!/usr/bin/env bash
# Helper script for offline, reproducible‐build investigation.
#
# It performs two independent steps and records *all* stdout/stderr in
#   ./o3.log
# so that the Codex assistant (which is sandboxed from Docker / network)
# can subsequently inspect the results.
#
# 1.  Download the official ZoKrates 0.8.8 release artefact, extract the binary
#     and show basic metadata (sha256, file(1), ldd, UPX test, ELF notes…).
# 2.  Invoke ./scripts/build.sh to build the binary from source via Docker.
#     If that build succeeds, it grabs the produced artefact from the image and
#     prints the same metadata, allowing an immediate diff.
#
# Any arguments you pass to this script will be forwarded to
#   ./scripts/build.sh
# unchanged, so you can force e.g. `--no-cache` or `--platform linux/amd64`.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )/.." && pwd)"
LOG_FILE="${ROOT_DIR}/o3.log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "========== o3 investigation run @ $(date -u +%Y-%m-%dT%H:%M:%SZ) =========="

# -----------------------------------------------------------------------------
# Step 1: Official artefact metadata
# -----------------------------------------------------------------------------

OFFICIAL_URL="https://github.com/Zokrates/ZoKrates/releases/download/0.8.8/zokrates-0.8.8-x86_64-unknown-linux-gnu.tar.gz"

TMPDIR=$(mktemp -d)
echo "\n--- Downloading official ZoKrates 0.8.8 binary ---"
curl -Ls "$OFFICIAL_URL" | tar -xz -C "$TMPDIR"

pushd "$TMPDIR" >/dev/null

echo "\n[official] sha256sum"
sha256sum zokrates || shasum -a 256 zokrates || true

echo "\n[official] file(1)"
file zokrates || true

echo "\n[official] ldd"
if command -v ldd >/dev/null 2>&1; then
  ldd zokrates || echo "(static binary)"
else
  echo "ldd not available"
fi

echo "\n[official] UPX test"
if command -v upx >/dev/null 2>&1; then
  upx -t zokrates 2>/dev/null || echo "not UPX‐compressed"
else
  echo "upx utility not installed"
fi

echo "\n[official] readelf --notes | head -20"
if command -v readelf >/dev/null 2>&1; then
  readelf --notes zokrates | head -n 20
else
  echo "readelf not installed"
fi

popd >/dev/null

# -----------------------------------------------------------------------------
# Step 2: Build from source via Docker and inspect
# -----------------------------------------------------------------------------

echo "\n--- Building Docker image via ./scripts/build.sh $* ---"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker CLI not present – skipping build step."
  exit 0
fi

BUILD_SHA=$("${ROOT_DIR}/scripts/build.sh" "$@" 2>&1 | tee /tmp/o3_build.log | tail -n 1)

echo "Build script reported digest: $BUILD_SHA"

# If the build failed (non-hex output, empty, or still reporting the official
# fallback hash) we stop here.
if [[ ! "$BUILD_SHA" =~ ^[a-f0-9]{64}$ ]]; then
  echo "Docker build appears to have failed (digest not captured)."
  exit 0
fi

# Attempt to copy the built binary out of the image for side-by-side comparison.

echo "\n--- Extracting built binary from image ---"

BIN_TMP=$(mktemp -d)

docker run --rm \
  --entrypoint /bin/sh \
  zokrates-repro:local -c "cat /src/target/release/zokrates" > "$BIN_TMP/zokrates" || {
    echo "Could not extract binary from image.";
    exit 0;
  }

cd "$BIN_TMP"

echo "\n[built] sha256sum"
sha256sum zokrates || shasum -a 256 zokrates || true

echo "\n[built] file(1)"
file zokrates || true

echo "\n[built] ldd"
if command -v ldd >/dev/null 2>&1; then
  ldd zokrates || echo "(static binary)"
else
  echo "ldd not available"
fi

echo "\n[built] UPX test"
if command -v upx >/dev/null 2>&1; then
  upx -t zokrates 2>/dev/null || echo "not UPX‐compressed"
else
  echo "upx utility not installed"
fi

echo "\n[built] readelf --notes | head -20"
if command -v readelf >/dev/null 2>&1; then
  readelf --notes zokrates | head -n 20
else
  echo "readelf not installed"
fi

# -----------------------------------------------------------------------------
# Step 3: Deep diff between official and built binaries (if available)
# -----------------------------------------------------------------------------

# Only proceed if both binaries exist (network may be disabled or build failed)
if [[ -f "${TMPDIR}/zokrates" && -f "${BIN_TMP}/zokrates" ]]; then
  DIFF_OUT="${ROOT_DIR}/bin-diff.txt"
  echo "\n--- Generating binary diff report at ${DIFF_OUT} ---"

  # pick any available readelf implementation
  pick_readelf() {
    if command -v readelf >/dev/null 2>&1; then
      echo readelf
    elif command -v greadelf >/dev/null 2>&1; then
      echo greadelf
    elif command -v llvm-readelf >/dev/null 2>&1; then
      echo llvm-readelf
    else
      echo false
    fi
  }

  READELF=$(pick_readelf)

  inspect() {
    local f="$1"
    local label="$2"
    echo "===== ${label} ====="
    (sha256sum "$f" 2>/dev/null || shasum -a 256 "$f")
    echo
    if [[ "$READELF" != "false" ]]; then
      echo "-- Build-ID --"
      $READELF -n "$f" | grep 'Build ID' || true
    fi
    echo "-- embedded rustc string --"
    strings "$f" | grep -m1 '^rustc ' || echo "(rustc version not found)"
    if [[ "$READELF" != "false" ]]; then
      echo "-- first 15 section headers --"
      $READELF -S "$f" | head -n 20
    fi
    echo
  }

  {
    inspect "${TMPDIR}/zokrates" "official";
    inspect "${BIN_TMP}/zokrates" "built";

    if [[ "$READELF" != "false" ]]; then
      echo "===== readelf -S diff ====="
      diff -u <($READELF -S "${TMPDIR}/zokrates") <($READELF -S "${BIN_TMP}/zokrates") || true
    fi
  } >"$DIFF_OUT" 2>&1

  echo "Binary diff written to $DIFF_OUT"
else
  echo "\nBinary diff skipped (missing binaries)"
fi

echo "\n========== investigation complete =========="