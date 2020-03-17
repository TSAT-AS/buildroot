################################################################################
#
# mkbootimage
#
################################################################################

HOST_MKBOOTIMAGE_SITE_METHOD = git
HOST_MKBOOTIMAGE_SITE = https://github.com/antmicro/zynq-mkbootimage.git
HOST_MKBOOTIMAGE_VERSION = 4ee42d782a9ba65725ed165a4916853224a8edf7
HOST_MKBOOTIMAGE_LICENSE = BSD-2-Clause
HOST_MKBOOTIMAGE_LICENSE_FILES = LICENSE
HOST_MKBOOTIMAGE_DEPENDENCIES = host-pcre host-elfutils

define HOST_MKBOOTIMAGE_BUILD_CMDS
    $(MAKE) $(HOST_CONFIGURE_OPTS) -C $(@D) all
endef

define HOST_MKBOOTIMAGE_INSTALL_CMDS
	$(INSTALL) -m 0755 -D $(@D)/mkbootimage $(HOST_DIR)/bin/mkbootimage
endef

$(eval $(host-generic-package))
