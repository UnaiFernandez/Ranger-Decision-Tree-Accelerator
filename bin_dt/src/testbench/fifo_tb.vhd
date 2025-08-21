library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fifo_pkg.all;
use work.sched_pkg.all;

entity fifo_tb is
end fifo_tb;

architecture arch_fifo_tb of fifo_tb is

signal clk		: std_logic := '0';
signal reset		: std_logic := '0';
signal data		: std_logic_vector(32 - 1 downto 0);
signal addr		: unsigned(16 - 1 downto 0) := (others => '0');

signal req		: std_logic_vector(32 - 1 downto 0);
signal grant		: std_logic_vector(32 - 1 downto 0);

begin


SCHEDULER: sched
generic map(
g_DATA_WIDTH => 32,
g_ADDR_WIDTH => 16,
g_INSTANCES => 32
)
port map(
i_CLK => clk,
i_RESET => reset,
i_ADDR => addr,
i_REQ => req,
o_DATA => data,
o_GRANT => grant
);



clk <= not clk after 10 ns;

process
begin
    req <= X"00000000";
    wait for 40 ns;
    req <= X"10000010";
    wait for 500 ns;
    req <= X"10000011";
    --wait for 10 ns;
    --req <= X"10000101";
    --wait for 20 ns;
    --req <= X"00000000";
    wait;
end process;

end arch_fifo_tb;

