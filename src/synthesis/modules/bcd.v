module bcd (in, ones, tens);
    input [5:0] in;
    output [3:0] ones;
    output [3:0] tens;
    
    assign ones=in % 10;
    assign tens=in/10 %10;
    
endmodule