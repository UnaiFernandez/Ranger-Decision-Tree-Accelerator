library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package ram_pkg is

    component ram is
    generic (
	g_ADDR_WIDTH : integer;
	g_DATA_WIDTH : integer;
	g_DEPTH	     : integer;
	g_INIT_FILE  : string;
	g_INIT	     : std_logic
    );
    port(
	i_CLK	    : in std_logic;
	i_RE_0 	    : in std_logic;
	i_RE_1 	    : in std_logic;
	i_WE_1 	    : in std_logic;
	i_ADDR_0    : in unsigned(g_addr_width - 1 downto 0);
	i_ADDR_1    : in unsigned(g_addr_width - 1 downto 0);
	i_WR_ADDR   : in unsigned(g_addr_width - 1 downto 0);
	i_DATA_1    : in std_logic_vector(g_data_width - 1 downto 0);
	--------------------------------------------------------------
	o_DATA_0    : out std_logic_vector(g_data_width - 1 downto 0);
	o_DATA_1    : out std_logic_vector(g_data_width - 1 downto 0)
    );
    end component;

end ram_pkg;
