# Pin every Stageˣ layer by digest to guarantee bit-for-bit reproducibility.
# Replace <digest-…> with the current sha256 you get from:
#   docker buildx imagetools inspect stagex/<pkg>:<tag>

ARG STAGEX_BASE=stagex/core-filesystem@sha256:2aaaea601e1725a8292c4c28e723db5761d892b869556f9b05c0983ba11fe30e
ARG STAGEX_BUSYBOX=stagex/core-busybox@sha256:cac5d773db1c69b832d022c469ccf5f52daf223b91166e6866d42d6983a3b374
ARG STAGEX_KERNEL_GUESTNET=stagex/user-linux-guest-net@sha256:116bfd07b18f2b21131bbd6ecbc0540fd60e1d39f16d148b0267a77a1f19ba50
ARG STAGEX_OPENSSH=stagex/user-openssh@sha256:09041e83e4e72f2696f4887e94185c5b0044abab769d3016f39310b0b07c7f2c
ARG STAGEX_DHCPCD=stagex/user-dhcpcd@sha256:60bd86d9e2fcb6341c1efaeda5d786b63ff92e9d0c729cd8f634a20ff54ee71e
ARG STAGEX_IPROUTE2=stagex/user-iproute2@sha256:fef26710a7ed455e613aedd9d1420eff609f3aa37b96e497991c64f2c3c31db3
ARG STAGEX_PLATFORM=linux/amd64

# Import external layers via lightweight stages (works without BuildKit variable expansion)
FROM --platform=$STAGEX_PLATFORM ${STAGEX_BUSYBOX} AS stage_busybox
FROM --platform=$STAGEX_PLATFORM ${STAGEX_KERNEL_GUESTNET} AS stage_kernel
FROM --platform=$STAGEX_PLATFORM ${STAGEX_OPENSSH} AS stage_openssh
FROM --platform=$STAGEX_PLATFORM ${STAGEX_DHCPCD} AS stage_dhcpcd
FROM --platform=$STAGEX_PLATFORM ${STAGEX_IPROUTE2} AS stage_iproute2

FROM --platform=$STAGEX_PLATFORM ${STAGEX_BASE} AS rootfs
ENV  SOURCE_DATE_EPOCH=1   TZ=UTC   LANG=C.UTF-8
USER 0
# Bring in BusyBox (gives /sbin/init) and other runtime bits
COPY --from=stage_busybox / /
# Kernel + gVNIC-enabled modules (guest-net config)
COPY --from=stage_kernel / /
# SSH daemon + networking utilities
COPY --from=stage_openssh / /
COPY --from=stage_dhcpcd / /
COPY --from=stage_iproute2 / /

# ── minimal runtime configuration ─────────────────────
RUN set -eux; \
	echo "root:x:0:0:root:/root:/bin/sh"   > /etc/passwd; \
	echo "root::19000:0:99999:7:::"        > /etc/shadow; \
	mkdir -p /root/.ssh; chmod 700 /root/.ssh; echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC0nSnwx3ko3Z7qnVB4PQD0hnsN3vS3IHR2E2PWN5bZaM7fAW//GTaWif5KOX3xKPVbLCE39N+MVxDNWUCBZw+aYV4u2nRDcouincywvBl1A2pFxNMqL1curpg8VF1DVdvrwEOrwO0jlVQyfaMC7Urg4l9Nm5B5NGu0jIGmsKqvpPMy01sevsvnvH5Vf3mHdxPOXE1Gf/hD503QmWNQ9UYVE/69FzShJxIo5WL4NbwAJMhKP9DWxg/oBGpqtQUjIX1m0NDQoRklixTQA62NPunFql/A0S/t+ZwRaWTGWPkljffQJ4ZvLFfqzEVygBRY4hy3GClA+6hfXajSPsPbrpAm6toJH6KklN4niYTykkgu6WNTUozGkj/OFzfPmhNsng3kKF5Upve2qFs6NNRsg7YrZf5JgaFtvszitY5s8Rl31CM1JTV4/LQO+DhMEBPuz4JqseI5f+ZW/8ZMoJgKspZG+j81bC4IjzyzrbE6cwptQs4jzgsSo87EfSjqafeTOsE= computer@Computer.local' > /root/.ssh/authorized_keys; chmod 600 /root/.ssh/authorized_keys; \
	# BusyBox init script – start DHCP then sshd
	echo '::sysinit:/sbin/dhcpcd -f'  > /etc/inittab; \
	echo '::respawn:/usr/sbin/sshd -D -e' >> /etc/inittab; \
	# Basic sshd hardening
	sed 's/^#PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config > /etc/ssh/sshd_config.tmp; \
	mv /etc/ssh/sshd_config.tmp /etc/ssh/sshd_config; \
	# Clamp mtimes on all new/modified files & dirs for reproducibility
	find / -xdev -exec touch -h -d "@1" {} + 2>/dev/null || true

ENTRYPOINT ["/sbin/init"]
CMD []

# The final image is reproducible, static, and runs /sbin/init which launches DHCP + sshd.