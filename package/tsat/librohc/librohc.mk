################################################################################
#
# librohc
#
################################################################################
LIBROHC_VERSION = tsat-rohc-2.3.0
LIBROHC_SOURCE = $(LIBROHC_VERSION).tar.gz
LIBROHC_SITE = https://github.com/TSAT-AS/rohc/archive
LIBROHC_AUTORECONF = YES
LIBROHC_CONF_OPTS = --enable-rohc-debug
LIBROHC_INSTALL_STAGING = YES
LIBROHC_INSTALL_TARGET = YES
LIBROHC_DEPENDENCIES = libpcap cmocka

$(eval $(autotools-package))
