library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RANGER_MAIN_pkg.all;
use work.axis_fifo_pkg.all;

entity RANGER_MAIN_tb is
end RANGER_MAIN_tb;

architecture arch_RANGER_MAIN_tb of RANGER_MAIN_tb is

signal clk		: std_logic := '0';
signal reset		: std_logic := '0';
signal init		: std_logic := '0';
signal ps_ready : std_logic := '0';
signal c 		: std_logic_vector(15 downto 0);
signal ps_data		: std_logic_vector(31 downto 0);
signal re, wr, ps_last, ps_valid :std_logic;
signal trampa: std_logic := '0';
signal ready : std_logic;
--signal c0, c1		: std_logic := '0';

begin

MAIN: RANGER_MAIN
generic map(
    g_data_width => 32,
    g_addr_width => 16
)
port map(
    clk => clk,
    reset => reset,
    init => init,
	s00_ps_tvalid => trampa,
   	s00_ps_tlast => ps_last,
   	s00_ps_tdata =>	ps_data,
	s00_ps_tready => ready,
   	m00_ps_tready => ps_ready
    --i_ps_ready => ps_ready,
    --o_re_data => re,
    --	o_wr_data => wr, 
    --	o_in_fifo_data	=> data, 
    --	o_out_fifo_data => c	
);

	-- DATA FIFO
    DATA_AXIS_FIFO: axis_fifo
    generic map(
        g_DATA_WIDTH => 32,
        g_ADDR_WIDTH => 16,
		g_EMPTY_THRESHOLD => 0,
        g_INIT_MEM => '1',
    g_init_file	    => "./memory_content/random_forest_bin.txt",
        g_DEPTH => 202
    )
    port map(
        i_CLK => clk,
        i_reset => reset,
        s00_TVALID => '0',
        s00_TLAST => '0',
        s00_TDATA => X"00000000",
        m00_TREADY => trampa,
		m00_TVALID => ps_valid,
		m00_TLAST => ps_last,
		m00_TDATA => ps_data
    );



clk <= not clk after 8 ns;

process
begin 
    reset <= '1';
    wait for 200 ns;
    reset <= '0';
    wait for 200 ns;
	trampa <= '1';
	wait for 600 ns;
    init <= '1';
    wait for 60 ns;
    init <= '0';
	wait for 400 ns;
	trampa <= '0';
	wait for 200 ns;
	trampa <= '1';
	wait for 400 ns;
	trampa <= '0';
	wait for 200 ns;
	trampa <= '1';
    wait for 1390 ns;
	trampa <= '0';
    ps_ready <= '1';
    wait;
end process;

end arch_RANGER_MAIN_tb;
