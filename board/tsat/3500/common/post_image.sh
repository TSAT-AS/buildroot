#!/usr/bin/env bash

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

# create FIT image
echo "create system FIT..."
if [ "$TSAT_RELEASE" = "1" ]; then
  FIT_SRC='kernel-ramdisk-dtb-release.its'
else
  FIT_SRC='kernel-ramdisk-dtb-debug.its'
fi
cp -v -- "board/tsat/3500/common/images/$FIT_SRC" "$1"
mkimage -f "$1/$FIT_SRC" "$1/kernel-ramdisk-dtb.itb"

# sign FIT image (only in release builds)
if [ "$TSAT_RELEASE" = "1" ]; then
  echo "sign system FIT..."
  mkimage -F "$1/kernel-ramdisk-dtb.itb" -k 'id=%15' -N pkcs11 -K "$1/u-boot.dtb" -c "Signed by build system" -r
fi

# get files for boot image creation
cp -- ../binaries/fsbl.elf "$1"
cp -- ../binaries/fpga.bit "$1"

# create terminal and fpga SWUs
cd -- "$1"
if [ "$TSAT_RELEASE" = "1" ]; then
  SIGN_OPT=('--release')
fi
$HOST_DIR/bin/mkswu.py "${SIGN_OPT[@]}" fpga 'fpga.tar.gz'
$HOST_DIR/bin/mkswu.py "${SIGN_OPT[@]}" terminal 'terminal.tar.gz'

# create appfs filesystem
# UBI/UBIFS input parameters described in http://www.linux-mtd.infradead.org/faq/ubifs.html#L_mkfubifs
# values found on target by running 'mtdinfo -u /dev/mtdX' and 'ubinfo -a':
# Name:                           appfs
# Type:                           nor
# Eraseblock size:                262144 bytes, 256.0 KiB
# Amount of eraseblocks:          130 (34078720 bytes, 32.5 MiB)
# Minimum input/output unit size: 1 byte
# Sub-page size:                  1 byte
# Character device major/minor:   90:16
# Bad blocks are allowed:         false
# Device is writable:             true
# Default UBI VID header offset:  64
# Default UBI data offset:        128
# Default UBI LEB size:           262016 bytes, 255.8 KiB
# Maximum UBI volumes count:      128
#
# UBI version:                    1
# Count of UBI devices:           1
# UBI control device major/minor: 10:59
# Present UBI devices:            ubi0
#
# ubi0
# Volumes count:                           1
# Logical eraseblock size:                 262016 bytes, 255.8 KiB
# Total amount of logical eraseblocks:     135 (35372160 bytes, 33.7 MiB)
# Amount of available logical eraseblocks: 0 (0 bytes)
# Maximum count of volumes                 128
# Count of bad physical eraseblocks:       0
# Count of reserved physical eraseblocks:  0
# Current maximum erase counter value:     1
# Minimum input/output unit size:          1 byte
# Character device major/minor:            245:0
# Present volumes:                         1
#
# Volume ID:   1 (on ubi0)
# Type:        dynamic
# Alignment:   1
# Size:        131 LEBs (34324096 bytes, 32.7 MiB)
# State:       OK
# Name:        appfs
# Character device major/minor: 245:2

if [ "$TSAT_RELEASE" = "1" ]; then
  TMP_DIR=$(mktemp -d -p /dev/shm)
  LINK_NAME="/dev/shm/tmp"
  ln -snf "$TMP_DIR" "$LINK_NAME"
  cp -- ../keys/efuse.nky.enc "$1"
  cp -- ../keys/appfs.key.enc "$1"
  gpg --decrypt --armor --output "$TMP_DIR/efuse.nky" "$1/efuse.nky.enc"
  gpg --decrypt --armor --output "$TMP_DIR/appfs.key" "$1/appfs.key.enc"
  gpg-connect-agent 'scd killscd' /bye # force GPG to release Yubikey and let PIV be used
fi

# generate appfs image
APPFS_INPUT="$1/appfs"
APPFS_OUTPUT="$1/appfs.ubifs"
test -d "$APPFS_INPUT" || exit 1
test -f "$APPFS_OUTPUT" && rm "$APPFS_OUTPUT"
if [ "$TSAT_RELEASE" = "1" ]; then
  CRYPT_OPT=('--cipher')
  CRYPT_OPT+=('AES-256-XTS')
  CRYPT_OPT+=('--key')
  CRYPT_OPT+=("$TMP_DIR/appfs.key")
