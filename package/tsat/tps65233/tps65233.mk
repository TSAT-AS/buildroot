################################################################################
#
# tps65233
#
################################################################################

TPS65233_SITE_METHOD = git
TPS65233_SITE = ssh://git@dev.tsat.net:7999/lrsnmb/tps65233.git
TPS65233_VERSION = 870fbab86fa41e9e8fa8b3ef777869f0ddff153d

$(eval $(kernel-module))
$(eval $(generic-package))
