`timescale 1ns/1ps
`define SD #0.010
`define HALF_CLOCK_PERIOD #0.90
`define QSIM_OUT_FN "./qsim.out"
`define MATLAB_OUT_FN "../../matlab/lfsr1/lfsr1.results"

module testbench();

	reg clk;
	reg resetn;
	reg [15:0] seed;

	integer lfsr_out_matlab;
	integer lfsr_out_qsim;

	wire [15:0] lfsr_out;

	integer i;
	integer ret_write;
	integer ret_read;
	integer qsim_out_file;
	integer matlab_out_file;

	integer error_count = 0;

	lfsr1 lfsr_0 ( .clk(clk), .resetn(resetn), .seed(seed), .lfsr_out(lfsr_out) );

	always begin
		`HALF_CLOCK_PERIOD;
		clk = ~clk;
	end

	initial begin
		// File IO
		qsim_out_file = $fopen(`QSIM_OUT_FN,"w");
		if (!qsim_out_file) begin
			$display("Couldn't create the output file.");
			$finish;
		end

		matlab_out_file = $fopen(`MATLAB_OUT_FN,"r");
		if (!matlab_out_file) begin
			$display("Couldn't open the Matlab file.");
			$finish;
		end

		// register setup
		clk = 0;
		resetn = 0;
		seed = 16'd2;
		@(posedge clk);

		@(negedge clk);   // release resetn
		resetn = 1;      

		@(posedge clk);   // start the first cycle
		for (i=0 ; i<256; i=i+1) begin 
			// compare w/ the results from Matlab sim
			ret_read = $fscanf(matlab_out_file, "%d", lfsr_out_matlab);
			lfsr_out_qsim = lfsr_out;

			$fwrite(qsim_out_file, "%0d\n", lfsr_out_qsim);
			if (lfsr_out_qsim != lfsr_out_matlab) begin
				error_count = error_count + 1;
			end

			@(posedge clk);  // next cycle
		end

		// Any mismatch b/w rtl and matlab sims?
		if (error_count > 0) begin
			$display("The results DO NOT match with those from Matlab :( ");
		end
		else begin
			$display("The results DO match with those from Matlab :) ");
		end
 
		// finishing this testbench
		$fclose(qsim_out_file);
		$fclose(matlab_out_file);
		$finish;
	end 

endmodule // testbench

