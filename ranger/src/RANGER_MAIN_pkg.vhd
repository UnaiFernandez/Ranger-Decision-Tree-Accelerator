library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package RANGER_MAIN_pkg is
    component RANGER_MAIN is
	generic(
	    g_data_width: integer;
	    g_addr_width: integer
	);
	port(
		clk : in std_logic;
		reset : in std_logic;
		init : in std_logic;
		stop_ranger : out std_logic;
		idle_ranger : out std_logic;
		empty_fifo	: out std_logic;
    	s00_ps_tvalid : in std_logic;	
    	s00_ps_tlast : in std_logic;	
    	s00_ps_tdata : in std_logic_vector(g_data_width - 1 downto 0);	
    	s00_ps_tready : out std_logic;
			
    	m00_ps_tvalid : out std_logic;	
    	m00_ps_tlast : out std_logic;	
    	m00_ps_tdata : out std_logic_vector(g_data_width - 1 downto 0);	
    	m00_ps_tready : in std_logic	
	    --clk : in std_logic;
	    --reset : in std_logic;
	    --init : in std_logic;
        --    i_ps_ready : in std_logic;
     	--    o_re_data : out std_logic;
    	--    o_wr_data : out std_logic;
    	--    o_in_fifo_data	  : out std_logic_vector(g_data_width - 1 downto 0);
    	--    o_out_fifo_data	  : out std_logic_vector(g_addr_width - 1 downto 0)
	    ----class_0 : out std_logic;
	    ----class_1 : out std_logic
    	);
    end component;
end RANGER_MAIN_pkg;
