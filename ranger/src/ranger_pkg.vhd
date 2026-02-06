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
    	    i_fifo_data : in std_logic_vector(g_data_width - 1 downto 0);
			i_fifo_empty : in std_logic;
	    o_rd_fifo_data : out std_logic;
    	    o_wr_fifo_data : out std_logic;
    	    o_last : out std_logic;
    	    o_stop : out std_logic;
			o_idle : out std_logic;
    	    o_fifo_data : out std_logic_vector(g_addr_width - 1 downto 0)
    	);
    end component;

end ranger_pkg;
