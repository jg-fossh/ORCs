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
// Last modified : 2021/01/04 23:27:25
// Project Name  : ORCs
// Module Name   : Memory_Backplane
// Description   : The Memory_Backplane controls access to the BRAMs.
//
// Additional Comments:
//   
/////////////////////////////////////////////////////////////////////////////////
module Memory_Backplane #(
  parameter integer P_MEM_ADDR_MSB     = 0,
  parameter integer P_MEM_DEPTH        = 0,
  parameter integer P_MEM_WIDTH        = 0,
  parameter integer P_NUM_GENERAL_REGS = 16 // Should be 16 or 32 per ISA
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
  input [P_MEM_WIDTH-1:0]  i_slave_core_write_data, // WB data
  // HCC Processor mem WB(pipeline) Slave Write Interface
  input                    i_slave_hcc_write_stb,  // WB write enable
  input [P_MEM_ADDR_MSB:0] i_slave_hcc_write_addr, // WB address
  input [P_MEM_WIDTH-1:0]  i_slave_hcc_write_data, // WB data
);
  ///////////////////////////////////////////////////////////////////////////////
  // Internal Parameter Declarations
  ///////////////////////////////////////////////////////////////////////////////
  localparam L_REG_RESET_INDEX_MSB = $clog2(P_NUM_GENERAL_REGS)-1;

  ///////////////////////////////////////////////////////////////////////////////
  // Internal Signals Declarations
  ///////////////////////////////////////////////////////////////////////////////
  // BRAM array duplicated to index source 0 & 1 at same time or individually. 
  // A fake a dual-port BRAM of sorts.
  // General Registers Reset
  reg [L_REG_RESET_INDEX_MSB:0] reset_index; //
  // Write Case
  wire w_write_enable = (i_reset_sync==1'b1 || i_slave_core_write_stb==1'b1 || i_slave_hcc_write_stb==1'b1) ? 1'b1 : 1'b0;
  // Write Address
  wire [P_MEM_ADDR_MSB:0] w_write_addr = i_reset_sync==1'b1 ? reset_index : 
                                         i_slave_core_write_stb==1'b1 ? i_slave_core_write_addr :
                                         i_slave_hcc_write_stb==1'b1 ? i_slave_hcc_write_addr : reset_index;
  // Write Data
  wire [P_MEM_WIDTH-1:0] w_write_data = i_reset_sync==1'b1 ? 0 : 
                                        i_slave_core_write_stb==1'b1 ? i_slave_core_write_data :
                                        i_slave_hcc_write_stb==1'b1 ? i_slave_hcc_write_data : 0;
  

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

  ///////////////////////////////////////////////////////////////////////////////
  // Instance    : Memory Space 0
  // Description : 
  ///////////////////////////////////////////////////////////////////////////////
  Generic_BRAM #(
    (P_MEM_WIDTH-1),
    P_MEM_ADDR_MSB,
    P_MEM_DEPTH
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
    P_MEM_DEPTH
  ) mem_space1 (
    .i_wclk(i_clk),
    .i_we(w_write_enable),
    .i_rclk(i_clk),
    .i_waddr(w_write_addr),
    .i_raddr(i_slave_core1_read_addr),
    .i_wdata(w_write_data),
    .o_rdata(o_slave_core1_read_data)
  );

endmodule

