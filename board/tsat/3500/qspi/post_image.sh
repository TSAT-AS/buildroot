#!/usr/bin/env bash

set -e

# create appfs filesystem
# UBI/UBIFS input parameters described in http://www.linux-mtd.infradead.org/faq/ubifs.html#L_mkfubifs
# values found on target by running 'mtdinfo -u /dev/mtd7':
# mtd7
# Name:                           appfs
# Type:                           nor
# Eraseblock size:                262144 bytes, 256.0 KiB
# Amount of eraseblocks:          131 (34340864 bytes, 32.7 MiB)
# Minimum input/output unit size: 1 byte
# Sub-page size:                  1 byte
# Character device major/minor:   90:14
# Bad blocks are allowed:         false
# Device is writable:             true
# Default UBI VID header offset:  64
# Default UBI data offset:        128
# Default UBI LEB size:           262016 bytes, 255.8 KiB
# Maximum UBI volumes count:      128

APPFS_INPUT="$1/appfs"
APPFS_OUTPUT="$1/appfs.ubifs"
test -d "$APPFS_INPUT" || exit 1
test -f "$APPFS_OUTPUT" && rm "$APPFS_OUTPUT"
$HOST_DIR/sbin/mkfs.ubifs --root="$APPFS_INPUT" --min-io-size=1 --leb-size=262016 --max-leb-cnt=131 --output="$APPFS_OUTPUT"

cp -- board/tsat/3500/qspi/images/appfs.cfg "$1"
UBI_IMAGE_INPUT="$1/appfs.cfg"
UBI_IMAGE_OUTPUT="$1/appfs.img"
test -f "$UBI_IMAGE_INPUT" || exit 1
test -f "$UBI_IMAGE_OUTPUT" && rm "$UBI_IMAGE_OUTPUT"
pushd -- "$1"
$HOST_DIR/sbin/ubinize --output="$UBI_IMAGE_OUTPUT" --peb-size=256KiB --min-io-size=1 "$UBI_IMAGE_INPUT"
popd

# build boot script FIT image
cp -v -- board/tsat/3500/common/images/u-boot-script.its "$1"
cp -v -- board/tsat/3500/qspi/uboot/boot_script.txt "$1"
mkimage -f "$1/u-boot-script.its" "$1/u-boot-script.itb"

# create default boot-selector and boot-count
echo -en "\xaa" > "$1/default_selector.bin"
echo -en "\x00" > "$1/default_count.bin"

# generate qspi full image
# release => secure boot image: encrypted and signed partitions
# debug => non-secure boot
FULL_IMG='qspi.img'

if [ "$TSAT_RELEASE" = "1" ]; then
  PRI_KEY_ID='pkcs11:id=%13;type=private'
  SEC_KEY_ID='pkcs11:id=%14;type=private'

  echo "Creating release QSPI image: $1/$FULL_IMG"

  cp -- board/tsat/3500/qspi/images/release_* "$1"
  cp -- ../keys/bootgen-release-ppk.pem "$1/ppk.pem"
  cp -- ../keys/bootgen-release-spk.pem "$1/spk.pem"
  cp -- ../keys/efuse.nky.enc "$1"
  cp -- ../keys/appfs.key.enc "$1"
  cd -- "$1"

  TMP_DIR=$(mktemp -d -p /dev/shm)
  LINK_NAME="/dev/shm/tmp"
  ln -snf "$TMP_DIR" "$LINK_NAME"
  gpg --decrypt --armor --output "$TMP_DIR/efuse.nky" efuse.nky.enc
  gpg --decrypt --armor --output "$TMP_DIR/appfs.key" appfs.key.enc
  gpg-connect-agent 'scd killscd' /bye # force GPG to release Yubikey and let PIV be used

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
  bootgen -arch zynq -image release_stage_2c.bif -w on -o appfskey_e.bin -encrypt efuse

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
  cp -- "board/tsat/3500/qspi/images/$BIF" "$1"
  cd -- "$1"
  bootgen -image "$BIF" -arch zynq -o "$FULL_IMG" -w on -log info
fi

# generate qspi swu packages
if [ "$TSAT_RELEASE" = "1" ]; then
  SIGN_OPT=('--release')
fi
$HOST_DIR/bin/mkswu.py "${SIGN_OPT[@]}" system 'kernel-ramdisk-dtb.itb'
$HOST_DIR/bin/mkswu.py "${SIGN_OPT[@]}" full 'kernel-ramdisk-dtb.itb' 'terminal.tar.gz' 'fpga.tar.gz'
