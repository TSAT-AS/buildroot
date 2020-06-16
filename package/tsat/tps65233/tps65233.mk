################################################################################
#
# tps65233
#
################################################################################

TPS65233_SITE_METHOD = git
TPS65233_SITE = ssh://git@dev.tsat.net:7999/lrsnmb/tps65233.git
TPS65233_VERSION = 779d223f5416021d7f9f0ff9a6ac61c79378936f

$(eval $(kernel-module))
$(eval $(generic-package))
