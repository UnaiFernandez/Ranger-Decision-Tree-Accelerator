library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fifo_pkg.all;

entity fifo_tb is
end fifo_tb;

architecture arch_fifo_tb of fifo_tb is

signal clk		: std_logic := '0';
signal reset		: std_logic := '0';
signal re_en_fifo	: std_logic := '0';
signal re_en_0		: std_logic := '0';
signal re_en_1		: std_logic := '0';
signal wr_en_fifo	: std_logic := '0';
signal wr_data		: std_logic_vector(16 - 1 downto 0);
signal rd_data		: std_logic_vector(16 - 1 downto 0);
signal fifo_empty	: std_logic;
signal fifo_full	: std_logic;
signal mode		: std_logic;
signal addr_0, addr_1	: unsigned(16 - 1 downto 0) := (others => '0');


begin

CLASS_FIFO: fifo
generic map(
    g_DATA_WIDTH => 16,
    g_ADDR_WIDTH => 16,
    g_SPAN => 4,
    g_INIT_MEM => '0',
    g_DEPTH => 10
)
port map(
    i_clk => clk,
    i_reset => reset,
    i_re_fifo => re_en_fifo,
    i_re_0 => re_en_0,
    i_re_1 => re_en_1,
    i_wr_fifo => wr_en_fifo,
    i_wr_data => wr_data,
    i_mode => mode,
    i_addr_0 => addr_0,
    i_addr_1 => addr_1,
    o_data_0 => rd_data,
    --o_data_1 => rd_data,
    o_fifo_empty => fifo_empty,
    o_fifo_full	=> fifo_full
);

clk <= not clk after 10 ns;

process
begin

    -- MODE 0 test
    mode <= '0';
    wait for 20 ns;
    wr_data <= x"FFFF";
    wr_en_fifo <= '1';
    wait for 20 ns;
    wr_data <= x"1243";
    wait for 20 ns;
    wr_data <= x"2346";
    wait for 20 ns;
    wr_data <= x"1111";
    wait for 20 ns;
    wr_data <= x"2222";
    wait for 20 ns;
    wr_en_fifo <= '0';
    wait for 20 ns;
    re_en_fifo <= '1';
    wait for 20 ns;
    re_en_fifo <= '0';
    wait for 20 ns;
    re_en_fifo <= '1';
    --wr_en <= '1';
    wait for 20 ns;
    re_en_fifo <= '0';
    wr_en_fifo <= '1';
    wait for 20 ns;
    wr_en_fifo <= '0';

    wait for 60 ns;
    -- MODE 1 test
    mode <= '1';
    addr_0 <= x"0002";
    addr_1 <= x"0001";
    wait for 20 ns;
    re_en_0 <= '1';
    wait for 20 ns;
    re_en_0 <= '0';
    re_en_1 <= '1';
    wait for 20 ns;
    re_en_1 <= '0';
    re_en_fifo <= '1';
    wait for 20 ns;
    re_en_fifo <= '0';
    wait;
end process;

end arch_fifo_tb;