fi
$HOST_DIR/sbin/mkfs.ubifs --root="$APPFS_INPUT" "${CRYPT_OPT[@]}" --min-io-size=1 --leb-size=262016 --max-leb-cnt=131 --output="$APPFS_OUTPUT" --squash-uids

cp -- board/tsat/3500/common/images/ubi.cfg "$1"
UBI_IMAGE_INPUT="$1/ubi.cfg"
UBI_IMAGE_OUTPUT="$1/ubi.img"
test -f "$UBI_IMAGE_INPUT" || exit 1
test -f "$UBI_IMAGE_OUTPUT" && rm "$UBI_IMAGE_OUTPUT"
pushd -- "$1"
$HOST_DIR/sbin/ubinize --output="$UBI_IMAGE_OUTPUT" --peb-size=256KiB --min-io-size=1 "$UBI_IMAGE_INPUT"
popd

# build boot script FIT image
cp -v -- board/tsat/3500/common/images/u-boot-script.its "$1"
cp -v -- board/tsat/3500/common/uboot/boot_script.txt "$1"
mkimage -f "$1/u-boot-script.its" "$1/u-boot-script.itb"

# create default boot-selector and boot-count
echo -en "\xaa" > "$1/default_selector.bin"
echo -en "\x00" > "$1/default_count.bin"

# generate qspi full image
# release => secure boot image: encrypted and signed partitions
# debug => non-secure boot
FULL_IMG='qspi.img'
FULL_IMG_PADDED='qspi_padded.img'

