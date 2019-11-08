/*
 * longdiv.v
 *
 * verilog module for "long-hand" division (no optimizations or enhancements,
 * 	requires 2n clock cycles to divide 2 n-bit unsigned integers).
 */

module longdivider(Clock, Resetn, s, LA, EB, DataA, DataB, R, Q, Done);
	
	parameter n = 8, logn = 3;
	
	// input and output 
	input Clock, Resetn, s, LA, EB;
	input [n-1:0] DataA, DataB;  // two n-bit inputs A and B
	output [n-1:0] Q, R;         // two n-bit outputs: Q=A/B, R=remainder
	output reg Done;             // signals when division is complete

	// internal vars
	wire Cout, z, R0;
	wire [n-1:0] DataR;
	wire [n:0] Sum;
	reg [1:0] y, Y;
	wire [n-1:0] A, B;
	wire [logn-1:0] Count;
	reg EA, Rsel, LR, ER, LC, EC, EQ;
	integer k;

	// control circuit (from ASM chart)
	parameter S1 = 2'b00, S2 = 2'b01, S3 = 2'b10, S4 = 2'b11;

	always @(s, y, z)
	begin: State_table
		case (y)
			S1: if (s==0) Y = S1;
			    else Y = S2;
			S2: Y = S3;  // always go to S3 when we're in S2
			S3: if (z==0) Y = S2;
			    else Y = S4;
			S4: if (s==0) Y = S1;
			    else Y = S4;
			default: Y = 2'bxx;
		endcase
	end

	// state flipflops (advance state according to control circuit on
	// each clock cycle)
	always @(posedge Clock, negedge Resetn)
	begin: State_flipflops
		if (Resetn == 0)
			y <= S1;
		else
			y <= Y;
	end

	// ouputs of each state 
	always @(y, s, Cout, z)
	begin: FSM_outputs
		// defaults
		Rsel = 0; LR = 0; LC = 0;
		ER = 0; EA = 0;
		EQ = 0; EC = 0;
		Done = 0;
		
		case (y)
			S1: begin
				Rsel = 0;
				LR = 1;
				LC = 1;
			    end
			S2: begin
				ER = 1;
				EA = 1;
			    end
			S3: begin
				EQ = 1;
				Rsel = 1;
				EC = 1;
				if (Cout == 1) LR = 1;
			    end
			S4: begin
				Done = 1;
			    end
		endcase
	end

	// datapath circuit
	regne RegB (DataB, Clock, Resetn, EB, B);
		defparam RegB.n = n;
	shiftlne ShiftA(DataA, LA, EA, 1'b0, Clock, A);
		defparam ShiftA.n = n;
	shiftlne ShiftR (DataR, LR, ER, A[n-1], Clock, R);
		defparam ShiftR.n = n;

	assign Sum = {1'b0, R} + {1'b0, ~B} + 1;
	assign Cout = Sum[n];
	
	shiftlne ShiftQ(n'b0, 1'b0, EQ, Cout, Clock, Q);
		defparam ShiftQ.n = n;

	downcount Counter(logn'b111, Clock, EC, LC, Count);
		defparam Counter.n = logn;

	assign z = (Count == 0);
	
	// 2 to 1 mux:
	assign DataR = Rsel ? Sum[n-1:0] : 0;

endmodule

// other modules taken from textbook
module regne(R, Clock, Resetn, E, Q);
	parameter n = 8;
	input [n-1:0] R;
	input Clock, Resetn, E;
	output reg [n-1:0] Q;

	always @(posedge Clock, negedge Resetn)
		if (Resetn == 0)
			Q <= 0;
		else if (E)
			Q <= R;
endmodule

module shiftlne(R, L, E, w, Clock, Q);
	parameter n = 8;
	input [n-1:0] R;
	input L, E, w, Clock;
	output reg [n-1:0] Q;
	integer k;

	always @(posedge Clock)
	begin
		if (L)
			Q <= R;
		else if (E)
		begin
			Q[0] <= w;
			for(k=1; k<n; k=k+1)
				Q[k] <= Q[k-1];
		end
	end
endmodule

module downcount(R, Clock, E, L, Q);
	parameter n = 3;
	input [n-1:0] R;
	input Clock, L, E;
	output reg [n-1:0] Q;
	
	always @(posedge Clock)
		if (L)
			Q <= R;
		else if (E)
			Q <= Q - 1;

endmodule

