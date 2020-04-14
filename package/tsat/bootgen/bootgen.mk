################################################################################
#
# bootgen
#
################################################################################

HOST_BOOTGEN_SITE_METHOD = git
HOST_BOOTGEN_SITE = https://github.com/Xilinx/bootgen.git
HOST_BOOTGEN_VERSION = d18107e10a753dca76555eef265ad9d631e66db6
HOST_BOOTGEN_LICENSE = Apache-2.0
HOST_BOOTGEN_LICENSE_FILES = LICENSE
HOST_BOOTGEN_DEPENDENCIES = host-libopenssl

define HOST_BOOTGEN_BUILD_CMDS
    $(MAKE) $(HOST_CONFIGURE_OPTS) -C $(@D) all
endef

define HOST_BOOTGEN_INSTALL_CMDS
	$(INSTALL) -m 0755 -D $(@D)/bootgen $(HOST_DIR)/bin/bootgen
endef

$(eval $(host-generic-package))
