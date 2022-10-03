/*
    This event generator gives out the delay for 
    each x1,x2,y1,y2 pulse including the delay.
    The values can be put with the PC through 
    a microcontroller. The maximum points it 
    can save is currently 64.
    
        
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
module EventGenerator2(
        input logic                  clk_i,          // 100MHz    
        input logic                  reset_i,        // reset
        
        input  logic                 enable_i,       // enable to write in the RAM
        input  logic unsigned [5:0]  addr_storage_i, // addr for writing the RAM
        input  logic unsigned [31:0] data_storage_i, // data for writing
        output logic unsigned [31:0] data_read_o,    // read-back of data
        
        input  logic                 start_i,        //this start signal should always be only 1 cycles long 
        
        output logic                 valid_o,        //high if the output pulse should be generated
        output logic unsigned [9:0]  x1_o,           //x1 output 
        output logic unsigned [9:0]  x2_o,           //x2 output
        output logic unsigned [9:0]  y1_o,           //y1 output
        output logic unsigned [9:0]  y2_o            //y2 output
    
    );

    logic                   enable;
    logic unsigned [5:0]    addr_storage;
    logic unsigned [31:0]   data_storage;


    logic unsigned [5:0]    array_choose;
    
    logic unsigned [9:0]    t0;
    logic unsigned [5:0]    x_axis;         
    logic unsigned [5:0]    y_axis;
    logic                   valid;
    
    logic unsigned [9:0]    t0_reg;
    logic unsigned [5:0]    x_axis_reg;         
    logic unsigned [5:0]    y_axis_reg;
    logic                   valid_reg;
    
    logic unsigned [31:0]   array_pulse [63:0];
    
    logic unsigned [31:0]   read_data;
    

    // inferred 2-port memory
    always_ff @(posedge clk_i) begin
        if (enable_i) begin
             array_pulse [addr_storage_i] <= data_storage_i;
        end
    end
    assign data_read_o = array_pulse[addr_storage_i];

   
    //choose which array
    always_ff @(posedge clk_i)
    begin
        if(reset_i) 
        begin
            array_choose <= 6'b0;
        end 
        if (start_i)
        begin
            if (array_pulse[array_choose + 6'b1] == 0) // if the next entry is 0: go back to the first entry
            begin
                array_choose <= 0;
            end else 
            begin
                array_choose <= array_choose + 6'b1;
            end
        end
    end

    //saving the data in the right place
    assign read_data = array_pulse [array_choose];
    
    assign t0     = read_data [9:0];
    assign x_axis = read_data [15:10];
    assign y_axis = read_data [21:16];
    assign valid  = read_data [22];
    
    //register to buffer?
    always_ff @(posedge clk_i)
    begin
        t0_reg <= t0;
        x_axis_reg <= x_axis;
        y_axis_reg <= y_axis;
        valid_reg <= valid;
    end
    
    assign valid_o = valid_reg;
    
    //modify x1, x2, y1, y2 so that the axis is included
    assign x1_o = (t0_reg + 10'd32 - 10'(x_axis_reg));
    assign x2_o = (t0_reg - 10'd32 + 10'(x_axis_reg));
    assign y1_o = (t0_reg + 10'd32 - 10'(y_axis_reg));
    assign y2_o = (t0_reg - 10'd32 + 10'(y_axis_reg));

endmodule
