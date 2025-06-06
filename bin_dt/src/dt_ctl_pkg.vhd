library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package dt_ctl_pkg is

    component dt_ctl is

        generic(
            node_width : integer;
            link_width : integer;
            data_width : integer;
            span : integer
        );
        port(
            i_clk		    : in std_logic;
            i_reset		    : in std_logic;
            i_node_info		    : in std_logic_vector(node_width - 1 downto 0);
            i_threshold		    : in std_logic_vector(node_width - 1 downto 0);
            i_data_out		    : in std_logic_vector(data_width - 1 downto 0);
            -----------------------------------------------------
            o_RE_node		    : out std_logic;
            o_RE_data		    : out std_logic;
            o_RE_thr		    : out std_logic;
            o_node_addr		    : out unsigned(link_width - 1 downto 0);
            o_thr_addr		    : out unsigned(link_width - 1 downto 0);
            o_data_addr		    : out unsigned(link_width - 1 downto 0);
            o_wr_fifo		    : out std_logic;
            o_class		    : out std_logic_vector(15 downto 0)
        );
    end component;

end dt_ctl_pkg;
