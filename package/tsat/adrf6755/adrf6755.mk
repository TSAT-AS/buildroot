################################################################################
#
# adrf6755
#
################################################################################

ADRF6755_SITE_METHOD = git
ADRF6755_SITE = ssh://git@dev.tsat.net:7999/lrsnmb/adrf6755.git
ADRF6755_VERSION = 4bd74502e0fa78800c4d8ecf1de8455d4968fec4

$(eval $(kernel-module))
$(eval $(generic-package))
