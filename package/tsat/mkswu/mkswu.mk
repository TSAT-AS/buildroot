################################################################################
#
# mkswu
#
################################################################################

HOST_MKSWU_SITE_METHOD = git
HOST_MKSWU_SITE = ssh://git@dev.tsat.net:7999/tsat3k/image-builder.git
HOST_MKSWU_VERSION = cbdf9c0bb20e0231b0fa0c4b79ff9b36f195b5f0
HOST_MKSWU_DEPENDENCIES = host-openssl host-cpio

define HOST_MKSWU_INSTALL_CMDS
	$(INSTALL) -m 0755 -D $(@D)/mkswu.py $(HOST_DIR)/bin/mkswu.py
endef

$(eval $(host-generic-package))
