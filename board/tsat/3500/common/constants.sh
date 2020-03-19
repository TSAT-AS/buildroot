# build output storage host
HOST='avsatcom@10.80.85.32'

# deployment category directories on host
DIR_TOP_LEVEL='Share/data/rd/TSAT3500/jenkins'
DIR_PARENT_TERMINAL="$DIR_TOP_LEVEL/terminal"
DIR_PARENT_FPGA="$DIR_TOP_LEVEL/fpga"

# latest deployment directories, per category
DIR_LATEST='latest'
DIR_LATEST_TERMINAL="$DIR_PARENT_TERMINAL/$DIR_LATEST"
DIR_LATEST_FPGA="$DIR_PARENT_FPGA/$DIR_LATEST"
