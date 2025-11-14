library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package RANGER_MAIN_DS_pkg is
    component RANGER_MAIN_DS is
	generic(
	    g_data_width: integer;
	    g_addr_width: integer
	);
	port(
	    clk : in std_logic;
	    reset : in std_logic;
	    init : in std_logic;
            i_ps_ready : in std_logic;
     	    o_re_data : out std_logic;
    	    o_wr_data : out std_logic;
    	    o_in_fifo_data	  : out std_logic_vector(g_data_width - 1 downto 0);
    	    o_out_fifo_data	  : out std_logic_vector(g_addr_width - 1 downto 0);
			o_s : out std_logic_vector(g_addr_width - 1 downto 0);
		o_cl_0 : out std_logic_vector(g_addr_width - 1 downto 0);
 		o_cl_1 : out std_logic_vector(g_addr_width - 1 downto 0);
 		o_cl_2 : out std_logic_vector(g_addr_width - 1 downto 0);
 		o_cl_3 : out std_logic_vector(g_addr_width - 1 downto 0);
 		o_cl_4 : out std_logic_vector(g_addr_width - 1 downto 0);
 		o_cl_5 : out std_logic_vector(g_addr_width - 1 downto 0)
	    --class_0 : out std_logic;
	    --class_1 : out std_logic
    	);
    end component;
end RANGER_MAIN_DS_pkg;
