// A version of the dhrystone test bench that isn't using the look-ahead interface

`timescale 1 ns / 1 ps

module testbench_nola # (
  // Test bench compile time parameters
  parameter integer P_NUM_SIM_CLKS = 380000
  // Compile time UUT configurable parameters
);

  ///////////////////////////////////////////////////////////////////////////////
  // Internal Parameter Declarations
  ///////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////
  // Internal Signals Declarations
  ///////////////////////////////////////////////////////////////////////////////
	reg clk = 1;
	reg resetn = 0;
  // Instructions WB Interface Signals
  wire        w_inst_read_stb;
  reg         w_inst_read_ack;
  wire [31:0] w_inst_read_addr;
  reg  [31:0] w_inst_read_data;
  // WB Read 
  wire        w_master_read_stb;
  reg         w_master_read_ack;
  wire [31:0] w_master_read_addr;
  reg  [31:0] w_master_read_data;
  // WB Write
  wire        w_master_write_stb;
  reg         w_master_write_ack;
  wire [31:0] w_master_write_addr;
  wire [31:0] w_master_write_data;
  wire [3:0]  w_master_write_sel;
  // Firmware
	reg [7:0] memory [0:256*1024-1];
	initial $readmemh("dhry.hex", memory);


  ///////////////////////////////////////////////////////////////////////////////
  //           ********      Test Bench Declaration      ********            //
  ///////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////
  // Instance    : ORC_R32IMAZicsr
  // Description : RISC-V "I" "M" Implementation
  ///////////////////////////////////////////////////////////////////////////////
	ORC_R32I #(
    // Compile time configurable generic parameters
    65536, // First instruction address
    65536, // Reg x2 reset value
    4,     //
    32,    //
    0,     // 0=No init file, 1=loads memory init file
    0,     // File name and directory "./example.txt"
    0      //
	) uut (
		.i_clk(clk),
		.i_reset_sync(!resetn),
    // Instruction Wishbone(pipeline) Master Read Interface
    .o_inst_read_stb(w_inst_read_stb),
    .i_inst_read_ack(w_inst_read_ack),
    .o_inst_read_addr(w_inst_read_addr),
    .i_inst_read_data(w_inst_read_data),
    // Wishbone(pipeline) Master Read Interface
    .o_master_read_stb(w_master_read_stb),
    .i_master_read_ack(w_master_read_ack),
    .o_master_read_addr(w_master_read_addr),
    .i_master_read_data(w_master_read_data),
    // Wishbone(pipeline) Master Write Interface
    .o_master_write_stb(w_master_write_stb),  
    .i_master_write_ack(w_master_write_ack),
    .o_master_write_addr(w_master_write_addr),
    .o_master_write_data(w_master_write_data),
    .o_master_write_sel(w_master_write_sel)
	);

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : Clock Generator Process
  // Description : .
  ///////////////////////////////////////////////////////////////////////////////
	always #5 clk = ~clk;

  ///////////////////////////////////////////////////////////////////////////////
  // Initial     : Reset Generator
  // Description : Creates a reset. Hold reset for 100 clocks
  ///////////////////////////////////////////////////////////////////////////////
	initial begin
		repeat (5) @(posedge clk);
		resetn <= 1;
		repeat (5) @(posedge clk);
		resetn <= 0;
		repeat (100) @(posedge clk);
		resetn <= 1;
	end

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : Instruction WB Handshake Process
  // Description : 
  ///////////////////////////////////////////////////////////////////////////////
	always @(posedge clk) begin
		w_inst_read_ack <= 1'b0;
		w_inst_read_data[ 7: 0] <= 'bx;
		w_inst_read_data[15: 8] <= 'bx;
		w_inst_read_data[23:16] <= 'bx;
		w_inst_read_data[31:24] <= 'bx;

		if (w_inst_read_stb & !w_inst_read_ack) begin
		  w_inst_read_ack         <= 1'b1;
		  w_inst_read_data[ 7: 0] <= memory[w_inst_read_addr + 0];
		  w_inst_read_data[15: 8] <= memory[w_inst_read_addr + 1];
		  w_inst_read_data[23:16] <= memory[w_inst_read_addr + 2];
		  w_inst_read_data[31:24] <= memory[w_inst_read_addr + 3];
		end
	end

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : External WB Read Handshake Process
  // Description : .
  ///////////////////////////////////////////////////////////////////////////////
  // External Interface
	always @(posedge clk) begin
		if (w_master_read_stb & !w_master_read_ack) begin
		  w_master_read_ack <= 1'b1;
		  w_master_read_data[ 7: 0] <= memory[w_master_read_addr + 0];
		  w_master_read_data[15: 8] <= memory[w_master_read_addr + 1];
		  w_master_read_data[23:16] <= memory[w_master_read_addr + 2];
		  w_master_read_data[31:24] <= memory[w_master_read_addr + 3];
		end
    else begin
		w_master_read_ack <= 1'b0;
		w_master_read_data <= 'bx;
    end
	end

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : External WB Write Handshake Process
  // Description : .
  ///////////////////////////////////////////////////////////////////////////////
  // External Interface
	always @(posedge clk) begin
		w_master_write_ack <= 1'b0;

		if (w_master_write_stb & !w_master_write_ack) begin
		  w_master_write_ack <= 1'b1;
		  case (w_master_write_addr)
		  	32'h1000_0000: begin
		  		$write("%c", w_master_write_data);
		  		$fflush();
		  	end
		  	default: begin
		  		if (w_master_write_sel[0]) memory[w_master_write_addr + 0] <= w_master_write_data[ 7: 0];
		  		if (w_master_write_sel[1]) memory[w_master_write_addr + 1] <= w_master_write_data[15: 8];
		  		if (w_master_write_sel[2]) memory[w_master_write_addr + 2] <= w_master_write_data[23:16];
		  		if (w_master_write_sel[3]) memory[w_master_write_addr + 3] <= w_master_write_data[31:24];
		  	end
		  endcase
		end
	end

  ///////////////////////////////////////////////////////////////////////////////
  // Initial     : Create a dump file
  // Description : .
  ///////////////////////////////////////////////////////////////////////////////
	initial begin
		$dumpfile("testbench_nola.vcd");
		$dumpvars(0, testbench_nola);
	end

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : End detector Process
  // Description : .
  ///////////////////////////////////////////////////////////////////////////////
	always @(posedge clk) begin
		if (resetn) begin
			repeat (P_NUM_SIM_CLKS) @(posedge clk);
			$display("TRAP");
			$finish;
		end
	end
endmodule
