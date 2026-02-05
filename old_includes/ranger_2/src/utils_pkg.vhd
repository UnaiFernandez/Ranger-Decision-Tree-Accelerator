
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package utils_pkg is
    -- Function Headers
    -------------------------------------------------------
    function log2 (x:in integer) return integer;
    function mem_dwidth (x: in integer) return integer;

    -- Constant Declaration 
    -------------------------------------------------------
    -- NOTE: Hay que tener cuidado con los widths porque igual a las memorias no les hace gracia
    constant C_NEURONS:  integer := 24;
    constant C_SYNAPSIS: integer := 135; 

    constant C_NADDR_WIDTH:  integer := log2(C_NEURONS);
    constant C_SADDR_WIDTH:  integer := log2(C_SYNAPSIS);
    constant C_N_DWIDTH:     integer := 32;
    constant C_W_DWIDTH:     integer := 15;

    constant C_DELAY:     integer := 1;
    constant C_T_REFRACT: integer := 2;
    constant C_V_MAX:     integer := 255;
    constant C_V_THRES:   integer := 300;

    constant C_TAU_M: integer := 20;
    constant C_TAU:   integer := 5;

    constant C_WIN_MAX:   integer := 10;
    constant C_WIN_MIN:   integer := -10;

    constant C_PAGE_WIDTH:  integer := 32;
    constant C_MEM_DWIDTH:  integer := 32;
    constant C_SP_AWIDTH:   integer := 32;
    constant C_PARAM_WIDTH: integer := 32;

    constant C_AXI_DWIDTH:  integer := 32;
    constant C_BUFF_SIZE:   integer := 256;
    constant C_BURST_SIZE:  integer := 32;


    -- Type Declaration
    -------------------------------------------------------
    -- NOTE: it_bit: 31, postNaddr: [30..15] (16b), weight: [14..0] (15b)
    subtype synapsis_t is std_logic_vector(C_MEM_DWIDTH-1 downto 0);

    subtype weight_t is signed(C_W_DWIDTH-1 downto 0);

    subtype timestamp_t   is unsigned(15 downto 0);
    subtype timestamp_2_t is unsigned(timestamp_t'length*2-1 downto 0);

    type spike_t is record
        addr:       unsigned(C_SP_AWIDTH-1 downto 0); 
        timestamp:  timestamp_2_t;
    end record;

    type LUT_type is array (0 to 31) of unsigned(7 downto 0);
end utils_pkg;


package body utils_pkg is 
    function log2(x: in integer) return integer is
        variable i: integer;
    begin
        i := 1;
        while (2**i < x) loop
            i := i + 1;
        end loop;
        return i;
    end;

    function mem_dwidth (x: in integer) return integer is
    begin
        if x <= 4 then
            return 4;
        elsif x <= 8 then
            return 8;
        elsif x <= 16 then
            return 16;
        elsif x <= 32 then
            return 32;
        else
            return 64;
        end if;
    end;
end utils_pkg;

