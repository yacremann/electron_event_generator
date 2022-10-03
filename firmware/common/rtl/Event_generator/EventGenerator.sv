/*
    The event generator calculates random delay
    times x1, x2, y1, y2 with start signal.
    The valid signal states, if the output pulse
    is generated or not.
    
    
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



module EventGenerator #(
    parameter LFSR_initial_value = 0
)(
    input logic                 clk,                //100MHz    
    input logic                 reset,              //reset
    
    input logic                 start_i,            //this start signal should always be only 1 cycles long (will be made in top file)
    
    output logic                valid_o,            //high if the output pulse should be generated
    output logic unsigned [9:0] x1_coord,           //x1 output 
    output logic unsigned [9:0] x2_coord,           //x2 output
    output logic unsigned [9:0] y1_coord,           //y1 output
    output logic unsigned [9:0] y2_coord            //y2 output
    
);

    logic [31:0]            LFSR_data_o;
    logic [31:0]            LFSR_data_o_reg;
    
    logic unsigned [9:0]    q;
    logic unsigned [9:0]    actual_time;  
    logic unsigned [9:0]    p;
    logic unsigned [5:0]    x_axis;         
    logic unsigned [5:0]    y_axis;
    
    logic unsigned [9:0]    q_reg;
    logic unsigned [9:0]    actual_time_reg;  
    logic unsigned [5:0]    x_axis_reg;         
    logic unsigned [5:0]    y_axis_reg;
    

    

    //Linear Feedback Shift Register (LFSR)
    //all states (expect 0) should be gone through in ~43s when the clock is 100MHz.
    LFSR #(
        .NUM_BITS(32)
    ) lFSR (
    
        .i_Clk(clk),                            //100MHz
        .i_Enable(1),
     
        .i_Seed_DV(reset),                      //set seed
        .i_Seed_Data(32'(LFSR_initial_value)),  //set value for seed (currently unused)
         
        .o_LFSR_Data(LFSR_data_o),              //generated number
        .o_LFSR_Done()                          //goes to 1 if every went through (currently unused)
    );

    //register for generated PRNG number
    always_ff @(posedge clk)
    begin
        if (start_i)
        begin
            LFSR_data_o_reg <= LFSR_data_o;
        end
    end

    //the prng value used for the number q, actual_time, x_axis and y_axis
    assign q = LFSR_data_o_reg [9:0];
    assign actual_time = LFSR_data_o_reg [19:10];
    assign x_axis = LFSR_data_o_reg [25:20];
    assign y_axis = LFSR_data_o_reg [31:26];
    
    // rendez-vous delay, adjusts forthe delay from the LUT
    always_ff @(posedge clk)
    begin
        q_reg <= q;
        actual_time_reg <= actual_time;
        x_axis_reg <= x_axis;
        y_axis_reg <= y_axis;
    end
    
    //gives out the probability p
    LUT_spectrum lUT_spectrum (
        .clk_i(clk),
        .addr_i(actual_time),
        .data_o(p)
    );

    //valid is high when probability is higher than the q.
    //additionally it doesn't allow over/underflow.
    //lastly it is limited for 100clock cycles (1MHz)
    //                                                                                  it is *8 because the LSB for delay (in clockcycles) in PulsePatternGenerator is at Bit4
    //                                                      (minimum increment)         (100 clock-cycles long (100*8 + 7) - maximum increment - cycles used in PulsePatternGenerator)
    //                                                                                  ((100*8 + 7) - 32 - 5*8) 
    assign valid_o = (p > q_reg) & (actual_time_reg >= 32) & (actual_time_reg <= 10'(807 - 73));
    
    

    //modify x1, x2, y1, y2 so that the axis is included
    assign x1_coord = (actual_time_reg + 10'd32 - 10'(x_axis_reg));
    assign x2_coord = (actual_time_reg - 10'd32 + 10'(x_axis_reg));
    assign y1_coord = (actual_time_reg + 10'd32 - 10'(y_axis_reg));
    assign y2_coord = (actual_time_reg - 10'd32 + 10'(y_axis_reg));

endmodule
