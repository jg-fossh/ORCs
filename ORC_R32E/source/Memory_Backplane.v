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
// Last modified : 2021/02/13 09:30:47
// Project Name  : ORCs
// Module Name   : Memory_Backplane
// Description   : The Memory_Backplane controls access to the DRAMs.
//
// Additional Comments:
//   
/////////////////////////////////////////////////////////////////////////////////
module Memory_Backplane #(
  parameter integer P_MEM_STACK_ADDR   = 0, // Reg 0x2 reset value
  parameter integer P_MEM_ADDR_MSB     = 3,
  parameter integer P_MEM_DEPTH        = 16,
  parameter integer P_MEM_WIDTH        = 32,
  parameter integer P_MEM_NUM_REGS     = 16,
  parameter integer P_MEM_ANLOGIC_DRAM = 0
)(
  // Component's clocks and resets
  input i_clk,        // clock
  input i_reset_sync, // reset
  // Core mem0 WB(pipeline) Slave Read Interface
  input  [P_MEM_ADDR_MSB:0] i_slave_core0_read_addr, // WB address
  output [P_MEM_WIDTH-1:0]  o_slave_core0_read_data, // WB data
  // Core mem1 WB(pipeline) Slave Read Interface
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
  // General Registers Reset
  reg [L_REG_RESET_INDEX_MSB:0] reset_index; //
  // Write Case
  wire w_write_enable = |{i_reset_sync, i_slave_core_write_stb};
  // Write Address
  wire [P_MEM_ADDR_MSB:0] w_write_addr = i_reset_sync==1'b1 ? reset_index : 
                                         i_slave_core_write_stb==1'b1 ? i_slave_core_write_addr :
                                         'h0;
  // Write Data
  wire [P_MEM_WIDTH-1:0] w_write_data = i_reset_sync==1'b1 ? (reset_index==2 ? P_MEM_STACK_ADDR : 'h0) : 
                                        i_slave_core_write_stb==1'b1 ? i_slave_core_write_data :
                                                                       'h0;
  
  ///////////////////////////////////////////////////////////////////////////////
  //            ********      Architecture Declaration      ********           //
  ///////////////////////////////////////////////////////////////////////////////
  
  ///////////////////////////////////////////////////////////////////////////////
  // Process     : General Purpose Registers Reset Index
  // Description : Increments address index while in reset.
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
    if (P_MEM_ANLOGIC_DRAM == 0) begin
      // Regs
      reg [P_MEM_WIDTH-1:0] general_regs [0:P_MEM_DEPTH-1];
      
      ///////////////////////////////////////////////////////////////////////////////
      // Instance    : Register Space Write Controls
      // Description : Selects appropriate index.
      ///////////////////////////////////////////////////////////////////////////////
      always@(posedge i_clk) begin
        if (i_reset_sync == 1'b1) begin
          general_regs[reset_index] <= w_write_data;
        end
        else begin
          if(w_write_enable == 1'b1) begin
            // Write Valid Data
            general_regs[w_write_addr] <= w_write_data;
          end
        end
      end
      // Read Controls
      assign o_slave_core0_read_data = general_regs[i_slave_core0_read_addr];
      assign o_slave_core1_read_data = general_regs[i_slave_core1_read_addr];
    end
  endgenerate

  generate
    if (P_MEM_ANLOGIC_DRAM == 1) begin
      ///////////////////////////////////////////////////////////////////////////////
      // Instance    : General Purpose Registers 0
      // Description : Anlogic IP EG_LOGIC_DRAM, TD version 4.6.18154
      ///////////////////////////////////////////////////////////////////////////////
      EG_LOGIC_DRAM #(
        .INIT_FILE("NONE"),
        .DATA_WIDTH_W(P_MEM_WIDTH),
        .ADDR_WIDTH_W(P_MEM_ADDR_MSB+1),
        .DATA_DEPTH_W(P_MEM_DEPTH),
        .DATA_WIDTH_R(P_MEM_WIDTH),
        .ADDR_WIDTH_R(P_MEM_ADDR_MSB+1),
        .DATA_DEPTH_R(P_MEM_DEPTH)
      ) general_regs0 (
        .di(w_write_data),
        .waddr(w_write_addr),
        .wclk(i_clk),
        .we(w_write_enable),
        .do(o_slave_core0_read_data),
        .raddr(i_slave_core0_read_addr)
      );
      
      ///////////////////////////////////////////////////////////////////////////////
      // Instance    : General Purpose Registers 1
      // Description : Anlogic IP EG_LOGIC_DRAM, TD version 4.6.18154
      ///////////////////////////////////////////////////////////////////////////////
      EG_LOGIC_DRAM #(
        .INIT_FILE("NONE"),
        .DATA_WIDTH_W(P_MEM_WIDTH),
        .ADDR_WIDTH_W(P_MEM_ADDR_MSB+1),
        .DATA_DEPTH_W(P_MEM_DEPTH),
        .DATA_WIDTH_R(P_MEM_WIDTH),
        .ADDR_WIDTH_R(P_MEM_ADDR_MSB+1),
        .DATA_DEPTH_R(P_MEM_DEPTH)
      ) general_regs1 (
        .di(w_write_data),
        .waddr(w_write_addr),
        .wclk(i_clk),
        .we(w_write_enable),
        .do(o_slave_core1_read_data),
        .raddr(i_slave_core1_read_addr)
      );
    end
  endgenerate

endmodule