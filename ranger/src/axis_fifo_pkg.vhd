library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package axis_fifo_pkg is
    component axis_fifo is
	generic(
	    g_DATA_WIDTH: integer;
	    g_ADDR_WIDTH: integer;
	    g_EMPTY_THRESHOLD: integer;
	    g_INIT_MEM: std_logic;
	    g_DEPTH: integer
    	);
	port(
    	    i_CLK		: in std_logic;
    	    i_RESET		: in std_logic;
	    s00_TVALID		: in std_logic; 
	    s00_TLAST		: in std_logic; 
	    s00_TDATA		: in std_logic_vector(g_data_width - 1 downto 0); 
	    m00_TREADY		: in std_logic; 
	    ----------------------------------------------------
		fifo_empty 		: out std_logic;
	    m00_TVALID		: out std_logic;
	    m00_TLAST		: out std_logic;
	    m00_TDATA		: out std_logic_vector(g_DATA_WIDTH - 1 downto 0);
	    s00_TREADY		: out std_logic
    	);		
    end component;
end axis_fifo_pkg;
