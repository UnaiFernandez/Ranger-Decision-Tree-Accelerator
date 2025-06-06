library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ram_pkg.all;

entity ram_tb is
end ram_tb;

architecture arch_ram_tb of ram_tb is

constant c_a_width: integer := 16;
constant c_d_width: integer := 16;

signal clk : std_logic := '0';
signal read_en_0 : std_logic := '0';
signal read_en_1 : std_logic := '0';
signal addr_0 : unsigned(c_a_width - 1 downto 0);
signal addr_1 : unsigned(c_a_width - 1 downto 0);
------------------------------------------------
signal data_0 : std_logic_vector(c_d_width - 1 downto 0);
signal data_1 : std_logic_vector(c_d_width - 1 downto 0);

signal read_link_en : std_logic := '0';
signal link_addr: unsigned(c_a_width - 1 downto 0);
signal link_data: std_logic_vector(c_d_width - 1 downto 0);

begin

NODE_MEM: ram
generic map(
    g_addr_width => c_a_width,
    g_data_width => c_d_width,
    g_init_file => "./memory_content/node_content.txt",
    g_init => '1'
)
port map(
    i_clk => clk,
    i_read_en_0 => read_en_0,
    i_read_en_1 => read_en_1,
    i_addr_0 => addr_0,
    i_addr_1 => addr_1,
    o_data_0 => data_0,
    o_data_1 => data_1
);

LINK_MEM: ram
generic map(
    g_addr_width => c_a_width,
    g_data_width => c_d_width,
    g_init_file => "./memory_content/node_links.txt",
    g_init => '1'
)
port map(
    i_clk => clk,
    i_read_en_0 => read_link_en,
    i_read_en_1 => read_link_en,
    i_addr_0 => link_addr,
    i_addr_1 => link_addr,
    o_data_0 => link_data
);

clk <= not clk after 10 ns;
addr_1 <= addr_0 + 1;

process
begin
    wait for 10 ns;
    addr_0 <= x"0000";
    --addr_1 <= x"0001";
    read_en_0 <= '1';
    read_en_1 <= '1';
    wait for 20 ns;
    read_en_0 <= '0';
    read_en_1 <= '0';
    --addr_1 <= x"0111";
    wait for 10 ns;
    addr_0 <= x"0003";
    read_en_0 <= '1';
    read_en_1 <= '1';
    read_link_en <= '1';
    link_addr <= unsigned(data_1);
    wait for 10 ns;
    read_en_0 <= '0';
    read_en_1 <= '0';
    read_link_en <= '0';
    wait;
end process;


end arch_ram_tb;
