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
// Last modified : 2021/01/04 10:11:50
// Project Name  : ORCs
// Module Name   : Hart_Core
// Description   : The Hart_Core is a machine mode capable hart, implementation of 
//                 the riscv32im instruction set architecture.
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
  // Instruction Wishbone(pipeline) Master Read Interface
  output        o_inst_read_stb,  // WB read enable
  input         i_inst_read_ack,  // WB acknowledge 
  output [31:0] o_inst_read_addr, // WB address
  input  [31:0] i_inst_read_data, // WB data
  // Core mem0 WB(pipeline) Slave Read Interface
  output                            o_master_core0_read_stb,  // WB read enable
  output [P_CORE_MEMORY_ADDR_MSB:0] o_master_core0_read_addr, // WB address
  input  [31:0]                     i_master_core0_read_data, // WB data
  // Core mem0 WB(pipeline) master Write Interface
  output                            o_master_core0_write_stb,  // WB write enable
  output [P_CORE_MEMORY_ADDR_MSB:0] o_master_core0_write_addr, // WB address
  output [31:0]                     o_master_core0_write_data, // WB data
  // Core mem1 WB(pipeline) master Read Interface
  output                            o_master_core1_read_stb,  // WB read enable
  output [P_CORE_MEMORY_ADDR_MSB:0] o_master_core1_read_addr, // WB address
  input  [31:0]                     i_master_core1_read_data, // WB data
  // Core mem1 WB(pipeline) master Write Interface
  output                            o_master_core1_write_stb,  // WB write enable
  output [P_CORE_MEMORY_ADDR_MSB:0] o_master_core1_write_addr, // WB address
  output [31:0]                     o_master_core1_write_data, // WB data
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
  output [3:0]  o_master_write_sel,  // WB byte enable
  // Integer Multiplication and Division Processor
  output                            o_master_hcc_processor_stb,  // start
  input                             i_master_hcc_processor_ack,  // done
  output                            o_master_hcc_processor_addr, // 0=mul, 1=div/rem
  output                            o_master_hcc_processor_tga,  // 0=div, 1=rem
  output [P_CORE_MEMORY_ADDR_MSB:0] o_master_hcc_processor_data, // rd
  output                            o_master_hcc_processor_tgd   // 0=lower bits, 1=higher bits
);
  ///////////////////////////////////////////////////////////////////////////////
  // Internal Parameter Declarations
  ///////////////////////////////////////////////////////////////////////////////
  // OpCodes 
  localparam [6:0] L_RII   = 7'b0010011; // imm[11:0],[19:15],funct[14:12],rd[11:7]
  localparam [6:0] L_MATH  = 7'b0110011; // funct[6:0],rs2[24:20],rs1[19:15],funct[14:12],rd[11:7]
  localparam [6:0] L_LUI   = 7'b0110111; // imm[31:12], rd[11:7]
  localparam [6:0] L_AUIPC = 7'b0010111; // imm[31:12], rd[11:7]
  localparam [6:0] L_JAL   = 7'b1101111; // imm[20|10:1|11|19:12],rd[11:7]
  localparam [6:0] L_JALR  = 7'b1100111; // imm[11:0], rs1[19:15],000,rd[11:7]
  localparam [6:0] L_BCC   = 7'b1100011; // imm[12|10:5],rs2[24:20],rs1[19:15],funct[14:12],imm[4:1|11]
  localparam [6:0] L_LCC   = 7'b0000011; // imm[11:0],rs1[19:15],funct[14:12],rd[11:7]
  localparam [6:0] L_SCC   = 7'b0100011; // imm[11:5],rs2[24:20],rs1[19:15],funct[14:12],imm[4:0]
  localparam [6:0] L_HCC   = 7'b0000001; // funct7[31:25],rs2[24:20],rs1[19:15],funct3[14:12]
  // Program Counter FSM States
  localparam [2:0] S_WAKEUP           = 3'h0; // r_program_counter_state after reset
  localparam [2:0] S_WAIT_FOR_ACK     = 3'h1; // r_program_counter_state, waiting for valid instruction
  localparam [2:0] S_WAIT_FOR_DECODER = 3'h2; // r_program_counter_state, wait for Decoder process
  localparam [2:0] S_WAIT_FOR_READ    = 3'h3; // r_program_counter_state, wait for load to complete
  localparam [2:0] S_WAIT_FOR_WRITE   = 3'h4; // r_program_counter_state, wait for store to complete
  localparam [2:0] S_WAIT_FOR_HCC     = 3'h5; // r_program_counter_state, wait for store to complete
  // Math fct3
  localparam [2:0] L_MUL    = 3'b000; // MUL
  localparam [2:0] L_MULH   = 3'b001; // MULH
  localparam [2:0] L_MULHSU = 3'b010; // MULHSU
  localparam [2:0] L_MULHU  = 3'b011; // MULHU
  localparam [2:0] L_DIV    = 3'b100; // DIV
  localparam [2:0] L_DIVU   = 3'b101; // DIVU
  localparam [2:0] L_REM    = 3'b110; // REM
  localparam [2:0] L_REMU   = 3'b111; // REMU
  // Misc Definitions
  localparam [31:0] L_FILLER_ZERO = 32'h0000_0000;
  localparam [31:0] L_FILLER_ONE  = 32'hFFFF_FFFF;
  ///////////////////////////////////////////////////////////////////////////////
  // Internal Signals Declarations
  ///////////////////////////////////////////////////////////////////////////////
  // Program Counter Process
  reg [31:0] r_next_pc_fetch;         // 32-bit program counter t
  reg [31:0] r_next_pc_decode;        // 32-bit program counter t-1
  reg        r_program_counter_valid; // Program Counter Valid
  reg [31:0] r_inst_data;             // registers the valid instructions
  reg [2:0]  r_program_counter_state; // Current State Holder.
  // Decoder Process Signals
  wire [6:0]  w_opcode = i_inst_read_data[6:0]; // OPCODE field
  reg  [31:0] r_simm;                           // Signed Immediate
  reg  [31:0] r_uimm;                           // Unsigned Immediate
  reg         r_jalr;                           // valid JALR flag
  reg         r_bcc;                            // valid branch flag
  reg         r_lcc;                            // valid load flag
  reg         r_scc;                            // valid store flag
  reg         r_rii;                            // valid register-immediate flag
  reg         r_rro;                            // valid register-register flag
  reg         r_mul;                            // valid register-register flag
  reg         r_div;                            // valid register-register flag
  // Memory Master Read and Write Process
  reg        r_master_read_ready;
  reg [31:0] r_master_read_addr;
  reg        r_master_write_ready;
  // Instruction Fields wires
  wire [4:0] w_rd                = i_inst_read_data[11:7];  // rd field
  wire [4:0] w_destination_index = r_inst_data[11:7];       // registered rd_field (one clock delayed of w_rd)
  wire [4:0] w_source1_pointer   = i_inst_read_data[19:15]; // s1 field
  wire [4:0] w_source2_pointer   = i_inst_read_data[24:20]; // s2 field
  wire [2:0] w_fct3              = r_inst_data[14:12];      // fct3 field
  wire [6:0] w_fct7              = r_inst_data[31:25];      // fct7 field
  // source-1 and source-2 register selection
  wire        [31:0] r_unsigned_rs1 = i_master_core0_read_data; // rs1 field
  wire        [31:0] r_unsigned_rs2 = i_master_core1_read_data; // rs2 field
  wire signed [31:0] w_signed_rs1   = $signed(r_unsigned_rs1);  // signed rs1
  wire signed [31:0] w_signed_rs2   = $signed(r_unsigned_rs2);  // signed rs2
  wire        [31:0] w_master_addr  = r_unsigned_rs1+r_simm;  // address created by lcc and scc instructions
  // L-group of instructions (w_opcode==7'b0000011)
  wire [31:0] w_l_data = (w_fct3==3'h0 || w_fct3==3'h4) ? 
                           (r_master_read_addr[1:0]==2'h3 ? {(w_fct3==3'h0 && i_master_read_data[31]==1'b1) ? L_FILLER_ONE[31:8]:L_FILLER_ZERO[31:8], i_master_read_data[31:24]} :
                            r_master_read_addr[1:0]==2'h2 ? {(w_fct3==3'h0 && i_master_read_data[23]==1'b1) ? L_FILLER_ONE[31:8]:L_FILLER_ZERO[31:8], i_master_read_data[23:16]} :
                            r_master_read_addr[1:0]==2'h1 ? {(w_fct3==3'h0 && i_master_read_data[15]==1'b1) ? L_FILLER_ONE[31:8]:L_FILLER_ZERO[31:8], i_master_read_data[15:8]} :
                              {(w_fct3==3'h0 && i_master_read_data[7]==1'b1) ? L_FILLER_ONE[31:8]:L_FILLER_ZERO[31:8], i_master_read_data[7:0]}):
                         (w_fct3==3'h1 || w_fct3==3'h5) ? (r_master_read_addr[1]==1'b1 ? {(w_fct3==3'h1 && i_master_read_data[31]==1'b1) ? L_FILLER_ONE[31:16]:L_FILLER_ZERO[31:16], i_master_read_data[31:16]} :
                           {(w_fct3==3'h1 && i_master_read_data[15]==1'b1) ? L_FILLER_ONE[31:16]:L_FILLER_ZERO[31:16], i_master_read_data[15:0]}) : i_master_read_data;
  // S-group of instructions (w_opcode==7'b0100011)
  wire [31:0] w_s_data = w_fct3==3'h0 ? (w_master_addr[1:0]==2'h3 ? {r_unsigned_rs2[7:0], L_FILLER_ZERO [23:0]} :
                                         w_master_addr[1:0]==2'h2 ? {L_FILLER_ZERO [31:24], r_unsigned_rs2[7:0], L_FILLER_ZERO[15:0]} :
                                         w_master_addr[1:0]==2'h1 ? {L_FILLER_ZERO [31:16], r_unsigned_rs2[7:0], L_FILLER_ZERO[7:0]} :
                                                                    {L_FILLER_ZERO [31:8], r_unsigned_rs2[7:0]}) :
                         w_fct3==3'h1 ? (w_master_addr[1]==1'b1 ? {r_unsigned_rs2[15:0], L_FILLER_ZERO [15:0]} :
                                                                  {L_FILLER_ZERO [31:16], r_unsigned_rs2[15:0]}) : r_unsigned_rs2;
  // RM-group of instructions (OPCODEs==7'b0010011/7'b0110011), merged! src=immediate(M)/register(R)
  wire signed [31:0] w_signed_rs2_extended   = r_rii==1'b1 ? r_simm : w_signed_rs2;
  wire        [31:0] w_unsigned_rs2_extended = r_rii==1'b1 ? r_uimm : r_unsigned_rs2;
  wire        [31:0] w_rm_data               = w_fct3==3'h7 ? (r_unsigned_rs1 & w_signed_rs2_extended) :
                                               w_fct3==3'h6 ? (r_unsigned_rs1 | w_signed_rs2_extended) :
                                               w_fct3==3'h4 ? (r_unsigned_rs1 ^ w_signed_rs2_extended) :
                                               w_fct3==3'h3 ? ((r_unsigned_rs1 < w_unsigned_rs2_extended) ? 32'h1 : 32'h0) :
                                               w_fct3==3'h2 ? ((w_signed_rs1 < w_signed_rs2_extended) ? 32'h1 : 32'h0) :
                                               w_fct3==3'h0 ? ((r_rro==1'b1 && w_fct7[5]==1'b1) ? (r_unsigned_rs1-w_unsigned_rs2_extended) :
                                                                                                  (r_unsigned_rs1+w_signed_rs2_extended)) :
                                               w_fct3==3'h1 ? (r_unsigned_rs1 << w_unsigned_rs2_extended[4:0]) :
                                               w_fct7[5]==1'b1 ? $signed(w_signed_rs1 >>> w_unsigned_rs2_extended[4:0]) :                   
                                                                 r_unsigned_rs1 >> w_unsigned_rs2_extended[4:0];
  // Jump/Branch-group of instructions (w_opcode==7'b1100011)
  wire        w_jal    = w_opcode==L_JAL ? 1'b1 : 1'b0;
  wire [31:0] w_j_simm = { i_inst_read_data[31]==1'b1 ? L_FILLER_ONE[31:21]:L_FILLER_ZERO[31:21],
                           i_inst_read_data[31], i_inst_read_data[19:12],
                           i_inst_read_data[20], i_inst_read_data[30:21], L_FILLER_ZERO[0] };
  wire w_bmux = r_bcc & (
                w_fct3==3'h4 ? w_signed_rs1 <  w_signed_rs2 :   // blt
                w_fct3==3'h5 ? w_signed_rs1 >= w_signed_rs2 :   // bge
                w_fct3==3'h6 ? r_unsigned_rs1 <  r_unsigned_rs2 : // bltu
                w_fct3==3'h7 ? r_unsigned_rs1 >= r_unsigned_rs2 : // bgeu
                w_fct3==3'h0 ? r_unsigned_rs1 == r_unsigned_rs2 : // beq
                w_fct3==3'h1 ? r_unsigned_rs1 != r_unsigned_rs2 : // bne
                1'b0);
  wire        w_jump_request = r_jalr | w_bmux;
  wire [31:0] w_jump_value   = r_jalr==1'b1 ? (r_simm+r_unsigned_rs1) : (r_simm+r_next_pc_decode);
  // Mem Process wires
  wire w_rd_not_zero = |w_rd; // or reduction of the destination register.
  // Qualifying signals
  // Decoder Process
  wire w_decoder_valid = r_jalr | r_bcc | r_rii | r_rro;
  // Decoder Process valid/enable
  wire w_decoder_opcode = w_opcode==L_RII  ? 1'b1 :
                          w_opcode==L_MATH ? 1'b1 :
                          w_opcode==L_LCC  ? 1'b1 :
                          w_opcode==L_SCC  ? 1'b1 :
                          w_opcode==L_BCC  ? 1'b1 :
                          w_opcode==L_JALR ? 1'b1 : 1'b0;
  // MUL/DIV instructions decoded
  reg        r_low_results;
  reg        r_high_results;
  wire [2:0] w_fct3_0 = i_inst_read_data[14:12];
  wire       w_mul_l  = w_fct3_0==L_MUL    ? 1'b1 : 1'b0;
  wire       w_mul_h  = w_fct3_0==L_MULH   ? 1'b1 :
                        w_fct3_0==L_MULHSU ? 1'b1 :
                        w_fct3_0==L_MULHU  ? 1'b1 : 1'b0;
  wire       w_div    = w_fct3_0==L_DIV    ? 1'b1 :
                        w_fct3_0==L_DIVU   ? 1'b1 : 1'b0; 
  wire       w_rem    = w_fct3_0==L_REM    ? 1'b1 :
                        w_fct3_0==L_REMU   ? 1'b1 : 1'b0;
  wire       w_hcc    = (i_inst_read_ack==1'b1 && w_opcode==L_MATH && i_inst_read_data[31:25]==L_HCC) ? 1'b1 : 1'b0;
  // Register Write Strobe Control
  wire w_reg_write_stb  = i_reset_sync ? 1'b0 :
                          (w_rd_not_zero==1'b1 && i_inst_read_ack==1'b1) ? (
                            (w_opcode==L_LUI || w_opcode==L_AUIPC || w_opcode==L_JAL) ? 1'b1 : 1'b0) :
                          (w_decoder_valid & (r_jalr | r_rii | r_rro)) ? 1'b1 :
                          (i_master_read_ack==1'b1 && r_master_read_ready==1'b0) ? 1'b1 : 1'b0;
  // Register write address Select
  wire [P_CORE_MEMORY_ADDR_MSB:0] w_reg_write_addr = (w_decoder_valid==1'b1 || (i_master_read_ack==1'b1 && r_master_read_ready==1'b0)) ? w_destination_index : w_rd;
  // Registers Write Data select
  wire [31:0] w_reg_write_data = (w_rd_not_zero==1'b1 && i_inst_read_ack==1'b1) ? (
                                   // Load Upper Immediate.
                                   // Used to build 32-bit constants and uses the U-type format. Places the
                                   // 32-bit U-immediate value into the destination register rd, filling in
                                   // the lowest 12 bits with zeros.
                                   w_opcode==L_LUI ? { i_inst_read_data[31:12], L_FILLER_ZERO[11:0] } :
                                   // Add Upper Immediate to Program Counter.
                                   // Is used to build pc-relative addresses and uses the U-type format. 
                                   // AUIPC forms a 32-bit offset from the U-immediate, filling in the 
                                   // lowest 12 bits with zeros, adds this offset to the address of the 
                                   // AUIPC instruction, then places the result in register rd.
                                   w_opcode==L_AUIPC ? (r_next_pc_fetch+({i_inst_read_data[31:12], L_FILLER_ZERO[11:0]})) :
                                   // Add Upper Immediate to Program Counter.
                                   // Is used to build pc-relative addresses and uses the U-type format. 
                                   // AUIPC forms a 32-bit offset from the U-immediate, filling in the 
                                   // lowest 12 bits with zeros, adds this offset to the address of the 
                                   // AUIPC instruction, then places the result in register rd.
                                   w_opcode==L_JAL ? (r_next_pc_fetch+(32'h4)) : w_rm_data) :
                                 // If w_decoder_valid = 1 store into general registers data that
                                 // required data from rs1 or rs2.
                                 // Jump And Link Register(indirect jump instruction).
                                 (w_decoder_valid==1'b1 && r_jalr==1'b1) ? (r_next_pc_decode+(32'h4)) :
                                 // If w_decoder_valid = 1 store into general registers data that
                                 // required data from rs1 or rs2.
                                 // Stores the Register-Immediate instruction result in the general register
                                 // or store the Register-Register operation result in the general registers
                                 (w_decoder_valid==1'b1 && (r_rii==1'b1 || r_rro==1'b1)) ? w_rm_data :
                                 // Data loaded from memory or I/O device.
                                 (i_master_read_ack==1'b1 && r_master_read_ready==1'b0) ? w_l_data :
                                 // Default case, no change.
                                 w_rm_data;

  ///////////////////////////////////////////////////////////////////////////////
  //            ********      Architecture Declaration      ********           //
  ///////////////////////////////////////////////////////////////////////////////
  
  // Wishbone Strobe and Address output assignments
  assign o_inst_read_stb  = r_program_counter_valid;
  assign o_inst_read_addr = r_next_pc_fetch;
  
  ///////////////////////////////////////////////////////////////////////////////
  // Process     : Program Counter Process
  // Description : Updates the next program counter after the data instruction 
  //               is consumed.
  ///////////////////////////////////////////////////////////////////////////////
  always@(posedge i_clk) begin
    if (i_reset_sync == 1'b1) begin
      r_program_counter_state <= S_WAKEUP;
      r_next_pc_fetch         <= P_CORE_INITIAL_FETCH_ADDR;
      r_next_pc_decode        <= L_FILLER_ZERO;
      r_inst_data             <= L_FILLER_ZERO;
      r_program_counter_valid <= 1'b0;
    end
    else begin
      casez (r_program_counter_state)
        S_WAKEUP : begin
          // Fetch first instruction after reset.
          r_program_counter_valid <= 1'b1;
          r_program_counter_state <= S_WAIT_FOR_ACK;
        end
        S_WAIT_FOR_ACK : begin
          // If the no valid inst is currently available or if the following process
          // is ready to consume the valid instruction.
          if (i_inst_read_ack == 1'b1) begin
            if (w_decoder_opcode == 1'b1) begin
              // Instructions that require accessing registers and/or external 
              // devices.
              // Increment the address and pre-load the program counter. Register
              // the instruction.
              r_next_pc_fetch <= (r_next_pc_fetch+32'h4);
              // Transition
              r_program_counter_valid <= 1'b0;
              r_program_counter_state <= S_WAIT_FOR_DECODER;
            end
            if (w_jal == 1'b1) begin
              // Is an immediate jump request. Update the program counter with the 
              // jump value.
              r_next_pc_fetch <= (w_j_simm+r_next_pc_fetch);
              r_program_counter_valid <= 1'b1;
              r_program_counter_state <= S_WAIT_FOR_ACK;
            end
            else begin
              // Instructions that are executed in one clock: LUI, AUIPC, FENCE, 
              // ECALL and BREAK
              // Increment the program counter. Ignore this instruction
              r_next_pc_fetch <= (r_next_pc_fetch+32'h4);
              r_program_counter_valid <= 1'b1;
              r_program_counter_state <= S_WAIT_FOR_ACK;
            end
            r_inst_data <= i_inst_read_data;
          end
          else begin
            r_inst_data             <= r_inst_data;
            r_program_counter_valid <= 1'b0;
            r_program_counter_state <= S_WAIT_FOR_ACK;
          end
          // Update the program counter.
          r_next_pc_decode <= r_next_pc_fetch;
        end
        S_WAIT_FOR_DECODER : begin
          // Wait one clock cycle to allow data to be stored in the registers.
          if (r_mul == 1'b1 || r_div == 1'b1) begin
            // Transition to wait for division to finish
            r_program_counter_valid <= 1'b0;
            r_program_counter_state <= S_WAIT_FOR_HCC;
          end
          else if (r_lcc == 1'b1) begin
            // Load external data
            r_program_counter_valid <= 1'b0;
            r_program_counter_state <= S_WAIT_FOR_READ;
          end
          else if (r_scc == 1'b1) begin
            // Store data in external.
            r_program_counter_valid <= 1'b0;
            r_program_counter_state <= S_WAIT_FOR_WRITE;
          end
          else begin
            // Done with two cycle instructions.
            if (w_jump_request == 1'b1) begin
              // Jump request by comparison (Branch or JALR).
              r_next_pc_fetch <= w_jump_value;
            end
            r_program_counter_valid <= 1'b1;
            r_program_counter_state <= S_WAIT_FOR_ACK;
          end
          r_inst_data <= r_inst_data;
        end
        S_WAIT_FOR_READ : begin
          if (i_master_read_ack == 1'b1) begin
            // Data received. Transition to fetch new instruction.
            r_program_counter_valid <= 1'b1;
            r_program_counter_state <= S_WAIT_FOR_ACK;
          end
          else begin
            r_program_counter_valid <= 1'b0;
            r_program_counter_state <= S_WAIT_FOR_READ;
          end
          r_inst_data <= r_inst_data;
        end
        S_WAIT_FOR_WRITE : begin
          if (i_master_write_ack == 1'b1) begin
            // Data write acknowledge. Transition to fetch new instruction.
            r_program_counter_valid <= 1'b1;
            r_program_counter_state <= S_WAIT_FOR_ACK;
          end
          else begin
            r_program_counter_valid <= 1'b0;
            r_program_counter_state <= S_WAIT_FOR_WRITE;
          end
          r_inst_data <= r_inst_data;
        end
        S_WAIT_FOR_HCC : begin
          if (i_master_hcc_processor_ack == 1'b1) begin
            // Data write acknowledge. Transition to fetch new instruction.
            r_program_counter_valid <= 1'b1;
            r_program_counter_state <= S_WAIT_FOR_ACK;
          end
          else begin
            r_program_counter_valid <= 1'b0;
            r_program_counter_state <= S_WAIT_FOR_HCC;
          end
          r_inst_data <= r_inst_data;
        end
        default : begin
          r_inst_data             <= r_inst_data;
          r_program_counter_valid <= 1'b0;
          r_program_counter_state <= S_WAIT_FOR_ACK;
        end
      endcase
    end
  end

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : Decoder Process
  // Description : Decodes and registers the instruction data.
  ///////////////////////////////////////////////////////////////////////////////
  always@(posedge i_clk) begin
    if (i_reset_sync == 1'b1) begin
      r_jalr         <= 1'b0;
      r_bcc          <= 1'b0;
      r_lcc          <= 1'b0;
      r_scc          <= 1'b0;
      r_rii          <= 1'b0;
      r_rro          <= 1'b0;
      r_mul          <= 1'b0;
      r_div          <= 1'b0;
      r_low_results  <= 1'b0;
      r_high_results <= 1'b0;
      r_simm         <= L_FILLER_ZERO;
      r_uimm         <= L_FILLER_ZERO;
    end
    else begin
      if (i_inst_read_ack == 1'b1 && w_rd_not_zero == 1'b1) begin
        // If rs1 and rs2 are valid
        if (w_opcode == L_RII) begin
          // Register-Immediate Instructions.
          // Performs ADDI, SLTI, ANDI, ORI, XORI, SLLI, SRLI, SRAI (I=immediate).
          r_rii  <= 1'b1;
          r_simm <= { i_inst_read_data[31]==1'b1 ? L_FILLER_ONE[31:12]:L_FILLER_ZERO[31:12], i_inst_read_data[31:20] };
          r_uimm <= { L_FILLER_ZERO[31:12], i_inst_read_data[31:20] };
        end
        else begin
          r_rii <= 1'b0;
        end
  
        if (w_opcode == L_MATH) begin
          // Register-Register Operations
          if (i_inst_read_data[31:25] == L_HCC) begin
            // Store, Math Operation (Multiplication or Division)
            // TBD
            r_mul <= w_mul_l | w_mul_h;
            r_div <= w_div | w_rem;
            // Higher or lower 32bits
            r_low_results  <= w_mul_l | w_rem;
            r_high_results <= w_mul_h | w_div;
            //
            r_rro <= 1'b0;
          end
          else begin
            // Performs ADD, SLT, SLTU, AND, OR, XOR, SLL, SRL, SUB, SRA
            r_rro          <= 1'b1;
            r_mul          <= 1'b0;
            r_div          <= 1'b0;
            r_low_results  <= 1'b0;
            r_high_results <= 1'b0;
          end
          //
          r_simm <= L_FILLER_ZERO;
          r_uimm <= L_FILLER_ZERO;
        end
        else begin
          r_rro          <= 1'b0;
          r_mul          <= 1'b0;
          r_div          <= 1'b0;
          r_low_results  <= 1'b0;
          r_high_results <= 1'b0;
        end
  
        if (w_opcode == L_JALR) begin
          //  Jump And Link Register(indirect jump instruction).
          // The target address is obtained by adding the sign-extended 12-bit
          // I-immediate to the register rs1, then setting the least-significant bit of
          // the result to zero. The address of the instruction following the jump
          // (r_next_pc_fetch) is written to register rd. Register x0 can be
          // used as the destination if the result is not required.
          r_jalr <= 1'b1;
          r_simm <= { i_inst_read_data[31]==1'b1 ? L_FILLER_ONE[31:12]:L_FILLER_ZERO[31:12],
                      i_inst_read_data[31:20] };
          r_uimm <= L_FILLER_ZERO;
        end
        else begin
          r_jalr <= 1'b0;
        end
          
        if (w_opcode == L_BCC) begin
          // Branches Conditional to Comparisons.
          // The 12-bit B-immediate encodes signed offsets in multiples of 2 bytes.
          // The offset is sign-extended and added to the address of the branch 
          // instruction to give the target address. Branch instructions compare 
          // two registers.
          r_bcc  <= 1'b1;
          r_simm <= { i_inst_read_data[31]==1'b1 ? L_FILLER_ONE[31:13]:L_FILLER_ZERO[31:13], 
                     i_inst_read_data[31],i_inst_read_data[7],i_inst_read_data[30:25],
                     i_inst_read_data[11:8],L_FILLER_ZERO[0] };
          r_uimm <= L_FILLER_ZERO;
        end
        else begin
          r_bcc <= 1'b0;
        end
  
        if (w_opcode == L_LCC) begin
          // Load, Conditional to Comparisons.
          // The effective address is obtained by adding register rs1 to the 
          // sign-extended 12-bit offset. Loads copy a value from memory to 
          // register rd.
          r_lcc  <= 1'b1;
          r_simm <= { i_inst_read_data[31]==1'b1 ? L_FILLER_ONE[31:12]:L_FILLER_ZERO[31:12], 
                     i_inst_read_data[31:20] };
          r_uimm <= L_FILLER_ZERO;
        end
        else begin
          r_lcc <= 1'b0;
        end
  
        if (w_opcode == L_SCC) begin
          // Store, Conditional to Comparisons.
          // The effective address is obtained by adding register rs1 to the 
          // sign-extended 12-bit offset. Stores copy the value in register rs2 to
          // memory.
          r_scc  <= 1'b1;
          r_simm <= { i_inst_read_data[31]==1'b1 ? L_FILLER_ONE[31:12]:L_FILLER_ZERO[31:12], 
                       i_inst_read_data[31:25], i_inst_read_data[11:7] };
          r_uimm <= L_FILLER_ZERO;
        end
        else begin
          r_scc <= 1'b0;
        end
      end
      else begin
        // If Data not valid or if decoder not ready
        r_rii  <= 1'b0;
        r_rro  <= 1'b0;
        r_jalr <= 1'b0;
        r_bcc  <= 1'b0;
        r_lcc  <= 1'b0;
        r_scc  <= 1'b0;
        r_mul  <= 1'b0;
        r_div  <= 1'b0;
        r_high_results <= 1'b0;
      end
    end
  end

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : General Purpose Registers Read Controls
  // Description : Updates the contents of the read strobe and address.
  ///////////////////////////////////////////////////////////////////////////////
  // Strobe Control
  assign o_master_core0_read_stb = i_inst_read_ack;
  assign o_master_core1_read_stb = i_inst_read_ack;
  // Address Select
  assign o_master_core0_read_addr = w_source1_pointer;
  assign o_master_core1_read_addr = w_source2_pointer;

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : General Purpose Registers Write Process
  // Description : Updates the write strobe, addr, and data.
  ///////////////////////////////////////////////////////////////////////////////
  // mem0
  assign o_master_core0_write_stb  = w_reg_write_stb;
  assign o_master_core0_write_addr = w_reg_write_addr;
  assign o_master_core0_write_data = w_reg_write_data;
  // mem1
  assign o_master_core1_write_stb  = w_reg_write_stb;
  assign o_master_core1_write_addr = w_reg_write_addr;
  assign o_master_core1_write_data = w_reg_write_data;

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : I/O Read Process
  // Description : Registers the signals that create the read interface
  //               transaction.
  ///////////////////////////////////////////////////////////////////////////////
  always@(posedge i_clk) begin
    if (i_reset_sync == 1'b1) begin
      r_master_read_ready <= 1'b1;
      r_master_read_addr  <= L_FILLER_ZERO;
    end
    else if (r_master_read_ready == 1'b1 &&  r_lcc == 1'b1) begin
      // Load the decode data to an external mem or I/O device.
      r_master_read_ready <= 1'b0;
      r_master_read_addr  <= w_master_addr;
    end
    else if (r_master_read_ready == 1'b0 &&  i_master_write_ack == 1'b1) begin
      // Received valid data. Ready for new transaction on the next clock.
      r_master_read_ready <= 1'b1;
    end
  end
  assign o_master_read_addr = w_master_addr;
  assign o_master_read_stb  = r_lcc;

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : I/O Write Process
  // Description : Registers the signals used to create a write interface
  //               transaction.
  ///////////////////////////////////////////////////////////////////////////////
  always@(posedge i_clk) begin
    if (i_reset_sync == 1'b1) begin
      r_master_write_ready <= 1'b0;
    end
    else if (r_master_write_ready == 1'b1 && r_scc == 1'b1) begin
      // Store (write) data in external memory or device.
      r_master_write_ready <= 1'b0;                       
    end
    else if (r_master_write_ready == 1'b0 && i_master_write_ack == 1'b1) begin
      r_master_write_ready <= 1'b1;
    end
  end
  assign o_master_write_stb  = r_scc;
  assign o_master_write_addr = w_master_addr;
  assign o_master_write_data = w_s_data;
  assign o_master_write_sel  = (w_fct3==3'h0 || w_fct3==3'h4) ? (
                                 w_master_addr[1:0]==2'h3 ? 4'b1000 :
                                 w_master_addr[1:0]==2'h2 ? 4'b0100 :
                                 w_master_addr[1:0]==2'h1 ? 4'b0010 :
                                                         4'b0001) :
                               (w_fct3==3'h1 || w_fct3==3'h5) ? (
                                 w_master_addr[1]==1'b1 ? 4'b1100 :
                                                          4'b0011) :
                                                          4'b1111;

  ///////////////////////////////////////////////////////////////////////////////
  // Assignment  : HCC Processor Connections
  // Description : 
  ///////////////////////////////////////////////////////////////////////////////
  assign o_master_hcc_processor_stb  = r_div | r_mul;
  assign o_master_hcc_processor_addr = r_div;
  assign o_master_hcc_processor_tga  = r_low_results;
  assign o_master_hcc_processor_data = w_destination_index;
  assign o_master_hcc_processor_tgd  = r_high_results;

endmodule
