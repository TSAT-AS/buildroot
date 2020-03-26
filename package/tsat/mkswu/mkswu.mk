################################################################################
#
# mkswu
#
################################################################################

HOST_MKSWU_SITE_METHOD = git
HOST_MKSWU_SITE = ssh://git@dev.tsat.net:7999/tsat3k/image-builder.git
HOST_MKSWU_VERSION = bce0c917cff3b24e1b56ba3f61daa5c54bd7aaa2
HOST_MKSWU_DEPENDENCIES = host-openssl host-cpio

define HOST_MKSWU_INSTALL_CMDS
	$(INSTALL) -m 0644 -D $(@D)/private.pem                           $(HOST_DIR)/usr/share/mkswu/private.pem
	$(INSTALL) -m 0644 -D $(@D)/scripts/swu-mmc-system/postinstall.sh $(HOST_DIR)/usr/share/mkswu/mmc-system-postinstall.sh

	$(INSTALL) -m 0755 -D $(@D)/scripts/swu-qspi-system/build.sh      $(HOST_DIR)/bin/mkswu-qspi-system
	$(INSTALL) -m 0755 -D $(@D)/scripts/swu-qspi-full/build.sh        $(HOST_DIR)/bin/mkswu-qspi-full
	$(INSTALL) -m 0755 -D $(@D)/scripts/swu-mmc-system/build.sh       $(HOST_DIR)/bin/mkswu-mmc-system
	$(INSTALL) -m 0755 -D $(@D)/scripts/swu-mmc-full/build.sh         $(HOST_DIR)/bin/mkswu-mmc-full
endef

$(eval $(host-generic-package))
