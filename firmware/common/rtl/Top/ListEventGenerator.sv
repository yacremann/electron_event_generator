`timescale 1ns / 1ps
/*
    The ListEventGenerator stores a list of events. On each start signal, one event
    will be generated and sent to the serializer to generate the corresponding output pulse.
    
    Copyright 2022 ETH Zurich

    SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

    Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may not use this file except in compliance with the License, or, at your option, the Apache License version 2.0.
    You may obtain a copy of the License at

    https://solderpad.org/licenses/SHL-2.1/
       
    Unless required by applicable law or agreed to in writing, any work distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and limitations under the License.

    Group of Prof. Vaterlaus
    Authors: Jingo Bozzini, Yves Acremann
*/
module ListEventGenerator#(
        parameter StartAddress = 0
    )(
        input  logic        clk_i,              // sys clk (100 MHz)
        input  logic        reset_i,            // reset, active high
        
        ApbBus.Slave        bus,                // APB bus
        
        input  logic        start_i,            // start signal (strobe)
        output logic [31:0] data_serializer_o   // output to the serializer
    );
    
    logic [5:0] ram_addr;
    
    logic                    valid;         //validation from the coord data
    logic unsigned [9:0]     x1_coord;      //x1 coord
    logic unsigned [9:0]     x2_coord;      //x2 coord
    logic unsigned [9:0]     y1_coord;      //y1 coord
    logic unsigned [9:0]     y2_coord;      //y2 coord
    
    logic [7:0]     pulse_x1_o;             //output for serializer
    logic [7:0]     pulse_x2_o;             //output for serializer
    logic [7:0]     pulse_y1_o;             //output for serializer
    logic [7:0]     pulse_y2_o;             //output for serializer
    
    
    // calculate the RAM address:
    assign ram_addr = 6'((bus.PADDR - 32'(StartAddress)) >> 2);
    // generate the RAM enable signal (condition: address is correct, select and enable are 1)
    assign ram_enable = (bus.PENABLE & (bus.PSEL > 0)) & (bus.PADDR >= 32'(StartAddress)) & (bus.PADDR < (32'(StartAddress)+32'h100));
    // Write enable if the bus wants to write and ram_enable = 1
    assign ram_write = ram_enable & bus.PWRITE;
    
    // enable signal for the control bus
    logic control_reg_enable;
    assign control_reg_enable = (bus.PENABLE & (bus.PSEL > 0)) & (bus.PADDR == (32'(StartAddress)+32'h100));
    
    // control register 
    logic [31:0] control_reg;
    always_ff @(posedge clk_i) begin
        if (reset_i)
            control_reg <= 32'h0;
        else if (control_reg_enable & bus.PWRITE)
            control_reg <= bus.PWDATA;
    end
    logic enable_pulser;
    assign enable_pulser = control_reg[0];
    
    
    
    assign bus.PREADY = 1;
    
    logic [31:0] data_read_ram;
    
    always_comb begin
        bus.PRDATA = 32'h0;
        if (ram_enable) bus.PRDATA = data_read_ram;
        if (control_reg_enable) bus.PRDATA = control_reg;
    end
    
    
    
    EventGenerator2 eventGenerator(
        .clk_i(clk_i),
        .reset_i(reset_i),         //reset
        
        .enable_i(ram_write),      //enable to write in array
        .addr_storage_i(ram_addr),
        .data_storage_i(bus.PWDATA),
        .data_read_o(data_read_ram),
    
        .start_i(start_i),         //this start signal should always be only 1 cycles long 
    
        .valid_o(valid),           //high if the output pulse should be generated
        .x1_o(x1_coord),           //x1 output 
        .x2_o(x2_coord),           //x2 output
        .y1_o(y1_coord),           //x1 output 
        .y2_o(y2_coord)
    );
    
    
    PulsePatternGenerator pulse_for_x1(
        .clk(clk_i),                                //100MHz
        .reset(reset_i),                            //reset
        
        .start_i(start_i),                          //this start signal should always be only 1 cycles long (will be made in top file)
        .valid_i(valid & enable_pulser),                            //validetes the coord data
        .coord_i(x1_coord),                         //coord data x1 from Event generator
        
        .pulse_o(pulse_x1_o)                        //output for serializer x1
    );
    
    PulsePatternGenerator pulse_for_x2(
        .clk(clk_i),                                 //100MHz
        .reset(reset_i),                             //reset
        
        .start_i(start_i),                          //this start signal should always be only 1 cycles long (will be made in top file)
        .valid_i(valid & enable_pulser),                            //validetes the coord data
        .coord_i(x2_coord),                         //coord data x2 from Event generator
        
        .pulse_o(pulse_x2_o)                        //output for serializer x2
    );
    
    PulsePatternGenerator pulse_for_y1(
        .clk(clk_i),                                //100MHz
        .reset(reset_i),                            //reset
        
        .start_i(start_i),                          //this start signal should always be only 1 cycles long (will be made in top file)
        .valid_i(valid & enable_pulser),                            //validetes the coord data
        .coord_i(y1_coord),                         //coord data y1 from Event generator
        
        .pulse_o(pulse_y1_o)                        //output for serializer y1
    );
    
    PulsePatternGenerator pulse_for_y2(
        .clk(clk_i),                                //100MHz
        .reset(reset_i),                            //reset
        
        .start_i(start_i),                          //this start signal should always be only 1 cycles long (will be made in top file)
        .valid_i(valid & enable_pulser),                            //validetes the coord data
        .coord_i(y2_coord),                         //coord data y2 from Event generator
        
        .pulse_o(pulse_y2_o)                        //output for serializer y2
    );
    
    
    genvar i;
    generate
        for (i = 0; i < 8; i++) begin
            assign data_serializer_o[(i*4)+0] = pulse_y1_o[i];
            assign data_serializer_o[(i*4)+1] = pulse_y2_o[i];
            assign data_serializer_o[(i*4)+2] = pulse_x1_o[i];
            assign data_serializer_o[(i*4)+3] = pulse_x2_o[i];
        end
    endgenerate
    
endmodule
