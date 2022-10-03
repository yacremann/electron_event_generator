/*
    This is an implementation of the APB-bus in SystemVerilog using interfaces.
    The use of interfaces simplifies the wiring of the interconnect. Caution: not all
    FPGA development environments already support arrays of buses!

    Copyright 2021 ETH Zurich

    SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

    Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may not use this file except in compliance with the License, or, at your option, the Apache License version 2.0.
    You may obtain a copy of the License at

    https://solderpad.org/licenses/SHL-2.1/
       
    Unless required by applicable law or agreed to in writing, any work distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and limitations under the License.

    Group of Prof. Vaterlaus
    Authors: Yves Acremann
*/


interface ApbBus #(
    parameter AddrWidth = 32,           // width of the address bus
    parameter DataWidth = 32            // width of the data bus
);
    logic                   PCLK;
    logic                   PRESETn;
    logic [AddrWidth-1:0]   PADDR;      // address
    logic [0:0]             PSEL;       // byte select
    logic                   PENABLE;    // slave enable
    logic                   PREADY;     // ready signal from slave
    logic                   PWRITE;     // write (1) / read (0)
    logic [DataWidth-1:0]   PWDATA;     // write data bus
    logic [DataWidth-1:0]   PRDATA;     // read data bus (from slave)
    logic                   PSLVERROR;  // error indicator (from slave)
    
    modport Slave (
        input  PCLK,
        input  PRESETn,
        input  PADDR,
        input  PSEL,
        input  PENABLE,
        output PREADY,
        input  PWRITE,
        input  PWDATA,
        output PRDATA,
        output PSLVERROR
    );
    
    modport Master (
        output PCLK,
        output PRESETn,
        output PADDR,
        output PSEL,
        output PENABLE,
        input  PREADY,
        output PWRITE,
        output PWDATA,
        input  PRDATA,
        input  PSLVERROR
    );
endinterface




/*
 * Output register with read-back function
 */
