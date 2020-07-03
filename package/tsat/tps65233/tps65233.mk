################################################################################
#
# tps65233
#
################################################################################

TPS65233_SITE_METHOD = git
TPS65233_SITE = ssh://git@dev.tsat.net:7999/lrsnmb/tps65233.git
TPS65233_VERSION = 0084471cdfb313ca5b249ef556e6b45d309eb21d

$(eval $(kernel-module))
$(eval $(generic-package))
