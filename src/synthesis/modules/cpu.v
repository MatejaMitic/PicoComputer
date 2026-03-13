module cpu #(
    parameter ADDR_WIDTH=6,
    parameter ADDR_HIGH = ADDR_WIDTH-1,
    parameter DATA_WIDTH=16,
    parameter DATA_HIGH = DATA_WIDTH-1,
    parameter IR_WIDTH=32,  
    parameter IR_HIGH = IR_WIDTH-1
) (
    input   clk,
    input   rst_n,
    input  [DATA_HIGH:0] mem,
    input  [DATA_HIGH:0] in,
    input   control,        // 1 = novi podatak spreman (od scan_codes)
    output  status,         // 1 = CPU ceka IN podatak (blokirajuca instrukcija)
    output  we,
    output [ADDR_HIGH:0] addr,
    output [DATA_HIGH:0] data,
    output [DATA_HIGH:0] out,
    output [ADDR_HIGH:0] pc,
    output [ADDR_HIGH:0] sp
);

    //PC registar
    reg ld_pc, inc_pc;
    wire [ADDR_WIDTH - 1:0]pc_out;
    reg  [ADDR_WIDTH - 1:0]in_pc;
    assign pc=pc_out;
    register #(.DATA_WIDTH(ADDR_WIDTH)) PC (
        .clk(clk), .rst_n(rst_n), .cl(1'b0), .ld(ld_pc), .in(in_pc), .inc(inc_pc),.dec(1'b0),.sr(1'b0),.ir(1'b0),.sl(1'b0),.il(1'b0),.out(pc_out)
    );
    
    //SP registar
    reg ld_sp, inc_sp, dec_sp;
    wire [ADDR_WIDTH - 1:0]sp_out;
    reg  [ADDR_WIDTH - 1:0]in_sp;
    assign sp=sp_out;
    register #(.DATA_WIDTH(ADDR_WIDTH)) SP (
        .clk(clk), .rst_n(rst_n), .cl(1'b0), .ld(ld_sp), .in(in_sp), .inc(inc_sp),.dec(dec_sp),.sr(1'b0),.ir(1'b0),.sl(1'b0),.il(1'b0),.out(sp_out)
    );
    
    //IR registar
    reg ld_ir;
    wire [IR_HIGH:0]ir_out;
    reg  [IR_HIGH:0] in_ir;
    register #(.DATA_WIDTH(IR_WIDTH)) IR (
        .clk(clk), .rst_n(rst_n), .cl(1'b0), .ld(ld_ir), .in(in_ir), .inc(1'b0),.dec(1'b0),.sr(1'b0),.ir(1'b0),.sl(1'b0),.il(1'b0),.out(ir_out)
    );
    
    //MAR registar
    reg ld_mar;
    wire [ADDR_HIGH:0]mar_out;
    reg  [ADDR_HIGH:0] in_mar;
    register #(.DATA_WIDTH(ADDR_WIDTH)) MAR (
        .clk(clk), .rst_n(rst_n), .cl(1'b0), .ld(ld_mar), .in(in_mar), .inc(1'b0),.dec(1'b0),.sr(1'b0),.ir(1'b0),.sl(1'b0),.il(1'b0),.out(mar_out)
    );
    
    //MDR registar
    reg ld_mdr;
    wire [DATA_HIGH:0]mdr_out;
    reg  [DATA_HIGH:0] in_mdr;
    register #(.DATA_WIDTH(DATA_WIDTH)) MDR (
        .clk(clk), .rst_n(rst_n), .cl(1'b0), .ld(ld_mdr), .in(in_mdr), .inc(1'b0),.dec(1'b0),.sr(1'b0),.ir(1'b0),.sl(1'b0),.il(1'b0),.out(mdr_out)
    );
    
    //ACC registar
    reg ld_acc;
    wire [DATA_HIGH:0]acc_out;
    reg  [DATA_HIGH:0] in_acc;
    register #(.DATA_WIDTH(DATA_WIDTH)) ACC (
        .clk(clk), .rst_n(rst_n), .cl(1'b0), .ld(ld_acc), .in(in_acc), .inc(1'b0),.dec(1'b0),.sr(1'b0),.ir(1'b0),.sl(1'b0),.il(1'b0),.out(acc_out)
    );
    
    // X registar
    wire [DATA_HIGH:0] x_out;
    reg  [DATA_HIGH:0] in_x;
    reg ld_x;
    register #(.DATA_WIDTH(DATA_WIDTH)) REGX (
        .clk(clk),.rst_n(rst_n),.cl(1'b0),.ld(ld_x),.in(in_x),.inc(1'b0),.dec(1'b0),.sr(1'b0),.ir(1'b0),.sl(1'b0),.il(1'b0),.out(x_out)
    );
    
    //Y registar
    wire [DATA_HIGH:0] y_out;
    reg  [DATA_HIGH:0] in_y;
    reg ld_y;
    register #(.DATA_WIDTH(DATA_WIDTH)) REGY (
        .clk(clk),.rst_n(rst_n),.cl(1'b0),.ld(ld_y),.in(in_y),.inc(1'b0),.dec(1'b0),.sr(1'b0),.ir(1'b0),.sl(1'b0),.il(1'b0),.out(y_out)
    );
    
    //Z registar
    wire [DATA_HIGH:0] z_out;
    reg  [DATA_HIGH:0] in_z;
    reg ld_z;
    register #(.DATA_WIDTH(DATA_WIDTH)) REGZ (
        .clk(clk),.rst_n(rst_n),.cl(1'b0),.ld(ld_z),.in(in_z),.inc(1'b0),.dec(1'b0),.sr(1'b0),.ir(1'b0),.sl(1'b0),.il(1'b0),.out(z_out)
    );
    
    //svi ostali outputi reg i next
    reg [ADDR_HIGH:0] addr_reg, addr_next;
    reg [DATA_HIGH:0] data_reg, data_next;
    reg we_reg, we_next;
    reg [DATA_HIGH:0] out_reg, out_next;
    reg status_reg, status_next;
    assign data = data_reg;
    assign addr = addr_reg;
    assign we = we_reg;
    assign out = out_reg;
    assign status = status_reg;
    
    //Operacija    
    wire [3:0] opcode = ir_out[31:28];
    
    //Localparam operacije
    localparam [3:0] MOV = 4'b0000;
    localparam [3:0] ADD = 4'b0001;
    localparam [3:0] SUB = 4'b0010;
    localparam [3:0] MUL = 4'b0011;
    localparam [3:0] DIV = 4'b0100;
    localparam [3:0] BGT = 4'b0110;  
    localparam [3:0] IN = 4'b0111;
    localparam [3:0] OUT = 4'b1000;
    localparam [3:0] ADD_CONST = 4'b1001;  
    localparam [3:0] STOP = 4'b1111;
    
    //Operandi
    wire mode_x = ir_out[27];
    wire [2:0] addr_x = ir_out[26:24];
    wire [5:0] full_addr_x = {3'b000, addr_x};

    wire mode_y = ir_out[23];
    wire [2:0] addr_y = ir_out[22:20];
    wire [5:0] full_addr_y = {3'b000, addr_y};

    wire mode_z = ir_out[19];
    wire [2:0] addr_z = ir_out[18:16];
    wire [5:0] full_addr_z = {3'b000, addr_z};

    wire [15:0] immed = ir_out[15:0];

    // ALU jedinica
    wire [2:0] alu_opcode = opcode[2:0] - 1'b1;
    wire [DATA_HIGH:0] op1 = y_out; 
    wire [DATA_HIGH:0] op2 = acc_out;
    wire [DATA_HIGH:0] alu_result_reg;
    alu #(.DATA_WIDTH(DATA_WIDTH)) ALU (
        .oc(alu_opcode),.a(op1),.b(op2),.f(alu_result_reg)
    );
    
    // Komparator za BGT
    wire compare_gt = (acc_out > y_out);  // X (ACC) > Y ?
    
    //localparam
    localparam lastAvailable = 6'd63;
    localparam pc_start = 6'd8;
    localparam pc_end = 6'd21;  

    reg [5:0] state_reg, state_next;

    localparam [5:0] INIT            = 6'd0,   ZERO_STATE      = 6'd1,   HALT            = 6'd2,   FETCH           = 6'd3,
    FETCH1          = 6'd4,   FETCH_PAUSE     = 6'd5,   FETCH2          = 6'd6,   FETCH3          = 6'd7,
    DECODE          = 6'd8,   EXEC            = 6'd9,   EXEC2           = 6'd10,  EXEC_PAUSE      = 6'd11,
    EXEC3           = 6'd12,  EXEC4           = 6'd13,  EXEC5           = 6'd14,  EXEC_PAUSE2     = 6'd15,
    EXEC6           = 6'd16,  EXEC7           = 6'd17,  EXEC8           = 6'd18,  EXEC_PAUSE3     = 6'd19,
    EXEC9           = 6'd20,  INDIR_Z         = 6'd21,  INDIR_Z1        = 6'd22,  INDIR_Z_PAUSE   = 6'd23,
    INDIR_Z2        = 6'd24,  INDIR_Z3        = 6'd25,  INDIR_Z4        = 6'd26,  INDIR_Z_PAUSE2  = 6'd27,
    INDIR_Z5        = 6'd28,  INDIR_Y         = 6'd29,  INDIR_Y1        = 6'd30,  INDIR_Y_PAUSE   = 6'd31,
    INDIR_Y2        = 6'd32,  INDIR_Y3        = 6'd33,  INDIR_Y4        = 6'd34,  INDIR_Y_PAUSE2  = 6'd35,
    INDIR_Y5        = 6'd36,  INDIR_X         = 6'd37,  INDIR_X1        = 6'd38,  INDIR_X_PAUSE   = 6'd39,
    INDIR_X2        = 6'd40,  INDIR_X3        = 6'd41,  INDIR_X4        = 6'd42,  INDIR_X_PAUSE2  = 6'd43,
    INDIR_X5        = 6'd44,  FFETCH3         = 6'd45,  FFETCH4         = 6'd46,  FFETCH5         = 6'd47,
    FFETCH_PAUSE    = 6'd48,  FFETCH6         = 6'd49;


    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            state_reg  <= INIT;
            data_reg   <= {DATA_WIDTH{1'b0}};
            addr_reg   <= {ADDR_WIDTH{1'b0}};
            out_reg    <= {DATA_WIDTH{1'b0}};
            we_reg     <= 1'b0;
            status_reg <= 1'b0;
        end else begin
            data_reg   <= data_next;
            addr_reg   <= addr_next;
            out_reg    <= out_next;
            we_reg     <= we_next;
            state_reg  <= state_next;
            status_reg <= status_next;
        end
    end

    always @(*) begin
        state_next = state_reg;
        ld_mar = 0; ld_mdr = 0; ld_ir = 0;
        ld_pc = 0; ld_acc = 0; ld_sp = 0; inc_pc = 0; inc_sp = 0; dec_sp = 0;
        in_mar = 0; in_mdr = 0; in_ir = 0; 
        in_acc = 0; in_pc = 0; in_sp = 0;  // ✅ UVEK inicijalizuj!
        we_next = 0;
        addr_next = addr_reg;  
        data_next = data_reg;  
        out_next = out_reg;
        status_next = status_reg;

        ld_x = 0; ld_y = 0; ld_z = 0;
        in_x = {DATA_WIDTH{1'b0}};
        in_y = {DATA_WIDTH{1'b0}};
        in_z = {DATA_WIDTH{1'b0}};

        case (state_reg)
            INIT: begin
                in_pc = pc_start;
                ld_pc = 1;
                in_sp = lastAvailable;
                ld_sp = 1;
                state_next = FETCH;
            end
            
            ZERO_STATE: begin
                state_next = FETCH;
                if (pc_out >= pc_end) state_next = HALT;  
            end
            
            HALT: begin
                state_next = HALT; 
            end 
            
            FETCH: begin
                in_mar = pc_out[ADDR_HIGH:0];
                ld_mar = 1;
                inc_pc = 1;
                state_next = FETCH1;
            end
            
            FETCH1: begin
                addr_next = mar_out;
                state_next = FETCH_PAUSE;
            end
            
            FETCH_PAUSE: begin
                state_next = FETCH2;
            end
            
            FETCH2: begin
                in_mdr = mem;
                ld_mdr = 1;
                state_next = FETCH3;  // uvek idi na FETCH3, mdr_out tek sada registruje
            end
            
            FETCH3: begin
                // mdr_out je sada validan - proveriti da li je dvorecna instrukcija
                in_ir = {mdr_out, 16'h0000};  
                ld_ir = 1;
                if(mdr_out[15:12] == ADD_CONST || 
                   (mdr_out[15:12] == BGT && mdr_out[3] == 1'b1)) begin
                    state_next = FFETCH3;  // idi po drugu rec
                end else begin
                    state_next = DECODE;
                end
            end
            
            // Ucitavanje druge reci instrukcije
            // IR[31:16] vec sadrzi prvu rec (postavljeno u FETCH3)
            FFETCH3: begin
                in_mar = pc_out[ADDR_HIGH:0];
                ld_mar = 1;
                inc_pc = 1;
                state_next = FFETCH4;
            end
            
            FFETCH4: begin
                addr_next = mar_out;
                state_next = FFETCH5;  // FFETCH5 je pauza
            end
            
            // PAUZA - memorija treba ciklus da se stabilizuje (kao FETCH_PAUSE)
            FFETCH5: begin
                state_next = FFETCH_PAUSE;
            end
            
            FFETCH_PAUSE: begin
                state_next = FFETCH6;
            end
            
            FFETCH6: begin
                in_ir = {ir_out[31:16], mem};  // spoji prvu i drugu rec
                ld_ir = 1;
                state_next = DECODE;
            end
            
            DECODE: begin
                case (opcode)
                    MOV: begin
                        if ({mode_z, addr_z} == 4'h0) begin
                            in_x = {{(DATA_WIDTH-ADDR_WIDTH){1'b0}}, full_addr_x};
                            ld_x = 1;
                            in_y = {{(DATA_WIDTH-ADDR_WIDTH){1'b0}}, full_addr_y};
                            ld_y = 1;
                            if (mode_x == 0 && mode_y == 0) begin
                                state_next = EXEC;                                
                            end else begin
                                state_next = INDIR_Y;
                            end
                        end else begin
                            state_next = ZERO_STATE;  
                        end
                    end
                    
                    ADD, SUB, MUL, DIV: begin
                        in_x = {{(DATA_WIDTH-ADDR_WIDTH){1'b0}}, full_addr_x};
                        ld_x = 1;
                        in_y = {{(DATA_WIDTH-ADDR_WIDTH){1'b0}}, full_addr_y};
                        ld_y = 1;
                        in_z = {{(DATA_WIDTH-ADDR_WIDTH){1'b0}}, full_addr_z};
                        ld_z = 1;
                        if ({mode_x, mode_y, mode_z} == 3'b000) begin
                            state_next = EXEC;                            
                        end else begin
                            state_next = INDIR_Z;
                        end
                    end
                    
                    // MOD2: ADD sa konstantom
                    ADD_CONST: begin
                        in_x = {{(DATA_WIDTH-ADDR_WIDTH){1'b0}}, full_addr_x};
                        ld_x = 1;
                        in_acc = immed;  
                        ld_acc = 1;
                        in_z = {{(DATA_WIDTH-ADDR_WIDTH){1'b0}}, full_addr_z};
                        ld_z = 1;
                        
                        if ({mode_x, mode_y, mode_z} == 3'b000) begin
                            state_next = EXEC;
                        end else begin
                            state_next = INDIR_Z;
                        end
                    end
                    
                    // MOD3: BGT
                    BGT: begin
                        in_x = {{(DATA_WIDTH-ADDR_WIDTH){1'b0}}, full_addr_x};
                        ld_x = 1;
                        in_y = {{(DATA_WIDTH-ADDR_WIDTH){1'b0}}, full_addr_y};
                        ld_y = 1;
                        
                        if ({mode_x, mode_y} == 2'b00) begin
                            state_next = EXEC;
                        end else begin
                            state_next = INDIR_Y;
                        end
                    end
                    
                    IN: begin
                        // Blokirajuca instrukcija: status=1 dok control ne postane 1
                        in_x = {{(DATA_WIDTH-ADDR_WIDTH){1'b0}}, full_addr_x};
                        ld_x = 1;
                        status_next = 1'b1;   // signaliziramo da smo spremni da primimo
                        if (control) begin
                            // control=1: podatak spreman, ucitaj ga
                            in_acc = in;
                            ld_acc = 1;
                            status_next = 1'b0; // vise ne cekamo
                            if (mode_x == 1'b0) begin
                                state_next = EXEC;
                            end else begin
                                state_next = INDIR_X;
                            end
                        end
                        // control=0: ostajemo u DECODE (blokiramo)
                    end
                    
                    OUT: begin
                        in_x = {{(DATA_WIDTH-ADDR_WIDTH){1'b0}}, full_addr_x};
                        ld_x = 1;
                        if (mode_x == 1'b0) begin
                            state_next = EXEC;                            
                        end else begin
                            state_next = INDIR_X;
                        end
                    end
                    
                    STOP: begin
                        if ({addr_x, addr_y, addr_z} == 9'b000000000) begin
                            state_next = HALT;
                        end else begin
                            in_x = {{(DATA_WIDTH-ADDR_WIDTH){1'b0}}, full_addr_x};
                            ld_x = 1;
                            in_y = {{(DATA_WIDTH-ADDR_WIDTH){1'b0}}, full_addr_y};
                            ld_y = 1;
                            in_z = {{(DATA_WIDTH-ADDR_WIDTH){1'b0}}, full_addr_z};
                            ld_z = 1;
                            if ({mode_x, mode_y, mode_z} == 3'b000) begin
                                state_next = EXEC;                            
                            end else begin
                                state_next = INDIR_Z;
                            end
                        end
                    end
                    
                    default: begin
                        state_next = ZERO_STATE;
                    end
                endcase
            end
            
            EXEC: begin
                case (opcode)
                    MOV: begin
                        in_mar = y_out[ADDR_HIGH:0];
                        ld_mar = 1;
                        state_next = EXEC2;
                    end
                    
                    ADD, SUB, MUL, DIV: begin
                        in_mar = y_out[ADDR_HIGH:0];
                        ld_mar = 1;
                        state_next = EXEC2;
                    end
                    
                    ADD_CONST: begin
                        in_mar = z_out[ADDR_HIGH:0];
                        ld_mar = 1;
                        state_next = EXEC2;
                    end
                    
                    BGT: begin
                        in_mar = x_out[ADDR_HIGH:0];
                        ld_mar = 1;
                        state_next = EXEC2;
                    end
                    
                    IN: begin
                        in_mar = x_out[ADDR_HIGH:0];
                        ld_mar = 1;
                        in_mdr = acc_out;
                        ld_mdr = 1;
                        state_next = EXEC2;
                    end
                    
                    OUT: begin
                        in_mar = x_out[ADDR_HIGH:0];
                        ld_mar = 1;
                        state_next = EXEC2;
                    end
                    
                    STOP: begin
                        if (x_out[ADDR_HIGH:0] != 6'b000000) begin
                            in_mar = x_out[ADDR_HIGH:0];
                            ld_mar = 1;
                            state_next = EXEC2;
                        end else begin
                            state_next = EXEC4;
                        end
                    end
                    
                    default: begin
                        state_next = ZERO_STATE;
                    end 
                endcase
            end
            
            EXEC2: begin
                case (opcode)
                    MOV: begin
                        addr_next = mar_out;
                        state_next = EXEC_PAUSE;
                    end
                    
                    ADD, SUB, MUL, DIV: begin
                        addr_next = mar_out;
                        in_mar = z_out[ADDR_HIGH:0];
                        ld_mar = 1;
                        state_next = EXEC_PAUSE;
                    end
                    
                    ADD_CONST: begin
                        addr_next = mar_out;
                        state_next = EXEC_PAUSE;
                    end
                    
                    BGT: begin
                        addr_next = mar_out;
                        state_next = EXEC_PAUSE;
                    end
                    
                    IN: begin
                        addr_next = mar_out;
                        data_next = acc_out;  // acc_out drzi SW vrednost (postavljena u DECODE), mdr_out nije validan ovde
                        we_next = 1;
                        state_next = EXEC_PAUSE;
                    end
                    
                    OUT: begin
                        addr_next = mar_out;
                        state_next = EXEC_PAUSE;
                    end
                    
                    STOP: begin
                        addr_next = mar_out;
                        state_next = EXEC_PAUSE;
                    end
                    
                    default: begin
                        state_next = ZERO_STATE;
                    end 
                endcase
            end
            
            EXEC_PAUSE: begin
                state_next = EXEC3;
            end
            
            EXEC3: begin
                case (opcode)
                    MOV: begin
                        in_mdr = mem;
                        ld_mdr = 1;
                        state_next = EXEC4;
                    end
                    
                    ADD, SUB, MUL, DIV: begin
                        in_mdr = mem;
                        ld_mdr = 1;
                        addr_next = mar_out;
                        state_next = EXEC4;
                    end
                    
                    ADD_CONST: begin
                        in_y = mem;
                        ld_y = 1;
                        state_next = EXEC7;
                    end
                    
                    BGT: begin
                        in_acc = mem;
                        ld_acc = 1;
                        if (addr_x == 3'b000) begin
                            in_acc = 16'h0000;
                        end
                        state_next = EXEC4;
                    end
                    
                    IN: begin
                        we_next = 0;
                        state_next = ZERO_STATE;
                    end
                    
                    OUT: begin
                        out_next = mem;
                        state_next = ZERO_STATE;
                    end
                    
                    STOP: begin
                        out_next = mem;
                        state_next = EXEC4;
                    end
                    
                    default: begin
                        state_next = ZERO_STATE;
                    end 
                endcase
            end
            
            EXEC4: begin
                case (opcode)
                    MOV: begin
                        in_acc = mdr_out;
                        ld_acc = 1;
                        state_next = EXEC5;
                    end
                    
                    ADD, SUB, MUL, DIV: begin
                        in_y = mdr_out;
                        ld_y = 1;
                        state_next = EXEC5;
                    end
                    
                    BGT: begin
                        in_mar = y_out[ADDR_HIGH:0];
                        ld_mar = 1;
                        state_next = EXEC5;
                    end
                    
                    STOP: begin
                        if (y_out[ADDR_HIGH:0] != 6'b000000) begin
                            in_mar = y_out[ADDR_HIGH:0];
                            ld_mar = 1;
                            state_next = EXEC5;
                        end else begin
                            state_next = EXEC7;
                        end
                    end
                    
                    default: begin
                        state_next = ZERO_STATE;
                    end 
                endcase
            end
            
            EXEC5: begin
                case (opcode)
                    MOV: begin
                        data_next = acc_out;
                        addr_next = x_out[ADDR_HIGH:0];
                        we_next = 1;
                        state_next = EXEC_PAUSE2;
                    end
                    
                    ADD, SUB, MUL, DIV: begin
                        in_mdr = mem;
                        ld_mdr = 1;
                        state_next = EXEC6;
                    end
                    
                    BGT: begin
                        addr_next = mar_out;
                        state_next = EXEC_PAUSE2;
                    end
                    
                    STOP: begin
                        addr_next = mar_out;
                        state_next = EXEC_PAUSE2;
                    end
                    
                    default: begin
                        state_next = ZERO_STATE;
                    end 
                endcase
            end
            
            EXEC_PAUSE2: begin
                state_next = EXEC6;
            end
            
            EXEC6: begin
                case (opcode)
                    MOV: begin
                        we_next = 0;
                        state_next = ZERO_STATE;
                    end
                    
                    ADD, SUB, MUL, DIV: begin
                        in_acc = mdr_out;
                        ld_acc = 1;
                        state_next = EXEC7;
                    end
                    
                    BGT: begin
                        in_y = mem;
                        ld_y = 1;
                        if (addr_y == 3'b000) begin
                            in_y = 16'h0000;
                        end
                        state_next = EXEC7;
                    end
                    
                    STOP: begin
                        out_next = mem;
                        state_next = EXEC7;
                    end
                    
                    default: begin
                        state_next = ZERO_STATE;
                    end 
                endcase
            end
            
            EXEC7: begin
                case (opcode)
                    ADD, SUB, MUL, DIV: begin
                        data_next = alu_result_reg;
                        addr_next = x_out[ADDR_HIGH:0];
                        we_next = 1;
                        state_next = EXEC_PAUSE3;
                    end
                    
                    ADD_CONST: begin
                        data_next = alu_result_reg;
                        addr_next = x_out[ADDR_HIGH:0];
                        we_next = 1;
                        state_next = EXEC_PAUSE3;
                    end
                    
                    BGT: begin
                        if (compare_gt) begin
                            if (mode_z == 1'b1) begin
                                in_pc = immed[ADDR_HIGH:0];
                            end else begin
                                in_pc = full_addr_z;
                            end
                            ld_pc = 1;
                        end
                        state_next = ZERO_STATE;
                    end
                    
                    STOP: begin
                        if (z_out[ADDR_HIGH:0] != 6'b000000) begin
                            in_mar = z_out[ADDR_HIGH:0];
                            ld_mar = 1;
                            state_next = EXEC8;
                        end else begin
                            state_next = HALT;
                        end  
                    end
                    
                    default: begin
                        state_next = ZERO_STATE;
                    end 
                endcase
            end
            
            EXEC8: begin
                case (opcode)
                    ADD, SUB, MUL, DIV, ADD_CONST: begin
                        state_next = EXEC_PAUSE3;
                    end 
                    
                    STOP: begin
                        addr_next = mar_out;
                        state_next = EXEC_PAUSE3;
                    end
                    
                    default: begin
                        state_next = ZERO_STATE;
                    end
                endcase
            end
            
            EXEC_PAUSE3: begin
                state_next = EXEC9;
            end
            
            EXEC9: begin
                case (opcode)
                    ADD, SUB, MUL, DIV, ADD_CONST: begin
                        we_next = 0;
                        state_next = ZERO_STATE;
                    end 
                    
                    STOP: begin
                        out_next = mem;
                        state_next = HALT;
                    end
                    
                    default: begin
                        state_next = ZERO_STATE;
                    end
                endcase
            end
            
            // Indirektno adresiranje
            INDIR_Z: begin
                if (mode_z == 1'b1) begin
                    in_mar = z_out[ADDR_HIGH:0];
                    ld_mar = 1;
                    state_next = INDIR_Z1;
                end else begin
                    state_next = INDIR_Y;
                end
            end
            
            INDIR_Z1: begin
                addr_next = mar_out;
                state_next = INDIR_Z_PAUSE;
            end
            
            INDIR_Z_PAUSE: begin
                state_next = INDIR_Z2;
            end
            
            INDIR_Z2: begin
                in_mdr = mem;
                ld_mdr = 1;
                state_next = INDIR_Z3;
            end
            
            INDIR_Z3: begin
                in_z = {{(DATA_WIDTH-ADDR_WIDTH){1'b0}}, mdr_out[ADDR_HIGH:0]};
                ld_z = 1;
                state_next = INDIR_Y;
            end
            
            INDIR_Y: begin
                if (mode_y == 1'b1) begin
                    in_mar = y_out[ADDR_HIGH:0];
                    ld_mar = 1;
                    state_next = INDIR_Y1;
                end else begin
                    state_next = INDIR_X;
                end
            end
            
            INDIR_Y1: begin
                addr_next = mar_out;
                state_next = INDIR_Y_PAUSE;
            end
            
            INDIR_Y_PAUSE: begin
                state_next = INDIR_Y2;
            end
            
            INDIR_Y2: begin
                in_mdr = mem;
                ld_mdr = 1;
                state_next = INDIR_Y3;
            end
            
            INDIR_Y3: begin
                in_y = {{(DATA_WIDTH-ADDR_WIDTH){1'b0}}, mdr_out[ADDR_HIGH:0]};
                ld_y = 1;
                state_next = INDIR_X;
            end
            
            INDIR_X: begin
                if (mode_x == 1'b1) begin
                    in_mar = x_out[ADDR_HIGH:0];
                    ld_mar = 1;
                    state_next = INDIR_X1;
                end else begin
                    state_next = EXEC;
                end
            end
            
            INDIR_X1: begin
                addr_next = mar_out;
                state_next = INDIR_X_PAUSE;
            end
            
            INDIR_X_PAUSE: begin
                state_next = INDIR_X2;
            end
            
            INDIR_X2: begin
                in_mdr = mem;
                ld_mdr = 1;
                state_next = INDIR_X3;
            end
            
            INDIR_X3: begin
                in_x = {{(DATA_WIDTH-ADDR_WIDTH){1'b0}}, mdr_out[ADDR_HIGH:0]};
                ld_x = 1;
                state_next = EXEC;
            end
            
            default: begin
                state_next = ZERO_STATE;
            end
        endcase
    end
endmodule