################################################################################
#
# tps65233
#
################################################################################

TPS65233_SITE_METHOD = git
TPS65233_SITE = ssh://git@dev.tsat.net:7999/lrsnmb/tps65233.git
TPS65233_VERSION = c69f9ff4c25ed22d76a653ccd87cce8739f5e595

$(eval $(kernel-module))
$(eval $(generic-package))
