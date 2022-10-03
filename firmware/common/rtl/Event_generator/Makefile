VERILOG_SOURCES = $(PWD)/EventGenerator.sv $(PWD)/LFSR.sv $(PWD)/LUT_spectrum.sv
# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file:
TOPLEVEL=EventGenerator
# MODULE is the name of the Python test file:
MODULE=TestEventGenerator


# use the Verilator for simulation
SIM=verilator
# set the timing precision (for performance reasons)
COCOTB_HDL_TIMEPRECISION = 100ps

# Tell it to trace the result
# if commented out, there won't be a dump file
EXTRA_ARGS += --trace --trace-structs


include $(shell cocotb-config --makefiles)/Makefile.sim

