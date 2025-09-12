library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package ranger_pkg is

    component  ranger is
	generic(
    	    g_dt_instances : integer;
            g_mem_depth : integer;
    	    g_data_width : integer;
    	    g_addr_width : integer
    	);
    	port(
    	    i_clk : in std_logic;
    	    i_reset : in std_logic;
	    init : in std_logic;
    	    i_data_mem : in std_logic_vector(g_data_width - 1 downto 0);
    	    i_wr_data : in std_logic;
    	    o_class_fifo : out std_logic_vector(g_addr_width - 1 downto 0)
    	);
    end component;

end ranger_pkg;
