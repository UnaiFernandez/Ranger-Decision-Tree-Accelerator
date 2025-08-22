library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package sched_pkg is
    component sched is
	generic(
	    g_INSTANCES: integer
    	);
	port(
    	    i_CLK		: in std_logic;
    	    i_RESET		: in std_logic;
    	    i_EMPTY		: in std_logic;
    	    i_REQ_ID		: in std_logic_vector(g_INSTANCES - 1 downto 0);
    	--------------------------------------------------------
    	    o_DEQUEUE		: out std_logic;
    	    o_RE_EN		: out std_logic;
    	    o_GRANT		: out std_logic_vector(g_INSTANCES - 1 downto 0)
    	);
    end component;
end sched_pkg;
