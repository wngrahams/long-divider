`timescale 1ns/100ps
`define QSIM_OUT_FM "./qsim.out"
`define CLOCK_PERIOD 1000

module testbench();

	reg clk, rst, s, LA, EB;
	reg [7:0] A;
	reg [7:0] B;

	wire Done;
	wire [7:0] Q;
	wire [7:0] R;
	
	reg [7:0] data_in_num [0:9];
	reg [7:0] data_in_den [0:9];
	reg [7:0] data_out_quo [0:9];
	reg [7:0] data_out_rem [0:9];

	longdivider longdiv_0(.Clock(clk),
			      .Resetn(rst),
			      .s(s),
			      .LA(LA),
			      .EB(EB),
			      .DataA(A),
			      .DataB(B),
			      .R(R),
			      .Q(Q),
			      .Done(Done));

	// generate test patterns
	initial
	begin
		data_in_num[0]=8'b00001111;  // 15
		data_in_den[0]=8'b00000010;  // 2
		data_out_quo[0]=8'b00000111;  // 7
		data_out_rem[0]=8'b00000001;  // 1
	end

	// initialize inputs
	initial
	begin
		clk = 0;
		rst = 0;
		s = 0;
		LA = 0;
		EB = 0;
		A = 0;
		B = 0;
	end

	// Update clock
	always
	begin
		#(`CLOCK_PERIOD/2);
		clk = ~clk;
	end

	// startup
	initial
	begin
		#`CLOCK_PERIOD;
		rst = 1;
		A = data_in_num[0];
		B = data_in_den[0];
		LA = 1;
		EB = 1;
		#`CLOCK_PERIOD;
		LA = 0;
		EB = 0;
		s = 1;
		#`CLOCK_PERIOD;
		s = 0;
	end

	// check tests
	initial
	begin
		$display("\nBeginning Simulation...");
		
		@(posedge Done);
		$display("Time%d: Numerator=%h; Denominator=%h; Expected Quotient=%h; Actual Quotient=%h; Expected Remainder=%h; Actual Remainder=%h", $stime, A, B, data_out_quo[0], Q, data_out_rem[0], R);

		$display("End of simulation.");
		#(`CLOCK_PERIOD*3);
		$finish;
	end
endmodule
	
