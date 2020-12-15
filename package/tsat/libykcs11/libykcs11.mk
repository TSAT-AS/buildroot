################################################################################
#
# libykcs11
#
################################################################################
HOST_LIBYKCS11_SITE_METHOD = git
HOST_LIBYKCS11_SITE = https://github.com/Yubico/yubico-piv-tool.git
HOST_LIBYKCS11_VERSION = yubico-piv-tool-2.1.1
HOST_LIBYKCS11_CONF_OPTS = -DGENERATE_MAN_PAGES=OFF -DBUILD_STATIC_LIB=OFF
HOST_LIBYKCS11_MAKE_OPTS = ykcs11
HOST_LIBYKCS11_DEPENDENCIES = host-gengetopt host-libopenssl host-libp11

$(eval $(host-cmake-package))
