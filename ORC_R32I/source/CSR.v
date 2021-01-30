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
// File name     : CSR.v
// Author        : Jose R Garcia
// Created       : 2020/12/06 00:33:28
// Last modified : 2021/01/24 21:23:59
// Project Name  : ORCs
// Module Name   : CSR
// Description   : CSR and Counters.
//
// Additional Comments:
//   .
/////////////////////////////////////////////////////////////////////////////////
module CSR (
  // Component's clocks and resets
  input i_clk,        // clock
  input i_reset_sync, // reset
  // CSR Interface
  input         i_csr_instr_decoded_stb, // Indicates an instruction was decode.
  input  [3:0]  i_csr_read_addr,         //
  output [31:0] o_csr_read_data          // 
);
  ///////////////////////////////////////////////////////////////////////////////
  // Internal Parameter Declarations
  ///////////////////////////////////////////////////////////////////////////////
  // Misc Definitions
  ///////////////////////////////////////////////////////////////////////////////
  // Internal Signals Declarations
  ///////////////////////////////////////////////////////////////////////////////
  // Counters
	reg [63:0] r_cycle_count;
	reg [63:0] r_instr_count;
  // Interface Signals
  reg [31:0] r_csr_read_data;

  ///////////////////////////////////////////////////////////////////////////////
  //            ********      Architecture Declaration      ********           //
  ///////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : Cycle Counter Process
  // Description : .
  ///////////////////////////////////////////////////////////////////////////////
  always @(posedge i_clk) begin
    if (i_reset_sync == 1'b1) begin
      r_cycle_count <= 64'h0;
    end
    else begin
      r_cycle_count <= r_cycle_count + 1;
    end
  end

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : Instruction Counter Process
  // Description : .
  ///////////////////////////////////////////////////////////////////////////////
  always @(posedge i_clk) begin
    if (i_reset_sync == 1'b1) begin
      r_instr_count <= 64'h0;
    end
    else if(i_csr_instr_decoded_stb == 1'b1) begin
      r_instr_count <= r_instr_count + 1;
    end
  end


  ///////////////////////////////////////////////////////////////////////////////
  // Process     : CSR Address Decoder
  // Description : .
  ///////////////////////////////////////////////////////////////////////////////
  always @(posedge i_clk) begin
    if (i_reset_sync == 1'b1) begin
      r_csr_read_data <= 32'h0;
    end
    else begin
		  (* parallel_case, full_case *)
		  case (1'b1)
		  	i_csr_read_addr[0] : begin
		  		r_csr_read_data <= r_cycle_count[31:0];
        end
		  	i_csr_read_addr[1] : begin
		  		r_csr_read_data <= r_cycle_count[63:32];
        end
		  	i_csr_read_addr[2] : begin
		  		r_csr_read_data <= r_instr_count[31:0];
        end
        i_csr_read_addr[3] : begin
		  		r_csr_read_data <= r_instr_count[63:32];
        end
		  endcase
    end
  end
  //
  assign o_csr_read_data = r_csr_read_data;

endmodule // CSR