if [ "$TSAT_RELEASE" = "1" ]; then
  PRI_KEY_ID='pkcs11:id=%13;type=private'
  SEC_KEY_ID='pkcs11:id=%14;type=private'

  echo "Creating release QSPI image: $1/$FULL_IMG"

  cp -- board/tsat/3500/common/images/release_* "$1"
  cp -- ../keys/bootgen-release-ppk.pem "$1/ppk.pem"
  cp -- ../keys/bootgen-release-spk.pem "$1/spk.pem"
  cd -- "$1"

  echo "Stage 0: generate SPK hash"
  bootgen -image release_stage_0.bif -arch zynq -w on -generate_hashes

  echo "- swap the bytes in SPK hash"
  objcopy -I binary -O binary --reverse-bytes=256 spk.pem.sha256

  echo "Stage 1: generate SPK signature"
  openssl rsautl -engine pkcs11 -keyform engine -inkey "$PRI_KEY_ID" -raw -sign -in spk.pem.sha256 -out spk.pem.sha256.sig

  echo "- swap the bytes in SPK signature"
  objcopy -I binary -O binary --reverse-bytes=256 spk.pem.sha256.sig

  echo "Stage 2a: encrypt FSBL"
  bootgen -arch zynq -image release_stage_2a.bif -w on -o fsbl_e.bin -encrypt efuse -p xc7z020

  echo "Stage 2b: encrypt FPGA"
  bootgen -arch zynq -image release_stage_2b.bif -w on -o fpga_e.bin -encrypt efuse

  echo "Stage 2c: encrypt APPFS key"
  bootgen -arch zynq -image release_stage_2c.bif -w on -o dummy.bin -encrypt efuse -split bin

  echo "Stage 3: generate partition hashes"
  bootgen -arch zynq -image release_stage_3.bif -generate_hashes

  echo "- swap the bytes in hashes"
  objcopy -I binary -O binary --reverse-bytes=256 fsbl.elf.0.sha256
  objcopy -I binary -O binary --reverse-bytes=256 fpga.bit.0.sha256
  objcopy -I binary -O binary --reverse-bytes=256 u-boot.elf.0.sha256
  objcopy -I binary -O binary --reverse-bytes=256 u-boot.dtb.0.sha256
  objcopy -I binary -O binary --reverse-bytes=256 u-boot-script.itb.0.sha256

  echo "Stage 4: sign partition hashes"
  openssl rsautl -engine pkcs11 -keyform engine -inkey "$SEC_KEY_ID" -raw -sign -in fsbl.elf.0.sha256          -out fsbl.elf.0.sha256.sig
  openssl rsautl -engine pkcs11 -keyform engine -inkey "$SEC_KEY_ID" -raw -sign -in fpga.bit.0.sha256          -out fpga.bit.0.sha256.sig
  openssl rsautl -engine pkcs11 -keyform engine -inkey "$SEC_KEY_ID" -raw -sign -in u-boot.elf.0.sha256        -out u-boot.elf.0.sha256.sig
  openssl rsautl -engine pkcs11 -keyform engine -inkey "$SEC_KEY_ID" -raw -sign -in u-boot.dtb.0.sha256        -out u-boot.dtb.0.sha256.sig
  openssl rsautl -engine pkcs11 -keyform engine -inkey "$SEC_KEY_ID" -raw -sign -in u-boot-script.itb.0.sha256 -out u-boot-script.itb.0.sha256.sig

  echo "- swap the bytes in signatures"
  objcopy -I binary -O binary --reverse-bytes=256 fsbl.elf.0.sha256.sig
  objcopy -I binary -O binary --reverse-bytes=256 fpga.bit.0.sha256.sig
  objcopy -I binary -O binary --reverse-bytes=256 u-boot.elf.0.sha256.sig
  objcopy -I binary -O binary --reverse-bytes=256 u-boot.dtb.0.sha256.sig
  objcopy -I binary -O binary --reverse-bytes=256 u-boot-script.itb.0.sha256.sig

  echo "Stage 5: insert signatures"
  bootgen -arch zynq -image release_stage_5a.bif -w on -o fsbl_e_ac.bin -nonbooting -efuseppkbits efuseppkbits.txt
  bootgen -arch zynq -image release_stage_5b.bif -w on -o fpga_e_ac.bin -nonbooting
  bootgen -arch zynq -image release_stage_5c.bif -w on -o u-boot-elf_ac.bin -nonbooting
  bootgen -arch zynq -image release_stage_5d.bif -w on -o u-boot-dtb_ac.bin -nonbooting
  bootgen -arch zynq -image release_stage_5e.bif -w on -o u-boot-script-itb_ac.bin -nonbooting

  echo "Stage 6: generate header table hash"
  bootgen -arch zynq -image release_stage_6.bif -generate_hashes

  echo "Stage 7: sign header table hash"
  objcopy -I binary -O binary --reverse-bytes=256 ImageHeaderTable.sha256
  openssl rsautl -engine pkcs11 -keyform engine -inkey "$SEC_KEY_ID" -raw -sign -in ImageHeaderTable.sha256 -out ImageHeaderTable.sha256.sig
  objcopy -I binary -O binary --reverse-bytes=256 ImageHeaderTable.sha256.sig

  echo "Stage 8: generate final bootable image"
  bootgen -arch zynq -image release_stage_8.bif -w on -o "${FULL_IMG}" -log info

  # cleanup
  rm "$LINK_NAME"
  rm -rf "$TMP_DIR"
else
  echo "Creating DEBUG QSPI image: $1/$FULL_IMG"
  BIF='debug.bif'
  cp -- "board/tsat/3500/common/images/$BIF" "$1"
  cd -- "$1"
  bootgen -image "$BIF" -arch zynq -o "$FULL_IMG" -w on -log info
fi

# pad file to fill the complete flash and make flashing simpler
echo "Generating padded QSPI bootable image: $FULL_IMG_PADDED"
dd if=/dev/zero count=512 | tr "\000" "\377" > ff_file_front
dd if=/dev/zero ibs=1024 count=65536 | tr "\000" "\377" > ff_file_back
cat ff_file_front "$FULL_IMG" ff_file_back > "$FULL_IMG_PADDED"
rm ff_file_front ff_file_back
truncate --size=64M "$FULL_IMG_PADDED"

# generate qspi swu packages
if [ "$TSAT_RELEASE" = "1" ]; then
  SIGN_OPT=('--release')
fi
$HOST_DIR/bin/mkswu.py "${SIGN_OPT[@]}" system 'kernel-ramdisk-dtb.itb'
$HOST_DIR/bin/mkswu.py "${SIGN_OPT[@]}" full 'kernel-ramdisk-dtb.itb' 'terminal.tar.gz' 'fpga.tar.gz'
