library verilog;
use verilog.vl_types.all;
entity \register\ is
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        cl              : in     vl_logic;
        ld              : in     vl_logic;
        \in\            : in     vl_logic_vector(3 downto 0);
        inc             : in     vl_logic;
        dec             : in     vl_logic;
        sr              : in     vl_logic;
        ir              : in     vl_logic;
        sl              : in     vl_logic;
        il              : in     vl_logic;
        \out\           : out    vl_logic_vector(3 downto 0)
    );
end \register\;
