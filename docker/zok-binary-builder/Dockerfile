# ----------------------------------------------------------------------------
# Reproducible Zokrates 0.8.8 Builder Image
# ----------------------------------------------------------------------------
# This Dockerfile defines a minimal, deterministic environment for building the
# Zokrates 0.8.8 linux/amd64 binary.  It is deliberately simple so auditors can
# easily verify every step.
# ----------------------------------------------------------------------------
# Base image pinned by digest to ensure immutability.  Digest taken on
# 2025-06-16 via:
# $ docker pull --platform=linux/amd64 stagex/pallet-rust:sx2025.06.0
# ----------------------------------------------------------------------------
ARG BASE_IMAGE="stagex/pallet-rust@sha256:740b9ed5f2a897d45cafdc806976d84231aa50a64998610750b42a48f8daacab"
FROM ${BASE_IMAGE} AS builder

# Build essentials – one line per pallet
COPY --from=stagex/pallet-gcc@sha256:415e04ee80c0fee389a25182ef3c32f319c1b70b833664d658249c88ee23175a /usr/ /usr/
COPY --from=stagex/make@sha256:ad81793d21d9778421925085c52734fdcca443957ade4f9bb80e4032b88252db /usr/ /usr/
COPY --from=stagex/curl@sha256:6566b4cc3148d450bc67980ef287751246ccb7c4cb3731f8e338014abda1449a /usr/ /usr/

# ---------------------------------------------------------------------------
# Environment configuration
# ---------------------------------------------------------------------------
ENV \
	# Pin locale
	LANG=C.UTF-8 \
	LC_ALL=C.UTF-8 \
	# Normalize timestamps
	SOURCE_DATE_EPOCH=1684155391 \
	# Pin timezone
	TZ=UTC \
	# Ensure Cargo uses locked dependencies
	CARGO_PROFILE_RELEASE_DEBUG=false \
	# Explicit Cargo directories for stability
	CARGO_HOME=/root/.cargo \
	CARGO_TARGET_DIR=/build/target \
	# Minimal, predictable PATH
	PATH="/usr/local/cargo/bin:/usr/local/bin:/usr/bin:/bin" \
	# Disable incremental compilation
	CARGO_INCREMENTAL=0 \
	# Set single codegen unit
	CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1 \
	# Set single build job
	CARGO_BUILD_JOBS=1 \
	# Ensure deterministic symbol / section order in GNU ld
	RUSTFLAGS="-C link-arg=-Wl,--build-id=none \
	-C embed-bitcode=no \
	-C link-arg=-Wl,--sort-common \
	-C link-arg=-Wl,--sort-section,alignment \
	--remap-path-prefix=/build=. \
	-C target-cpu=generic"

WORKDIR /build

# Set umask for consistent file permissions
RUN umask 022

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
RUN strip --strip-all --preserve-dates --enable-deterministic-archive target/release/zokrates && \
	objcopy --remove-section .note.gnu.build-id target/release/zokrates && \
	mkdir -p /out && \
	cp target/release/zokrates /out/ && \
	# Normalize file timestamps to SOURCE_DATE_EPOCH
	touch -d "@${SOURCE_DATE_EPOCH}" /out/zokrates

# Default command drops into shell with built binary available under /out
CMD ["bash"]
