# (C) ETH Zurich 2022
# Authors: Jingo Bozzini

VERILOG_SOURCES = $(PWD)/EventGenerator2.sv 
# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file:
TOPLEVEL=EventGenerator2
# MODULE is the name of the Python test file:
MODULE=TestEventGenerator2


# use the Verilator for simulation
SIM=verilator
# set the timing precision (for performance reasons)
COCOTB_HDL_TIMEPRECISION = 100ps

# Tell it to trace the result
# if commented out, there won't be a dump file
EXTRA_ARGS += --trace --trace-structs


include $(shell cocotb-config --makefiles)/Makefile.sim

