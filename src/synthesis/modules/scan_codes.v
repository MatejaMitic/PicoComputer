module scan_codes (
    input  wire        clk,       // brzi takt (50MHz) - isti kao PS2
    input  wire        rst_n,
    input  wire [15:0] code,      // sa ps2 modula
    input  wire        status,    // od CPU-a (slow_clk domena!) - treba sinhronizovati
    output reg         control,   // ka CPU-u - ostaje 1 dok status ne padne
    output reg  [3:0]  num
);

    // ------------------------------------------------------------------
    // Sinhronizacija 'status' signala iz slow_clk domene u clk domenu
    // ------------------------------------------------------------------
    reg status_s1, status_s2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            status_s1 <= 1'b0;
            status_s2 <= 1'b0;
        end else begin
            status_s1 <= status;
            status_s2 <= status_s1;
        end
    end
    wire status_sync = status_s2;

    // ------------------------------------------------------------------
    // Detekcija otpustanja tastera
    // PS/2 sekvenca: bajt F0 stize -> code[7:0]=F0
    //                scan kod stize -> code={F0, scan}
    // Detektujemo: prethodni code[7:0]==F0 I trenutni code[7:0]!=F0
    // ------------------------------------------------------------------
    reg [15:0] prev_code;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_code <= 16'h0000;
            control   <= 1'b0;
            num       <= 4'b0;
        end else begin
            prev_code <= code;

            if (!status_sync) begin
                // CPU vise ne ceka (prihvatio podatak ili nije u IN)
                control <= 1'b0;
            end else if (status_sync && !control &&
                         (prev_code[7:0] == 8'hF0) &&
                         (code[7:0]      != 8'hF0)) begin
                // Release detektovan dok CPU ceka i control jos nije 1
                // Postavi control i sacuvaj cifru
                case (code[7:0])
                    8'h45: begin num <= 4'd0; control <= 1'b1; end
                    8'h16: begin num <= 4'd1; control <= 1'b1; end
                    8'h1E: begin num <= 4'd2; control <= 1'b1; end
                    8'h26: begin num <= 4'd3; control <= 1'b1; end
                    8'h25: begin num <= 4'd4; control <= 1'b1; end
                    8'h2E: begin num <= 4'd5; control <= 1'b1; end
                    8'h36: begin num <= 4'd6; control <= 1'b1; end
                    8'h3D: begin num <= 4'd7; control <= 1'b1; end
                    8'h3E: begin num <= 4'd8; control <= 1'b1; end
                    8'h46: begin num <= 4'd9; control <= 1'b1; end
                    default: ; // nije cifra — ne menjamo
                endcase
            end
            // Ako status_sync=1 i control=1: drzimo control=1 dok CPU ne spusti status
        end
    end

endmodule