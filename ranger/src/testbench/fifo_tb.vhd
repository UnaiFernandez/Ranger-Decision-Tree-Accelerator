library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.axis_fifo_pkg.all;

entity fifo_tb is
end fifo_tb;

architecture arch_fifo_tb of fifo_tb is

signal clk		: std_logic := '0';
signal reset		: std_logic := '0';
--signal re_en_fifo	: std_logic := '0';
--signal re_en_0		: std_logic := '0';
--signal re_en_1		: std_logic := '0';
--signal wr_en_fifo	: std_logic := '0';
--signal wr_data		: std_logic_vector(32 - 1 downto 0);
--signal rd_data		: std_logic_vector(32 - 1 downto 0);
--signal fifo_empty	: std_logic;
--signal fifo_full	: std_logic;
--signal mode		: std_logic;
--signal addr_0, addr_1	: unsigned(16 - 1 downto 0) := (others => '0');
signal wr_fifo, re_fifo: std_logic := '0';
signal last : std_logic := '0';
signal wr_data : std_logic_vector(31 downto 0);


begin

--CLASS_FIFO: fifo
--generic map(
--    g_DATA_WIDTH => 32,
--    g_ADDR_WIDTH => 16,
--    g_INIT_MEM => '0',
--    g_DEPTH => 10
--)
--port map(
--    i_clk => clk,
--    i_reset => reset,
--    i_re_fifo => re_en_fifo,
--    i_wr_fifo => wr_en_fifo,
--    i_wr_data => wr_data,
--    o_data_0 => rd_data,
--    --o_data_1 => rd_data,
--    o_fifo_empty => fifo_empty,
--    o_fifo_full	=> fifo_full
--);


AXI_FIFO: axis_fifo
generic map(
    g_DATA_WIDTH => 32,
    g_ADDR_WIDTH => 16,
	g_EMPTY_THRESHOLD => 1,
    g_INIT_MEM => '0',
    g_DEPTH => 5
)
port map(
    i_CLK => clk,
    i_reset => reset,
    s00_TVALID => wr_fifo,
    s00_TLAST => last,
    s00_TDATA => wr_data,
    m00_TREADY => re_fifo
    --m00_TVALID =>
    --m00_TLAST =>
    --m00_TDATA =>
    --s00_TREADY =>
);

clk <= not clk after 10 ns;

process
begin

	wait for 30 ns;

	wr_fifo <= '1'; --tvalid
	wr_data <= X"00000001";
    wait for 20 ns;
	wr_data <= X"00000002";
    wait for 20 ns;
	wr_data <= X"00000003";
    wait for 20 ns;
	wr_data <= X"00000004";
    wait for 20 ns;
	wr_data <= X"00000005";
    wait for 20 ns;
	wr_data <= X"00000006";
    wait for 20 ns;
	wr_data <= X"00000007";
    wait for 20 ns;
	wr_data <= X"00000008";
    wait for 20 ns;
    wr_fifo <= '0'; --tvalid


	--wait for 5 ns;
	re_fifo <= '1'; --tready
	wait for 60 ns;
	re_fifo <= '0'; --tready
	wait for 60 ns;
	re_fifo <= '1'; --tready
	wait for 60 ns;
	re_fifo <= '0'; --tready

    wait;
end process;

end arch_fifo_tb;
