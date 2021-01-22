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
// File name     : Goldschmidt_Convergence_Division.v
// Author        : Jose R Garcia
// Created       : 2020/12/06 15:51:57
// Last modified : 2021/01/22 12:12:18
// Project Name  : ORCs
// Module Name   : Goldschmidt_Convergence_Division
// Description   : The Goldschmidt Convergence Division is an iterative method
//                 to approximate the division result. This implementation
//                 targets integer numbers. It is specifically designed to work
//                 with the ORC_R32IM* processors.
//
// Additional Comments:
//   This code implementation is based on the description of the Goldschmidt
//   Convergence Dividers found on a publication of 2006; Synthesis of Arithmetic
//   Circuits, FPGA, ASIC and Embedded Systems by Jean-Pierre Deschamp,
//   Gery Jean Antoine Bioul and Gustavo D. Sutter. This divider computes:
//                 d(i) = d[i-1].(2-d[i-1])
//                          and
//                 D(i) = D[i-1].(2-d[i-1])
//   were 'd' is the divisor; 'D' is the dividend; 'i' is the step.
//
//  The remainder calculation requires an extra which is why the address tag is
//  used to make the decision on whether to do the calculation or skip it.
/////////////////////////////////////////////////////////////////////////////////
module Goldschmidt_Convergence_Division #(
  parameter integer P_GCD_FACTORS_MSB  = 7,
  parameter integer P_GCD_ACCURACY     = 0,
  parameter integer P_GCD_MEM_ADDR_MSB = 0
)(
  input i_clk,
  input i_reset_sync,
  // WB Interface
  input        i_slave_stb, // valid
  input  [1:0] i_slave_tga, // 0=div, 1=rem
  output       o_slave_ack, // ready
  // GDC mem0 WB(pipeline) master Read Interface
  input  [P_GCD_FACTORS_MSB:0] i_master_div0_read_data, // WB data
  // GDC mem1 WB(pipeline) master Read Interface
  input  [P_GCD_FACTORS_MSB:0] i_master_div1_read_data, // WB data
  // GDC mem WB(pipeline) master Write Interface
  output                       o_master_div_write_stb,  // WB write enable
  output [P_GCD_FACTORS_MSB:0] o_master_div_write_data, // WB data
  // Multiplier interface
  output [((P_GCD_FACTORS_MSB+1)*2)-1:0] o_multiplicand,
  output [((P_GCD_FACTORS_MSB+1)*2)-1:0] o_multiplier,
  input  [((P_GCD_FACTORS_MSB+1)*4)-1:0] i_product
);

  ///////////////////////////////////////////////////////////////////////////////
  // Internal Parameter Declarations
  ///////////////////////////////////////////////////////////////////////////////
  // Misc.
  localparam [P_GCD_FACTORS_MSB:0] L_GCD_NUMBER_TWO       = 2;
  localparam [P_GCD_FACTORS_MSB:0] L_GCD_ZERO_FILLER      = 0;
  localparam integer               L_GCD_MUL_FACTORS_MSB  = ((P_GCD_FACTORS_MSB+1)*2)-1;
  localparam integer               L_GCD_STEP_PRODUCT_MSB = ((L_GCD_MUL_FACTORS_MSB+1)+P_GCD_FACTORS_MSB);
  localparam integer               L_GCD_RESULT_MSB       = ((P_GCD_FACTORS_MSB+1)*3)-1;
  localparam integer               L_GCD_RESULT_LSB       = (P_GCD_FACTORS_MSB+1)*2;
  // Program Counter FSM States
  localparam [2:0] S_IDLE                 = 3'h0; // Waits for valid factors.
  localparam [2:0] S_SHIFT_DIVISOR_POINT  = 3'h1; // multiply the divisor by minus powers of ten to shift the decimal point.
  localparam [2:0] S_SHIFT_DIVIDEND_POINT = 3'h2; // multiply the dividend by minus powers of ten to shift the decimal point.
  localparam [2:0] S_HALF_STEP_ONE        = 3'h3; // D[i] * (2-d[i]); were i is the iteration.
  localparam [2:0] S_HALF_STEP_TWO        = 3'h4; // d[i] * (2-d[i]); were i is the iteration.
  localparam [2:0] S_REMAINDER_TO_NATURAL = 3'h5; // Convert remainder from decimal fraction to a natural number.
  // Divider LUT values
  localparam [P_GCD_FACTORS_MSB:0] L_REG_E10 = 429496730; // X.1
  localparam [P_GCD_FACTORS_MSB:0] L_REG_E100 = 42949673; // X.01
  localparam [P_GCD_FACTORS_MSB:0] L_REG_E1000 = 4294967; // X.001
  localparam [P_GCD_FACTORS_MSB:0] L_REG_E10000 = 429497; // X.0001
  localparam [P_GCD_FACTORS_MSB:0] L_REG_E100000 = 42950; // X.00001
  localparam [P_GCD_FACTORS_MSB:0] L_REG_E1000000 = 4295; // X.000001
  localparam [P_GCD_FACTORS_MSB:0] L_REG_E10000000 = 429; // X.0000001
  localparam [P_GCD_FACTORS_MSB:0] L_REG_E100000000 = 43; // X.00000001
  localparam [P_GCD_FACTORS_MSB:0] L_REG_E1000000000 = 4; // X.000000001
  // Divisor convergence threshold
  localparam [P_GCD_ACCURACY-1:0] L_CONVERGENCE_THRESHOLD = -1;

  ///////////////////////////////////////////////////////////////////////////////
  // Internal Signals Declarations
  ///////////////////////////////////////////////////////////////////////////////
  // Offset Counter
  reg [P_GCD_FACTORS_MSB:0] r_lut_value;
  // Divider Accumulator signals
  reg  [2:0]                     r_divider_state;
  reg                            r_calculate_remainder;
  wire [L_GCD_MUL_FACTORS_MSB:0] w_number_two_extended = {L_GCD_NUMBER_TWO,L_GCD_ZERO_FILLER};
  wire                           w_dividend_not_zero   = i_master_div0_read_data==0 ? 1'b0 : 1'b1;
  wire                           w_divisor_not_zero    = i_master_div1_read_data==0 ? 1'b0 : 1'b1;
  wire [P_GCD_FACTORS_MSB:0]     w_dividend = (i_slave_tga[0]==1'b0 && i_master_div0_read_data[P_GCD_FACTORS_MSB]==1'b1) ? ~i_master_div0_read_data : i_master_div0_read_data;
  wire [P_GCD_FACTORS_MSB:0]     w_divisor  = (i_slave_tga[0]==1'b0 && i_master_div1_read_data[P_GCD_FACTORS_MSB]==1'b1) ? ~i_master_div1_read_data : i_master_div1_read_data;
  reg  [P_GCD_FACTORS_MSB:0]     r_dividend;
  reg  [P_GCD_FACTORS_MSB:0]     r_divisor;
  reg  [L_GCD_MUL_FACTORS_MSB:0] r_multiplicand;
  reg  [L_GCD_MUL_FACTORS_MSB:0] r_multiplier;
  reg                            r_signed_extend;
  // Iterative operation signals
  wire [L_GCD_MUL_FACTORS_MSB:0] w_current_divisor   = r_divider_state==S_HALF_STEP_TWO ? r_multiplicand : i_product[L_GCD_STEP_PRODUCT_MSB:P_GCD_FACTORS_MSB+1];
  wire [L_GCD_MUL_FACTORS_MSB:0] w_two_minus_divisor = (w_number_two_extended + ~w_current_divisor);
  wire                           w_converged         = &r_multiplicand[P_GCD_FACTORS_MSB:P_GCD_FACTORS_MSB-P_GCD_ACCURACY-1]; // is it 0.9xxx...
  reg                            r_converged;
  // MEMx Result Registers Write Signals
  reg                        r_div_write_stb;
  wire [P_GCD_FACTORS_MSB:0] w_quotient  = r_converged==1'b0 ? r_dividend : 
                                             i_product[L_GCD_RESULT_LSB-1:L_GCD_RESULT_LSB-3]==3'b100 |
                                             i_product[L_GCD_RESULT_LSB-1:L_GCD_RESULT_LSB-3]==3'b101 | 
                                             i_product[L_GCD_RESULT_LSB-1:L_GCD_RESULT_LSB-3]==3'b111 ? (i_product[L_GCD_RESULT_MSB:L_GCD_RESULT_LSB]+1) :
                                             i_product[L_GCD_RESULT_MSB:L_GCD_RESULT_LSB];

  wire [P_GCD_FACTORS_MSB:0] w_remainder = r_converged==1'b0 ? r_divisor :
                                             i_product[L_GCD_RESULT_LSB-1:L_GCD_RESULT_LSB-3]==3'b100 |
                                             i_product[L_GCD_RESULT_LSB-1:L_GCD_RESULT_LSB-3]==3'b101 | 
                                             i_product[L_GCD_RESULT_LSB-1:L_GCD_RESULT_LSB-3]==3'b111 ? (i_product[L_GCD_RESULT_MSB:L_GCD_RESULT_LSB]+1) :
                                             i_product[L_GCD_RESULT_MSB:L_GCD_RESULT_LSB];
  wire [P_GCD_FACTORS_MSB:0] w_result    = r_calculate_remainder==1'b1 ? ((r_converged==1'b1 && r_signed_extend==1'b1) ? ~w_remainder : w_remainder) :
                                                                         ((r_converged==1'b1 && r_signed_extend==1'b1) ? ~w_quotient : w_quotient);

  ///////////////////////////////////////////////////////////////////////////////
  //            ********      Architecture Declaration      ********           //
  ///////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : Offset Counter
  // Description : Count until the hot bit is detected to determine which value
  //               from the lookup table to get.
  ///////////////////////////////////////////////////////////////////////////////
  always @(posedge i_clk) begin
    if (i_reset_sync == 1'b1) begin
      r_lut_value <= L_REG_E1000000000;
    end
    else if (i_slave_stb == 1'b1) begin
      // Detect how many position to shift the decimal point for divisor to be 
      // less than 2.
      if (w_divisor < 20) begin
        // from 2 to 19, use 0.1
        r_lut_value <= L_REG_E10;
      end
      else if (w_divisor < 200) begin
        // from 20 to 199, use 0.01
        r_lut_value <= L_REG_E100;
      end
      else if (w_divisor < 2000) begin
        // from 200 to 1999, use 0.001
        r_lut_value <= L_REG_E1000;
      end
      else if (w_divisor < 20000) begin
        // from 2000 to 19999, use 0.0001
        r_lut_value <= L_REG_E10000;
      end
      else if (w_divisor < 200000) begin
        // from 20000 to 199999, use 0.00001
        r_lut_value <= L_REG_E100000;
      end
      else if (w_divisor < 2000000) begin
        // from 200000 to 1999999, use 0.000001
        r_lut_value <= L_REG_E1000000;
      end
      else if (w_divisor < 20000000) begin
        // from 2000000 to 19999999, use 0.0000001
        r_lut_value <= L_REG_E10000000;
      end
      else if (w_divisor < 200000000) begin
        // from 20000000 to 199999999, use 0.00000001
        r_lut_value <= L_REG_E100000000;
      end
      else begin
        // from 200000000 or higher, use 0.000000001
        r_lut_value <= L_REG_E1000000000;
      end
    end
  end

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : Divider Accumulator
  // Description : 
  ///////////////////////////////////////////////////////////////////////////////
  always @(posedge i_clk) begin
    if (i_reset_sync == 1'b1) begin
      r_divider_state       <= S_IDLE;
      r_div_write_stb       <= 1'b0;
      r_divisor             <= 0;
      r_dividend            <= 0;
      r_multiplicand        <= 0;
      r_multiplier          <= 0;
      r_calculate_remainder <= 1'b0;
      r_converged           <= 1'b0;
      r_signed_extend       <= 1'b0;
    end
    else begin
      casez (r_divider_state)
        S_IDLE : begin
          if (i_slave_stb == 1'b1) begin
            if (w_divisor_not_zero == 1'b0) begin
              // If either is zero return zero
              r_div_write_stb <= 1'b1;
              r_divisor       <= i_master_div0_read_data;
              r_dividend      <= -1;
              r_divider_state <= S_IDLE;
            end
            else if (w_dividend_not_zero == 1'b0) begin
              // If either is zero return zero
              r_div_write_stb <= 1'b1;
              r_divisor       <= L_GCD_ZERO_FILLER;
              r_dividend      <= L_GCD_ZERO_FILLER;
              r_divider_state <= S_IDLE;
            end
            else if ($signed(i_master_div1_read_data) == 1) begin
              // if denominator is 1 return numerator
              r_div_write_stb <= 1'b1;
              r_divisor       <= L_GCD_ZERO_FILLER;
              r_dividend      <= i_master_div0_read_data;
              r_divider_state <= S_IDLE;
            end
            else if ($signed(i_master_div1_read_data) == -1 && i_slave_tga[0] == 1'b0) begin
              // if denominator is -1 return -1*numerator
              r_div_write_stb <= 1'b1;
              r_divisor       <= L_GCD_ZERO_FILLER;
              r_dividend      <= ~i_master_div0_read_data;
              r_divider_state <= S_IDLE;
            end
            else begin
              // Shift the decimal point in the divisor.
              if (i_slave_tga[0] == 1'b0 && (
                i_master_div0_read_data[P_GCD_FACTORS_MSB]==1'b1 ^ i_master_div1_read_data[P_GCD_FACTORS_MSB]==1'b1)) begin
                // 
                r_signed_extend <= 1'b1;
              end
              else begin
                //
                r_signed_extend <= 1'b0;
              end
              r_div_write_stb <= 1'b0;
              r_dividend      <= w_dividend;
              r_divisor       <= w_divisor;
              r_divider_state <= S_SHIFT_DIVISOR_POINT;
            end
            r_calculate_remainder <= i_slave_tga[1];
          end
          else begin
            //
            r_div_write_stb       <= 1'b0;
            r_divisor             <= 0;
            r_dividend            <= 0;
            r_calculate_remainder <= 1'b0;
            r_divider_state       <= S_IDLE;
          end
          r_converged <= 1'b0;
        end
        S_SHIFT_DIVISOR_POINT : begin
          // 
          r_multiplicand  <= {r_divisor, L_GCD_ZERO_FILLER};
          r_multiplier    <= {L_GCD_ZERO_FILLER, r_lut_value};
          r_divider_state <= S_SHIFT_DIVIDEND_POINT;
        end
        S_SHIFT_DIVIDEND_POINT : begin
          // 
          r_multiplicand  <= {r_dividend, L_GCD_ZERO_FILLER};
          r_multiplier    <= r_multiplier;
          r_divider_state <= S_HALF_STEP_ONE;
        end
        S_HALF_STEP_ONE : begin
          //
          if (r_converged == 1'b1) begin
            // When the divisor converges to 1.0 (actually 0.99...).
            // Return the quotient
            r_div_write_stb <= 1'b1;
            r_divider_state <= S_IDLE;
          end
          else begin
            // Increase count and start another division whole step.
            r_multiplicand  <= i_product[L_GCD_STEP_PRODUCT_MSB:P_GCD_FACTORS_MSB+1];
            r_multiplier    <= w_two_minus_divisor;
            r_divider_state <= S_HALF_STEP_TWO;
          end
        end
        S_HALF_STEP_TWO : begin
          if (w_converged == 1'b1 && r_calculate_remainder == 1'b1) begin
            // Convert the remainder from decimal fraction to a natural number
            r_multiplicand  <= (i_product[L_GCD_RESULT_LSB-1:L_GCD_RESULT_LSB-3]==3'b100 |
                               i_product[L_GCD_RESULT_LSB-1:L_GCD_RESULT_LSB-3]==3'b101 | 
                               i_product[L_GCD_RESULT_LSB-1:L_GCD_RESULT_LSB-3]==3'b111) ? {L_GCD_ZERO_FILLER, L_GCD_ZERO_FILLER} :
                               {L_GCD_ZERO_FILLER, i_product[L_GCD_MUL_FACTORS_MSB:P_GCD_FACTORS_MSB+1]};
            r_multiplier    <= {r_divisor, L_GCD_ZERO_FILLER};
            r_converged     <= 1'b1;
            r_divider_state <= S_REMAINDER_TO_NATURAL;
          end
          else begin
            // Second half of the division step
            r_multiplicand  <= i_product[L_GCD_STEP_PRODUCT_MSB:P_GCD_FACTORS_MSB+1];
            r_multiplier    <= w_two_minus_divisor;
            r_converged     <= w_converged;
            r_divider_state <= S_HALF_STEP_ONE;
          end
        end
        S_REMAINDER_TO_NATURAL : begin
          // Return the remainder
          r_div_write_stb <= 1'b1;
          r_divider_state <= S_IDLE;
        end
        default : begin
          r_div_write_stb <= 1'b0;
          r_converged     <= 1'b0;
          r_divider_state <= S_IDLE;
        end
      endcase
    end
  end
  // MEMx Result Registers Write Access
  assign o_master_div_write_stb  = r_div_write_stb;
  assign o_master_div_write_data = w_result;
  // Multiplication Processor Access
  assign o_multiplicand = r_multiplicand;
  assign o_multiplier   = r_multiplier;
  // WB Valid/Ready 
  assign o_slave_ack = r_div_write_stb;

endmodule // Goldschmidt_Convergence_Division
