# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# load block diagrams
loadBlockDesign -dir  "$::DIR_PATH/bd/microcontroller"

# Load IP
loadIpCore -dir  "$::DIR_PATH/ip/clk_generator"
loadIpCore -dir  "$::DIR_PATH/ip/serializer"

# load block diagrams
loadBlockDesign -path  "$::DIR_PATH/bd/microcontroller/microcontroller.bd"

# Load Source Code
loadSource -dir  "$::DIR_PATH/rtl/Event_generator"
loadSource -dir  "$::DIR_PATH/rtl/Event_generator2"
loadSource -dir  "$::DIR_PATH/rtl/Pulse_pattern_generator"
loadSource -dir  "$::DIR_PATH/rtl/Top"
