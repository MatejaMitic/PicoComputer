// VGA kontroler — 640x480 @ 60Hz
// Sistemski takt: 50 MHz  →  pixel clock: 25 MHz (interno deljenje sa 2)
//
// Horizontalni tajming (pikseli pri 25MHz):
//   Visible   : 640
//   Front porch:  16
//   Sync pulse:   96  (active LOW)
//   Back porch:   48
//   Total      : 800
//
// Vertikalni tajming (linije):
//   Visible   : 480
//   Front porch:  10
//   Sync pulse:    2  (active LOW)
//   Back porch:   33
//   Total      : 525

module vga (
    input  wire        clk,       // 50 MHz
    input  wire        rst_n,
    input  wire [23:0] code,      // [23:12]=leva boja, [11:0]=desna boja
    output reg         hsync,
    output reg         vsync,
    output reg  [3:0]  red,
    output reg  [3:0]  green,
    output reg  [3:0]  blue
);

    // ------------------------------------------------------------------
    // Pixel clock: 50MHz -> 25MHz
    // ------------------------------------------------------------------
    reg pix_clk;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) pix_clk <= 1'b0;
        else        pix_clk <= ~pix_clk;
    end

    // ------------------------------------------------------------------
    // Tajming parametri
    // ------------------------------------------------------------------
    localparam H_VISIBLE    = 640;
    localparam H_FP         = 16;
    localparam H_SYNC_W     = 96;
    localparam H_BP         = 48;
    localparam H_TOTAL      = H_VISIBLE + H_FP + H_SYNC_W + H_BP; // 800

    localparam H_SYNC_START = H_VISIBLE + H_FP;          // 656
    localparam H_SYNC_END   = H_SYNC_START + H_SYNC_W;   // 752

    localparam V_VISIBLE    = 480;
    localparam V_FP         = 10;
    localparam V_SYNC_W     = 2;
    localparam V_BP         = 33;
    localparam V_TOTAL      = V_VISIBLE + V_FP + V_SYNC_W + V_BP; // 525

    localparam V_SYNC_START = V_VISIBLE + V_FP;          // 490
    localparam V_SYNC_END   = V_SYNC_START + V_SYNC_W;   // 492

    // ------------------------------------------------------------------
    // Horizontalni i vertikalni brojaci
    // ------------------------------------------------------------------
    reg [9:0] h_cnt; // 0..799
    reg [9:0] v_cnt; // 0..524

    always @(posedge pix_clk or negedge rst_n) begin
        if (!rst_n) begin
            h_cnt <= 10'd0;
            v_cnt <= 10'd0;
        end else begin
            if (h_cnt == H_TOTAL - 1) begin
                h_cnt <= 10'd0;
                v_cnt <= (v_cnt == V_TOTAL - 1) ? 10'd0 : v_cnt + 1'b1;
            end else begin
                h_cnt <= h_cnt + 1'b1;
            end
        end
    end

    // ------------------------------------------------------------------
    // Aktivan region i boja piksela
    // ------------------------------------------------------------------
    wire active = (h_cnt < H_VISIBLE) && (v_cnt < V_VISIBLE);

    // Leva polovina: x < 320 → code[23:12]
    // Desna polovina: x >= 320 → code[11:0]
    wire [11:0] pixel_color = (h_cnt < 10'd320) ? code[23:12] : code[11:0];

    // ------------------------------------------------------------------
    // Registrovani izlazi (sinhronizovani sa pixel clockom)
    // ------------------------------------------------------------------
    always @(posedge pix_clk or negedge rst_n) begin
        if (!rst_n) begin
            hsync <= 1'b1;
            vsync <= 1'b1;
            red   <= 4'h0;
            green <= 4'h0;
            blue  <= 4'h0;
        end else begin
            // Sync signali — active LOW
            hsync <= ~((h_cnt >= H_SYNC_START) && (h_cnt < H_SYNC_END));
            vsync <= ~((v_cnt >= V_SYNC_START) && (v_cnt < V_SYNC_END));

            if (active) begin
                red   <= pixel_color[11:8];
                green <= pixel_color[7:4];
                blue  <= pixel_color[3:0];
            end else begin
                red   <= 4'h0;
                green <= 4'h0;
                blue  <= 4'h0;
            end
        end
    end

endmodule