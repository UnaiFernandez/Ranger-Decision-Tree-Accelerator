library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package fifo_pkg is
    component fifo is
	generic(
	    g_DATA_WIDTH: integer;
	    g_ADDR_WIDTH: integer;
	    g_INIT_MEM: std_logic;
	    g_DEPTH: integer
    	);
	port(
    	    i_CLK		: in std_logic;
    	    i_RESET		: in std_logic;
    	    i_RE_FIFO		: in std_logic;
    	    i_WR_FIFO		: in std_logic;
    	    i_WR_DATA		: in std_logic_vector(g_DATA_WIDTH - 1 downto 0);
    	--------------------------------------------------------
    	    o_DATA_0		: out std_logic_vector(g_DATA_WIDTH - 1 downto 0);
    	    o_DATA_1		: out std_logic_vector(g_DATA_WIDTH - 1 downto 0);
    	    o_FIFO_EMPTY	: out std_logic;
    	    o_FIFO_LAST		: out std_logic;
    	    o_FIFO_FULL		: out std_logic
    	);
    end component;
end fifo_pkg;
