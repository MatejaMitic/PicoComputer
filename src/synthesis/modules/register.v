module register #(
    parameter DATA_WIDTH = 16,
    parameter HIGH = DATA_WIDTH-1
) (
    input clk, rst_n, cl, ld, inc, dec, sr, ir, sl ,il,
    input [HIGH:0] in,
    output [HIGH:0] out
);
    reg [HIGH:0] out_reg, out_next;
    assign out=out_reg;
    
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            out_reg<={HIGH{1'b0}};
        end else begin
            out_reg<=out_next;
        end
    end

    always @(*) begin
        out_next=out_reg;
        if (cl) begin
            out_next={HIGH{1'b0}};
        end
        else if (ld) begin
            out_next=in;
        end
        else if(inc)begin
            out_next=out_next+1'b1;
        end
        else if (dec) begin
            out_next=out_next-1'b1;
        end
        else if (sr) begin
            out_next = { ir, out_reg[HIGH:1] };  
        end
        else if (sl) begin
            out_next = { out_reg[HIGH-1:0], il };   
        end

    end
    
endmodule