################################################################################
#
# adrf6755
#
################################################################################

ADRF6755_SITE_METHOD = git
ADRF6755_SITE = ssh://git@dev.tsat.net:7999/lrsnmb/adrf6755.git
ADRF6755_VERSION = 1f197df2e7c533e888d00804ca3cbaf6880f1b71

$(eval $(kernel-module))
$(eval $(generic-package))
