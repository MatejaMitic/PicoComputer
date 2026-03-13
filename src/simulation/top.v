module top;
    reg [3:0] a, b;
    reg [2:0] oc;
    wire [3:0] f;
    integer index;

    alu test1(oc, a, b, f);

    reg clk, rst_n, cl, ld, inc, dec, sr, ir, sl, il;
    reg [3:0] in;
    wire [3:0] out;

    register test2(clk, rst_n, cl, ld, in, inc, dec, sr, ir, sl, il, out);

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        oc = 3'b000;
        a = 4'b0000;
        b = 4'b0000;
        for (index = 0; index < 2048; index = index + 1) begin
            {oc, a, b} = index;
            #5;
            $display("ALU: t=%0t, oc=%0d, f=%4b, a=%4b, b=%4b", $time, oc, f, a, b);
        end
        $stop;
        rst_n = 1'b0;
        #5 rst_n = 1'b1;
        cl = 1'b0; ld = 1'b0; in = 4'b0000; inc = 1'b0; dec = 1'b0; sr = 1'b0; ir = 1'b0; sl = 1'b0; il = 1'b0;
        repeat (1000) begin
            #10 {cl, ld, in, inc, dec, sr, ir, sl, il} = $urandom % 4096;
            #0;
            $display("REGISTER: t=%0t, cl=%b, ld=%b, in=%4b, inc=%b, dec=%b, sr=%b, ir=%b, sl=%b, il=%b, out=%4b",
                     $time, cl, ld, in, inc, dec, sr, ir, sl, il, out);
        end
        #10 $finish;
    end
endmodule
