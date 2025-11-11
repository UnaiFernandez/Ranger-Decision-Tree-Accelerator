library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RANGER_MAIN_DS_pkg.all;

entity RANGER_MAIN_DS_tb is
end RANGER_MAIN_DS_tb;

architecture arch_RANGER_MAIN_DS_tb of RANGER_MAIN_DS_tb is

signal clk		: std_logic := '0';
signal reset		: std_logic := '0';
signal init		: std_logic := '0';
signal ps_ready : std_logic := '0';
signal c 		: std_logic_vector(15 downto 0);
signal data		: std_logic_vector(31 downto 0);
signal re, wr		: std_logic;
--signal c0, c1		: std_logic := '0';

begin

MAIN: RANGER_MAIN_DS
generic map(
    g_data_width => 32,
    g_addr_width => 16
)
port map(
    clk => clk,
    reset => reset,
    init => init,
    i_ps_ready => ps_ready,
    o_re_data => re,
    	o_wr_data => wr, 
    	o_in_fifo_data	=> data, 
    	o_out_fifo_data => c	
);

clk <= not clk after 8 ns;

process
begin 
    reset <= '1';
    wait for 200 ns;
    reset <= '0';
    init <= '1';
    wait for 60 ns;
    init <= '0';
    wait for 3 us;
    ps_ready <= '1';
    wait;
end process;

end arch_RANGER_MAIN_DS_tb;
