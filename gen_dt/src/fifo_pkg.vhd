library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package fifo_pkg is
    component fifo is
	generic(
    	    g_depth : integer;
    	    g_width : integer
    	);
    	port(
    	    i_clk		: in std_logic;
    	    i_re_en		: in std_logic;
    	    i_wr_en		: in std_logic;
    	    i_wr_data	: in std_logic_vector(g_width - 1 downto 0);
    	--------------------------------------------------------
    	    o_rd_data	: out std_logic_vector(g_width - 1 downto 0);
    	    o_fifo_empty	: out std_logic;
    	    o_fifo_full	: out std_logic
    	);
    end component;
end fifo_pkg;
