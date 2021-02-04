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
// File name     : Hart_Core.v
// Author        : Jose R Garcia
// Created       : 2020/12/06 00:33:28
// Last modified : 2021/02/04 15:23:49
// Project Name  : ORCs
// Module Name   : Hart_Core
// Description   : The Hart_Core is a machine mode capable hart, implementation
//                 of the riscv32im instruction set architecture.
//
// Additional Comments:
//   .
/////////////////////////////////////////////////////////////////////////////////
module Hart_Core #(
  // Compile time configurable generic parameters
  parameter integer P_CORE_INITIAL_FETCH_ADDR = 0, // First instruction address
  parameter integer P_CORE_MEMORY_ADDR_MSB    = 4  //
)(
  // Component's clocks and resets
  input i_clk,        // clock
  input i_reset_sync, // reset
  // Instruction Wishbone(Standard) Master Read Interface
  output        o_inst_read_stb,  // WB read enable
  input         i_inst_read_ack,  // WB acknowledge 
  output [31:0] o_inst_read_addr, // WB address
  input  [31:0] i_inst_read_data, // WB data
  // General Regs0 Read Interface
  output [P_CORE_MEMORY_ADDR_MSB:0] o_master_core0_read_addr, // address
  input  [31:0]                     i_master_core0_read_data, // data. unsigned rs1
  // General Regs1 Read Interface
  output [P_CORE_MEMORY_ADDR_MSB:0] o_master_core1_read_addr, // address
  input  [31:0]                     i_master_core1_read_data, // data. unsigned rs2
  // General Regs Write Interface
  output                            o_master_core_write_stb,  // WB write enable
  output [P_CORE_MEMORY_ADDR_MSB:0] o_master_core_write_addr, // WB address
  output [31:0]                     o_master_core_write_data, // WB data
  // Wishbone(Standard) Master Read Interface
  output        o_master_read_stb,  // WB read enable
  input         i_master_read_ack,  // WB acknowledge 
  output [31:0] o_master_read_addr, // WB address
  input  [31:0] i_master_read_data, // WB data
  // Wishbone(Standard) Master Write Interface
  output        o_master_write_stb,  // WB write enable
  input         i_master_write_ack,  // WB acknowledge 
  output [31:0] o_master_write_addr, // WB address
  output [31:0] o_master_write_data, // WB data
  output [3:0]  o_master_write_sel,  // WB byte enable
  // MUL Processor Interface
  output       o_master_mul_stb,  // start pulse
  output [1:0] o_master_mul_tga,  // signed/uynsigned
  // DIV Processor Interface
  output       o_master_div_stb,  // start pulse
  output [1:0] o_master_div_tga,  // 0=div, 1=rem
  input        i_master_div_ack,  // done pulse
  // CSR Interface
  output       o_csr_instr_decoded, // Indicates an instruction was decode.
  output       o_csr_read_stb,      //
  output [3:0] o_csr_read_addr,     //
  // General Purpose Signals
  output [P_CORE_MEMORY_ADDR_MSB:0] o_rd //
);
  ///////////////////////////////////////////////////////////////////////////////
  // Internal Parameter Declarations
  ///////////////////////////////////////////////////////////////////////////////
  // OpCodes 
  localparam [6:0] L_AUIPC = 7'b0010111; // imm[31:12], rd[11:7]
  localparam [6:0] L_LUI   = 7'b0110111; // imm[31:12], rd[11:7]
  localparam [6:0] L_JAL   = 7'b1101111; // imm[20|10:1|11|19:12],rd[11:7]
  localparam [6:0] L_JALR  = 7'b1100111; // imm[11:0], rs1[19:15],000,rd[11:7]
  localparam [6:0] L_BCC   = 7'b1100011; // imm[12|10:5],rs2[24:20],rs1[19:15],funct[14:12],imm[4:1|11]
  localparam [6:0] L_RII   = 7'b0010011; // imm[11:0],[19:15],funct[14:12],rd[11:7]
  localparam [6:0] L_MATH  = 7'b0110011; // funct[6:0],rs2[24:20],rs1[19:15],funct[14:12],rd[11:7]
  localparam [6:0] L_LCC   = 7'b0000011; // imm[11:0],rs1[19:15],funct[14:12],rd[11:7]
  localparam [6:0] L_SCC   = 7'b0100011; // imm[11:5],rs2[24:20],rs1[19:15],funct[14:12],imm[4:0]
  localparam [6:0] L_HCC   = 7'b0000001; // funct7[31:25],rs2[24:20],rs1[19:15],funct3[14:12]
  localparam [6:0] L_SYSTM = 7'b1110011; //
  // Program Counter FSM States
  localparam [3:0] S_WAKEUP          = 4'b0001; // r_program_counter_state after reset
  localparam [3:0] S_WAIT_FOR_ACK    = 4'b0010; // r_program_counter_state, waiting for valid instruction
  localparam [3:0] S_WAIT_FOR_EXT    = 4'b0100; // r_program_counter_state, wait for load to complete
  localparam [3:0] S_WAIT_FOR_SETTLE = 4'b1000; // r_program_counter_state after reset
  // LCC cases
  localparam [3:0] L_LOAD_SIGNED_3_BYTE       = 4'h0;
  localparam [3:0] L_LOAD_SIGNED_2_BYTE       = 4'h1;
  localparam [3:0] L_LOAD_SIGNED_1_BYTE       = 4'h2;
  localparam [3:0] L_LOAD_SIGNED_0_BYTE       = 4'h3;
  localparam [3:0] L_LOAD_UNSIGNED_3_BYTE     = 4'h4;
  localparam [3:0] L_LOAD_UNSIGNED_2_BYTE     = 4'h5;
  localparam [3:0] L_LOAD_UNSIGNED_1_BYTE     = 4'h6;
  localparam [3:0] L_LOAD_UNSIGNED_0_BYTE     = 4'h7;
  localparam [3:0] L_LOAD_SIGNED_UPPER_WORD   = 4'h8;
  localparam [3:0] L_LOAD_SIGNED_LOWER_WORD   = 4'h9;
  localparam [3:0] L_LOAD_UNSIGNED_UPPER_WORD = 4'hA;
  localparam [3:0] L_LOAD_UNSIGNED_LOWER_WORD = 4'hB;
  localparam [3:0] L_LOAD_WORD                = 4'hC;
  localparam [3:0] L_LOAD_OTHERS              = 4'hF;
  // Misc Definitions
  localparam [31:0] L_ALL_ZERO = 0;
  localparam [31:0] L_ALL_ONES = -1;
  // CSR Addresses 
  localparam [11:0] L_RDCYCLE    = 12'hC00;
  localparam [11:0] L_RDINSTRET  = 12'hC02;
  localparam [11:0] L_RDCYCLEH   = 12'hC80;
  localparam [11:0] L_RDINSTRETH = 12'hC82;
  ///////////////////////////////////////////////////////////////////////////////
  // Internal Signals Declarations
  ///////////////////////////////////////////////////////////////////////////////
  // Program Counter Process
  reg [31:0] r_pc_fetch;              // 32-bit program counter t
  reg        r_program_counter_valid; // Program Counter Valid
  reg [3:0]  r_program_counter_state; // Current State Holder.
  // Decoder Signals
  reg  [P_CORE_MEMORY_ADDR_MSB:0] r_rd1;                                             // reg with rd field
  reg  [P_CORE_MEMORY_ADDR_MSB:0] r_rd2;                                             // reg with rd field
  wire [P_CORE_MEMORY_ADDR_MSB:0] w_rd                   = i_inst_read_data[11:7];   // rd field
  wire                            w_rd_not_zero          = w_rd==5'h0 ? 1'b0 : 1'b1; // not zero
  wire                            w_destination_not_zero = r_rd1==5'h0 ? 1'b0 : 1'b1; // not zero

  wire [4:0]  w_source1_pointer = i_inst_read_data[19:15];   // s1 field
  wire [4:0]  w_source2_pointer = i_inst_read_data[24:20];   // s2 field

  wire [11:0] w_csr_field       = i_inst_read_data[31:20]; // CSR

  wire [6:0]  w_fct7            = i_inst_read_data[31:25];   // fct7 field
  wire [2:0]  w_fct3            = i_inst_read_data[14:12];   // fct3 field
  wire [7:0]  w_fct3_one_hot    = w_fct3==3'h0 ? 8'b00000001 : // fct3 field decoded/unwrapped
                                  w_fct3==3'h1 ? 8'b00000010 :
                                  w_fct3==3'h2 ? 8'b00000100 :
                                  w_fct3==3'h3 ? 8'b00001000 :
                                  w_fct3==3'h4 ? 8'b00010000 :
                                  w_fct3==3'h5 ? 8'b00100000 :
                                  w_fct3==3'h6 ? 8'b01000000 :
                                  w_fct3==3'h7 ? 8'b10000000 :
                                                 8'b00000000;

  wire [6:0]  w_opcode = (r_program_counter_state[1]==1'b1 && i_inst_read_ack==1'b1) ? i_inst_read_data[6:0] : 7'h0; // OPCODE field

  wire        w_lui    = w_opcode==L_LUI   ? 1'b1 : 1'b0;         // valid branch flag/
  wire        w_auipc  = w_opcode==L_AUIPC ? 1'b1 : 1'b0;         // valid JALR flag
  wire        w_jal    = w_opcode==L_JAL   ? 1'b1 : 1'b0;         // valid load flag             
  wire        w_jalr   = w_opcode==L_JALR  ? 1'b1 : 1'b0;         // valid JALR flag
  wire        w_bcc    = w_opcode==L_BCC   ? 1'b1 : 1'b0;         // valid branch flag
  wire        w_rii    = w_opcode==L_RII   ? 1'b1 : 1'b0;         // valid register-immediate flag
  wire        w_rro    = w_opcode==L_MATH  ? (
                           w_fct7==L_HCC   ? 1'b0 : 1'b1) : 1'b0; // valid register-register flag
  wire        w_lcc    = w_opcode==L_LCC   ? 1'b1 : 1'b0;         // valid load flag
  wire        w_scc    = w_opcode==L_SCC   ? 1'b1 : 1'b0;         // valid store flag
  wire        w_hcc    = w_opcode==L_MATH  ? (
                           w_fct7==L_HCC   ? 1'b1 : 1'b0) : 1'b0; // valid register-register flag
  wire        w_systm  = w_opcode==L_SYSTM ? 1'b1 : 1'b0;         // valid register-register flag
                
  wire [31:0] w_uimm   = {L_ALL_ZERO[31:12], i_inst_read_data[31:20]};                                 
  wire [31:0] w_simm   = (w_jalr==1'b1 || w_rii==1'b1 || w_lcc==1'b1) ? 
                           {(i_inst_read_data[31] ? L_ALL_ONES[31:11]:L_ALL_ZERO[31:11]), i_inst_read_data[30:20]} : 
                         w_bcc==1'b1 ? {(i_inst_read_data[31] ? L_ALL_ONES[31:12]:L_ALL_ZERO[31:12]), 
                           i_inst_read_data[7],i_inst_read_data[30:25], i_inst_read_data[11:8],L_ALL_ZERO[0]} :
                         w_scc==1'b1 ? {(i_inst_read_data[31] ? L_ALL_ONES[31:11] : L_ALL_ZERO[31:11]), 
                           i_inst_read_data[30:25], i_inst_read_data[11:7]} :
                         i_master_core0_read_data; // Signed Immediate
  // RM-group of instructions (OPCODEs==7'b0010011/7'b0110011), merged! src=immediate(M)/register(R)
  // ALU Signals
  wire w_add = w_fct3_one_hot[0]==1'b1 ? (
                 w_rro==1'b1 ? (
                   |w_fct7==1'b0 ? 1'b1 : 1'b0) : 
                 1'b1) : 1'b0;
  wire w_sub = (w_fct3_one_hot[0]==1'b1 && w_rro==1'b1 && w_fct7[5]==1'b1) ? 1'b1 : 1'b0;
  wire w_sll = (w_fct3_one_hot[1]==1'b1 && |w_fct7==1'b0) ? 1'b1 : 1'b0;
  wire w_slt = (w_fct3_one_hot[2]==1'b1 || w_fct3_one_hot[3]==1'b1) ? (
                 w_rro==1'b1 ? (
                   |w_fct7==1'b0 ? 1'b1 : 1'b0) : 
                 1'b1) : 1'b0;
  wire w_xor = w_fct3_one_hot[4]==1'b1 ? (
                 w_rro==1'b1 ? (
                   |w_fct7==1'b0 ? 1'b1 : 1'b0) : 
                 1'b1) : 1'b0;
  wire w_srl = (w_fct3_one_hot[5]==1'b1 && |w_fct7==1'b0) ? 1'b1 : 1'b0;
  wire w_sra = (w_fct3_one_hot[5]==1'b1 && w_fct7[5]==1'b1) ? 1'b1 : 1'b0;
  wire w_or  = w_fct3_one_hot[6]==1'b1 ? (
                 w_rro==1'b1 ? (
                   |w_fct7==1'b0 ? 1'b1 : 1'b0) : 
                 1'b1) : 1'b0;
  wire w_and = w_fct3_one_hot[7]==1'b1 ? (
                 w_rro==1'b1 ? (
                   |w_fct7==1'b0 ? 1'b1 : 1'b0) : 
                 1'b1) : 1'b0;

  wire [31:0] w_simm_rs2 = w_rii==1'b1 ? ((w_fct3_one_hot[3]==1'b1 || ((w_fct3_one_hot[1]==1'b1 || w_fct3_one_hot[5]==1'b1) && |w_fct7==1'b0)) ? w_uimm : w_simm) : 
                                         (w_fct3_one_hot[2]==1'b1 ? $signed(i_master_core1_read_data) : i_master_core1_read_data);
  wire [31:0] w_rxx_data = w_add==1'b1 ? (i_master_core0_read_data+w_simm_rs2) :
                           w_sub==1'b1 ? (i_master_core0_read_data-w_simm_rs2) :
                           w_sll==1'b1 ? (i_master_core0_read_data << w_simm_rs2[4:0]) :
                           w_slt==1'b1 ? (i_master_core0_read_data < w_simm_rs2 ? 32'h1 : 32'h0) :
                           w_xor==1'b1 ? (i_master_core0_read_data ^ w_simm_rs2) :
                           w_srl==1'b1 ? (i_master_core0_read_data >> w_simm_rs2[4:0]) :
                           w_sra==1'b1 ? ($signed(i_master_core0_read_data) >>> w_simm_rs2[4:0]) :
                           w_or ==1'b1 ? (i_master_core0_read_data | w_simm_rs2) :
                           w_and==1'b1 ? (i_master_core0_read_data & w_simm_rs2) : 
                           i_master_core0_read_data;
  wire w_mul = (w_hcc==1'b1 && w_fct3[2]==1'b0) ? 1'b1 : 1'b0;
  wire w_div = (w_hcc==1'b1 && w_fct3[2]==1'b1) ? 1'b1 : 1'b0;
  reg r_div_ready;
  // Jump/Branch-group of instructions (w_opcode==7'b1100011)
  wire [31:0] w_j_simm = {(i_inst_read_data[31] ? L_ALL_ONES[31:21] : L_ALL_ZERO[31:21]),
                          i_inst_read_data[31], i_inst_read_data[19:12],
                          i_inst_read_data[20], i_inst_read_data[30:21], L_ALL_ZERO[0]};
  wire w_bmux = (w_bcc==1'b1 && (
                  w_fct3_one_hot[0]==1'b1 ? (i_master_core0_read_data == i_master_core1_read_data) :                   // beq
                  w_fct3_one_hot[1]==1'b1 ? (i_master_core0_read_data != i_master_core1_read_data) :                   // bne
                  w_fct3_one_hot[4]==1'b1 ? ($signed(i_master_core0_read_data) < $signed(i_master_core1_read_data)) :  // blt
                  w_fct3_one_hot[5]==1'b1 ? ($signed(i_master_core0_read_data) >= $signed(i_master_core1_read_data)) : // bge
                  w_fct3_one_hot[6]==1'b1 ? (i_master_core0_read_data < i_master_core1_read_data) :                    // bltu
                  w_fct3_one_hot[7]==1'b1 ? (i_master_core0_read_data >= i_master_core1_read_data) :                   // bgeu
                  1'b0)) ? 1'b1 : 1'b0;
  wire        w_jump_request = (w_jalr==1'b1 || w_bmux==1'b1) ? 1'b1 : 1'b0;
  wire [31:0] w_master_addr  = (i_master_core0_read_data+w_simm); // Address created by bcc, lcc and scc instructions
  wire [31:0] w_jump_value   = w_jalr==1'b1 ? w_master_addr : (w_simm+r_pc_fetch);
  reg  [29:0] r_master_addr;
  reg  [3:0]  r_master_select;
  // L-group of instructions (w_opcode==7'b0000011)
  reg  [3:0]  r_load_cases;
  wire [31:0] w_l_data = r_load_cases==L_LOAD_SIGNED_3_BYTE ? {(i_master_read_data[31]==1'b1 ? L_ALL_ONES[31:8] : L_ALL_ZERO[31:8]), i_master_read_data[31:24]} :
                         r_load_cases==L_LOAD_SIGNED_2_BYTE ? {(i_master_read_data[23]==1'b1 ? L_ALL_ONES[31:8] : L_ALL_ZERO[31:8]), i_master_read_data[23:16]} :
                         r_load_cases==L_LOAD_SIGNED_1_BYTE ? {(i_master_read_data[15]==1'b1 ? L_ALL_ONES[31:8] : L_ALL_ZERO[31:8]), i_master_read_data[15:8]} :
                         r_load_cases==L_LOAD_SIGNED_0_BYTE ? {(i_master_read_data[7]==1'b1 ? L_ALL_ONES[31:8] : L_ALL_ZERO[31:8]), i_master_read_data[7:0]}:
                         r_load_cases==L_LOAD_UNSIGNED_3_BYTE ? {L_ALL_ZERO[31:8], i_master_read_data[31:24]} :
                         r_load_cases==L_LOAD_UNSIGNED_2_BYTE ? {L_ALL_ZERO[31:8], i_master_read_data[23:16]} :
                         r_load_cases==L_LOAD_UNSIGNED_1_BYTE ? {L_ALL_ZERO[31:8], i_master_read_data[15:8]} :
                         r_load_cases==L_LOAD_UNSIGNED_0_BYTE ? {L_ALL_ZERO[31:8], i_master_read_data[7:0]}:
                         r_load_cases==L_LOAD_SIGNED_UPPER_WORD ? {(i_master_read_data[31]==1'b1 ? L_ALL_ONES[31:16] : L_ALL_ZERO[31:16]), i_master_read_data[31:16]} :
                         r_load_cases==L_LOAD_SIGNED_LOWER_WORD ? {(i_master_read_data[31]==1'b1 ? L_ALL_ONES[31:16] : L_ALL_ZERO[31:16]), i_master_read_data[15:0]} :
                         r_load_cases==L_LOAD_UNSIGNED_UPPER_WORD ? {L_ALL_ZERO[31:16], i_master_read_data[31:16]} :
                         r_load_cases==L_LOAD_UNSIGNED_LOWER_WORD ? {L_ALL_ZERO[31:16], i_master_read_data[15:0]} : 
                         r_load_cases==L_LOAD_WORD ? i_master_read_data : 32'h0;
  // S-group of instructions (w_opcode==7'b0100011)
  wire [31:0] w_s_data = w_fct3_one_hot[0]==1'b1 ? {4{i_master_core1_read_data[7:0]}} :
                         w_fct3_one_hot[1]==1'b1 ? {2{i_master_core1_read_data[15:0]}} : i_master_core1_read_data;
  reg  [31:0] r_s_data;
  // Memory Master Read and Write Process
  reg  r_master_read_ready;
  reg  r_master_write_ready;
  wire w_write_stb = (w_scc==1'b1 || r_master_write_ready==1'b0) ? 1'b1 : 1'b0; // Store Strobe
  wire w_read_stb  = (w_lcc==1'b1 || r_master_read_ready==1'b0)  ? 1'b1 : 1'b0; // Load Strobe
  // CSRs
  reg  r_decoded_instr;
  wire w_csr = (w_systm==1'b1 && |w_source1_pointer==1'b0 &&
                |o_csr_read_addr==1'b1 && w_fct3_one_hot[2]==1'b1) ? 1'b1 : 1'b0; // Cycle or Instr reg
                
  ///////////////////////////////////////////////////////////////////////////////
  //            ********      Architecture Declaration      ********           //
  ///////////////////////////////////////////////////////////////////////////////
    
  ///////////////////////////////////////////////////////////////////////////////
  // Process     : Program Counter Process
  // Description : Updates the next program counter after the data instruction 
  //               is consumed.
  ///////////////////////////////////////////////////////////////////////////////
  always @(posedge i_clk) begin
    if (i_reset_sync == 1'b1) begin
      r_program_counter_state <= S_WAKEUP;
      r_pc_fetch              <= P_CORE_INITIAL_FETCH_ADDR;
      r_rd1                   <= 'h0;
      r_rd2                   <= 'h0;
      r_program_counter_valid <= 1'b0;
      r_decoded_instr         <= 1'b0;
      r_master_addr           <= 30'h0;
    end
    else begin
      casez (1'b1)
        r_program_counter_state[0] : begin
          // Fetch first instruction after reset.
          r_program_counter_valid <= 1'b1;
          r_program_counter_state <= S_WAIT_FOR_ACK;
        end
        r_program_counter_state[1] : begin
          // If the no valid inst is currently available or if the following process
          // is ready to consume the valid instruction.
          if (i_inst_read_ack == 1'b1 ) begin
            if (w_lcc == 1'b1 || w_scc == 1'b1 || w_div == 1'b1) begin
              // If a valid instruction was just received.
              r_master_addr           <= w_master_addr[31:2];
              r_master_select         <= o_master_write_sel;
              r_decoded_instr         <= 1'b0;
              r_rd1                   <= w_rd;
              r_program_counter_state <= S_WAIT_FOR_EXT;
            end
            else if (w_mul == 1'b1 || w_csr == 1'b1) begin
              // If a valid instruction was just received.
              r_rd2                   <= w_rd;
              r_decoded_instr         <= 1'b0;
              r_program_counter_state <= S_WAIT_FOR_SETTLE;
            end
            else begin
              // Transition
              r_decoded_instr         <= 1'b1;
              r_program_counter_state <= S_WAIT_FOR_ACK;
            end

            if (w_jal==1'b1) begin
              // Is an immediate jump request. Update the program counter with the 
              // jump value. (JAL)
              r_pc_fetch <= (r_pc_fetch+w_j_simm);
            end
            else if (w_jump_request == 1'b1) begin
              // Jump request by comparison (Branch or JALR).
              r_pc_fetch <= w_jump_value;
            end
            else begin
              // Increment the program counter. Ignore this instruction
              r_pc_fetch <= (r_pc_fetch+4);
            end
          end 
          else begin
            r_decoded_instr         <= 1'b0;
            r_program_counter_state <= S_WAIT_FOR_ACK;
          end
        end
        r_program_counter_state[2] : begin
          // Wait one clock cycle to allow data to be stored in the registers.
          if (i_master_read_ack == 1'b1 || i_master_write_ack == 1'b1 || 
            i_master_div_ack == 1'b1) begin
            // Data received. Transition to fetch new instruction.
            r_decoded_instr         <= 1'b1;
            r_program_counter_state <= S_WAIT_FOR_ACK;
          end
        end
        r_program_counter_state[3] : begin
          // Wait one clock cycle to allow data to be stored in the registers.
            r_decoded_instr         <= 1'b1;
            r_program_counter_state <= S_WAIT_FOR_ACK;
        end
      endcase
    end
  end
  // Wishbone Strobe and Address output assignments
  assign o_inst_read_stb  = r_program_counter_valid;
  assign o_inst_read_addr = r_pc_fetch;

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : General Purpose Registers Read Controls Connections
  // Description : Updates the contents of the read strobe and address.
  ///////////////////////////////////////////////////////////////////////////////
  // Address Select
  assign o_master_core0_read_addr = w_source1_pointer;
  assign o_master_core1_read_addr = w_source2_pointer;

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : General Purpose Registers Write Connections
  // Description : Updates the write strobe, addr, and data.
  ///////////////////////////////////////////////////////////////////////////////
    // Register Write Strobe Control
  assign o_master_core_write_stb = (r_program_counter_state[1]==1'b1 && w_rd_not_zero==1'b1 && i_inst_read_ack==1'b1) ? (
                                     (w_auipc==1'b1 || w_lui==1'b1 ||  w_jal==1'b1 || w_rii==1'b1 ||
                                     w_rro==1'b1 || w_jalr==1'b1) ? 1'b1 : 1'b0) :
                                   w_destination_not_zero==1'b1 && i_master_read_ack==1'b1 && r_program_counter_state[2]==1'b1 ? 1'b1 : 
                                   1'b0;
  // Register write address Select
  assign o_master_core_write_addr = r_program_counter_state[1]==1'b1 ? w_rd : r_rd1;
  // Registers Write Data select
  assign o_master_core_write_data = w_lui==1'b1 ? {i_inst_read_data[31:12], L_ALL_ZERO[11:0]} :
                                      // Load Upper Immediate.
                                      // Used to build 32-bit constants and uses the U-type format. Places the
                                      // 32-bit U-immediate value into the destination register rd, filling in
                                      // the lowest 12 bits with zeros.
                                    w_auipc==1'b1 ? (r_pc_fetch+({i_inst_read_data[31:12], L_ALL_ZERO[11:0]})) :
                                      // Add Upper Immediate to Program Counter.
                                      // Is used to build pc-relative addresses and uses the U-type format. 
                                      // AUIPC forms a 32-bit offset from the U-immediate, filling in the 
                                      // lowest 12 bits with zeros, adds this offset to the address of the 
                                      // AUIPC instruction, then places the result in register rd.
                                    w_jal==1'b1 ? (r_pc_fetch+(32'h4)) :
                                      // If w_decoder_valid = 1 store into general registers data that
                                      // required data from rs1 or rs2.
                                      // Jump And Link Register(indirect jump instruction). JAL
                                    w_jalr==1'b1 ? (r_pc_fetch+(32'h4)) :
                                      // JALR
                                    (w_rii==1'b1 || w_rro==1'b1) ? w_rxx_data :
                                      // Stores the Register-Immediate instruction result in the general register
                                      // Store the Register-Register operation result in the general registers
                                    (i_master_read_ack==1'b1) ? w_l_data :
                                      // Data loaded from memory or I/O device.
                                    i_master_core0_read_data;

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : Read Process
  // Description : Registers the signals that create the read interface
  //               transaction.
  ///////////////////////////////////////////////////////////////////////////////
  always @(posedge i_clk) begin
    if (i_reset_sync == 1'b1) begin
      r_master_read_ready <= 1'b1;
      r_load_cases        <= L_LOAD_OTHERS;
    end
    else begin
      if (w_lcc == 1'b1) begin
        // Load the decode data to an external mem or I/O device.
        r_master_read_ready <= 1'b0;
        if (w_fct3_one_hot[0] == 1'b1) begin
          if (w_master_addr[1:0] == 2'h3) begin
            r_load_cases <= L_LOAD_SIGNED_3_BYTE;
          end
          if (w_master_addr[1:0] == 2'h2) begin
            r_load_cases <= L_LOAD_SIGNED_2_BYTE;
          end
          if (w_master_addr[1:0] == 2'h1) begin
            r_load_cases <= L_LOAD_SIGNED_1_BYTE;
          end
          if (w_master_addr[1:0] == 2'h0) begin
            r_load_cases <= L_LOAD_SIGNED_0_BYTE;
          end
        end
        else if (w_fct3_one_hot[4] == 1'b1) begin
          if (w_master_addr[1:0] == 2'h3) begin
            r_load_cases <= L_LOAD_UNSIGNED_3_BYTE;
          end
          if (w_master_addr[1:0] == 2'h2) begin
            r_load_cases <= L_LOAD_UNSIGNED_2_BYTE;
          end
          if (w_master_addr[1:0] == 2'h1) begin
            r_load_cases <= L_LOAD_UNSIGNED_1_BYTE;
          end
          if (w_master_addr[1:0] == 2'h0) begin
            r_load_cases <= L_LOAD_UNSIGNED_0_BYTE;
          end
        end
        else if (w_fct3_one_hot[1] == 1'b1) begin
          if (w_master_addr[1] == 1'b1) begin
            r_load_cases <= L_LOAD_SIGNED_UPPER_WORD;
          end
          else begin
            r_load_cases <= L_LOAD_SIGNED_LOWER_WORD;
          end
        end
        else if (w_fct3_one_hot[5] == 1'b1) begin
          if (w_master_addr[1] == 1'b1) begin
            r_load_cases <= L_LOAD_UNSIGNED_UPPER_WORD;
          end
          else begin
            r_load_cases <= L_LOAD_UNSIGNED_LOWER_WORD;
          end
        end
        else if (w_fct3_one_hot[2] == 1'b1) begin
          r_load_cases <= L_LOAD_WORD;
        end
        else begin
          r_load_cases <= L_LOAD_OTHERS;
        end
      end
      if (r_master_read_ready == 1'b0 && i_master_read_ack == 1'b1) begin
        // Received valid data. Ready for new transaction on the next clock.
        r_master_read_ready <= 1'b1;
      end
    end
  end
  // Read WB interface connections
  assign o_master_read_addr = w_lcc==1'b1 ? {w_master_addr[31:2], 2'b00} : {r_master_addr, 2'b00};
  assign o_master_read_stb  = w_read_stb;

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : Write Process
  // Description : Registers the signals used to create a write interface
  //               transaction.
  ///////////////////////////////////////////////////////////////////////////////
  always @(posedge i_clk) begin
    if (i_reset_sync == 1'b1) begin
      r_master_write_ready <= 1'b1;
      r_s_data             <= 32'h0;
    end
    else begin
      if (w_scc == 1'b1) begin
        // Store (write) data in external memory or device.
        r_master_write_ready <= 1'b0;
        r_s_data             <= w_s_data;                    
      end
      if (r_master_write_ready == 1'b0 && i_master_write_ack == 1'b1) begin
        //
        r_master_write_ready <= 1'b1;
      end
    end
  end
  // Write WB interface connections
  assign o_master_write_stb  = w_write_stb;
  assign o_master_write_addr = w_scc==1'b1 ? {w_master_addr[31:2], 2'b00} : {r_master_addr, 2'b00};
  assign o_master_write_data = w_scc==1'b1 ? w_s_data : r_s_data;
  assign o_master_write_sel  = w_scc==1'b1 ?
                                 w_fct3_one_hot[0]==1'b1 ? ( 
                                   w_master_addr[1:0]==2'h3 ? 4'b1000 : 
                                   w_master_addr[1:0]==2'h2 ? 4'b0100 : 
                                   w_master_addr[1:0]==2'h1 ? 4'b0010 : 
                                                              4'b0001 ) :
                                 w_fct3_one_hot[1]==1'b1 ? ( 
                                   w_master_addr[1]==1'b1 ? 4'b1100 :
                                                            4'b0011 ) :
                                                            4'b1111 : 
                                 r_master_select;

  ///////////////////////////////////////////////////////////////////////////////
  // Assignment  : MUL Processor Connections
  // Description : 
  ///////////////////////////////////////////////////////////////////////////////
  assign o_master_mul_stb  = w_mul;
  assign o_master_mul_tga  = w_fct3[1:0];

  ///////////////////////////////////////////////////////////////////////////////
  // Assignment  : DIV Processor Connections
  // Description : 
  ///////////////////////////////////////////////////////////////////////////////
  assign o_master_div_stb  = w_div==1;
  assign o_master_div_tga  = w_fct3[1:0];

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : CSR Connections
  // Description : Decodes and registers the instruction data.
  ///////////////////////////////////////////////////////////////////////////////
  assign o_csr_instr_decoded = r_decoded_instr;
  assign o_csr_read_stb      = w_csr;
  assign o_csr_read_addr     = w_csr_field==L_RDCYCLE    ? 4'b0001 :
                               w_csr_field==L_RDCYCLEH   ? 4'b0010 :
                               w_csr_field==L_RDINSTRET  ? 4'b0100 :
                               w_csr_field==L_RDINSTRETH ? 4'b1000 : 
                                                           4'b0000;
  // General Purpose Signals
  assign o_rd = r_rd2;

endmodule