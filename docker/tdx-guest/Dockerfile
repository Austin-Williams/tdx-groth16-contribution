FROM --platform=linux/amd64 stagex/core-filesystem@sha256:2aaaea601e1725a8292c4c28e723db5761d892b869556f9b05c0983ba11fe30e

# Set a working directory
WORKDIR /app

# Copy the pre-built zokrates binary from the build context into the image
# Assumes the build context is the root of the tdx-groth16-contribution project
# and the binary is at bin/zokrates relative to the context.
COPY bin/zokrates /usr/local/bin/zokrates

# Ensure the zokrates binary is executable
RUN chmod +x /usr/local/bin/zokrates

# Copy the entrypoint script from the docker/tdx-guest directory (relative to context)
COPY docker/tdx-guest/entrypoint.sh /entrypoint.sh

# Ensure the entrypoint script is executable
RUN chmod +x /entrypoint.sh

# Declare the mount point for shared data from the host.
# The host will mount its shared folder to /mnt/tdx_share inside the container.
VOLUME ["/mnt/tdx_share"]

# Set the entrypoint for the container
ENTRYPOINT ["/entrypoint.sh"]