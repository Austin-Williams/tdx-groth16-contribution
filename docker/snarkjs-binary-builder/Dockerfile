# Build SEA standalone binary for SnarkJS phase2 contribution

ARG STAGEX_PALLET_NODEJS=stagex/pallet-nodejs@sha256:07c6e3d54dfa7df17134ebab33310442adceeca1d980cbf7169a6f15737cd0e0

FROM ${STAGEX_PALLET_NODEJS} AS builder
ENV SOURCE_DATE_EPOCH=1
ENV NODE_ENV=production \
	TZ=UTC

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
