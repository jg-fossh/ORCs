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
// File name     : MUL_Processor.v
// Author        : Jose R Garcia
// Created       : 2020/12/06 15:51:57
// Last modified : 2021/02/01 11:59:29
// Project Name  : ORCs
// Module Name   : MUL_Processor
// Description   : 
//
// Additional Comments:
//   .
/////////////////////////////////////////////////////////////////////////////////
module MUL_Processor #(
  parameter integer P_MUL_FACTORS_MSB = 31,
  parameter integer P_MUL_ANLOGIC_MUL = 0
)(
  // Clock and Reset
  input i_clk,
  input i_reset_sync,
  // WB Slave Interface
  input                     i_slave_mul_processor_stb,
  input  [1:0]              i_slave_mul_processor_tga,
  // WB(pipeline) master Read Interface
  input  [P_MUL_FACTORS_MSB:0] i_master_mul0_read_data, // WB data
  // WB(pipeline) master Read Interface
  input  [P_MUL_FACTORS_MSB:0] i_master_mul1_read_data, // WB data
  // WB(pipeline) Master Write Interface
  output                       o_master_mul_write_stb, // WB data
  output [P_MUL_FACTORS_MSB:0] o_master_mul_write_data // WB data
);

  ///////////////////////////////////////////////////////////////////////////////
  // Internal Parameter Declarations
  ///////////////////////////////////////////////////////////////////////////////
  localparam L_MUL_FACTORS_NUM_BITS     = P_MUL_FACTORS_MSB+1;
  localparam L_MUL_FACTORS_EXTENDED_MSB = ((P_MUL_FACTORS_MSB+1)*2)-1;
  localparam L_MUL_PRODUCT_EXTENDED_MSB = ((L_MUL_FACTORS_EXTENDED_MSB+1)*2)-1;
  ///////////////////////////////////////////////////////////////////////////////
  // Internal Signals Declarations
  ///////////////////////////////////////////////////////////////////////////////
  // MUL Controls
  reg r_stb;
  reg r_tgd;
  // MUL Processor to Memory_Backplane connecting wires.
  reg  [L_MUL_FACTORS_EXTENDED_MSB:0] r_product;
  wire [P_MUL_FACTORS_MSB:0]          w_product_select = r_tgd==1'b1 ? r_product[63:32] : r_product[31:0];
  //
  wire [P_MUL_FACTORS_MSB:0] w_multiplicand = ^i_slave_mul_processor_tga ? {{L_MUL_FACTORS_NUM_BITS{i_master_mul0_read_data[P_MUL_FACTORS_MSB]}}, i_master_mul0_read_data} :
                                                {{L_MUL_FACTORS_NUM_BITS{1'b0}}, i_master_mul0_read_data};
  wire [P_MUL_FACTORS_MSB:0] w_multiplier   = i_slave_mul_processor_tga==2'b01 ? {{L_MUL_FACTORS_NUM_BITS{i_master_mul1_read_data[P_MUL_FACTORS_MSB]}}, i_master_mul1_read_data} :
                                                {{L_MUL_FACTORS_NUM_BITS{1'b0}}, i_master_mul1_read_data};
  ///////////////////////////////////////////////////////////////////////////////
  //            ********      Architecture Declaration      ********           //
  ///////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : WB Control Process
  // Description : Controls the access to the multiplier
  ///////////////////////////////////////////////////////////////////////////////
  always @(posedge i_clk) begin
    if (i_reset_sync == 1'b1) begin
      r_tgd <= 1'b0;
      r_stb <= 1'b0;
    end
    else begin
      r_tgd <= |i_slave_mul_processor_tga;
      r_stb <= i_slave_mul_processor_stb;
    end
  end
  // WB(pipeline) master Write access control
  assign o_master_mul_write_stb  = r_stb;
  assign o_master_mul_write_data = w_product_select;

  generate
    if (P_MUL_ANLOGIC_MUL == 0) begin
      /////////////////////////////////////////////////////////////////////////////
      // Process     : Multiplication Process
      // Description : Generic code that modern synthesizers infer as DSP blocks.
      /////////////////////////////////////////////////////////////////////////////
      always @(posedge i_clk) begin
        if (i_reset_sync == 1'b1) begin
          r_product <= 64'h0;
        end
        else if (i_slave_mul_processor_stb == 1'b1) begin
          // Multiply any time the inputs changes.
          r_product <= $signed(w_multiplicand) * $signed(w_multiplier);
        end
      end
    end
  endgenerate

  generate
    if (P_MUL_ANLOGIC_MUL == 1) begin
      ///////////////////////////////////////////////////////////////////////////////
      // Instance    : Integer_Multiplier
      // Description : Anlogic IP EG_LOGIC_MULT, TD version 4.6.18154
      ///////////////////////////////////////////////////////////////////////////////
	    EG_LOGIC_MULT #(
        .INPUT_WIDTH_A(P_MUL_FACTORS_MSB+1),
	      .INPUT_WIDTH_B(P_MUL_FACTORS_MSB+1),
	      .OUTPUT_WIDTH(L_MUL_FACTORS_EXTENDED_MSB+1),
	      .INPUTFORMAT("SIGNED"),
	      .INPUTREGA("DISABLE"),
	      .INPUTREGB("DISABLE"),
	      .OUTPUTREG("ENABLE"),
	      .IMPLEMENT("DSP"),
	      .SRMODE("ASYNC")
	    ) Integer_Multiplier (
	      .a(i_master_mul0_read_data),
	      .b(i_master_mul1_read_data),
	      .p(r_product),
	      .cea(1'b0),
	      .ceb(1'b0),
	      .cepd(1'b1),
	      .clk(i_clk),
	      .rstan(1'b0),
	      .rstbn(1'b0),
	      .rstpdn(~i_reset_sync)
	    );
    end
  endgenerate
endmodule // MUL_Processor
