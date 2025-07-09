#!/usr/bin/env bash
# entrypoint.sh – convert deterministic StageX rootfs tarball into
# disk.raw + tdx-image.tar.gz (GCP format) deterministically.
#
# Usage inside container (must be --privileged with a loop module):
#   /entrypoint.sh /io/tdx-rootfs.tar.gz [IMAGE_SIZE_MB]
#
# The script is fully reproducible: fixed UUID, timestamps, tar ordering, etc.

set -euo pipefail

if [[ "$#" -lt 1 ]]; then
  echo "Usage: $0 <rootfs.tar.gz> [image_size_mb]" >&2
  exit 1
fi

ROOTFS_TAR="$1"
IMAGE_SIZE_MB="${2:-512}"

if [[ ! -f "$ROOTFS_TAR" ]]; then
  echo "Rootfs tarball '$ROOTFS_TAR' not found" >&2
  exit 1
fi

# Work in the tarball's directory so outputs land next to it.
WORKDIR="$(dirname "$ROOTFS_TAR")"
cd "$WORKDIR"
ROOTFS_TAR="$(basename "$ROOTFS_TAR")"

DISK_RAW="disk.raw"
OUTPUT_TAR="tdx-image.tar.gz"

rm -f "$DISK_RAW" "$OUTPUT_TAR"

printf '[builder] Creating %s (%s MiB) from %s\n' "$DISK_RAW" "$IMAGE_SIZE_MB" "$ROOTFS_TAR"

# 1. Create sparse disk file and deterministic ext4 filesystem.

dd if=/dev/zero of="$DISK_RAW" bs=1M count=0 seek="$IMAGE_SIZE_MB"

mkfs.ext4 -F -O ^64bit,^metadata_csum_seed,^dir_index \
          -U 00000000-0000-0000-0000-000000000000 \
          -E lazy_itable_init=0,lazy_journal_init=0 "$DISK_RAW"

# 2. Mount, extract rootfs, unmount.

mkdir -p /mnt/img
mount -o loop "$DISK_RAW" /mnt/img

# Extract preserving numeric ownership (everything root:root)
TAR_FLAGS=(--numeric-owner -xzf "$ROOTFS_TAR" -C /mnt/img)
tar "${TAR_FLAGS[@]}"

sync
umount /mnt/img

# 3. Zero out superblock timestamps for reproducibility.
for field in mtime wtime lastcheck; do
  debugfs -w -R "set_super_value $field 0" "$DISK_RAW"
done

# 4. Package into deterministic tarball expected by GCP (gzip -n).

tar --sort=name --format=gnu -S --owner=0 --group=0 --numeric-owner \
    --mtime=@0 -cf - "$DISK_RAW" | gzip -9n > "$OUTPUT_TAR"

ls -l "$DISK_RAW" "$OUTPUT_TAR"

echo "[builder] Finished – outputs at $WORKDIR"
