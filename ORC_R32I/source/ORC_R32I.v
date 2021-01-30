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
// File name     : ORC_R32I.v
// Author        : Jose R Garcia
// Created       : 2020/11/04 23:20:43
// Last modified : 2021/01/29 23:52:12
// Project Name  : ORCs
// Module Name   : ORC_R32I
// Description   : The ORC_R32I is a machine mode capable hart implementation of 
//                 the riscv32i instruction set architecture.
//
// Additional Comments:
//   
/////////////////////////////////////////////////////////////////////////////////
module ORC_R32I #(
  // Compile time configurable generic parameters
  parameter integer P_INITIAL_FETCH_ADDR = 0,  // First instruction address
  parameter integer P_STACK_ADDR         = 0,  // Reg x2 reset value
  parameter integer P_MEMORY_ADDR_MSB    = 4,  //
  parameter integer P_MEMORY_DEPTH       = 32, //
  parameter integer P_MEMORY_HAS_INIT    = 0,  // 0=No init file, 1=loads memory init file
  parameter         P_MEMORY_FILE        = 0,  // File name and directory "./example.txt"
  parameter integer P_IS_ANLOGIC         = 0   //
)(
  // Processor's clocks and resets
  input i_clk,        // clock
  input i_reset_sync, // reset
  // Instruction Wishbone(pipeline) Master Read Interface
  output        o_inst_read_stb,  // WB read enable
  input         i_inst_read_ack,  // WB acknowledge 
  output [31:0] o_inst_read_addr, // WB address
  input  [31:0] i_inst_read_data, // WB data
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
  // Hart_Core to Memory_Backplane connecting wires.
  wire                       w_core0_read_stb;  // WB read enable
  wire [P_MEMORY_ADDR_MSB:0] w_core0_read_addr; // WB address
  wire [31:0]                w_core0_read_data; // WB data
  wire                       w_core1_read_stb;  // WB read enable
  wire [P_MEMORY_ADDR_MSB:0] w_core1_read_addr; // WB address
  wire [31:0]                w_core1_read_data; // WB data
  wire                       w_core_write_stb;  // WB write enable
  wire [P_MEMORY_ADDR_MSB:0] w_core_write_addr; // WB address
  wire [31:0]                w_core_write_data; // WB data
  // CSR
  wire        w_csr_instr_decoded_stb;
  wire [3:0]  w_csr_read_addr;
  wire [31:0] w_csr_read_data;

  ///////////////////////////////////////////////////////////////////////////////
  //            ********      Architecture Declaration      ********           //
  ///////////////////////////////////////////////////////////////////////////////
  
  ///////////////////////////////////////////////////////////////////////////////
  // Instance    : core
  // Description : Hardware thread riscv32 ISA decoder.
  ///////////////////////////////////////////////////////////////////////////////
  Hart_Core #(
    P_INITIAL_FETCH_ADDR, //
    P_MEMORY_ADDR_MSB     //
  ) core (
    // Component's clocks and resets
    .i_clk(i_clk),               // clock
    .i_reset_sync(i_reset_sync), // reset
    // Instruction Wishbone(pipeline) Master Read Interface
    .o_inst_read_stb(o_inst_read_stb),   // WB read enable
    .i_inst_read_ack(i_inst_read_ack),   // WB acknowledge 
    .o_inst_read_addr(o_inst_read_addr), // WB address
    .i_inst_read_data(i_inst_read_data), // WB data
    // Core mem0 WB(pipeline) Slave Read Interface
    .o_master_core0_read_stb(w_core0_read_stb),   // WB read enable
    .o_master_core0_read_addr(w_core0_read_addr), // WB address
    .i_master_core0_read_data(w_core0_read_data), // WB data
    // Core mem1 WB(pipeline) master Read Interface
    .o_master_core1_read_stb(w_core1_read_stb),   // WB read enable
    .o_master_core1_read_addr(w_core1_read_addr), // WB address
    .i_master_core1_read_data(w_core1_read_data), // WB data
    // Core memX WB(pipeline) master Write Interface
    .o_master_core_write_stb(w_core_write_stb),   // WB write enable
    .o_master_core_write_addr(w_core_write_addr), // WB address
    .o_master_core_write_data(w_core_write_data), // WB data
    // I/O Wishbone(pipeline) Master Read Interface
    .o_master_read_stb(o_master_read_stb),   // WB read enable
    .i_master_read_ack(i_master_read_ack),   // WB acknowledge 
    .o_master_read_addr(o_master_read_addr), // WB address
    .i_master_read_data(i_master_read_data), // WB data
    // I/O Wishbone(pipeline) Master Write Interface
    .o_master_write_stb(o_master_write_stb),   // WB write enable
    .i_master_write_ack(i_master_write_ack),   // WB acknowledge
    .o_master_write_addr(o_master_write_addr), // WB address
    .o_master_write_data(o_master_write_data), // WB data
    .o_master_write_sel(o_master_write_sel),   // WB byte enable
    // CSR Interface
    .o_csr_instr_decoded_stb(w_csr_instr_decoded_stb), // Indicates an instruction was decode.
    .o_csr_read_addr(w_csr_read_addr),                 //
    .i_csr_read_data(w_csr_read_data)                  // 
  );

  ///////////////////////////////////////////////////////////////////////////////
  // Instance    : Memory_Backplane
  // Description : A memory access controller. Contains general purpose 
  //               registers, division lookup table, division scratch pad and
  //               CSRs for the multiple profiles.
  ///////////////////////////////////////////////////////////////////////////////
  Memory_Backplane #(
    P_STACK_ADDR,      // P_MEM_STACK_ADDR
    P_MEMORY_ADDR_MSB, // P_MEM_ADDR_MSB
    P_MEMORY_DEPTH,    // P_MEM_DEPTH
    32,                // P_MEM_WIDTH
    32,                // P_MEM_NUM_REGS
    P_MEMORY_HAS_INIT, // P_MEM_NUM_REGS
    P_MEMORY_FILE,     // P_MEM_NUM_REGS
    P_IS_ANLOGIC       // P_MEM_ANLOGIC_BRAM
  ) mem_access_controller(
    // Component's clocks and resets
    .i_clk(i_clk),               // clock
    .i_reset_sync(i_reset_sync), // synchronous reset
    // Core mem0 WB(pipeline) Slave Read Interface
    .i_slave_core0_read_stb(w_core0_read_stb),   // WB read enable
    .i_slave_core0_read_addr(w_core0_read_addr), // WB address
    .o_slave_core0_read_data(w_core0_read_data), // WB data
    // Core mem1 WB(pipeline) Slave Read Interface
    .i_slave_core1_read_stb(w_core1_read_stb),   // WB read enable
    .i_slave_core1_read_addr(w_core1_read_addr), // WB address
    .o_slave_core1_read_data(w_core1_read_data), // WB data
    // Core mem1 WB(pipeline) Slave Write Interface
    .i_slave_core_write_stb(w_core_write_stb),   // WB write enable
    .i_slave_core_write_addr(w_core_write_addr), // WB address
    .i_slave_core_write_data(w_core_write_data)  // WB data
  );


  ///////////////////////////////////////////////////////////////////////////////
  // Instance    : CSRs
  // Description : Only Cycle and Instr for benchmarking.
  ///////////////////////////////////////////////////////////////////////////////
  CSR csrs (
    // Component's clocks and resets
    .i_clk(i_clk),               // clock
    .i_reset_sync(i_reset_sync), // reset
    // CSR Interface
    .i_csr_instr_decoded_stb(w_csr_instr_decoded_stb), // Indicates an instruction was decode.
    .i_csr_read_addr(w_csr_read_addr),                 //
    .o_csr_read_data(w_csr_read_data)                  // 
  );

endmodule
