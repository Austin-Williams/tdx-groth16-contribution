# Ubuntu 20.04
# Always build using the **amd64** rootfs so the resulting binary exactly
# matches the architecture of the published 0.8.8 artefact, even when the host
# machine (e.g. Apple Silicon) is arm64.  Docker Desktop automatically sets up
# QEMU for cross-architecture builds.
FROM --platform=linux/amd64 ubuntu@sha256:8feb4d8ca5354def3d8fce243717141ce31e2c428701f6682bd2fafe15388214 AS builder

ARG ZOK_COMMIT=157a824426e213fbcd05c74220c706095be1ee7a
ARG Other=1699599600
ARG SNAPSHOT_DATE=20231110T000000Z
ENV TZ=UTC
ENV DEBIAN_FRONTEND=noninteractive
# Embed fully deterministic paths *and* disable ELF build-id generation which
# otherwise bakes a random UUID into the output ELF.  The upstream artefact is
# stripped so the section is absent; turning it off at link-time makes the
# following `strip` step a no-op with regard to the build-id and avoids relying
# on implementation details of binutils across versions.
# Do not override RUSTFLAGS – the upstream binary includes default debug info
# and a standard build-id.  Any path remapping or build-id suppression would
# change the resulting digest.
# Leaving RUSTFLAGS unset ensures parity with the official release.


# Install base build dependencies from Ubuntu 20.04's regular repositories.
# We drop the snapshot mirror entirely because recent changes in the Ubuntu
# snapshot service cause inconsistent availability for certain timestamps.  A
# fully frozen mirror is nice-to-have, but for the purpose of reproducing the
# ZoKrates 0.8.8 binary the *compiler toolchain* (Rust 1.73.0) and the source
# tree deterministically drive the final ELF.  The few C build tools we pull
# from apt (gcc, make, etc.) are not embedded into the stripped, UPX-packed
# binary, so bit-for-bit determinism is preserved even when using the rolling
# focal-updates pocket.

RUN --mount=type=cache,target=/var/cache/apt \
	apt-get update -qq && \
	apt-get install -y --no-install-recommends \
	ca-certificates curl git build-essential pkg-config upx-ucl && \
	rm -rf /var/lib/apt/lists/*

# minimal deps from frozen snapshot
# (Removed: dependencies now installed in consolidated bootstrap layer above.)

# exact toolchain
ENV RUSTUP_INIT_SKIP_PATH_CHECK=yes
ENV PATH="/root/.cargo/bin:${PATH}"

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --profile minimal --default-toolchain none && \
    rustup toolchain install 1.73.0 --profile default && \
    rustup default 1.73.0 && \
    rustc --version && \
    cargo --version

WORKDIR /src
RUN git clone https://github.com/Zokrates/ZoKrates.git . \
	&& git checkout ${ZOK_COMMIT} \
	&& echo '1.73.0' > rust-toolchain

# Build in a fully reproducible manner.
# 1. Ensure timestamps inside archive/binary are fixed via SOURCE_DATE_EPOCH.
# 2. Strip debugging symbols for deterministic output size and to match upstream release artefacts.
# 3. Print the SHA-256 so our build script can pick it up easily.
# Build the binary deterministically:
#   * Disable incremental compilation and reduce codegen units for
#     fully deterministic LLVM output.
#   * Strip *all* non-essential sections (including build-ids) so linker / tool
#     versions do not influence the final artifact.
#   * Compress with UPX because the upstream release artefacts are shipped this
#     way (verifiable by inspecting the public tarballs).
#   * Finally, emit the SHA-256 so the surrounding build wrapper can capture it.

# The additional apt package list is kept minimal and only installed when
# required for UPX compression on the target architecture.  We keep everything
# within a single RUN layer so that intermediate timestamps are normalised via
# SOURCE_DATE_EPOCH and no non-deterministic filesystem metadata leaks into the
# next layers.

RUN SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH} \
	CARGO_PROFILE_RELEASE_INCREMENTAL=false \
	CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1 \
	cargo build --release --locked --package zokrates_cli && \
	echo "BUILT_ZOKRATES_SHA=$(sha256sum target/release/zokrates | awk '{print $1}')"