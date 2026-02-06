library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package configurator_pkg is
    component  configurator is
	generic(
    	    g_dt_number : integer;
	    g_ADDR_WIDTH: integer
    	);
    	port(
    	    i_clk : in std_logic;
    	    i_reset : in std_logic;
    	    i_en_config : in std_logic;
    	    i_data : in std_logic_vector(31 downto 0);
    	    i_up_int_data : in std_logic;
				i_empty_fifo	: in std_logic; 
    	    -----------------------------------------------
    	    o_dt_id : out std_logic_vector(7 downto 0);
	    o_data_addr : out unsigned(g_ADDR_WIDTH - 1 downto 0);
	    o_config_done : out std_logic;
    	    o_re_data : out std_logic;
    	    o_transfer_done : out std_logic;
    	    o_get_data : out std_logic
    	);
    end component;

end configurator_pkg;
