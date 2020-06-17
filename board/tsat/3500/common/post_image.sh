#!/bin/sh

set -e

# normalize U-Boot filename (for bootgen)
UBOOT="$1/u-boot"
if [ -f "$UBOOT" ]; then
  mv -v -- "$UBOOT" "$UBOOT.elf"
fi

# populate appfs directory
APPFS_DIR="$1/appfs"
APPFS_FPGA_DIR="$APPFS_DIR/fpga"
APPFS_TERM_DIR="$APPFS_DIR/terminal"
mkdir -p "$APPFS_DIR"
mkdir -p "$APPFS_FPGA_DIR"
mkdir -p "$APPFS_TERM_DIR"
tar -x --no-same-owner -v -f "$1/fpga.tar.gz" -C "$APPFS_FPGA_DIR"
tar -x --no-same-owner -v -f "$1/terminal.tar.gz" -C "$APPFS_TERM_DIR"
ln -snf "$(basename "$APPFS_FPGA_DIR")/fpga_viterbi_low.bit" "$APPFS_DIR/fpga.bit"
ln -snf "$(basename "$APPFS_TERM_DIR")" "$APPFS_DIR/current"

# populate initramfs with required binaries and libraries
INITRAMFS_DIR="$1/initramfs"
INITRAMFS_FILE="${INITRAMFS_DIR}.cpio"
mkdir -p -- "$INITRAMFS_DIR"
cp -v -- \
   "$TARGET_DIR/bin/busybox" \
   "$TARGET_DIR/lib/ld-linux-armhf.so.3" \
   "$TARGET_DIR/lib/libatomic.so.1.2.0" \
   "$TARGET_DIR/lib/libblkid.so.1.1.0" \
   "$TARGET_DIR/lib/libc.so.6" \
   "$TARGET_DIR/lib/libdl.so.2" \
   "$TARGET_DIR/lib/libm-2.30.so" \
   "$TARGET_DIR/lib/libpthread.so.0" \
   "$TARGET_DIR/lib/libresolv.so.2" \
   "$TARGET_DIR/lib/libuuid.so.1.3.0" \
   "$TARGET_DIR/usr/lib/libargon2.so.1" \
   "$TARGET_DIR/usr/lib/libcrypto.so.1.1" \
   "$TARGET_DIR/usr/lib/libcryptsetup.so.12.5.0" \
   "$TARGET_DIR/usr/lib/libdevmapper.so.1.02" \
   "$TARGET_DIR/usr/lib/libjson-c.so.4.0.0" \
   "$TARGET_DIR/usr/lib/libpopt.so.0.0.0" \
   "$TARGET_DIR/usr/lib/libssl.so.1.1" \
   "$TARGET_DIR/usr/sbin/veritysetup" \
   "$INITRAMFS_DIR"

# calculate squashfs hash to be used with dm-verity
SQUASHFS_SIZE="$(stat --printf="%s" "$1/rootfs.squashfs")"
echo "$SQUASHFS_SIZE" > "$INITRAMFS_DIR/verity-hash-dev-offset"
cp -- "$1/rootfs.squashfs" "$1/rootfs.squashfs.nohash"
veritysetup --hash-offset="$SQUASHFS_SIZE" format "$1/rootfs.squashfs" "$1/rootfs.squashfs" | awk '/Root hash/ {print $3}' > "$INITRAMFS_DIR/verity-root-hash"

# generate initramfs
cp -v -- board/tsat/3500/common/initramfs/init.sh "$INITRAMFS_DIR"
cp -v -- board/tsat/3500/common/initramfs/filelist.txt "$INITRAMFS_DIR"
cd "$INITRAMFS_DIR"
$BUILD_DIR/linux-v1.8.2/usr/gen_init_cpio filelist.txt > "$INITRAMFS_FILE"
xz --threads=0 --check=crc32 --force "$INITRAMFS_FILE" # Linux only supports CRC32 check, xz defaults to CRC64
cd -

# build signed FIT image
cp -v -- board/tsat/3500/common/images/kernel-ramdisk-dtb.its "$1"
mkimage -f "$1/kernel-ramdisk-dtb.its" "$1/kernel-ramdisk-dtb.itb"
mkimage -F "$1/kernel-ramdisk-dtb.itb" -k "$1/keys" -K "$1/u-boot.dtb" -c "Signed by build system" -r

# build boot image
cp -- board/tsat/3500/common/images/boot.bif "$1"
cp -- ../binaries/fsbl.elf "$1"
cp -- ../binaries/fpga.bit "$1"

BOOT_IMG='boot.bin'
echo "Creating boot image: $1/$BOOT_IMG"

cd -- "$1"
bootgen -image boot.bif -arch zynq -o "$BOOT_IMG" -efuseppkbits hash_ppk.txt -p xc7z020 -encrypt efuse -w on -log info


# create terminal and fpga SWUs
export KEY="$HOST_DIR/usr/share/mkswu/private.pem"
export POSTSCRIPT="$HOST_DIR/usr/share/mkswu/fpga-postinstall.sh"
$HOST_DIR/bin/mkswu-fpga 'fpga.tar.gz'
export POSTSCRIPT="$HOST_DIR/usr/share/mkswu/terminal-postinstall.sh"
$HOST_DIR/bin/mkswu-terminal 'terminal.tar.gz'
