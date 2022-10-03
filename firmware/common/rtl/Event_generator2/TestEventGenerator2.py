#   Simulation file for event generator 2
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

import h5py
import numpy as np



@cocotb.test()
async def TestEventGenerator2(dut):
    """Try accessing the design."""

    # set up the clock
    clock = Clock(dut.clk_i, 10, units="ns")  # Create a 10ns period clock on port clk
    cocotb.fork(clock.start())  # Start the clock
    # Synchronize with the clock
    await FallingEdge(dut.clk_i)
    
    # set the reset
    dut.reset_i = 1
    await FallingEdge(dut.clk_i)
    await FallingEdge(dut.clk_i)
    
    # switch off the reset
    dut.reset_i = 0
    await FallingEdge(dut.clk_i)
    await FallingEdge(dut.clk_i)
    
    
    
    #check if able to read write every register (in array)
    data = 0x00000030
    addr = 0x00
    
    for i in range(0, 63):
        dut.addr_storage_i = addr
        dut.data_storage_i = data
        await FallingEdge(dut.clk_i)
        dut.enable_i = 1
        await FallingEdge(dut.clk_i)
        dut.enable_i = 0
        await FallingEdge(dut.clk_i)
        data += 1
        addr += 1
        await FallingEdge(dut.clk_i)
    
    for i in range(0, 63):
        dut.start_i = 1
        await FallingEdge(dut.clk_i)
        dut.start_i = 0
        await FallingEdge(dut.clk_i)
        await FallingEdge(dut.clk_i)
        
        
        
    #check if data in array is 0 that it goes to the beginning
    dut.addr_storage_i = 24
    dut.data_storage_i = 0
    await FallingEdge(dut.clk_i)
    dut.enable_i = 1
    await FallingEdge(dut.clk_i)
    dut.enable_i = 0
    await FallingEdge(dut.clk_i)
        
    for i in range(0, 63):
        dut.start_i = 1
        await FallingEdge(dut.clk_i)
        dut.start_i = 0
        await FallingEdge(dut.clk_i)
        await FallingEdge(dut.clk_i)
        
        
        
    #check t0, x_axis, y_axis, valid functions properly
    #1-10 = t0
    #11-16 = x_axis
    #17-22 = y_axis
    #23 = valid
    
    #t0 + 0x11
    #x_axis + 1
    #y_axis + 2
    #valid (on/off)
    addr = 0
    data = 0x00463030
    for i in range(0, 10):
        dut.addr_storage_i = addr
        dut.data_storage_i = data
        await FallingEdge(dut.clk_i)
        dut.enable_i = 1
        await FallingEdge(dut.clk_i)
        dut.enable_i = 0
        await FallingEdge(dut.clk_i)
        addr += 1
        data += 0x00020411
        data &= ~(0x00400000)
        await FallingEdge(dut.clk_i)
        dut.addr_storage_i = addr
        dut.data_storage_i = data
        await FallingEdge(dut.clk_i)
        dut.enable_i = 1
        await FallingEdge(dut.clk_i)
        dut.enable_i = 0
        await FallingEdge(dut.clk_i)
        addr += 1
        data += 0x00020411
        data |= 0x00400000
        await FallingEdge(dut.clk_i)
      
    #setting the other data to 0
    addr -= 1
    for i in range(0, 43):  
        addr += 1
        data = 0
        await FallingEdge(dut.clk_i)
        dut.addr_storage_i = addr
        dut.data_storage_i = data
        await FallingEdge(dut.clk_i)
        dut.enable_i = 1
        await FallingEdge(dut.clk_i)
        dut.enable_i = 0
        await FallingEdge(dut.clk_i)
    
    for i in range(0, 63):
        dut.start_i = 1
        await FallingEdge(dut.clk_i)
        dut.start_i = 0
        await FallingEdge(dut.clk_i)
        await FallingEdge(dut.clk_i)
    
    
