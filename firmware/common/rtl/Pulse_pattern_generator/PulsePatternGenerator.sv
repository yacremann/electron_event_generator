/* 
    The Pulse pattern generator will generate a 8bit
    signal which will be connected to the serializer.
    The output of the serializer is a two-bit pulse. Its delay
    is set by the input "coord_i".
    
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
module PulsePatternGenerator(
    input logic                 clk,                //100MHz
    input logic                 reset,              //reset
    
    input logic                 start_i,            //this start signal should always be only 1 cycles long (will be made in top file)
    input logic                 valid_i,            //validetes the coord data
    input logic unsigned [9:0]  coord_i,            //time from Event generator
    
    output logic [7:0]          pulse_o             //output for serializer
);

    logic [9:0]                 coord_reg;

    logic unsigned [6:0]        delay_long;
    logic [2:0]                 delay_short;
    
    logic [15:0]                pulse_pattern_long; 
    logic [7:0]                 pulse_pattern1;
    logic [7:0]                 pulse_pattern2;
    
    logic unsigned [6:0]        count_delay_q;
    logic unsigned [6:0]        count_delay_d;
    
    logic [7:0]                 pulse_o_temp;
    
    //register for coord_i and valid_i
    always_ff @(posedge clk)
    begin
        if (start_i & valid_i)
        begin
            coord_reg <= coord_i;
        end
    end
    
    //the bottom 3 bits of coord_reg are used to create the pulse pattern
    //the top 7 bits (aka the rest) of coord_reg are used to delay the pulse_pattern
    assign delay_long [6:0] = coord_reg [9:3];
    assign delay_short [2:0] = coord_reg [2:0];
    
    //this line is created if the serializer pushes data from LSB to MSB
    assign pulse_pattern_long   = 16'b11 << delay_short;
    assign pulse_pattern1 [7:0] = pulse_pattern_long [7:0];
    assign pulse_pattern2 [7:0] = pulse_pattern_long [15:8];


    //state machine
    //define states
    typedef enum logic [1:0] {
        IDLE,           // wait till start comes
        WAIT_DELAY,     // wait delay for pulse
        PATTERN1,       // output pulse_pattern1 to MUX
        PATTERN2        // output pulse_pattern2 to MUX
    } state_t;
    state_t state_d, state_q;
    
    // transition logic
    always_comb begin
        state_d = state_q;
        
        case (state_q)
        
            IDLE:
                //only changes if the valid is high (with start signal)
                if (start_i & valid_i)
                    state_d = WAIT_DELAY;
                        
            WAIT_DELAY: 
                if (delay_long <= count_delay_q) 
                    state_d = PATTERN1;
                
            PATTERN1: 
                state_d = PATTERN2;
                    
            PATTERN2: 
                state_d = IDLE;
                    
            default: state_d = IDLE;
            
        endcase
    end
    
    //state register
    always_ff @(posedge clk, posedge reset) begin
        //for reset
        if (reset == 1)
            state_q <= IDLE;
        else
            state_q <= state_d;
    end
    
    //counter for delay
    always_ff @(posedge clk) begin
        if (state_q == WAIT_DELAY) begin
            count_delay_q <= count_delay_d;
        end else begin
            count_delay_q <= 0; // was 1
        end
    end
    assign count_delay_d = count_delay_q + 1;
    
    //MUX
    always @(posedge clk)
    begin
        case (state_q) 
            IDLE:           pulse_o_temp <= 8'b0;
            WAIT_DELAY:     pulse_o_temp <= 8'b0;
            PATTERN1:       pulse_o_temp <= pulse_pattern1;
            PATTERN2:       pulse_o_temp <= pulse_pattern2;
            default:        pulse_o_temp <= 8'b0;
        endcase 
    end 
    
    //register for pulse_o
    always_ff @(posedge clk)
    begin
        pulse_o <= pulse_o_temp;
    end
    
endmodule
