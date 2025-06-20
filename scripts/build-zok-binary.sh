#!/usr/bin/env bash
# build-zok-binary.sh — Deterministically build the ZoKrates 0.8.8 linux/amd64 binary
#
# This script wraps our reproducible Dockerfile so that auditors can produce the
# exact same bit-for-bit ZoKrates binary that gets used in the tdx-guest image.
#
# 1. Builds the Docker image pinned in docker/zok-binary-builder/.
# 2. Extracts the compiled binary from the /out directory inside the image.
# 3. Writes the binary to bin/zokrates-0.8.8 (creating bin/ if necessary).
# 4. Computes and stores the SHA-256 sum alongside the binary.
#
# Requirements:
#   • Docker CLI & daemon available to current user
#   • ~4 GB free disk space for the build artefacts
#
# Usage:
# normal build:
#   ./scripts/build-zok-binary.sh
# override image tag:
#   IMAGE_TAG=my-tag ./scripts/build-zok-binary.sh
# override output dir:
#   OUTPUT_DIR=custom ./scripts/build-zok-binary.sh
#
set -euo pipefail

IMAGE_TAG="${IMAGE_TAG:-zokrates-build:0.8.8}"
DOCKERFILE_DIR="docker/zok-binary-builder"
BIN_OUTPUT_DIR="${BIN_OUTPUT_DIR:-bin}"
HASH_OUTPUT_DIR="${HASH_OUTPUT_DIR:-.}"
BINARY_NAME="zokrates-0.8.8"
DOCKER_BUILDKIT=1
COMPOSE_DOCKER_CLI_BUILD=1

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
mkdir -p "${BIN_OUTPUT_DIR}" "${HASH_OUTPUT_DIR}"
docker cp "${CID}:/out/zokrates" "${BIN_OUTPUT_DIR}/${BINARY_NAME}"

printf "[+] Binary copied to %s/%s\n" "${BIN_OUTPUT_DIR}" "${BINARY_NAME}"

echo "[+] Generating SHA-256 checksum..."
sha256sum "${BIN_OUTPUT_DIR}/${BINARY_NAME}" | awk '{print $1}' | tee "${HASH_OUTPUT_DIR}/${BINARY_NAME}.sha256"

echo "[✓] Build complete. Binary in ${BIN_OUTPUT_DIR}/; checksum stored in ${HASH_OUTPUT_DIR}/"
