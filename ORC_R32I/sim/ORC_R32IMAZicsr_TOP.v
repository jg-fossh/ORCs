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
// File name     : ORC_R32IMAZicsr_TOP.v
// Author        : Jose R Garcia
// Created       : 2020/11/04 23:20:43
// Last modified : 2020/12/29 11:01:17
// Project Name  : ORCs
// Module Name   : ORC_R32IMAZicsr_TOP
// Description   : The ORC_R32IMAZicsr_TOP is a wrapper to include the missing signals
//                 required by the verification agents.
//
// Additional Comments:
//   
/////////////////////////////////////////////////////////////////////////////////
module ORC_R32IMAZicsr_TOP #(
  // Compile time configurable generic parameters
  // Compile time configurable generic parameters
  parameter P_INITIAL_FETCH_ADDR = 0,  // First instruction address
  parameter P_MEMORY_ADDR_MSB    = 5,  //
  parameter P_MEMORY_DEPTH       = 36, //
  parameter P_DIV_START_ADDR     = 32, // 
  parameter P_DIV_ACCURACY       = 3   // 1e10^-P_DIVISION_ACCURACY
)(
  // Component's clocks and resets
  input i_clk,        // clock
  input i_reset_sync, // reset
  // Instruction Wishbone(pipeline) Master Read Interface
  output        o_inst_read_stb,  // WB read enable
  input         i_inst_read_ack,  // WB acknowledge 
  output [31:0] o_inst_read_addr, // WB address
  input  [31:0] i_inst_read_data, // WB data
  output [31:0] dat_o,            // Added to stub connections
  output        we_o,             // Added to stub connections
  output        sel_o,            // Added to stub connections
  output        cyc_o,            // Added to stub connections
  input         stall_i,          // Added to stub connections
  output        tga_o,            // Added to stub connections
  input         tgd_i,            // Added to stub connections
  output        tgd_o,            // Added to stub connections
  output        tgc_o,            // Added to stub connections
  // Wishbone(pipeline) Master Read Interface
  output        o_master_read_stb,  // WB read enable
  input         i_master_read_ack,  // WB acknowledge 
  output [31:0] o_master_read_addr, // WB address
  input  [31:0] i_master_read_data, // WB data
  // Wishbone(pipeline) Master Write Interface
  output        o_master_write_stb,  // WB write enable
  input         i_master_write_ack,  // WB acknowledge 
  output [31:0] o_master_write_addr, // WB address
  output [31:0] o_master_write_data, // WB data
  output [3:0]  o_master_write_sel   // WB byte enable
);
  ///////////////////////////////////////////////////////////////////////////////
  // Internal Parameter Declarations
  ///////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////
  // Internal Signals Declarations
  ///////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////
  //            ********      Architecture Declaration      ********           //
  ///////////////////////////////////////////////////////////////////////////////
  ORC_R32IMAZicsr #(
    P_INITIAL_FETCH_ADDR,
    P_MEMORY_ADDR_MSB,
    P_MEMORY_DEPTH,
    P_DIV_START_ADDR,
    P_DIV_ACCURACY
  ) uut (
    // Component's clocks and resets
    .i_clk(i_clk),
    .i_reset_sync(i_reset_sync),
    // Instruction Wishbone(pipeline) Master Read Interface
    .o_inst_read_stb(o_inst_read_stb),
    .i_inst_read_ack(i_inst_read_ack),
    .o_inst_read_addr(o_inst_read_addr),
    .i_inst_read_data(i_inst_read_data),
    // Wishbone(pipeline) Master Read Interface
    .o_master_read_stb(o_master_read_stb),
    .i_master_read_ack(i_master_read_ack),
    .o_master_read_addr(o_master_read_addr),
    .i_master_read_data(i_master_read_data),
    // Wishbone(pipeline) Master Write Interface
    .o_master_write_stb(o_master_write_stb),  
    .i_master_write_ack(i_master_write_ack),
    .o_master_write_addr(o_master_write_addr),
    .o_master_write_data(o_master_write_data),
    .o_master_write_sel(o_master_write_sel)
  );

assign we_o  = 0;
assign sel_o = 0;
assign cyc_o = 0;
assign tga_o = 0;
assign tgd_o = 0;
assign tgc_o = 0;   

endmodule
