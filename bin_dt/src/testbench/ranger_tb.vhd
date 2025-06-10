library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ranger_pkg.all;
use work.fifo_pkg.all;

entity ranger_tb is
end ranger_tb;

architecture arch_ranger_tb of ranger_tb is

constant n_width: integer := 32;
constant l_width: integer := 16;

signal clk : std_logic := '1';
signal reset : std_logic := '0';
signal data : std_logic_vector(n_width - 1 downto 0);
---------------------------------------------------------------------
signal RE_data : std_logic;
signal data_addr: unsigned(l_width - 1 downto 0);
signal class: std_logic_vector(15 downto 0);

signal re_en		: std_logic;
signal wr_en		: std_logic;
signal fifo_empty	: std_logic;
signal fifo_full	: std_logic;
signal class_wr: std_logic_vector(31 downto 0);
signal class_re: std_logic_vector(31 downto 0);

signal init_button	: std_logic;

begin

DT_RANGER: ranger
generic map(
    g_dt_instances => 1,
    g_data_width => 32,
    g_addr_width => 16
)
port map(
    i_clk => clk,
    i_reset => reset,
    init => init_button,
    i_ram_data => class_re,
    o_RE_data => RE_data,
    o_ram_addr => data_addr,
    o_class_fifo => class
);

FIFO_DATA: fifo
generic map(
    g_depth => 8,
    g_data_width=> 32,
    g_addr_width=> 32
)
port map(
    i_clk => clk,
    i_re_en => RE_data,
    i_wr_en => wr_en,
    i_wr_data => class_wr,
    o_rd_data => class_re, 
    o_fifo_empty => fifo_empty,
    o_fifo_full	=> fifo_full
);



clk <= not clk after 10 ns;

process
begin
    wait for 60 ns;
    init_button <= '1';
    class_wr <= x"00000201";
    wr_en <= '1';
    wait for 20 ns;
    init_button <= '0';
    class_wr <= x"11112222";
    wr_en <= '1';
    wait for 20 ns;
    class_wr <= x"11113333";
    wr_en <= '1';
    wait for 20 ns;
    class_wr <= x"00000202";
    wr_en <= '1';
    wait for 20 ns;
    class_wr <= x"11114444";
    wr_en <= '1';
    wait for 20 ns;
    wr_en <= '0';
    wait;
end process;


end arch_ranger_tb;
