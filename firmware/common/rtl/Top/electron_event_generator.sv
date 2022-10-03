/* 
    The Top file are all the different components connected to
    generate a Electron pulse.
    
    A rising edge on the start pulse leads to the generation of electron events (
    tyhere are an array of SpectrumGenerators, which generate random events and two 
    ListEventGenerators, which use a list of events to be generated.
    The output pulse is pushed out with a Serializer to achieve a time resolution
    of 1.25ns.
    
    A microblaze microcontroller is used for configuration. The internal registers are
    connected to the controller using an APB bus multiplexer.
    
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


module electron_event_generator(
    input   logic clk_i,            // sys-clk, 100 MHz
    output  logic led_o,            // LED for testing
    
    input   logic Start_i,          // start signal input (async)
    
    input   logic TMS_i,            // JTAG (not used)
    input   logic TDO_i,
    output  logic TDI_o,
    input   logic TCK_i,
    
    output  logic RXD_o,            // UART for communication with the host
    input   logic TXD_i,
    
    output  logic unused4,
    output  logic unused3,
    output  logic unused2,
    output  logic unused1,
    
    output  logic TDC_signal_y1_n,  // output signals to the TDC (differential)
    output  logic TDC_signal_y1_p,
    output  logic TDC_signal_y2_n,
    output  logic TDC_signal_y2_p,
    output  logic TDC_signal_x1_n,
    output  logic TDC_signal_x1_p,
    output  logic TDC_signal_x2_n,
    output  logic TDC_signal_x2_p,
    
    // FLASH SPI
    inout   logic spi_io0_io,       // connections to the SPI flash memory
    inout   logic spi_io1_io,       // (not used)
    inout   logic spi_io2_io,
    inout   logic spi_io3_io,
    inout logic [0:0] spi_ss_io
    
);

    logic                   clk_locked;
    
    // internally generated start signal (for testing)
    logic unsigned [15:0]   internal_clk_counter;
    logic                   internal_start;

    // reset signal
    logic                   reset;                  //reset generated internally
    logic unsigned [7:0]    reset_counter = 8'h0;   //letting the reset on for a few cycles
    logic unsigned [7:0]    reset_lengh = 8'h0F;    //lengh reset in cycles
    
    // synchronization and generation of a single cycle strobe from the start signal
    logic                   start_reg;
    logic                   start_reg2;
    logic                   start_pulse;            //1 cycle long start
    logic unsigned [7:0]    start_counter;          
    
    
    // serializer data
    logic [31:0]            data_serializer_all;
    logic [3:0]             serializer_out_p;
    logic [3:0]             seiralizer_out_n;
    
    
    logic reset_start;
    logic clk;
    logic clk_400MHz;
    logic clk_ser_div;
    
    
    assign unused1 = 0;
    assign unused2 = 0;
    assign unused3 = 0;
    assign unused4 = 0;
    
    
    
    

    //generate 400MHz DDR clock rate
    clk_generator mmcm1
    (
        .clk_in1(clk_i),
        
        // Status and control signals
        .reset(0),
        .locked(clk_locked),
        
        // clock port for the DDR serializer
        .clk_400MHz(clk_400MHz),
        
        // Clock in ports: 100 MHz
        .clk_fabric(clk),
        .clk_ser_div(clk_ser_div)
    );
    
   
    
    logic [31:0] start_signal_config;
    logic [15:0] duration_between_starts;
    logic use_external_start;
    
    assign use_external_start      = start_signal_config[16];
    assign duration_between_starts = start_signal_config[15:0];
    //generate internal start
    always_ff @(posedge clk)
    begin
        if (internal_clk_counter < duration_between_starts) // TODO: add register!
        begin
            internal_clk_counter <= internal_clk_counter + 1;
        end else begin
            internal_clk_counter = 0;
        end
    end
    
    assign internal_start = internal_clk_counter == 0;
    //assign unused1 = internal_start;             //debug purpose
    

    //reset
    always_ff @(posedge clk)
    begin
        if (reset_start == 1) begin
            reset_counter <= 0;
        end else begin
            if (reset_counter <= reset_lengh)
            begin
                reset_counter <= reset_counter + 1;
            end
        end
    end
    
    assign reset = reset_counter <= reset_lengh;
    
    //start input "cleaning"
    always_ff @(posedge clk)
    begin
        start_reg <= Start_i;
        start_reg2 <= start_reg;
    end
    
    logic start;
    assign start = use_external_start ? start_reg2 : internal_start;
    
    //state machine for debouncing the start signal
    //define states
    typedef enum logic [1:0] {
        IDLE,           // wait till start comes
        START,          // 1 cycle long pulse
        COUNT,          // count
        WAIT_LOW        // wait till start goes to 0
    } state_t;
    state_t state_d, state_q;
    
    //change in state
    always_comb begin
        state_d = state_q;
        
        case (state_q)
            IDLE:
                if (start)          //start_reg2
                    state_d = START;
            
            START: 
                state_d = COUNT;
                
            COUNT: 
                if (start_counter >= 8'h08) 
                    state_d = WAIT_LOW;
                
            WAIT_LOW:
                if (!start)         //!start_reg2
                    state_d = IDLE;
                                   
            default: 
                state_d = IDLE;    
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
    
    
    
    
    //counter for start
    always_ff @(posedge clk) begin
        if (state_q == COUNT) begin
            start_counter <= start_counter + 1;
        end else begin
            start_counter <= 0;
        end
    end
    
    assign start_pulse = state_q == START;
    
    
    // serializing the 4 output pulses 
    serializer serializer_all
    (
        // From the device out to the system
        .data_out_from_device(data_serializer_all),
        .data_out_to_pins_p(serializer_out_p),
        .data_out_to_pins_n(seiralizer_out_n),
        .clk_in(clk_400MHz),        // Fast clock input from PLL/MMCM
        .clk_div_in(clk_ser_div),   // Slow clock input from PLL/MMCM
        .io_reset(0)
    );
    
    //assign serialized signals to correct output
    assign TDC_signal_y1_p = serializer_out_p [0];
    assign TDC_signal_y2_p = serializer_out_p [1];
    assign TDC_signal_x1_p = serializer_out_p [2];
    assign TDC_signal_x2_p = serializer_out_p [3];
    
    assign TDC_signal_y1_n = seiralizer_out_n [0];
    assign TDC_signal_y2_n = seiralizer_out_n [1];
    assign TDC_signal_x1_n = seiralizer_out_n [2];
    assign TDC_signal_x2_n = seiralizer_out_n [3];
    
    
    // CPU and bus
    ApbBus cpuBus();
    assign cpuBus.PCLK = clk;
    assign cpuBus.PRESETn = !reset;
    
    microcontroller_wrapper cpu
   (
        .apb_o_paddr(cpuBus.PADDR),
        .apb_o_penable(cpuBus.PENABLE),
        .apb_o_prdata(cpuBus.PRDATA),
        .apb_o_pready(cpuBus.PREADY),
        .apb_o_psel(cpuBus.PSEL),
        .apb_o_pslverr(cpuBus.PSLVERROR),
        .apb_o_pwdata(cpuBus.PWDATA),
        .apb_o_pwrite(cpuBus.PWRITE),
        .clk_100MHz(clk),
        .reset_rtl_0(!reset),
        .uart_rtl_0_rxd(TXD_i),
        .uart_rtl_0_txd(RXD_o),
        
        .flash_qspi_io0_io(spi_io0_io),
        .flash_qspi_io1_io(spi_io1_io),
        .flash_qspi_io2_io(spi_io2_io),
        .flash_qspi_io3_io(spi_io3_io),
        .flash_qspi_ss_io (spi_ss_io)
    );
    
    
    // define the addresses of the slaves:
    parameter integer numOfSlaves = 5;
    parameter integer addressesStart [numOfSlaves] = '{
        32'h44a0_0000,    // config reg (LED, reset)
        32'h44a0_0004,    // Start signal
        32'h44a0_0100,    // MultiSpectrumGenerator (enable signals)
        32'h44a0_0200,    // ListEventGenerator 1
                          //   0x440a_0200 - 0x44a0_02FC => RAM 
                          //   0x440a_0300               => control register
        32'h44a0_0400     // ListEventGenerator 2
                          //   0x440a_0400 - 0x44a0_04FC => RAM 
                          //   0x440a_0500               => control register
    };
    
    parameter integer addressesEnd [numOfSlaves] = '{
        32'h44a0_0000,    // config reg (LED, reset)
        32'h44a0_0004,    // Start signal
        32'h44a0_0100,    // MultiSpectrumGenerator (enable signals)
        32'h44a0_0300,    // ListEventGenerator 1
        32'h44a0_0500     // ListEventGenerator 2
    };
    
    // the slave buses:
    ApbBus slave_buses [numOfSlaves]();
    
    // the APB multiplexer:
    ApbMultiplexer #(
        .NumOfSlaves(numOfSlaves), 
        .StartAddresses(addressesStart),
        .EndAddresses(addressesEnd)
    ) mux(
        .master(cpuBus.Slave),
        .slaves(slave_buses)
    );
    
    // Main configuration register
    logic [31:0]config_reg;
    ApbWriteRegister #(.Address(addressesStart[0])) configReg(.bus(slave_buses[0].Slave), .value(config_reg));
    assign led_o = config_reg[0]; 
    assign reset_start = config_reg[1];
    
    
    // register for configuration of the internal start signal generator
    ApbWriteRegister #(.Address(addressesStart[1]), .InitialValue(200 | (1 << 16) )) startSignalConfigReg(.bus(slave_buses[1].Slave), .value(start_signal_config));
    
    
    
    // the multi-spectrum generator (generates random events corresponding to a particular spectrum)
    logic [31:0] multiSpectrumResult;
    MultiSpectrumGenerator#(
        .Address(addressesStart[2])
    ) spectrumGenerator (
        .clk_i(clk),
        .reset_i(reset),
        
        .bus(slave_buses[2]),
        
        .start_i(start_pulse),
        .data_serializer_o(multiSpectrumResult)
    );
    
    
    // the electron list event generator (uses a list of electron events to be generated)
    logic [31:0] listEventResult1;
    ListEventGenerator#(
        .StartAddress(addressesStart[3])
    ) listEventGenerator1 (
        .clk_i(clk),
        .reset_i(reset),
        
        .bus(slave_buses[3]),
        
        .start_i(start_pulse),
        .data_serializer_o(listEventResult1)
    );
    
    // the electron list event generator (uses a list of electron events to be generated)
    logic [31:0] listEventResult2;
    ListEventGenerator#(
        .StartAddress(addressesStart[4])
    ) listEventGenerator2 (
        .clk_i(clk),
        .reset_i(reset),
        
        .bus(slave_buses[4]),
        
        .start_i(start_pulse),
        .data_serializer_o(listEventResult2)
    );
    
    assign data_serializer_all = multiSpectrumResult | listEventResult1 | listEventResult2;
        
endmodule
