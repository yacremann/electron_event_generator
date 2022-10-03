#   Simulation file for pulse pattern generator
#
#   (C) ETH Zurich
#   Group of Prof. Vaterlaus
#   Authors: Jingo Bozzini
#

import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge
from cocotb.result import TestFailure

@cocotb.test()
async def TestPulsePatternGenerator(dut):
    """Try accessing the design."""

    # set up the clock
    clock = Clock(dut.clk, 10, units="ns")  # Create a 10ns period clock on port clk
    cocotb.fork(clock.start())  # Start the clock
    # Synchronize with the clock
    await FallingEdge(dut.clk)
    
    # set the reset
    dut.reset = 1
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)
    
    # set up the input signals
    dut.reset = 0
    dut.valid_i = 1
    dut.coord_i = 0x01F
    await FallingEdge(dut.clk)
    
    # start signal
    dut.start_i = 1
    await FallingEdge(dut.clk)
    dut.start_i = 0
    await Timer(50, "ns")
    
    # set up the input signals with different values
    dut.coord_i = 0b101110
    await FallingEdge(dut.clk)
    
    # start signal
    dut.start_i = 1
    await FallingEdge(dut.clk)
    dut.start_i = 0
    await Timer(200, "ns")
    
    # set up the input signals with different values
    dut.valid_i = 0
    dut.coord_i = 0x01F
    await FallingEdge(dut.clk)
    
    # start signal
    dut.start_i = 1
    await FallingEdge(dut.clk)
    dut.start_i = 0
    await Timer(200, "ns")
