module memory #(
	parameter FILE_NAME = "mem_init.mif",
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
)(
    input clk,
    input we,
    input rst_n,
    input [ADDR_WIDTH - 1:0] addr,
    input [DATA_WIDTH - 1:0] data,
    output reg [DATA_WIDTH - 1:0] out
);

	(* ram_init_file = FILE_NAME *) reg [DATA_WIDTH - 1:0] mem [2**ADDR_WIDTH - 1:0];

    always @(posedge clk) begin
        if (we) begin
            mem[addr] = data;
        end
        out <= mem[addr];
    end

endmodule







































/*
module memory (clk, we, addr, data, out);
    input clk, we;
    input [5:0]addr;
    input [7:0]data;
    output [7:0]out;

    reg [7:0]mem_reg[63:0];
    reg [7:0]mem_next[63:0];
    reg [5:0]addr_reg, addr_next;

    integer j;
    assign out=mem_reg[addr_reg];

    always @(posedge clk ) begin
        for (j =0;j<64 ;j=j+1 ) begin
            mem_reg[j]=mem_next[j];
        end
        addr_reg=addr_next;
    end
    always @(*) begin
        addr_next=addr;
        for (j =0;j<64 ;j=j+1 ) begin
            mem_next[j]=mem_reg[j];
        end
        if (we) begin
            mem_next[addr]=data;
        end
        addr_next=addr;
    end
    
endmodule


module dut (clk, we, addr, data, out);
    input clk, we;
    input [5:0]addr;
    input [15:0]data;
    output [15:0]out;

    memory low(clk, we, addr, data[7:0], out[7:0]);
    memory high(clk, we, addr, data[15:8], out[15:8]);

endmodule

module tb;
    reg clk, we;
    reg [5:0] addr;
    reg [15:0] data;
    wire [15:0] out;
    dut test(clk, we, addr, data, out);
    initial clk = 0;
    always #5 clk = ~clk;
    integer j;
    initial begin
        we   = 0;
        addr = 0;
        data = 16'h0000;
        for (j = 0; j < 64; j = j + 1) begin
            @(posedge clk);
            we   = 1;
            addr = j;
            data = $urandom;
        end
        @(posedge clk);
        we = 0;
        repeat (100) begin
            @(posedge clk);
            addr = $urandom % 64;
            @(posedge clk);  
            $display("READ addr=%0d  out=%h", addr, out);
        end
        $finish;
    end

endmodule

*/