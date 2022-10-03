`timescale 1ns / 1ps

/*
    This module bundles 32 SpectrumGenerators togetehr in order to generate more than one event per start pulse.
    It includes a register to enable / disable some of the SpectrumGenerators.

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


module MultiSpectrumGenerator#(
       parameter Address = 0
    )(
        input  logic        clk_i,
        input  logic        reset_i,
        
        ApbBus.Slave        bus,
        
        input  logic        start_i,
        output logic [31:0] data_serializer_o
    );
    
    
    localparam numOfElements = 32;  // max. 32, but saturation is significant at 20
    

    logic [31:0] enable_reg;
    logic [31:0] [numOfElements-1:0] data_serializer;
 
    // register to enable the individual SpectrumGenerators
    ApbWriteRegister #(.Address(Address), .InitialValue(32'hf)) enableRegister (.bus(bus), .value(enable_reg));
 
    genvar i;
    genvar j;
    generate
        for (i = 0; i < numOfElements; i++) begin : genSpectrumGenerator
            logic [31:0] result;
            
            SpectrumGenerator#(
                .LFSR_initial_value(i*12345)
            ) spectrumGen (
                .clk_i(clk_i),
                .reset_i(reset_i),
                
                .start_i(start_i),
                .enable_i(enable_reg[i]),
                .data_serializer_o(result)
            );
            for (j = 0; j < 32; j++)
                assign data_serializer[j][i] = result[j];
        end
    endgenerate
    
    // generate OR for the outputs
    generate
        for(i=0; i < 32; i++) begin : genOr
            logic [numOfElements-1:0] genSer;
            for(j=0; j<numOfElements; j++)
                assign genSer[j] = data_serializer[i][j];
            
            assign data_serializer_o[i] = | genSer;  
        end
    endgenerate
    
    
    
endmodule
