library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package sched_pkg is
    component sched is
	generic(
	    g_DATA_WIDTH: integer;
	    g_ADDR_WIDTH: integer;
	    g_INSTANCES: integer
    	);
	port(
    	    i_CLK		: in std_logic;
    	    i_RESET		: in std_logic;
    	    i_ADDR		: in unsigned(g_ADDR_WIDTH - 1 downto 0);
    	    i_REQ		: in std_logic_vector(g_INSTANCES - 1 downto 0);
    	--------------------------------------------------------
    	    o_DATA		: out std_logic_vector(g_DATA_WIDTH - 1 downto 0);
    	    o_GRANT		: out std_logic_vector(g_INSTANCES - 1 downto 0)
    	);
    end component;
end sched_pkg;
