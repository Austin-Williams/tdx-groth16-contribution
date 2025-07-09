#!/usr/bin/env bash
# build-tdx-docker-image.sh
# Build a Docker image from a rootfs tarball.
#
# Usage: ./scripts/build-tdx-image.sh
# This script always expects the Docker context at docker/tdx-image and outputs:
#   tdx-rootfs.tar.gz  – compressed root filesystem (exported from container)
set -euo pipefail

ROOTFS_TAR="tdx-rootfs.tar.gz"

# Target platform for reproducible builds (override by exporting PLATFORM before running)
PLATFORM=${PLATFORM:-linux/amd64}

# Remove any existing tarball to start clean
rm -f "$ROOTFS_TAR"
# Build StageX TDX image from scratch (no cache)
docker build --platform="$PLATFORM" --pull --no-cache -t tdx-image docker/tdx-image
# Export filesystem into temp dir
TMP_DIR=$(mktemp -d)
aCID=$(docker create --platform="$PLATFORM" tdx-image)
# extract into tmp
mkdir -p "$TMP_DIR/extract"
docker export "$aCID" | tar -C "$TMP_DIR/extract" -xf -
docker rm "$aCID"

# Repack the extracted rootfs deterministically using a slim Debian image (GNU tar present)
DEB_IMG="debian@sha256:6ac2c08566499cc2415926653cf2ed7c3aedac445675a013cc09469c9e118fdd"
docker run --platform="$PLATFORM" --rm -v "$TMP_DIR/extract":/data:ro "$DEB_IMG" \
  sh -c 'cd /data && tar --sort=name --mtime="@0" --owner=0 --group=0 --numeric-owner -cf - . | gzip -n' > "$ROOTFS_TAR"

rm -rf "$TMP_DIR"

echo "[build-tdx-docker-image] Created $ROOTFS_TAR ($(du -h "$ROOTFS_TAR" | cut -f1))"
