# Build SEA standalone binary for SnarkJS phase2 contribution

ARG STAGEX_PALLET_NODEJS=stagex/pallet-nodejs@sha256:07c6e3d54dfa7df17134ebab33310442adceeca1d980cbf7169a6f15737cd0e0
# Version-pinned Node source to build a fully-static binary deterministically
ARG NODE_VERSION=20.14.0
# SHA-256 of the official Node tarball for the above version. Update if NODE_VERSION changes.
ARG NODE_TARBALL_SHA256=08655028f0d8436e88163f9186044d635d3f36a85ee528f36bd05b6c5e46c1bb

FROM ${STAGEX_PALLET_NODEJS} AS builder
ARG NODE_VERSION
ARG NODE_TARBALL_SHA256
ENV SOURCE_DATE_EPOCH=1 \
    NODE_VERSION=${NODE_VERSION} \
    NODE_TARBALL_SHA256=${NODE_TARBALL_SHA256}
ENV NODE_ENV=production \
	TZ=UTC

WORKDIR /build

# -----------------------------------------------------------------------------
# Build a *fully static* Node.js (musl, no shared libs) in a deterministic way
# -----------------------------------------------------------------------------
# Bring in required build tools from minimal Stageˣ images to keep supply-chain
# provenance while avoiding a heavy pallet. We selectively copy only the
# binaries we need.

# Copy deterministic tool binaries
# BusyBox provides tar for extraction
COPY --from=stagex/core-busybox@sha256:cac5d773db1c69b832d022c469ccf5f52daf223b91166e6866d42d6983a3b374 /usr/bin/busybox /usr/bin/
# No curl needed - we'll COPY the tarball directly

COPY --from=stagex/core-make@sha256:d8730e484095283508cb7d3243b31068972d4879d26347f74d96742e416e5bdd /usr/bin/make /usr/bin/
COPY --from=stagex/core-gcc@sha256:125bd6306e7f37e57d377d5a189c0e499388aff42b22cc79acee6097357c617f /usr/bin/gcc /usr/bin/
# Copy binutils (includes assembler 'as', linker 'ld', etc required for Node compilation)
COPY --from=stagex/core-binutils@sha256:83c66e9d7393d7004442f8c1f2ad0f69979cc2a9193222338f4736abf17b6752 /usr/bin /usr/bin
# Copy musl libc and headers for static compilation
COPY --from=stagex/core-musl@sha256:d5f86324920cfc7fc34f0163502784b73161543ba0a312030a3ddff3ef8ab2f8 /usr/lib /usr/lib
COPY --from=stagex/core-musl@sha256:d5f86324920cfc7fc34f0163502784b73161543ba0a312030a3ddff3ef8ab2f8 /usr/include /usr/include
# Copy Linux kernel headers required by OpenSSL
COPY --from=stagex/core-linux-headers@sha256:3d0bc27681eb22c8346ecad67a8200bb5e427741f06ad6bfc4b7632604b5e818 /usr/include /usr/include
# Python is required for node-gyp; copy python binary and stdlib from core-python
COPY --from=stagex/core-python@sha256:17d634028c3ed31707aa492dc65dc15ac27bab197d08e447786b3b1e8c26df2c /usr/bin/python3 /usr/bin/
COPY --from=stagex/core-python@sha256:17d634028c3ed31707aa492dc65dc15ac27bab197d08e447786b3b1e8c26df2c /usr/lib /usr/lib

# Copy pre-downloaded Node.js tarball to avoid network issues in container
COPY node-v20.14.0.tar.xz /tmp/

WORKDIR /tmp/node-src
RUN echo "${NODE_TARBALL_SHA256}  /tmp/node-v20.14.0.tar.xz" | sha256sum -c - \
    && /usr/bin/busybox tar -xJf /tmp/node-v20.14.0.tar.xz --strip-components=1 \
    # Configure + compile; fully-static links against musl and embeds npm for postject
    && ./configure --fully-static --enable-lto \
    && make -j$(nproc) \
    && install -Dm755 out/Release/node /usr/local/bin/node-static \
    # Normalise timestamp for bit-reproducible output
    && touch -d "@${SOURCE_DATE_EPOCH}" /usr/local/bin/node-static \
    # Make the static build the default "node" in PATH
    && ln -sf /usr/local/bin/node-static /usr/local/bin/node

# Return to build dir for SEA steps
WORKDIR /build

# Copy source files into the build context
COPY package.json contribute.cjs snarkjs-wrapper.js snarkjs.js sea-config.json ./

# Install postject locally (no global permissions needed)
RUN npm install --no-save postject@1.0.0-alpha.6

# Generate the SEA blob and inject it
RUN node --experimental-sea-config sea-config.json \
	&& cp $(command -v node) /build/snarkjs-contribute \
	&& npx -y postject@1.0.0-alpha.6 /build/snarkjs-contribute NODE_SEA_BLOB sea-prep.blob --sentinel-fuse NODE_SEA_FUSE_fce680ab2cc467b6e072b8b5df1996b2 \
	&& chmod +x /build/snarkjs-contribute \
	# Normalise timestamps for deterministic builds
	&& touch -d "@${SOURCE_DATE_EPOCH}" /build/snarkjs-contribute

# Final minimal layer that just ships the binary artefact
FROM scratch AS final
COPY --from=builder /build/snarkjs-contribute /snarkjs-contribute
ENTRYPOINT ["/snarkjs-contribute"]
CMD ["--help"]
