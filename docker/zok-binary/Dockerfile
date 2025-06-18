# ----------------------------------------------------------------------------
# Reproducible Zokrates 0.8.8 Builder Image
# ----------------------------------------------------------------------------
# This Dockerfile defines a minimal, deterministic environment for building the
# Zokrates 0.8.8 linux/amd64 binary.  It is deliberately simple so auditors can
# easily verify every step.
# ----------------------------------------------------------------------------
# Base image pinned by digest to ensure immutability.  Digest taken on
# 2025-06-16 via:
# $ docker pull rust:1.73.0-slim-bullseye
# $ docker inspect --format='{{index .RepoDigests 0}}' rust:1.73.0-slim-bullseye
# Update only with explicit commit review.

# rust:1.73.0-slim-bullseye SHA256 digest:
#   ARG BASE_IMAGE="rust@sha256:d641cda2c7add455eb7c565f99ca718b6e4f5c1246f2d75f15d7a2c2cc6c58da"
# ----------------------------------------------------------------------------
ARG BASE_IMAGE="rust@sha256:d641cda2c7add455eb7c565f99ca718b6e4f5c1246f2d75f15d7a2c2cc6c58da"
FROM ${BASE_IMAGE} AS builder

LABEL org.opencontainers.image.title="Zokrates-Builder"
LABEL org.opencontainers.image.version="0.8.8"
LABEL org.opencontainers.image.source="https://github.com/Zokrates/ZoKrates"
LABEL org.opencontainers.image.description="Deterministic build environment for Zokrates 0.8.8 linux/amd64 binary"

# ---------------------------------------------------------------------------
# Environment configuration
# ---------------------------------------------------------------------------
ENV DEBIAN_FRONTEND=noninteractive \
	# Normalize timestamps for deterministic builds
	SOURCE_DATE_EPOCH=1684155391 \
	# Ensure Cargo uses locked dependencies
	CARGO_PROFILE_RELEASE_DEBUG=false \
	# Debian snapshot timestamps (UTC, ISO-8601 basic)
	SNAPSHOT_TS=20230515T125631Z \
	# Security snapshot needs a different timestamp with valid Release file
	SNAPSHOT_SECURITY_TS=20230515T032833Z \
	# Disable ELF build-id to avoid host-dependent hash differences
	RUSTFLAGS="-C link-arg=-Wl,--build-id=none -C embed-bitcode=no" \
	# Disable incremental compilation
	CARGO_INCREMENTAL=0 \
	# Set single codegen unit
	CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1 \
	# Set single build job
	CARGO_BUILD_JOBS=1

WORKDIR /build

# ---------------------------------------------------------------------------
# Install minimal build tools (git, binutils, etc.) using a **frozen** Debian
# snapshot to guarantee identical package versions forever.  We swap the default
# mirrors for snapshot.debian.org at a fixed timestamp (SNAPSHOT_TS) so any
# future build resolves to the exact same .deb files.
# ---------------------------------------------------------------------------
RUN --mount=type=cache,target=/var/cache/apt bash -c "set -euo pipefail; \
	echo '=== Original sources.list ==='; \
	cat /etc/apt/sources.list; \
	sed -i 's|deb http://deb.debian.org/debian |deb https://snapshot.debian.org/archive/debian/${SNAPSHOT_TS} |g' /etc/apt/sources.list; \
	sed -i 's|deb http://deb.debian.org/debian-security |deb https://snapshot.debian.org/archive/debian-security/${SNAPSHOT_SECURITY_TS} |g' /etc/apt/sources.list; \
	echo '=== Modified sources.list ==='; \
	cat /etc/apt/sources.list; \
	apt-get -o Acquire::Check-Valid-Until=false update; \
	apt-get install -y --no-install-recommends git ca-certificates binutils gcc g++ libc6-dev make; \
	rm -rf /var/lib/apt/lists/*"

# ---------------------------------------------------------------------------
# Clone ZoKrates source (use exact commit for tag 0.8.8 as of June 16th 2025)
# We have to remove rust-toolchain and rust-toolchain.toml from the cloned repo
# because it overrides our pinned rust version and forces "latest" which breaks reproducibility.
# ---------------------------------------------------------------------------
ARG ZOKRATES_COMMIT=157a824426e213fbcd05c74220c706095be1ee7a
RUN git init . \
	&& git remote add origin https://github.com/Zokrates/ZoKrates.git \
	&& git fetch --depth 1 origin ${ZOKRATES_COMMIT} \
	&& git checkout --detach ${ZOKRATES_COMMIT} \
	&& rm -f rust-toolchain rust-toolchain.toml

# ---------------------------------------------------------------------------
# Compile ZoKrates
# ---------------------------------------------------------------------------
RUN --mount=type=cache,target=/root/.cargo/registry \
	--mount=type=cache,target=/root/.cargo/git \
	cargo build --release --locked

# ---------------------------------------------------------------------------
# Strip & copy binary
# ---------------------------------------------------------------------------
RUN strip --strip-all --preserve-dates target/release/zokrates && \
	objcopy --remove-section .note.gnu.build-id target/release/zokrates && \
	mkdir -p /out && \
	cp target/release/zokrates /out/

# Default command drops into shell with built binary available under /out
CMD ["bash"]
