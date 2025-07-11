#!/usr/bin/env bash
# Build reproducible TDX rootfs tarball using the Docker-CLI wrapper.
# Usage: ./scripts/build-rootfs-in-docker.sh [output_dir]
# If output_dir is omitted, ./out will be used.
set -euo pipefail

OUTPUT_DIR="${1:-out}"
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/rootfs.tar.gz"

# Ensure we run from repository root
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# Always rebuild the CLI wrapper image (cache-less)
docker build --no-cache -t cli-wrapper \
  -f docker/tdx-rootfs-builder/Dockerfile .

# Group ID that owns the Docker socket (usually the "docker" group)
SOCK_GID=$(stat -c '%g' /var/run/docker.sock)

# Run the build inside the minimal CLI wrapper, talking to host Docker daemon
docker run --rm \
	--user "$(id -u):$(id -g)" \
	--group-add "$SOCK_GID" \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-v "$PWD":/work -w /work \
	cli-wrapper \
	buildx build --no-cache --pull \
		-f docker/tdx-rootfs/Dockerfile docker/tdx-rootfs \
		--target export \
		--output "type=local,dest=${OUTPUT_DIR}"

# Post-build sanity checks
TARBALL="${OUTPUT_DIR}/rootfs.tar.gz"
if [[ ! -f "$TARBALL" ]]; then
  echo "❌ Expected tarball $TARBALL not found – build failed" >&2
  exit 1
fi
if [[ $(stat -c %s "$TARBALL") -lt 1024000 ]]; then
  echo "❌ Tarball looks too small – build likely failed" >&2
  exit 1
fi
gzip -t "$TARBALL" || { echo "❌ Gzip integrity test failed for $TARBALL" >&2; exit 1; }

# Calculate SHA-256 digest
if command -v sha256sum >/dev/null 2>&1; then
  SHA=$(sha256sum "$TARBALL" | cut -d' ' -f1)
else
  SHA=$(shasum -a 256 "$TARBALL" | cut -d' ' -f1)
fi

echo "✅ rootfs built successfully"
echo "   size=$(stat -c %s "$TARBALL") bytes"
echo "   sha256:$SHA"

