BIN_DIR=/opt/Xilinx/Vitis/2021.2/bin/

$BIN_DIR/updatemem -force -meminfo \
_ide/bitstream/electron_event_generator.mmi \
-bit \
_ide/bitstream/electron_event_generator.bit \
-data \
Debug/DldSimulator.elf \
-proc cpu/microcontroller_i/microblaze_0 -out \
_ide/bitstream/download.bit 



# program the FLASH memory

$BIN_DIR/program_flash -f \
_ide/bitstream/download.bit \
-offset 0 -flash_type s25fl256sxxxxxx0-spi-x1_x2_x4 -verify -cable type xilinx_tcf url \
TCP:127.0.0.1:3121


rm -f updatemem_*
rm -f updatemem.jou
rm -f updatemem.log
