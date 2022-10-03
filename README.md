Signal generator for testing the TDC and integrating it into the DAQ system at LCLS-II
======================================================================================

This is a hardware signal generator to simulate electron events from a momentum-resolved
time-of-flight electron spectrometer. The output are pulses sent to the time-to-digital (TDC) converter
unit from Surface Concept. Our generator is useful for testing the TDC and interating it into the
DAQ system at LCLS-II.

License:
--------
The code written by our group is released under the Solderpad license (see LICENSE.md).
This project also includes code written by the Xilinx Vivado and Vitis software. See license note within these files.

Directories:
------------
* Board: The PCB design of the adapter board to the FPGA board from Trenz Electronics (TE0725-03-100-2C)

* firmware: FPGA design files using the Ruckus build system. It also contains the simulation files using Cocotb and Verilator

* software: The software running on the softcore-CPU to communicate with the host (using an UART on the board)

* Python: Drivers and GUI to configure the electron event generator.


Build the firmware:
-------------------
cd firmware/targets/electron_event_generator/
make
(or "make gui" to get into the vivado gui)

make also generated the exported hardware in ./software

Caution: The vivado binary (version 2021.2) needs to be in the path!

Building the software on the device:
------------------------------------
still work in progress; semi-manual process (see README file therein).
You need to create an external workspace directory for Vitis and import the files.

Required software:
------------------
* Vivado and Vitis, tested with version 2021.2

* For simulating: Verilator (v.4.106), Cocotb

* Kicad version 6

* Ruckus (sub-repository)
