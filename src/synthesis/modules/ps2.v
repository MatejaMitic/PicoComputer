module ps2 (
    input clk,
    input rst_n,
    input ps2_clk,
    input ps2_data,
    output reg [15:0] code
);

    reg [3:0] bit_counter;
    reg [10:0] shift_register;
    reg ps2_clk_prev;
    reg ps2_clk_sync;
    reg [2:0] sync_counter;
    
    // Synchronize PS/2 clock
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_counter <= 3'b0;
            ps2_clk_sync <= 1'b1;
            ps2_clk_prev <= 1'b1;
        end else begin
            sync_counter <= {sync_counter[1:0], ps2_clk};
            if (sync_counter[2:1] == 2'b11) ps2_clk_sync <= 1'b1;
            else if (sync_counter[2:1] == 2'b00) ps2_clk_sync <= 1'b0;
            
            ps2_clk_prev <= ps2_clk_sync;
        end
    end
    
    // Detect falling edge of PS/2 clock
    wire ps2_clk_falling = ps2_clk_prev && !ps2_clk_sync;
    
    // Shift register and bit counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 4'b0;
            shift_register <= 11'b0;
            code <= 16'b0;
        end else if (ps2_clk_falling) begin
            if (bit_counter == 4'd0) begin
                // Start bit should be 0
                if (!ps2_data) begin
                    bit_counter <= bit_counter + 1;
                    shift_register[0] <= ps2_data;
                end
            end else if (bit_counter < 4'd9) begin
                // Data bits
                bit_counter <= bit_counter + 1;
                shift_register[bit_counter] <= ps2_data;
            end else if (bit_counter == 4'd9) begin
                // Parity bit (we'll ignore for simplicity)
                bit_counter <= bit_counter + 1;
            end else begin
                // Stop bit should be 1
                if (ps2_data) begin
                    // Valid frame received
                    code <= {code[7:0], shift_register[8:1]}; // Store last two bytes
                end
                bit_counter <= 4'b0;
                shift_register <= 11'b0;
            end
        end
    end

endmodule