library verilog;
use verilog.vl_types.all;
entity alu is
    port(
        oc              : in     vl_logic_vector(2 downto 0);
        a               : in     vl_logic_vector(3 downto 0);
        b               : in     vl_logic_vector(3 downto 0);
        f               : out    vl_logic_vector(3 downto 0)
    );
end alu;
