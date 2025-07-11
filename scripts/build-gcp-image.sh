#!/usr/bin/env bash
# Deterministically converts any rootfs tarball into .raw + .raw.tar.gz image suitable for GCP
# 
# Usage: ./scripts/build-gcp-image.sh path/to/rootfs.tar.gz [out_dir]
# If out_dir is omitted, ./out will be used.

set -euo pipefail
ROOTFS="${1:?Usage: $0 path/to/rootfs.tar.gz [out_dir]}"
OUTDIR="${2:-out}"

ROOTFS_DIR="$(cd "$(dirname "$ROOTFS")" && pwd)"
ROOTFS_NAME="$(basename "$ROOTFS")"

SOCK_GID=$(stat -c '%g' /var/run/docker.sock)

# Always rebuild the CLI wrapper image (cache-less)
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

docker build --no-cache -t cli-wrapper \
  -f docker/tdx-rootfs-builder/Dockerfile .


# Mount both repository and rootfs directory; provide named build context
# rootfs_ctx → /rootfs_ctx inside container

docker run --rm \
  --user "$(id -u):$(id -g)" --group-add "$SOCK_GID" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD":/work -w /work \
  -v "$ROOTFS_DIR":/rootfs_ctx:ro \
  cli-wrapper \
  buildx build --no-cache --pull \
    --build-context rootfs_ctx=/rootfs_ctx \
    --build-arg ROOTFS_NAME="$ROOTFS_NAME" \
    -f docker/gcp-image-builder/Dockerfile . \
    --target export \
    --output "type=local,dest=${OUTDIR}"


# Post-build sanity checks
RAW_IMG="${OUTDIR}/rootfs.raw"
RAW_GZ="${OUTDIR}/rootfs.raw.tar.gz"

if [[ -f "$RAW_IMG" && -f "$RAW_GZ" ]]; then
  echo "Build artifacts:"
  ls -lh "$RAW_IMG" "$RAW_GZ"
  echo "SHA256 checksums:"
  sha256sum "$RAW_IMG" "$RAW_GZ"
  # simple size sanity checks (>100MB raw, >10MB gz)
  RAW_SIZE=$(stat -c %s "$RAW_IMG")
  GZ_SIZE=$(stat -c %s "$RAW_GZ")
  if (( RAW_SIZE < 100000000 )); then
    echo "Error: rootfs.raw unexpectedly small (${RAW_SIZE} bytes)" >&2
    exit 1
  fi
  if (( GZ_SIZE < 10000000 )); then
    echo "Error: rootfs.raw.tar.gz unexpectedly small (${GZ_SIZE} bytes)" >&2
    exit 1
  fi
else
  echo "Error: Expected artifacts not found in $OUTDIR" >&2
  exit 1
fi