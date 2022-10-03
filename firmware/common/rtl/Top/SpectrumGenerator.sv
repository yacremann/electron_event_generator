`timescale 1ns / 1ps

/*
    The SpectrumGenerator contains an EventGenerator and four PulsePatternGenerators.
    The output are input signals for the serializer to generate the pulses for the 
    TDC. The spectrum generator generates electron events, which correspond to a
    photoelectron spectrum.
    
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

module SpectrumGenerator#(
       parameter LFSR_initial_value = 0
    )(
        input logic clk_i,
        input logic reset_i,
        
        input logic start_i,
        input logic enable_i,
        output logic [31:0] data_serializer_o
    );
    
    
    logic                    valid;                  //validation from the coord data
    logic unsigned [9:0]     x1_coord;               //x1 coord
    logic unsigned [9:0]     x2_coord;               //x2 coord
    logic unsigned [9:0]     y1_coord;               //y1 coord
    logic unsigned [9:0]     y2_coord;               //y2 coord
    
    logic [7:0]     pulse_x1_o;             //output for serializer
    logic [7:0]     pulse_x2_o;             //output for serializer
    logic [7:0]     pulse_y1_o;             //output for serializer
    logic [7:0]     pulse_y2_o;             //output for serializer
    
    EventGenerator #(
        .LFSR_initial_value(LFSR_initial_value)
    ) eventGenerator (
        .clk(clk_i),                                //100MHz    
        .reset(reset_i),                              //reset
    
        .start_i(start_i),                      //this start signal should always be only 1 cycles long (will be made in top file)
    
        .valid_o(valid),                            //high if the output pulse should be generated
        .x1_coord(x1_coord),                        //x1 output 
        .x2_coord(x2_coord),                        //x2 output
        .y1_coord(y1_coord),                        //y1 output
        .y2_coord(y2_coord)                         //y2 output
    );


    PulsePatternGenerator pulse_for_x1(
        .clk(clk_i),                                  //100MHz
        .reset(reset_i),                              //reset
        
        .start_i(start_i),                      //this start signal should always be only 1 cycles long (will be made in top file)
        .valid_i(valid & enable_i),                            //validetes the coord data
        .coord_i(x1_coord),                         //coord data x1 from Event generator
        
        .pulse_o(pulse_x1_o)                        //output for serializer x1
    );
    
    PulsePatternGenerator pulse_for_x2(
        .clk(clk_i),                                  //100MHz
        .reset(reset_i),                              //reset
        
        .start_i(start_i),                      //this start signal should always be only 1 cycles long (will be made in top file)
        .valid_i(valid & enable_i),                            //validetes the coord data
        .coord_i(x2_coord),                         //coord data x2 from Event generator
        
        .pulse_o(pulse_x2_o)                        //output for serializer x2
    );
    
    PulsePatternGenerator pulse_for_y1(
        .clk(clk_i),                                  //100MHz
        .reset(reset_i),                              //reset
        
        .start_i(start_i),                      //this start signal should always be only 1 cycles long (will be made in top file)
        .valid_i(valid & enable_i),                            //validetes the coord data
        .coord_i(y1_coord),                         //coord data y1 from Event generator
        
        .pulse_o(pulse_y1_o)                        //output for serializer y1
    );
    
    PulsePatternGenerator pulse_for_y2(
        .clk(clk_i),                                  //100MHz
        .reset(reset_i),                              //reset
        
        .start_i(start_i),                      //this start signal should always be only 1 cycles long (will be made in top file)
        .valid_i(valid & enable_i),                            //validetes the coord data
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
