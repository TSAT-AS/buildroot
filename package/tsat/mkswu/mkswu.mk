################################################################################
#
# mkswu
#
################################################################################

HOST_MKSWU_SITE_METHOD = git
HOST_MKSWU_SITE = ssh://git@dev.tsat.net:7999/tsat3k/image-builder.git
HOST_MKSWU_VERSION = 992315f69133cd2cbab5c65310e04bd1c51664ce
HOST_MKSWU_DEPENDENCIES = host-openssl host-cpio

define HOST_MKSWU_INSTALL_CMDS
	$(INSTALL) -m 0755 -D $(@D)/mkswu.py $(HOST_DIR)/bin/mkswu.py
endef

$(eval $(host-generic-package))
