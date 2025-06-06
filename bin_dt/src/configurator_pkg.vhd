library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package configurator_pkg is

    component  configurator is
	generic(
    	    g_dt_number : integer	
    	);
    	port(
    	    i_clk : in std_logic;
    	    i_reset : in std_logic;
    	    i_en_config : in std_logic;
    	    i_data : in std_logic_vector(31 downto 0);
    	    -----------------------------------------------
    	    o_dt_id : out std_logic_vector(7 downto 0);
	    o_config_done : out std_logic;
    	    o_re_data : out std_logic
    	);
    end component;

end configurator_pkg;
