################################################################################
#
# mkswu
#
################################################################################

HOST_MKSWU_SITE_METHOD = git
HOST_MKSWU_SITE = ssh://git@dev.tsat.net:7999/tsat3k/image-builder.git
HOST_MKSWU_VERSION = 2da918ac0e9ae3b2b70419763b8767abf5e75fd6
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
