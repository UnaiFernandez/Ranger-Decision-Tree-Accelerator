library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package dt_accel_pkg is

    component dt_accel is
	generic(
    	    g_DATA_WIDTH: integer;
    	    g_ADDR_WIDTH: integer;
	    g_K		: integer;
    	    g_DEPTH	: integer
    	);
	port(
    	    i_CLK	: in std_logic;
    	    i_RESET	: in std_logic;
	    i_ENABLE	: in std_logic;
	    i_SEL	: in std_logic;
	    i_GET_DATA	: in std_logic;
	    i_DATA_ADDR : in UNSIGNED(g_ADDR_WIDTH - 1 downto 0);
    	    i_DATA_MEM	: in std_logic_vector;
	    i_CALC_RESULT : in std_logic;
    	    ----------------------------------------------------
    	    --o_CLASS	: out std_logic_vector(g_K - 1 downto 0);
	    o_CLASS	: out std_logic_vector(g_K - 1 downto 0);
    	    o_DONE	: out std_logic
    	);
    end component;

end dt_accel_pkg;
