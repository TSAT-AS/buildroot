################################################################################
#
# adrf6755
#
################################################################################

ADRF6755_SITE_METHOD = git
ADRF6755_SITE = ssh://git@dev.tsat.net:7999/lrsnmb/adrf6755.git
ADRF6755_VERSION = 7ac3fbf41b9b4986394f40691068e9c47a3a9dae

$(eval $(kernel-module))
$(eval $(generic-package))
