/************************************************************\
 **  Copyright (c) 2011-2021 Anlogic, Inc.
 **  All Right Reserved.
\************************************************************/
/************************************************************\
 ** Log	:	This file is generated by Anlogic IP Generator.
 ** File	:	/home/jota/Documents/HW/HDL_projects/ORCs/ORC_R32IMAZicsr/source/anlogic_mul.v
 ** Date	:	2021 01 03
 ** TD version	:	4.6.18154
\************************************************************/

`timescale 1ns / 1ps

module Integer_Multiplier ( p, a, b, cepd, clk, rstpdn );

	output [127:0] p;

	input  [63:0] a;
	input  [63:0] b;
	input  cepd;
	input  clk;
	input  rstpdn;



	EG_LOGIC_MULT #( .INPUT_WIDTH_A(64),
				.INPUT_WIDTH_B(64),
				.OUTPUT_WIDTH(128),
				.INPUTFORMAT("SIGNED"),
				.INPUTREGA("DISABLE"),
				.INPUTREGB("DISABLE"),
				.OUTPUTREG("ENABLE"),
				.IMPLEMENT("DSP"),
				.SRMODE("ASYNC")

			)
			inst(
				.a(a),
				.b(b),
				.p(p),
				.cea(1'b0),
				.ceb(1'b0),
				.cepd(cepd),
				.clk(clk),
				.rstan(1'b0),
				.rstbn(1'b0),
				.rstpdn(rstpdn)
			);


endmodule