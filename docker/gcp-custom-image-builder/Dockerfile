# gcp-custom-image-builder – reproducible Stageˣ utility that converts a
# deterministic container rootfs tarball into `disk.raw` + `tdx-image.tar.gz`
# (Google Cloud custom-image format).
#
# Requirements at runtime (not build-time): run with --privileged so the loop
# device can be mounted.  Building the image itself needs no special
# entitlements.
#
# Stageˣ design: the final image is assembled from pre-built pallets, each pinned
# by SHA-256 digest, so the resulting filesystem and configuration are
# byte-for-byte reproducible.
#
# Placeholder digests (<sha256:…>) must be replaced with the actual digests in
# this repository’s lock file or via `docker buildx imagetools inspect`.
#
# Build:
#   docker build -t gcp-custom-image-builder docker/gcp-custom-image-builder
# Run (from repo root):
#   docker run --rm --privileged -v "$PWD":/io gcp-custom-image-builder \
#       /io/tdx-rootfs.tar.gz 512
# Produces /io/disk.raw and /io/tdx-image.tar.gz next to the input.

ARG STAGEX_BASE=stagex/core-filesystem@sha256:<digest-base>
ARG STAGEX_BUSYBOX=stagex/core-busybox@sha256:<digest-busybox>
ARG STAGEX_E2FSPROGS=stagex/user-e2fsprogs@sha256:<digest-e2fs>
ARG STAGEX_TAR=stagex/core-tar@sha256:<digest-tar>
ARG STAGEX_PLATFORM=linux/amd64

# ── import pallets ────────────────────────────────────────────────────────────
FROM --platform=$STAGEX_PLATFORM ${STAGEX_BUSYBOX} AS busybox
FROM --platform=$STAGEX_PLATFORM ${STAGEX_E2FSPROGS} AS e2fs
FROM --platform=$STAGEX_PLATFORM ${STAGEX_TAR} AS gnutar

# ── final minimal runtime image ───────────────────────────────────────────────
FROM --platform=$STAGEX_PLATFORM ${STAGEX_BASE}

ENV SOURCE_DATE_EPOCH=1 \
    TZ=UTC \
    LANG=C.UTF-8

# Bring in required binaries
COPY --from=busybox / /
COPY --from=e2fs / /
COPY --from=gnutar / /usr/bin/tar

# Clamp mtimes for determinism
RUN find / -xdev -exec touch -h -d "@1" {} + 2>/dev/null || true

# Add entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
