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
// File name     : HCC_Arithmetic_Processor.v
// Author        : Jose R Garcia
// Created       : 2020/12/06 15:51:57
// Last modified : 2021/01/04 09:34:56
// Project Name  : ORCs
// Module Name   : HCC_Arithmetic_Processor
// Description   : The High Computational Cost Arithmetic Processor encapsules 
//                 an integer multiplier and an integer division module.
//
// Additional Comments:
//   .
/////////////////////////////////////////////////////////////////////////////////
module HCC_Arithmetic_Processor #(
  parameter integer P_HCC_FACTORS_MSB  = 7,
  parameter integer P_HCC_MEM_ADDR_MSB = 0,
  parameter integer P_HCC_DIV_ACCURACY = 2
)(
  // WB Interface
  input                         i_slave_hcc_processor_clk,
  input                         i_slave_hcc_processor_reset_sync,
  input                         i_slave_hcc_processor_stb,
  output                        o_slave_hcc_processor_ack,
  input                         i_slave_hcc_processor_addr,
  input                         i_slave_hcc_processor_tga,
  input  [P_HCC_MEM_ADDR_MSB:0] i_slave_hcc_processor_data, // rd
  input                         i_slave_hcc_processor_tgd,  // 0=low, 1=high bits
  // HCC Processor mem0 WB(pipeline) master Read Interface
  input  [P_HCC_FACTORS_MSB:0]  i_master_hcc0_read_data, // WB data
  // HCC Processor mem0 WB(pipeline) master Write Interface
  output                        o_master_hcc0_write_stb,  // WB write enable
  output [P_HCC_MEM_ADDR_MSB:0] o_master_hcc0_write_addr, // WB address
  output [P_HCC_FACTORS_MSB:0]  o_master_hcc0_write_data, // WB data
  // HCC Processor mem1 WB(pipeline) master Read Interface
  input  [P_HCC_FACTORS_MSB:0]  i_master_hcc1_read_data, // WB data
  // HCC Processor mem1 WB(pipeline) master Write Interface
  output                        o_master_hcc1_write_stb,  // WB write enable
  output [P_HCC_MEM_ADDR_MSB:0] o_master_hcc1_write_addr, // WB address
  output [P_HCC_FACTORS_MSB:0]  o_master_hcc1_write_data  // WB data
);

  ///////////////////////////////////////////////////////////////////////////////
  // Internal Parameter Declarations
  ///////////////////////////////////////////////////////////////////////////////
  localparam L_HCC_FACTORS_NUM_BITS     = P_HCC_FACTORS_MSB+1;
  localparam L_HCC_FACTORS_EXTENDED_MSB = ((P_HCC_FACTORS_MSB+1)*2)-1;
  localparam L_HCC_PRODUCT_EXTENDED_MSB = ((L_HCC_FACTORS_EXTENDED_MSB+1)*2)-1;
  ///////////////////////////////////////////////////////////////////////////////
  // Internal Signals Declarations
  ///////////////////////////////////////////////////////////////////////////////
  // HCC Controls
  reg                        r_wait_ack;
  reg                        r_select;
  reg [P_HCC_MEM_ADDR_MSB:0] r_addr;
  reg                        r_tgd;
  // HCC Processor to Memory_Backplane connecting wires.
  wire                        w_div0_read_stb;   // WB read enable
  wire [P_HCC_MEM_ADDR_MSB:0] w_div0_read_addr;  // WB address
  wire                        w_div1_read_stb;   // WB read enable
  wire [P_HCC_MEM_ADDR_MSB:0] w_div1_read_addr;  // WB address
  wire                        w_div_write_stb;  // WB write enable
  wire [P_HCC_FACTORS_MSB:0]  w_div_write_data; // WB data
  // Divider
  wire                                w_div_stb = i_slave_hcc_processor_stb & i_slave_hcc_processor_addr;
  wire                                w_div_ack;
  wire [L_HCC_FACTORS_EXTENDED_MSB:0] w_div_multiplicand;
  wire [L_HCC_FACTORS_EXTENDED_MSB:0] w_div_multiplier;
  wire [L_HCC_PRODUCT_EXTENDED_MSB:0] w_product;
  wire [P_HCC_FACTORS_MSB:0]          w_product_bits_select = r_tgd==1'b1 ? w_product[L_HCC_FACTORS_EXTENDED_MSB:P_HCC_FACTORS_MSB+1] : w_product[P_HCC_FACTORS_MSB:0];
  wire [P_HCC_FACTORS_MSB:0]          w_write_data      = r_select==1'b0 ? w_product_bits_select : w_div_write_data;
  wire                                w_write_stb       = (r_select==1'b0 && r_wait_ack==1'b1) ? 1'b1 : w_div_write_stb;
  // Multiplier
  wire signed [L_HCC_FACTORS_EXTENDED_MSB:0] w_multiplicand = r_select==1'b1 ? $signed(w_div_multiplicand) :
                                                                {{L_HCC_FACTORS_NUM_BITS{i_master_hcc0_read_data[P_HCC_FACTORS_MSB]}}, i_master_hcc0_read_data[P_HCC_FACTORS_MSB:0]};
  wire signed [L_HCC_FACTORS_EXTENDED_MSB:0] w_multiplier   = r_select==1'b1 ? $signed(w_div_multiplier) :
                                                                {{L_HCC_FACTORS_NUM_BITS{i_master_hcc1_read_data[P_HCC_FACTORS_MSB]}}, i_master_hcc1_read_data[P_HCC_FACTORS_MSB:0]};

  ///////////////////////////////////////////////////////////////////////////////
  //            ********      Architecture Declaration      ********           //
  ///////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : Control Process
  // Description : Controls the access to the multiplier
  ///////////////////////////////////////////////////////////////////////////////
  always @(posedge i_slave_hcc_processor_clk) begin
    if (i_slave_hcc_processor_reset_sync == 1'b1) begin
      r_select   <= 1'b1;
      r_addr     <= 0;
      r_tgd      <= 0;
      r_wait_ack <= 1'b0;
    end
    else begin
      if (i_slave_hcc_processor_stb == 1'b1) begin
        // Received valid factors index.
        r_select   <= i_slave_hcc_processor_addr;
        r_addr     <= i_slave_hcc_processor_data; // rd
        r_tgd      <= i_slave_hcc_processor_tgd;
        r_wait_ack <= 1'b1;
      end
      if (r_select == 1'b0 && r_wait_ack == 1'b1) begin
        // Multiplication done after one clock.
        r_wait_ack <= 1'b0;
      end
      if (r_select == 1'b1 && r_wait_ack == 1'b1) begin
        // Wait for Division to finish.
        r_wait_ack <= !w_div_ack;
      end
    end
  end
  assign o_slave_hcc_processor_ack = (r_select==1'b0 && r_wait_ack==1'b1) ? 1'b1 :
                                     r_select==1'b1 ? w_div_ack : 1'b0;
  // HCC Processor mem0 WB(pipeline) master Write access control
  assign o_master_hcc0_write_stb  = w_write_stb;  // WB write enable
  assign o_master_hcc0_write_addr = r_addr;       // WB address
  assign o_master_hcc0_write_data = w_write_data; // WB data
  // HCC Processor mem1 WB(pipeline) master Write access control
  assign o_master_hcc1_write_stb  = w_write_stb;  // WB write enable
  assign o_master_hcc1_write_addr = r_addr;       // WB address
  assign o_master_hcc1_write_data = w_write_data; // WB data

  ///////////////////////////////////////////////////////////////////////////////
  // Instance    : Integer Multiplier
  // Description : A High Computational Cost Arithmetic Processor that handles
  //               multiplication and division operations.
  ///////////////////////////////////////////////////////////////////////////////
  Integer_Multiplier mul (
    .p(w_product),              //
    .a(w_multiplicand),   //
    .b(w_multiplier),       //
    .cepd(1'b1),
    .clk(i_slave_hcc_processor_clk), //
    .rstpdn(i_slave_hcc_processor_reset_sync) //
  );

  ///////////////////////////////////////////////////////////////////////////////
  // Instance    : Integer Divider
  // Description : Instance of a Goldschmidt Division implementation.
  ///////////////////////////////////////////////////////////////////////////////
  Goldschmidt_Convergence_Division #(
    P_HCC_FACTORS_MSB,  // 
    P_HCC_DIV_ACCURACY, //
    P_HCC_MEM_ADDR_MSB  //
  ) div (
    // Clock and Reset
    .i_clk(i_slave_hcc_processor_clk),
    .i_reset_sync(i_slave_hcc_processor_reset_sync),
    // WB Interface
    .i_slave_stb(w_div_stb),                 // valid
    .i_slave_tga(i_slave_hcc_processor_tga), // quotient=0, remainder=1
    .o_slave_ack(w_div_ack),                 // ready
    // mem0 WB(pipeline) master Read Interface
    .i_master_div0_read_data(i_master_hcc0_read_data), // WB data
    // mem1 WB(pipeline) master Read Interface
    .i_master_div1_read_data(i_master_hcc1_read_data), // WB data
    // mem WB(pipeline) master Write Interface
    .o_master_div_write_stb(w_div_write_stb),   // WB write enable
    .o_master_div_write_data(w_div_write_data), // WB data
    // Connection to multiplier
    .o_multiplicand(w_div_multiplicand),
    .o_multiplier(w_div_multiplier),
    .i_product(w_product)
  );

endmodule // HCC_Arithmetic_Processor
