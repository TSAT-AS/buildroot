################################################################################
#
# tps65233
#
################################################################################

TPS65233_SITE_METHOD = git
TPS65233_SITE = ssh://git@dev.tsat.net:7999/lrsnmb/tps65233.git
TPS65233_VERSION = cb617f7241c0cf88422e858c96d2ae4686747e47

$(eval $(kernel-module))
$(eval $(generic-package))
