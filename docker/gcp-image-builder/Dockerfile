# Stage 1 – tooling
FROM stagex/stage3:latest AS builder
# bring in CA certificates then curl + libs
COPY --from=stagex/core-ca-certificates@sha256:d6fca6c0080e8e5360cd85fc1c4bd3eab71ce626f40602e38488bfd61fd3e89d /etc/ssl /etc/ssl
COPY --from=stagex/core-openssl:latest /lib /lib
COPY --from=stagex/core-openssl:latest /usr/lib /usr/lib
COPY --from=stagex/core-curl:latest /usr/bin/curl /usr/bin/curl
COPY --from=stagex/core-curl:latest /usr/lib /usr/lib


ENV SOURCE_DATE_EPOCH=1 TZ=UTC LANG=C.UTF-8 PATH="/usr/sbin:/sbin:$PATH"
USER 0

# StageX user-e2fsprogs seems to ship only libraries, not utilities, so we need to build mke2fs from e2fsprogs source for ext4 + -d support
# Build libarchive to give mke2fs tar population support
ARG LIBARCHIVE_VERSION=3.7.2
RUN set -eux; \
	curl -fsSL "https://github.com/libarchive/libarchive/releases/download/v${LIBARCHIVE_VERSION}/libarchive-${LIBARCHIVE_VERSION}.tar.gz" -o /tmp/libarchive.tar.gz; \
	mkdir -p /tmp/libarchive && tar -xzf /tmp/libarchive.tar.gz -C /tmp/libarchive --strip-components=1; \
	cd /tmp/libarchive; \
	./configure --prefix=/usr --disable-bsdtar --disable-bsdcpio --disable-bsdcat --without-openssl --without-nettle --without-xml2 --without-expat --without-iconv --without-lzo2 --without-lz4 --without-lzmadec --without-xz --without-zstd; \
	make -j"$(nproc)"; \
	make install; \
	strip -s /usr/lib/libarchive.so* || true; \
	rm -rf /tmp/libarchive /tmp/libarchive.tar.gz

ARG E2FSPROGS_VERSION=1.47.1
RUN set -eux; \
	curl -fsSL "https://mirrors.edge.kernel.org/pub/linux/kernel/people/tytso/e2fsprogs/v${E2FSPROGS_VERSION}/e2fsprogs-${E2FSPROGS_VERSION}.tar.gz" -o /tmp/e2fs.tar.gz; \
	mkdir -p /tmp/e2fs && tar -xzf /tmp/e2fs.tar.gz -C /tmp/e2fs --strip-components=1; \
	cd /tmp/e2fs; \
	./configure --disable-nls --prefix=/usr; \
	make -j"$(nproc)" libs; \
	make -C misc -j"$(nproc)" mke2fs dumpe2fs; \
	install -m 0755 misc/mke2fs misc/dumpe2fs /usr/sbin/; \
	make -C debugfs -j"$(nproc)" debugfs; \
	install -m 0755 debugfs/debugfs /usr/sbin/debugfs; \
	strip /usr/sbin/mke2fs /usr/sbin/dumpe2fs /usr/sbin/debugfs; \
	rm -rf /tmp/e2fs /tmp/e2fs.tar.gz

ARG ROOTFS_NAME
COPY --from=rootfs_ctx ${ROOTFS_NAME} /rootfs.tar.gz

RUN set -eux; \
	mkdir /rootfs && tar -xzf /rootfs.tar.gz -C /rootfs; \
	# size of unpacked rootfs in MiB + 100 MB slack
	size=$(du -sm /rootfs | cut -f1); size=$((size+100)); \
	dd if=/dev/zero of=/rootfs.raw bs=1M count=$size; \
	# create ext4 FS from tar stream for deterministic inode ordering (mke2fs supports -d -)
	gunzip -c /rootfs.tar.gz | /usr/sbin/mke2fs -t ext4 -q -F -d - -U 00000000-0000-0000-0000-000000000000 \
	-L tdx_rootfs \
	-I 128 -m 0 -s 0 \
	-E lazy_itable_init=0,lazy_journal_init=0,hash_seed=00000000-0000-0000-0000-000000000000 \
	-O ^has_journal,^resize_inode,^dir_index,^flex_bg,^sparse_super,^sparse_super2,^huge_file,^dir_nlink,^extra_isize,^filetype,^ea_inode,^encrypt,^project,^verity,^uninit_bg,^metadata_csum,^metadata_csum_seed /rootfs.raw; \
	# mke2fs still writes a random journal UUID at super-block offset 0xE0; zero it for determinism (1024+0xE0 = 1248)
	# zero per-inode random generation numbers for reproducibility
	# set deterministic timestamps on root and lost+found inodes
	for inode in 2 11; do for fld in atime ctime mtime; do /usr/sbin/debugfs -w -R "set_inode_field $inode $fld 1" /rootfs.raw || true; done; done; \
	inode_cnt=$(dumpe2fs -h /rootfs.raw 2>/dev/null | awk '/Inode count:/ {print $3}'); \
	for i in $(seq 1 "$inode_cnt"); do /usr/sbin/debugfs -w -R "set_inode_field $i generation 0" /rootfs.raw || true; done; \
	# zero leftover journal UUID location (even though journal disabled) for safety
	dd if=/dev/zero of=/rootfs.raw bs=1 seek=1248 count=32 conv=notrunc; \
	gzip -9n < /rootfs.raw > /rootfs.raw.tar.gz; \
	touch -d '@1' /rootfs.raw /rootfs.raw.tar.gz

# Stage 2 – export only the artefacts
FROM scratch AS export
COPY --from=builder /rootfs.raw /
COPY --from=builder /rootfs.raw.tar.gz /