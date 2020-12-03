#!/usr/bin/env bash
set -e

# generate qspi full image
# secure => secure boot image: encrypted and signed partitions
FULL_IMG='qspi.img'
BOOTGEN="$HOST_DIR/bin/bootgen"
OPENSSL="$HOST_DIR/bin/openssl"

if [ "$BUILD_TYPE" = "PROD" ]; then
  echo "Creating secure QSPI image: $1/$FULL_IMG"

  # prepare openssl config
  export OPENSSL_CONF='/tmp/openssl.cnf'
  cp -- board/tsat/3500/production/openssl.cnf "$OPENSSL_CONF"
  sed -i "s#= BR_HOST#= $HOST_DIR#g" "$OPENSSL_CONF"
  sed -i "s#= SC_PIN#= $PIN#g" "$OPENSSL_CONF"

  # set PKCS11 identifiers for signing keys
  PRI_KEY_ID='pkcs11:id=%13;type=private'
  SEC_KEY_ID='pkcs11:id=%14;type=private'

  cp -- ../keys/bootgen-release-ppk.pem "$1/ppk.pem"
  cp -- ../keys/bootgen-release-spk.pem "$1/spk.pem"
  cp -- board/tsat/3500/common/images/bootgen_secure_* "$1"
  cd -- "$1"

  echo "Stage 0: generate SPK hash"
  $BOOTGEN -image bootgen_secure_stage_0.bif -arch zynq -w on -generate_hashes

  echo "- swap the bytes in SPK hash"
  objcopy -I binary -O binary --reverse-bytes=256 spk.pem.sha256

  echo "Stage 1: generate SPK signature"
  $OPENSSL rsautl -engine pkcs11 -keyform engine -inkey "$PRI_KEY_ID" -raw -sign -in spk.pem.sha256 -out spk.pem.sha256.sig

  echo "- swap the bytes in SPK signature"
  objcopy -I binary -O binary --reverse-bytes=256 spk.pem.sha256.sig

  echo "Stage 2a: encrypt FSBL"
  $BOOTGEN -arch zynq -image bootgen_secure_stage_2a.bif -w on -o fsbl_e.bin -encrypt efuse -p xc7z020

  echo "Stage 2b: encrypt FPGA"
  $BOOTGEN -arch zynq -image bootgen_secure_stage_2b.bif -w on -o fpga_e.bin -encrypt efuse

  echo "Stage 2c: encrypt APPFS key"
  $BOOTGEN -arch zynq -image bootgen_secure_stage_2c.bif -w on -o dummy.bin -encrypt efuse -split bin

  echo "Stage 3: generate partition hashes"
  $BOOTGEN -arch zynq -image bootgen_secure_stage_3.bif -generate_hashes

  echo "- swap the bytes in hashes"
  objcopy -I binary -O binary --reverse-bytes=256 fsbl.elf.0.sha256
  objcopy -I binary -O binary --reverse-bytes=256 fpga.bit.0.sha256
  objcopy -I binary -O binary --reverse-bytes=256 u-boot.elf.0.sha256
  objcopy -I binary -O binary --reverse-bytes=256 u-boot.dtb.0.sha256
  objcopy -I binary -O binary --reverse-bytes=256 u-boot-script.itb.0.sha256

  echo "Stage 4: sign partition hashes"
  $OPENSSL rsautl -engine pkcs11 -keyform engine -inkey "$SEC_KEY_ID" -raw -sign -in fsbl.elf.0.sha256          -out fsbl.elf.0.sha256.sig
  $OPENSSL rsautl -engine pkcs11 -keyform engine -inkey "$SEC_KEY_ID" -raw -sign -in fpga.bit.0.sha256          -out fpga.bit.0.sha256.sig
  $OPENSSL rsautl -engine pkcs11 -keyform engine -inkey "$SEC_KEY_ID" -raw -sign -in u-boot.elf.0.sha256        -out u-boot.elf.0.sha256.sig
  $OPENSSL rsautl -engine pkcs11 -keyform engine -inkey "$SEC_KEY_ID" -raw -sign -in u-boot.dtb.0.sha256        -out u-boot.dtb.0.sha256.sig
  $OPENSSL rsautl -engine pkcs11 -keyform engine -inkey "$SEC_KEY_ID" -raw -sign -in u-boot-script.itb.0.sha256 -out u-boot-script.itb.0.sha256.sig

  echo "- swap the bytes in signatures"
  objcopy -I binary -O binary --reverse-bytes=256 fsbl.elf.0.sha256.sig
  objcopy -I binary -O binary --reverse-bytes=256 fpga.bit.0.sha256.sig
  objcopy -I binary -O binary --reverse-bytes=256 u-boot.elf.0.sha256.sig
  objcopy -I binary -O binary --reverse-bytes=256 u-boot.dtb.0.sha256.sig
  objcopy -I binary -O binary --reverse-bytes=256 u-boot-script.itb.0.sha256.sig

  echo "Stage 5: insert signatures"
  $BOOTGEN -arch zynq -image bootgen_secure_stage_5a.bif -w on -o fsbl_e_ac.bin -nonbooting -efuseppkbits efuseppkbits.txt
  $BOOTGEN -arch zynq -image bootgen_secure_stage_5b.bif -w on -o fpga_e_ac.bin -nonbooting
  $BOOTGEN -arch zynq -image bootgen_secure_stage_5c.bif -w on -o u-boot-elf_ac.bin -nonbooting
  $BOOTGEN -arch zynq -image bootgen_secure_stage_5d.bif -w on -o u-boot-dtb_ac.bin -nonbooting
  $BOOTGEN -arch zynq -image bootgen_secure_stage_5e.bif -w on -o u-boot-script-itb_ac.bin -nonbooting

  echo "Stage 6: generate header table hash"
  $BOOTGEN -arch zynq -image bootgen_secure_stage_6.bif -generate_hashes

  echo "Stage 7: sign header table hash"
  objcopy -I binary -O binary --reverse-bytes=256 ImageHeaderTable.sha256
  $OPENSSL rsautl -engine pkcs11 -keyform engine -inkey "$SEC_KEY_ID" -raw -sign -in ImageHeaderTable.sha256 -out ImageHeaderTable.sha256.sig
  objcopy -I binary -O binary --reverse-bytes=256 ImageHeaderTable.sha256.sig

  echo "Stage 8: generate final bootable image"
  $BOOTGEN -arch zynq -image bootgen_secure_stage_8.bif -w on -o "${FULL_IMG}" -log info

  # clean up
  rm "$OPENSSL_CONF"
  unset OPENSSL_CONF
else
  echo "Creating DEBUG QSPI image: $1/$FULL_IMG"
  BIF='bootgen_non_secure.bif'
  cp -- "board/tsat/3500/common/images/$BIF" "$1"
  cd -- "$1"
  $BOOTGEN -arch zynq -image "$BIF" -o "$FULL_IMG" -w on -log info
fi
