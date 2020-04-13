################################################################################
#
# terminal
#
################################################################################

TERMINAL_SITE_METHOD = git
TERMINAL_GIT_SUBMODULES = yes
TERMINAL_SITE = ssh://git@dev.tsat.net:7999/tsat3k/terminal-converted.git
TERMINAL_VERSION = 214740844a2185d8a69db37b3583d3d7bebb2f16
TERMINAL_CONF_OPTS = -DCMAKE_BUILD_TYPE=Release
TERMINAL_DEPENDENCIES = host-cmake boost libnftnl libnl libopenssl libgpiod libiio

define TERMINAL_INSTALL_TARGET_CMDS
  $(HOST_DIR)/bin/cmake --build $(@D) --target package
  $(INSTALL) -m 0644 $(@D)/*terminal.tar.gz $(BINARIES_DIR)/terminal.tar.gz
  $(INSTALL) -m 0644 $(@D)/*fpga.tar.gz $(BINARIES_DIR)/fpga.tar.gz
endef

$(eval $(cmake-package))
