#!/usr/bin/env bash
# Build SnarkJS phase2 contribution standalone binary inside Docker,
# copy the resulting binary to bin/ and the SHA256 hash to /
set -euo pipefail

# Resolve repository root (script is in ./scripts)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="${SCRIPT_DIR%/scripts}"
DOCKER_CONTEXT="$REPO_ROOT/docker/snarkjs-binary-builder"
BIN_DIR="$REPO_ROOT/bin"
IMAGE_TAG="snarkjs-binary-builder:sea-$(date +%s)"
BINARY_NAME="snarkjs-contribute"

# Ensure bin directory exists
mkdir -p "$BIN_DIR"

printf "[1/4] 🐳 Building Docker image...\n"
docker build --no-cache --pull --platform linux/amd64 -t "$IMAGE_TAG" "$DOCKER_CONTEXT"

printf "[2/4] 📦 Creating temporary container...\n"
CID=$(docker create "$IMAGE_TAG")
trap 'docker rm -f "$CID" >/dev/null 2>&1 || true' EXIT

printf "[3/4] 📤 Extracting binary from container...\n"
docker cp "$CID":/snarkjs-contribute "$BIN_DIR/$BINARY_NAME"
chmod +x "$BIN_DIR/$BINARY_NAME"

echo "[4/4] 🔑 Generating SHA-256 checksum..."
(
  cd "$BIN_DIR"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$BINARY_NAME" | awk '{print $1}' > "$REPO_ROOT/$BINARY_NAME.sha256"
  else
    sha256sum "$BINARY_NAME" | awk '{print $1}' > "$REPO_ROOT/$BINARY_NAME.sha256"
  fi
)

printf "✅ Standalone binary written to %s\n" "$BIN_DIR/$BINARY_NAME"
printf "✅ SHA256 hash written to %s\n" "$REPO_ROOT/$BINARY_NAME.sha256"