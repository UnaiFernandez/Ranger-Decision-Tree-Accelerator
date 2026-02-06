library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package dt_ctl_pkg is

    component dt_ctl is

        generic(
	    g_NODE_WIDTH 		: integer;
	    g_LINK_WIDTH 		: integer;
	    g_DATA_WIDTH 		: integer;
	    g_SPAN 			: integer
        );
        port(
            i_clk		        : in std_logic;
            i_reset		        : in std_logic;
            i_ENABLE			: in std_logic;
            i_node_info		    	: in std_logic_vector(g_NODE_WIDTH - 1 downto 0);
            i_threshold		    	: in std_logic_vector(g_NODE_WIDTH - 1 downto 0);
            i_data_out		    	: in std_logic_vector(g_DATA_WIDTH	 - 1 downto 0);
	    i_CALC_RESULT		: in std_logic;
            -----------------------------------------------------
            o_RE_node			: out std_logic;
            o_RE_data		    	: out std_logic;
            o_RE_thr		    	: out std_logic;
            o_node_addr		    	: out unsigned(g_LINK_WIDTH - 1 downto 0);
            o_thr_addr		    	: out unsigned(g_LINK_WIDTH - 1 downto 0);
            o_data_addr		    	: out unsigned(g_LINK_WIDTH - 1 downto 0);
            o_DONE		    	: out std_logic;
            o_class		        : out std_logic_vector(15 downto 0)
        );
    end component;

end dt_ctl_pkg;
