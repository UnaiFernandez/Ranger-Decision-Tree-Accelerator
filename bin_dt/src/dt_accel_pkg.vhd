library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package dt_accel_pkg is

    component dt_accel is
	generic(
	    g_data_width: integer;
	    g_addr_width: integer
	);    
	port(
    	    i_clk : in std_logic;
    	    i_reset : in std_logic;
    	    i_data : in std_logic_vector;
    	    ----------------------------------------------------
    	    o_RE_data : out std_logic;
    	    o_data_addr : out unsigned(g_addr_width - 1 downto 0);
    	    o_class : out std_logic_vector(15 downto 0)
    	);
    end component;

end dt_accel_pkg;
