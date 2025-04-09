library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dt_ctl_pkg.all;
use work.ram_pkg.all;

entity dt_ctl_tb is
end dt_ctl_tb;

architecture arch_dt_ctl_tb of dt_ctl_tb is

constant n_width: integer := 32;
constant l_width: integer := 16;

signal clk : std_logic := '1';
signal reset : std_logic := '0';
signal node_out : std_logic_vector(n_width - 1 downto 0);
signal link_addr_out : std_logic_vector(l_width - 1 downto 0);
signal data_out : std_logic_vector(n_width - 1 downto 0);
---------------------------------------------------------------------
signal RE_node : std_logic := '0';
signal RE_link : std_logic := '0';
signal RE_data : std_logic := '0';
signal node_addr: unsigned(l_width - 1 downto 0);
signal link_addr: unsigned(l_width - 1 downto 0);
signal data_addr: unsigned(l_width - 1 downto 0);
signal class: std_logic_vector(15 downto 0);

begin

NODE_MEM: ram
generic map(
    g_addr_width => l_width,
    g_data_width => n_width,
    g_init_file => "./memory_content/node_content.txt",
    g_init => '1'
)
port map(
    i_clk => clk,
    i_read_en_0 => RE_node,
    i_read_en_1 => RE_node,
    i_addr_0 => node_addr,
    i_addr_1 => node_addr,
    o_data_0 => node_out,
    o_data_1 => node_out
);

LINK_MEM: ram
generic map(
    g_addr_width => l_width,
    g_data_width => l_width,
    g_init_file => "./memory_content/node_links.txt",
    g_init => '1'
)
port map(
    i_clk => clk,
    i_read_en_0 => RE_link,
    i_read_en_1 => RE_link,
    i_addr_0 => link_addr,
    i_addr_1 => link_addr,
    o_data_0 => link_addr_out
);

DATA_MEM: ram
generic map(
    g_addr_width => l_width,
    g_data_width => n_width,
    g_init_file => "./memory_content/data_content.txt",
    g_init => '1'
)
port map(
    i_clk => clk,
    i_read_en_0 => RE_data,
    i_read_en_1 => RE_data,
    i_addr_0 => data_addr,
    i_addr_1 => data_addr,
    o_data_0 => data_out,
    o_data_1 => data_out
);

DT: dt_ctl
generic map(
    node_width => n_width,
    link_width => l_width,
    data_width => n_width,
    span => 4
)
port map(
    i_clk => clk,
    i_reset => reset,
    i_node_out => node_out,
    i_link_addr_out	=> link_addr_out,
    i_data_out => data_out,
    -----------------------------------------------------
    o_RE_node => RE_node,
    o_RE_data => RE_data,
    o_RE_link => RE_link,
    o_node_addr => node_addr,
    o_link_addr => link_addr,
    o_data_addr	=> data_addr,
    o_class => class
);

clk <= not clk after 10 ns;

process
begin
    wait for 20 ns;
    wait;
end process;


end arch_dt_ctl_tb;
