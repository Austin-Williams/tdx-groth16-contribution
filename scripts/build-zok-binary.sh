#!/usr/bin/env bash
# build-zok-binary.sh — Deterministically build the ZoKrates 0.8.8 linux/amd64 binary
#
# This script wraps our reproducible Dockerfile so that auditors can produce the
# exact same bit-for-bit binary that the project ships.
#
# 1. Builds the Docker image pinned in docker/zok-binary/.
# 2. Extracts the compiled binary from the /out directory inside the image.
# 3. Writes the binary to bin/zokrates-0.8.8 (creating bin/ if necessary).
# 4. Computes and stores the SHA-256 sum alongside the binary.
#
# Requirements:
#   • Docker CLI & daemon available to current user
#   • ~4 GB free disk space for the build artefacts
#
# Usage:
#   ./scripts/build-zok-binary.sh            # normal build
#   IMAGE_TAG=my-tag ./scripts/build-zok-binary.sh    # override image tag
#   OUTPUT_DIR=custom ./scripts/build-zok-binary.sh   # override output dir
#
set -euo pipefail

IMAGE_TAG="${IMAGE_TAG:-zokrates-build:0.8.8}"
DOCKERFILE_DIR="docker/zok-binary"
OUTPUT_DIR="${OUTPUT_DIR:-bin}"
BINARY_NAME="zokrates-0.8.8"

echo "[+] Building Docker image (${IMAGE_TAG})..."
docker build \
  --platform linux/amd64 \
  --no-cache \
  --pull \
  -t "$IMAGE_TAG" \
  "$DOCKERFILE_DIR"

echo "[+] Creating temporary container..."
CID=$(docker create "${IMAGE_TAG}")
trap 'docker rm -f "$CID" >/dev/null' EXIT

echo "[+] Extracting binary from container..."
mkdir -p "${OUTPUT_DIR}"
docker cp "${CID}:/out/zokrates" "${OUTPUT_DIR}/${BINARY_NAME}"

printf "[+] Binary copied to %s/%s\n" "${OUTPUT_DIR}" "${BINARY_NAME}"

echo "[+] Generating SHA-256 checksum…"
sha256sum "${OUTPUT_DIR}/${BINARY_NAME}" | tee "${OUTPUT_DIR}/${BINARY_NAME}.sha256"

echo "[✓] Build complete. Binary & checksum are ready in ${OUTPUT_DIR}/"
