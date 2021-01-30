/////////////////////////////////////////////////////////////////////////////////
// BSD 3-Clause License
// 
// Copyright (c) 2020, Jose R. Garcia
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// 
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
// 
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
// 
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
/////////////////////////////////////////////////////////////////////////////////
// File name     : Memory_Backplane.v
// Author        : Jose R Garcia
// Created       : 2020/12/23 14:17:03
// Last modified : 2021/01/29 13:40:40
// Project Name  : ORCs
// Module Name   : Memory_Backplane
// Description   : The Memory_Backplane controls access to the BRAMs.
//
// Additional Comments:
//   
/////////////////////////////////////////////////////////////////////////////////
module Memory_Backplane #(
  parameter integer P_MEM_STACK_ADDR   = 0,  // Reg x2 reset value
  parameter integer P_MEM_ADDR_MSB     = 0,
  parameter integer P_MEM_DEPTH        = 0,
  parameter integer P_MEM_WIDTH        = 0,
  parameter integer P_MEM_NUM_REGS     = 16,
  parameter integer P_MEM_HAS_FILE     = 0,
  parameter         P_MEM_INIT_FILE    = 0,
  parameter integer P_MEM_ANLOGIC_BRAM = 0
)(
  // Component's clocks and resets
  input i_clk,        // clock
  input i_reset_sync, // reset
  // Core mem0 WB(pipeline) Slave Read Interface
  input                     i_slave_core0_read_stb,  // WB read enable
  input  [P_MEM_ADDR_MSB:0] i_slave_core0_read_addr, // WB address
  output [P_MEM_WIDTH-1:0]  o_slave_core0_read_data, // WB data
  // Core mem1 WB(pipeline) Slave Read Interface
  input                     i_slave_core1_read_stb,  // WB read enable
  input  [P_MEM_ADDR_MSB:0] i_slave_core1_read_addr, // WB address
  output [P_MEM_WIDTH-1:0]  o_slave_core1_read_data, // WB data
  // Core mem1 WB(pipeline) Slave Write Interface
  input                    i_slave_core_write_stb,  // WB write enable
  input [P_MEM_ADDR_MSB:0] i_slave_core_write_addr, // WB address
  input [P_MEM_WIDTH-1:0]  i_slave_core_write_data  // WB data
);
  ///////////////////////////////////////////////////////////////////////////////
  // Internal Parameter Declarations
  ///////////////////////////////////////////////////////////////////////////////
  localparam L_REG_RESET_INDEX_MSB = $clog2(P_MEM_NUM_REGS)-1;

  ///////////////////////////////////////////////////////////////////////////////
  // Internal Signals Declarations
  ///////////////////////////////////////////////////////////////////////////////
  // BRAM array duplicated to index source 0 & 1 at same time or individually. 
  // A fake a dual-port BRAM of sorts.
  // General Registers Reset
  reg [L_REG_RESET_INDEX_MSB:0] reset_index; //
  // Write Case
  wire w_write_enable = (i_reset_sync==1'b1 || i_slave_core_write_stb==1'b1) ? 1'b1 : 1'b0;
  // Write Address
  wire [P_MEM_ADDR_MSB:0] w_write_addr = i_reset_sync==1'b1 ? reset_index : i_slave_core_write_addr;
  // Write Data
  wire [P_MEM_WIDTH-1:0] w_write_data = i_reset_sync==1'b1 ? (reset_index==2 ? P_MEM_STACK_ADDR : 0) : 
                                        i_slave_core_write_data;
  

  ///////////////////////////////////////////////////////////////////////////////
  //            ********      Architecture Declaration      ********           //
  ///////////////////////////////////////////////////////////////////////////////
  
  ///////////////////////////////////////////////////////////////////////////////
  // Process     : General Purpose Registers Reset Index
  // Description : 
  ///////////////////////////////////////////////////////////////////////////////
  always@(posedge i_clk) begin
    if (i_reset_sync == 1'b1) begin
      reset_index <= reset_index+1;
    end
    else begin
      reset_index <= 0;
    end
  end

  generate
    if (P_MEM_ANLOGIC_BRAM == 0) begin
      ///////////////////////////////////////////////////////////////////////////////
      // Instance    : Memory Space 0
      // Description : 
      ///////////////////////////////////////////////////////////////////////////////
      Generic_BRAM #(
        (P_MEM_WIDTH-1),
        P_MEM_ADDR_MSB,
        P_MEM_DEPTH,
        P_MEM_HAS_FILE,
        P_MEM_INIT_FILE
      ) mem_space0 (
        .i_wclk(i_clk),
        .i_we(w_write_enable),
        .i_rclk(i_clk),
        .i_waddr(w_write_addr),
        .i_raddr(i_slave_core0_read_addr),
        .i_wdata(w_write_data),
        .o_rdata(o_slave_core0_read_data)
      );
  
      ///////////////////////////////////////////////////////////////////////////////
      // Instance    : Memory Space 1
      // Description : 
      ///////////////////////////////////////////////////////////////////////////////
      Generic_BRAM #(
        (P_MEM_WIDTH-1),
        P_MEM_ADDR_MSB,
        P_MEM_DEPTH,
        P_MEM_HAS_FILE,
        P_MEM_INIT_FILE
      ) mem_space1 (
        .i_wclk(i_clk),
        .i_we(w_write_enable),
        .i_rclk(i_clk),
        .i_waddr(w_write_addr),
        .i_raddr(i_slave_core1_read_addr),
        .i_wdata(w_write_data),
        .o_rdata(o_slave_core1_read_data)
      );
    end
  endgenerate

  generate
    if (P_MEM_ANLOGIC_BRAM == 1) begin
      ///////////////////////////////////////////////////////////////////////////////
      // Instance    : Memory Space 0
      // Description : 
      ///////////////////////////////////////////////////////////////////////////////
      EG_LOGIC_BRAM #(
        .DATA_WIDTH_A(P_MEM_WIDTH),
				.DATA_WIDTH_B(P_MEM_WIDTH),
				.ADDR_WIDTH_A(P_MEM_ADDR_MSB+1),
				.ADDR_WIDTH_B(P_MEM_ADDR_MSB+1),
				.DATA_DEPTH_A(P_MEM_DEPTH),
				.DATA_DEPTH_B(P_MEM_DEPTH),
				.MODE("PDPW"),
				.REGMODE_A("NOREG"),
				.REGMODE_B("NOREG"),
				.WRITEMODE_A("NORMAL"),
				.WRITEMODE_B("NORMAL"),
				.RESETMODE("SYNC"),
				.IMPLEMENT("9K(FAST)"),
				.INIT_FILE("NONE"),
				.FILL_ALL("NONE")
      ) mem_space0 (
				.dia(w_write_data),
				.dib({P_MEM_WIDTH{1'b0}}),
				.addra(w_write_addr),
				.addrb(i_slave_core0_read_addr),
				.cea(w_write_enable),
				.ceb(i_slave_core0_read_stb),
				.ocea(1'b0),
				.oceb(1'b0),
				.clka(i_clk),
				.clkb(i_clk),
				.wea(1'b1),
				.web(1'b0),
				.bea(1'b0),
				.beb(1'b0),
				.rsta(1'b0),
				.rstb(1'b0),
				.doa(),
				.dob(o_slave_core0_read_data)
      );

      ///////////////////////////////////////////////////////////////////////////////
      // Instance    : Memory Space 1
      // Description : 
      ///////////////////////////////////////////////////////////////////////////////
      EG_LOGIC_BRAM #(
        .DATA_WIDTH_A(P_MEM_WIDTH),
				.DATA_WIDTH_B(P_MEM_WIDTH),
				.ADDR_WIDTH_A(P_MEM_ADDR_MSB+1),
				.ADDR_WIDTH_B(P_MEM_ADDR_MSB+1),
				.DATA_DEPTH_A(P_MEM_DEPTH),
				.DATA_DEPTH_B(P_MEM_DEPTH),
				.MODE("PDPW"),
				.REGMODE_A("NOREG"),
				.REGMODE_B("NOREG"),
				.WRITEMODE_A("NORMAL"),
				.WRITEMODE_B("NORMAL"),
				.RESETMODE("SYNC"),
				.IMPLEMENT("9K(FAST)"),
				.INIT_FILE("NONE"),
				.FILL_ALL("NONE")
      ) mem_space1 (
				.dia(w_write_data),
				.dib({P_MEM_WIDTH{1'b0}}),
				.addra(w_write_addr),
				.addrb(i_slave_core1_read_addr),
				.cea(w_write_enable),
				.ceb(i_slave_core1_read_stb),
				.ocea(1'b0),
				.oceb(1'b0),
				.clka(i_clk),
				.clkb(i_clk),
				.wea(1'b1),
				.web(1'b0),
				.bea(1'b0),
				.beb(1'b0),
				.rsta(1'b0),
				.rstb(1'b0),
				.doa(),
				.dob(o_slave_core1_read_data));
    end
  endgenerate

endmodule

