#   Simulation file for event generator
#
#   (C) ETH Zurich 2022
#   Group of Prof. Vaterlaus
#   Authors: Jingo Bozzini
#

import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge
from cocotb.result import TestFailure

import h5py
import numpy as np



@cocotb.test()
async def TestEventGenerator(dut):
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
    
    # switch off the reset
    dut.reset = 0
    await Timer(50, "ns")
    await FallingEdge(dut.clk)
    
    # prepare lists for storing the data:
    x1 = []
    x2 = []
    y1 = []
    y2 = []
    
    for i in range(0, 120):
    
        # start signal
        dut.start_i = 1
        await FallingEdge(dut.clk)
        dut.start_i = 0
        await FallingEdge(dut.clk)
        
        # save coord if valid
        if (dut.valid_o == 1):
            x1.append(dut.x1_coord.value.integer)
            x2.append(dut.x2_coord.value.integer)
            y1.append(dut.y1_coord.value.integer)
            y2.append(dut.y2_coord.value.integer)
        await FallingEdge(dut.clk)
        
        # to check if the code is still running
        if ((i % 1000) == 0):
            print(i)
            
    # save the various coord in "recorded_events"
    myfile = h5py.File('recorded_events.h5', 'w')
    myfile['x1'] = np.asarray(x1)
    myfile['x2'] = np.asarray(x2)
    myfile['y1'] = np.asarray(y1)
    myfile['y2'] = np.asarray(y2)
    myfile.close()
