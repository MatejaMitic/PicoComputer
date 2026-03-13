module top #(
    parameter DIVISOR    = 50_000_000,
    parameter FILE_NAME  = "mem_init.mif",
    parameter ADDR_WIDTH = 6,
    parameter ADDR_HIGH  = ADDR_WIDTH - 1,
    parameter DATA_WIDTH = 16,
    parameter DATA_HIGH  = DATA_WIDTH - 1
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [1:0]  kbd,       // kbd[0]=ps2_clk, kbd[1]=ps2_data
    input  wire [2:0]  btn,
    input  wire [8:0]  sw,
    output wire [13:0] mnt,       // mnt[13]=hsync, mnt[12]=vsync, mnt[11:8]=R, mnt[7:4]=G, mnt[3:0]=B
    output wire [9:0]  led,       // led[5]=status, led[4:0]=cpu_out[4:0]
    output wire [27:0] hex
);

    // ----------------------------------------------------------------
    // Takt: RST = sw[8] (sw[9] u shemi odgovara sw[8] u 9-bitnom sw)
    // ----------------------------------------------------------------
    wire rst = sw[8];   // sw[9] iz slike -> indeks 8 u sw[8:0]

    // ----------------------------------------------------------------
    // Delitelj takta
    // ----------------------------------------------------------------
    wire slow_clk;
    clk_div #(.DIVISOR(DIVISOR)) u_div (
        .clk   (clk),
        .rst_n (rst_n),
        .out   (slow_clk)
    );

    // ----------------------------------------------------------------
    // Debouncer za tastere i prekidace
    // ----------------------------------------------------------------
    wire [2:0] btn_db, btn_clean;
    debouncer u_btn_db0 (.clk(clk), .rst_n(rst_n), .in(btn[0]), .out(btn_db[0]));
    debouncer u_btn_db1 (.clk(clk), .rst_n(rst_n), .in(btn[1]), .out(btn_db[1]));
    debouncer u_btn_db2 (.clk(clk), .rst_n(rst_n), .in(btn[2]), .out(btn_db[2]));

    red u_red0 (.clk(clk), .rst_n(rst_n), .in(btn_db[0]), .out(btn_clean[0]));
    red u_red1 (.clk(clk), .rst_n(rst_n), .in(btn_db[1]), .out(btn_clean[1]));
    red u_red2 (.clk(clk), .rst_n(rst_n), .in(btn_db[2]), .out(btn_clean[2]));

    wire [8:0] sw_clean;
    genvar i;
    generate
        for (i = 0; i < 9; i = i+1) begin : SW_DB
            debouncer u_db (
                .clk   (clk),
                .rst_n (rst_n),
                .in    (sw[i]),
                .out   (sw_clean[i])
            );
        end
    endgenerate

    // ----------------------------------------------------------------
    // PS/2 kontroler
    // kbd[0] = ps2_clk,  kbd[1] = ps2_data
    // ----------------------------------------------------------------
    wire [15:0] ps2_code;
    ps2 u_ps2 (
        .clk      (clk),
        .rst_n    (rst_n),
        .ps2_clk  (kbd[0]),
        .ps2_data (kbd[1]),
        .code     (ps2_code)
    );

    // ----------------------------------------------------------------
    // CPU signali
    // ----------------------------------------------------------------
    wire                  cpu_we;
    wire [ADDR_HIGH:0]    cpu_addr;
    wire [DATA_HIGH:0]    cpu_data;
    wire [DATA_HIGH:0]    cpu_out;
    wire [DATA_HIGH:0]    mem_out;
    wire [ADDR_HIGH:0]    pc;
    wire [ADDR_HIGH:0]    sp;
    wire                  cpu_status;   // CPU ceka IN podatak
    wire                  scan_control; // scan_codes ima spreman broj

    // ----------------------------------------------------------------
    // Scan Codes: prevodi PS/2 code -> cifra
    // scan_codes prima status od CPU-a i salje control kad je cifra spremna
    // ----------------------------------------------------------------
    wire [3:0] kbd_num;
    scan_codes u_scan (
        .clk     (clk),
        .rst_n   (rst_n),
        .code    (ps2_code),
        .status  (cpu_status),
        .control (scan_control),
        .num     (kbd_num)
    );

    // ----------------------------------------------------------------
    // Memorija
    // ----------------------------------------------------------------
    memory #(
        .FILE_NAME  (FILE_NAME),
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH)
    ) u_mem (
        .clk  (slow_clk),
        .we   (cpu_we),
        .rst_n(rst_n),
        .addr (cpu_addr),
        .data (cpu_data),
        .out  (mem_out)
    );

    // ----------------------------------------------------------------
    // CPU
    // in = podatak sa tastature prosiren na DATA_WIDTH
    // sw[3:0] se vise ne koriste za IN (koristi se tastatura)
    // ----------------------------------------------------------------
    wire [DATA_HIGH:0] cpu_in;
    assign cpu_in = {{(DATA_WIDTH-4){1'b0}}, kbd_num};

    cpu #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH)
    ) u_cpu (
        .clk     (slow_clk),
        .rst_n   (rst_n),
        .mem     (mem_out),
        .in      (cpu_in),
        .control (scan_control),
        .status  (cpu_status),
        .we      (cpu_we),
        .addr    (cpu_addr),
        .data    (cpu_data),
        .out     (cpu_out),
        .pc      (pc),
        .sp      (sp)
    );

    // ----------------------------------------------------------------
    // LED izlazi
    // led[4:0] = cpu_out[4:0]
    // led[5]   = cpu_status (CPU spreman za IN)
    // led[9:6] = 0
    // ----------------------------------------------------------------
    assign led[4:0] = cpu_out[4:0];
    assign led[5]   = cpu_status;
    assign led[9:6] = 4'b0000;

    // ----------------------------------------------------------------
    // BCD + SSD za PC i SP (hex displej)
    // hex[6:0]   = pc ones
    // hex[13:7]  = pc tens
    // hex[20:14] = sp ones
    // hex[27:21] = sp tens
    // ----------------------------------------------------------------
    wire [3:0] pc_ones, pc_tens, sp_ones, sp_tens;
    bcd u_bcd_pc (.in(pc), .ones(pc_ones), .tens(pc_tens));
    bcd u_bcd_sp (.in(sp), .ones(sp_ones), .tens(sp_tens));

    wire [6:0] pc_ones_ssd, pc_tens_ssd, sp_ones_ssd, sp_tens_ssd;
    ssd u_ssd_pc_ones (.in(pc_ones), .out(pc_ones_ssd));
    ssd u_ssd_pc_tens (.in(pc_tens), .out(pc_tens_ssd));
    ssd u_ssd_sp_ones (.in(sp_ones), .out(sp_ones_ssd));
    ssd u_ssd_sp_tens (.in(sp_tens), .out(sp_tens_ssd));

    assign hex = {sp_tens_ssd, sp_ones_ssd, pc_tens_ssd, pc_ones_ssd};

    // ----------------------------------------------------------------
    // COLOR_CODES: cpu_out[5:0] -> 24-bit RGB kod za VGA
    // Koristimo cpu_out[5:0] kao dvocifreni broj (0-63 = 00-63 decimalno)
    // ----------------------------------------------------------------
    wire [23:0] color_code;
    color_codes u_color (
        .num  (cpu_out[5:0]),
        .code (color_code)
    );

    // ----------------------------------------------------------------
    // VGA kontroler
    // mnt[13]  = hsync
    // mnt[12]  = vsync
    // mnt[11:8] = red[3:0]
    // mnt[7:4]  = green[3:0]
    // mnt[3:0]  = blue[3:0]
    // ----------------------------------------------------------------
    wire vga_hsync, vga_vsync;
    wire [3:0] vga_red, vga_green, vga_blue;

    vga u_vga (
        .clk   (clk),        // VGA koristi brzi takt (50MHz)
        .rst_n (rst_n),
        .code  (color_code),
        .hsync (vga_hsync),
        .vsync (vga_vsync),
        .red   (vga_red),
        .green (vga_green),
        .blue  (vga_blue)
    );

    assign mnt[13]   = vga_hsync;
    assign mnt[12]   = vga_vsync;
    assign mnt[11:8] = vga_red;
    assign mnt[7:4]  = vga_green;
    assign mnt[3:0]  = vga_blue;

endmodule