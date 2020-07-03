################################################################################
#
# adrf6755
#
################################################################################

ADRF6755_SITE_METHOD = git
ADRF6755_SITE = ssh://git@dev.tsat.net:7999/lrsnmb/adrf6755.git
ADRF6755_VERSION = 472ea6a9dfb4295c985fc018957d5f7137de7eb6

$(eval $(kernel-module))
$(eval $(generic-package))
