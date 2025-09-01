library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package bus_master_pkg is
    component bus_master is
	generic(
	    g_DATA_WIDTH: integer;
	    g_ADDR_WIDTH: integer;
	    g_INSTANCES: integer
    	);
	port(
    	    i_CLK		: in std_logic;
    	    i_RESET		: in std_logic;
    	    i_REQ		: in std_logic_vector(g_INSTANCES - 1 downto 0);
    	--------------------------------------------------------
	    o_RE_EN		: out std_logic;
    	    o_GRANT		: out std_logic_vector(g_INSTANCES - 1 downto 0)
    	);
    end component;
end bus_master_pkg;
