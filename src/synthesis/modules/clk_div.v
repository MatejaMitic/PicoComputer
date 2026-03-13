module clk_div #(
    parameter DIVISOR = 10_000_000
)(
    input  wire clk,       
    input  wire rst_n,     
    output wire out        
);
    reg [25:0] counter;    
    reg out_reg;           
    assign out = out_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter  <= 26'd0;
            out_reg  <= 1'b0;
        end else begin
            if (counter == DIVISOR-1) begin
                counter <= 26'd0;
                out_reg <= ~out_reg;   
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end

endmodule