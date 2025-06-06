library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fifo_pkg.all;

entity fifo_tb is
end fifo_tb;

architecture arch_fifo_tb of fifo_tb is

signal clk		: std_logic := '0';
signal re_en		: std_logic;
signal wr_en		: std_logic;
signal wr_data		: std_logic_vector(16 - 1 downto 0);
signal rd_data		: std_logic_vector(16 - 1 downto 0);
signal fifo_empty	: std_logic;
signal fifo_full	: std_logic;


begin

CLASS_FIFO: fifo
generic map(
    g_depth => 4,
    g_width => 16
)
port map(
    i_clk => clk,
    i_re_en => re_en,
    i_wr_en => wr_en,
    i_wr_data => wr_data,
    o_rd_data => rd_data, 
    o_fifo_empty => fifo_empty,
    o_fifo_full	=> fifo_full
);

clk <= not clk after 10 ns;

process
begin
    wait for 20 ns;
    wr_data <= x"FFFF";
    wr_en <= '1';
    wait for 10 ns;
    wr_en <= '0';
    wait for 40 ns;
    wr_data <= x"1243";
    wr_en <= '1';
    wait for 20 ns;
    wr_en <= '0';
    wait for 40 ns;
    wr_data <= x"2346";
    wr_en <= '1';
    wait for 20 ns;
    wr_en <= '0';
    wait for 40 ns;
    wr_data <= x"1111";
    wr_en <= '1';
    wait for 20 ns;
    wr_en <= '0';
    wait for 40 ns;
    wr_data <= x"2222";
    wr_en <= '1';
    wait for 20 ns;
    wr_en <= '0';
    wait for 20 ns;
    re_en <= '1';
    wait for 20 ns;
    re_en <= '0';
    wait for 20 ns;
    re_en <= '1';
    wait for 20 ns;
    re_en <= '0';
    wait;
end process;

end arch_fifo_tb;

