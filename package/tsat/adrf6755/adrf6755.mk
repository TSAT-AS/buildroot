################################################################################
#
# adrf6755
#
################################################################################

ADRF6755_SITE_METHOD = git
ADRF6755_SITE = ssh://git@dev.tsat.net:7999/lrsnmb/adrf6755.git
ADRF6755_VERSION = 1b4559ffa71e1b3113b79849aebf65079b3ff05d

$(eval $(kernel-module))
$(eval $(generic-package))
