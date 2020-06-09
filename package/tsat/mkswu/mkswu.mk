################################################################################
#
# mkswu
#
################################################################################

HOST_MKSWU_SITE_METHOD = git
HOST_MKSWU_SITE = ssh://git@dev.tsat.net:7999/tsat3k/image-builder.git
HOST_MKSWU_VERSION = d6982f8adfdb8f60ebd6814f7998ad5eef38e675
HOST_MKSWU_DEPENDENCIES = host-openssl host-cpio

define HOST_MKSWU_INSTALL_CMDS
	$(INSTALL) -m 0644 -D $(@D)/private.pem                       $(HOST_DIR)/usr/share/mkswu/private.pem
	$(INSTALL) -m 0644 -D $(@D)/targets/fpga/postinstall.sh       $(HOST_DIR)/usr/share/mkswu/fpga-postinstall.sh
	$(INSTALL) -m 0644 -D $(@D)/targets/terminal/postinstall.sh   $(HOST_DIR)/usr/share/mkswu/terminal-postinstall.sh
	$(INSTALL) -m 0644 -D $(@D)/targets/mmc-system/postinstall.sh $(HOST_DIR)/usr/share/mkswu/mmc-system-postinstall.sh

	$(INSTALL) -m 0755 -D $(@D)/targets/fpga/mkswu.sh             $(HOST_DIR)/bin/mkswu-fpga
	$(INSTALL) -m 0755 -D $(@D)/targets/terminal/mkswu.sh         $(HOST_DIR)/bin/mkswu-terminal
	$(INSTALL) -m 0755 -D $(@D)/targets/qspi-system/mkswu.sh      $(HOST_DIR)/bin/mkswu-qspi-system
	$(INSTALL) -m 0755 -D $(@D)/targets/qspi-full/mkswu.sh        $(HOST_DIR)/bin/mkswu-qspi-full
	$(INSTALL) -m 0755 -D $(@D)/targets/mmc-system/mkswu.sh       $(HOST_DIR)/bin/mkswu-mmc-system
	$(INSTALL) -m 0755 -D $(@D)/targets/mmc-full/mkswu.sh         $(HOST_DIR)/bin/mkswu-mmc-full
endef

$(eval $(host-generic-package))
