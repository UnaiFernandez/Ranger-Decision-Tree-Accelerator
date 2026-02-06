library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.test_comb_pkg.all;
use work.axis_fifo_pkg.all;

entity test_comb_tb is
end test_comb_tb;

architecture arch_test_comb_tb of test_comb_tb is

signal clk		: std_logic := '0';
signal reset		: std_logic := '0';


signal valid_0: std_logic := '0';
signal ready_0: std_logic := '0';
signal last_0 : std_logic := '0';
signal data_0 : std_logic_vector(31 downto 0);


signal valid_in: std_logic;
signal ready_in: std_logic;
signal last_in : std_logic;
signal data_in : std_logic_vector(31 downto 0);


signal valid_out: std_logic := '0';
signal ready_out: std_logic := '0';
signal last_out : std_logic := '0';
signal data_out : std_logic_vector(31 downto 0) := x"00000000";



begin

IN_FIFO: axis_fifo
generic map(
    g_DATA_WIDTH => 32,
    g_ADDR_WIDTH => 16,
    g_INIT_MEM => '1',
    g_DEPTH => 10
)
port map(
	i_CLK => clk,
    i_reset => reset,
    s00_TVALID => valid_0,
    s00_TLAST => last_0,
    s00_TDATA => data_0,
    m00_TREADY => ready_in,
	------------------------
    m00_TVALID => valid_in,
    m00_TLAST => last_in,
    m00_TDATA => data_in
    --s00_TREADY =>

);

AXI_TEST: test_comb
port map(
    s00_ACLK => clk,
    s00_ARESETN => reset,
    m00_ACLK => clk,
    m00_ARESETN => reset,
    s00_TVALID => valid_in,
    s00_TLAST => last_in,
    s00_TDATA => data_in,
    m00_TREADY => ready_out,
	-------------------------
    m00_TVALID => valid_out,
    m00_TLAST => last_out,
    m00_TDATA => data_out,
    s00_TREADY => ready_in

);


OUT_FIFO: axis_fifo
generic map(
    g_DATA_WIDTH => 32,
    g_ADDR_WIDTH => 16,
    g_INIT_MEM => '0',
    g_DEPTH => 10
)
port map(
    i_CLK => clk,
    i_reset => reset,
    s00_TVALID => valid_out,
    s00_TLAST => last_out,
    s00_TDATA => data_out,
    m00_TREADY => ready_0,
	----------------------------
    s00_TREADY => ready_out
);
clk <= not clk after 10 ns;

process
begin

    ---- MODE 0 test
    --wait for 20 ns;
    --data <= x"0000FFFF";
    --valid <= '1';
    --wait for 20 ns;
    ----data <= x"00001243";
    --wait for 20 ns;
    ----data <= x"00002346";
    --ready <= '1';
    --wait for 20 ns;
    ----data <= x"00001111";
    --wait for 20 ns;
    ----data <= x"00002222";
    --wait for 20 ns;
    --valid <= '0';
    --ready <= '0';
    wait;
end process;

end arch_test_comb_tb;
