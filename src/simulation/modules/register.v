module register(clk, rst_n, cl, ld, in, inc, dec, sr, ir, sl, il, out);

    input clk, rst_n, ld, inc, cl, dec, sr, ir, sl, il;
    input [3:0] in;
    output reg [3:0] out;

    always @(posedge clk, negedge rst_n)
        if (!rst_n)
            out <= 4'h0;
        else
            if(cl)
                out <= 4'h0;
            else if (ld)
                out <= in;
            else if (inc)
                out <= out + {{3{1'b0}}, 1'b1};
            else if (dec)
                out <= out - {{3{1'b0}}, 1'b1};
            else if (sr)
                out <= {ir, out[3:1]};
            else if (sl)
                out <= {out[2:0], il};
            
endmodule