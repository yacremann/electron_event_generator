#Differential signals
set_property IOSTANDARD LVDS_25 [get_ports TDC_signal_y1_p]
set_property IOSTANDARD LVDS_25 [get_ports TDC_signal_y1_n]
set_property IOSTANDARD LVDS_25 [get_ports TDC_signal_y2_p]
set_property IOSTANDARD LVDS_25 [get_ports TDC_signal_y2_n]
set_property IOSTANDARD LVDS_25 [get_ports TDC_signal_x1_p]
set_property IOSTANDARD LVDS_25 [get_ports TDC_signal_x1_n]
set_property IOSTANDARD LVDS_25 [get_ports TDC_signal_x2_p]
set_property IOSTANDARD LVDS_25 [get_ports TDC_signal_x2_n]

# set_property IOSTANDARD LVDS_25 [get_ports {LVDS_unused2_p LVDS_unused2_n}]
# set_property IOSTANDARD LVDS_25 [get_ports {LVDS_unused1_p LVDS_unused1_n}]


#Single ended signals
set_property IOSTANDARD LVCMOS33 [get_ports clk_i]
create_clock -period 10.000 [get_ports clk_i]


set_property IOSTANDARD LVCMOS33 [get_ports led_o]




set_property IOSTANDARD LVCMOS33 [get_ports Start_i]

set_property IOSTANDARD LVCMOS33 [get_ports TMS_i]
set_property IOSTANDARD LVCMOS33 [get_ports TDO_i]
set_property IOSTANDARD LVCMOS33 [get_ports TDI_o]
set_property IOSTANDARD LVCMOS33 [get_ports TCK_i]

set_property IOSTANDARD LVCMOS33 [get_ports RXD_o]
set_property IOSTANDARD LVCMOS33 [get_ports TXD_i]

set_property IOSTANDARD LVCMOS33 [get_ports unused4]
set_property IOSTANDARD LVCMOS33 [get_ports unused3]
set_property IOSTANDARD LVCMOS33 [get_ports unused2]
set_property IOSTANDARD LVCMOS33 [get_ports unused1]


#Differential signals
set_property PACKAGE_PIN H2 [get_ports TDC_signal_y1_p]
set_property PACKAGE_PIN G2 [get_ports TDC_signal_y1_n]
set_property PACKAGE_PIN E3 [get_ports TDC_signal_y2_p]
set_property PACKAGE_PIN D3 [get_ports TDC_signal_y2_n]
set_property PACKAGE_PIN H1 [get_ports TDC_signal_x1_p]
set_property PACKAGE_PIN G1 [get_ports TDC_signal_x1_n]
set_property PACKAGE_PIN E2 [get_ports TDC_signal_x2_p]
set_property PACKAGE_PIN D2 [get_ports TDC_signal_x2_n]

# set_property PACKAGE_PIN C5     [get_ports LVDS_unused2_n]
# set_property PACKAGE_PIN C6     [get_ports LVDS_unused2_p]
# set_property PACKAGE_PIN D7     [get_ports LVDS_unused1_n]
# set_property PACKAGE_PIN E7     [get_ports LVDS_unused1_p]


#Single ended signals
set_property PACKAGE_PIN P17 [get_ports clk_i]
set_property PACKAGE_PIN M16 [get_ports led_o]

set_property PACKAGE_PIN U6 [get_ports Start_i]

set_property PACKAGE_PIN N5 [get_ports TMS_i]
set_property PACKAGE_PIN T5 [get_ports TDO_i]
set_property PACKAGE_PIN T3 [get_ports TDI_o]
set_property PACKAGE_PIN P4 [get_ports TCK_i]

set_property PACKAGE_PIN T1 [get_ports RXD_o]
set_property PACKAGE_PIN R2 [get_ports TXD_i]

set_property PACKAGE_PIN U3 [get_ports unused4]
set_property PACKAGE_PIN U2 [get_ports unused3]
set_property PACKAGE_PIN U1 [get_ports unused2]
set_property PACKAGE_PIN P5 [get_ports unused1]


#FLASH QSPI signals
set_property IOSTANDARD LVCMOS33 [get_ports {spi_io0_io spi_io1_io spi_io2_io spi_io3_io spi_ss_io}]
set_property PACKAGE_PIN K17 [get_ports spi_io0_io]
set_property PACKAGE_PIN K18 [get_ports spi_io1_io]
set_property PACKAGE_PIN L14 [get_ports spi_io2_io]
set_property PACKAGE_PIN M14 [get_ports spi_io3_io]
set_property PACKAGE_PIN L13 [get_ports spi_ss_io]

set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]




