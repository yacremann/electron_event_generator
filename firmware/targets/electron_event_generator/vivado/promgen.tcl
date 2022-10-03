# Programming device: s25fl256sxxxxxx0

set format   "mcs"
set inteface "SPIx4"
set size     "256"

source -quiet $::env(RUCKUS_DIR)/vivado_env_var.tcl
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# also export the hardware desctiption to the software directory
write_hw_platform -fixed -include_bit -force -file ${TOP_DIR}/../software/electron_event_generator.xsa
