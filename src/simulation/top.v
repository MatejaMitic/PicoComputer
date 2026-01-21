module top;

    reg [2:0] oc;
    reg [3:0] a, b, in;
    reg clk, rst_n, ld, inc, dec, cl, sr, ir, sl, il;
    wire [3:0] f, out;

    integer index;

    alu alu_unit(.oc(oc), .a(a), .b(b), .f(f));
    register reg_unit(.clk(clk), .rst_n(rst_n), .cl(cl), .ld(ld), .in(in), .inc(inc), .dec(dec), .sr(sr), .ir(ir), .sl(sl), .il(il), .out(out));

    initial begin
        a = 4'b1010; 
        b = 4'b0011;
        for (index = 0; index < 8; index = index + 1) begin
            {oc} = index;
            #5;
        end
        $stop;
        rst_n = 1'b0; clk = 1'b0; cl = 1'b0; ld = 1'b0; inc = 1'b0;
        dec = 1'b0; sr = 1'b0; ir = 1'b0; sl = 1'b0; il = 1'b0; in = 4'b0000;
        #2 rst_n = 1'b1;
        repeat (1000) begin
            #5; ld = {$random} % 2;
            inc = $urandom % 2;
            dec = $urandom % 2;
            cl = $urandom % 2;
            sr = $urandom % 2;
            ir = $urandom % 2;
            sl = $urandom % 2;
            il = $urandom % 2;
            in = $urandom_range(255);
        end

        $finish;
    end

    always
        #5 clk = ~clk;

    initial
        $monitor("Vreme = %2d, a = %b, b = %b Izlaz = %b, oc = %b", $time, a, b, f, oc);

    always @(out) begin
        $display("--- REG CHANGE @%0d ---", $time);
        $display("OUT = %b, IN = %b", out, in);
        $display("Controls: cl=%b, ld=%b, inc=%b, dec=%b", cl, ld, inc, dec);
        $display("Shift: sr=%b, ir=%b, sl=%b, il=%b", sr, ir, sl, il);
        $display("------------------------");
end

endmodule