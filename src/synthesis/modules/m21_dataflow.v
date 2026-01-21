module m21_dataflow(I0, I1, S0, Y);

	input I0, I1, S0;
	output Y;

	assign Y = S0 ? I1 : I0;

endmodule 
