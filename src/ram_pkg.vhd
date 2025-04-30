library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package ram_pkg is

    component ram is
        generic (
       	    g_addr_width : integer;
       	    g_data_width : integer;
       	    G_init_file  : string;
       	    g_init	     : std_logic
        );
        port(
            i_clk	    : in std_logic;
            i_read_en_0 : in std_logic;
            i_read_en_1 : in std_logic;
            i_addr_0    : in unsigned(g_addr_width - 1 downto 0);
            i_addr_1    : in unsigned(g_addr_width - 1 downto 0);
            --------------------------------------------------------------
            o_data_0    : out std_logic_vector(g_data_width - 1 downto 0);
            o_data_1    : out std_logic_vector(g_data_width - 1 downto 0)
        );
    end component;

end ram_pkg;
