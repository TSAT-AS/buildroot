################################################################################
#
# mkswu
#
################################################################################

HOST_MKSWU_SITE_METHOD = git
HOST_MKSWU_SITE = ssh://git@dev.tsat.net:7999/tsat3k/image-builder.git
HOST_MKSWU_VERSION = ea2b76281f69819416552edbdddb2e1ff200ed31
HOST_MKSWU_DEPENDENCIES = host-openssl host-cpio

define HOST_MKSWU_INSTALL_CMDS
	$(INSTALL) -m 0755 -D $(@D)/mkswu.py $(HOST_DIR)/bin/mkswu.py
endef

$(eval $(host-generic-package))