module ApbWriteRegister #(
     parameter Address = 0,                   // address of the reg.
	 parameter DataWidth = 32,
	 parameter AddrWidth = 32,
	 parameter InitialValue = 0
)(
    ApbBus.Slave bus,                       // the APB bus interface
    output logic [DataWidth-1:0] value  // the output of the reg.
);

    // states of the FSM
    typedef enum logic [1:0] {
        IDLE,    // wait for select
        ENABLE   // perform the transfer
    } state_t;
    state_t state, next_state;
    logic selected;
    logic enabled;
    logic [DataWidth-1:0] result_reg;
    
    assign selected = (bus.PSEL != 0) & (bus.PADDR == AddrWidth'(Address));
    assign enabled = (state == ENABLE) & (bus.PENABLE);
    assign bus.PRDATA = (enabled & !bus.PWRITE)? result_reg : 0;
    
    // the flipflops:
    always_ff @(posedge bus.PCLK, negedge bus.PRESETn) begin
        if (bus.PRESETn == 0) begin
            state <= IDLE;
            result_reg <= 32'(InitialValue);
        end else begin
            state <= next_state;
            if (enabled & bus.PWRITE)
                result_reg <= bus.PWDATA;
        end
    end
    
    // next state logic:
    always_comb begin
        next_state = state;
        
        case(state)
            IDLE:
                if (selected == 1) next_state = ENABLE;
            ENABLE: 
                if (selected == 0) 
                    next_state = IDLE;
            default:
                next_state = IDLE;
        endcase
    end

    assign value = result_reg;
    assign bus.PSLVERROR = 0;
    assign bus.PREADY = 1;
endmodule



/*
 * Input register
 */
module ApbReadRegister #(
     parameter Address = 0,                 // the address of the reg.
	 parameter DataWidth = 32,
	 parameter AddrWidth = 32
)(
    ApbBus.Slave                    bus,  // the APB bus interface
    input logic [DataWidth-1:0] value // the input to read
);

    // states of the FSM
    typedef enum logic [1:0] {
        IDLE,    // wait for select
        ENABLE   // perform the transfer
    } state_t;
    
    state_t state, next_state;
    logic selected;
    logic enabled;
    logic [DataWidth-1:0] read_reg;
    
    assign selected = (bus.PSEL != 0) & (bus.PADDR == AddrWidth'(Address));
    assign enabled = (state == ENABLE) & (bus.PENABLE);
    assign bus.PRDATA = enabled & !bus.PWRITE ? read_reg : 0;
    
    // the flipflops:
    always_ff @(posedge bus.PCLK, negedge bus.PRESETn) begin
        if (bus.PRESETn == 0) begin
            state <= IDLE;
            read_reg <= 0;
        end else begin
            state <= next_state;
            if (selected & !bus.PWRITE)
                read_reg <= value;
        end
    end
    
    // next state logic:
    always_comb begin
        next_state = state;
        
        case(state)
            IDLE:
                if (selected == 1) next_state = ENABLE;
            ENABLE: 
                if (selected == 0) 
                    next_state = IDLE;
            default:
                next_state = IDLE;
        endcase
    end

    assign bus.PSLVERROR = 0;
    assign bus.PREADY = 1;
endmodule


/*
 * Multiplexer for the APB bus.
 * 
 * Parameters:
 *  NumOfSlaves: Number of slaves
 *  StartAddresses: Start of the address range for each slave
 *  EndAddresses: End of the address range for each slave
 *
 * The address decoder is implemented such that if the start and end 
 * addresses are equal only that particular address is assigned to the slave.
 * If the start and end addresses are non-equal, the whole range is assigned
 * to the slave ([StartAddress, EndAddress]).
 *
 * It is inspired by the solution from here:
 * https://github.com/RoaLogic/apb4_mux
 */
module ApbMultiplexer #(
    parameter NumOfSlaves = 2,
    parameter integer StartAddresses [NumOfSlaves] = '{10, 20},
    parameter integer EndAddresses   [NumOfSlaves] = '{10, 20},
	 parameter DataWidth = 32,
	 parameter AddrWidth = 32
    )(
    ApbBus.Slave  master,                      // master bus interface
    ApbBus.Master slaves [NumOfSlaves]     // slave bus interfaces
    );
    
    // intermediate signals for generating the multiplexer structures.
    // These are sent to an OR to generate the signals to the master.
    logic addr_ok [NumOfSlaves-1:0] ;
    logic [NumOfSlaves-1:0] slave_PREADY_switched ;
    logic [DataWidth-1:0][NumOfSlaves-1:0] slave_PRDATA_switched;
    logic [NumOfSlaves-1:0] slave_PSLVERROR_switched ;
    
    
    genvar b, s;
    generate
        // loop over all slaves:
        for (s = 0; s < NumOfSlaves; s++) begin : gen_loop
        
            // the address decoding logic
            if (StartAddresses[s] == EndAddresses[s])
                assign addr_ok[s] = (master.PADDR == AddrWidth'(StartAddresses[s]));
            else
                assign addr_ok[s] = (master.PADDR >= AddrWidth'(StartAddresses[s]))
                        & (master.PADDR <= AddrWidth'(EndAddresses[s]));
        
            // connect the signals from the master to the slaves:
            assign slaves[s].PCLK = master.PCLK;
            assign slaves[s].PRESETn = master.PRESETn;
            assign slaves[s].PWRITE = master.PWRITE;
            assign slaves[s].PWDATA = master.PWDATA;
            assign slaves[s].PENABLE = master.PENABLE & addr_ok[s];
            assign slaves[s].PSEL = master.PSEL & addr_ok[s];
            assign slaves[s].PADDR = master.PADDR;
            
            // the AND part of the multiplexer from the slaves to the master
            assign slave_PREADY_switched[s] = slaves[s].PREADY & addr_ok[s];
            assign slave_PSLVERROR_switched[s] = slaves[s].PSLVERROR & addr_ok[s];
            
        end // gen_loop
    endgenerate
    
    
    // for the PRDATA signals we need to generate the correct assignment bit-wise...
    generate
        for (b = 0; b < DataWidth; b++) begin : bit_loop
                for (s = 0; s < NumOfSlaves; s++) begin : slave_loop
                     assign slave_PRDATA_switched[b][s] = addr_ok[s]? slaves[s].PRDATA[b] : 0;
                end // slave_loop
                // here we assign the OR for each bit separately.
                assign master.PRDATA[b] = |slave_PRDATA_switched[b];
        end // bit_loop
        
    endgenerate
    
    // the OR part of the multiplexer for the signle bit signals to the master:
    assign master.PREADY =|slave_PREADY_switched;
    assign master.PSLVERROR =|slave_PSLVERROR_switched;
    
endmodule


