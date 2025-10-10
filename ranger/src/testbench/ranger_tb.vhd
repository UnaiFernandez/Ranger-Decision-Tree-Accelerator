library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

use work.ranger_pkg.all;
use work.fifo_pkg.all;

entity ranger_tb is
end ranger_tb;

architecture arch_ranger_tb of ranger_tb is

constant n_width: integer := 32;
constant l_width: integer := 16;
constant depth: integer := 64;
constant g_data_width: integer := 32;
constant g_addr_width: integer := 16;
constant g_init_file: string := "./memory_content/random_forest.txt";

signal clk : std_logic := '1';
signal reset : std_logic := '0';
---------------------------------------------------------------------
signal class: std_logic_vector(15 downto 0);

signal init_button	: std_logic := '0';

-------------------------------------------------------------------------

signal in_fifo_data : std_logic_vector(g_data_width - 1 downto 0);
signal out_fifo_data : std_logic_vector(g_addr_width - 1 downto 0);
signal rd_fifo_data, wr_fifo_data : std_logic;
signal in_fifo_empty, in_fifo_full : std_logic;
signal out_fifo_empty, out_fifo_full : std_logic;
begin

-- RANGER

    DT_RANGER: ranger
    generic map(
        g_dt_instances  => 16,
        g_mem_depth    => 1024,
        g_data_width    => 32,
        g_addr_width    => 16
    )
    port map(
        i_clk	        => clk,
        i_reset	        => reset,
        init	        => init_button,
        i_fifo_data	=> in_fifo_data,
        o_rd_fifo_data	=> rd_fifo_data,
	o_wr_fifo_data	=> wr_fifo_data,
        o_fifo_data    	=> out_fifo_data
    );

-- IN FIFO

    IN_FIFO: fifo
    generic map(
        g_depth	        => 1024,
        g_data_width    => 32,
	g_init_mem	=> '1',
        g_addr_width    => 16
    )
    port map(
        i_clk	        => clk,
        i_reset	        => reset,
        i_re_fifo	=> rd_fifo_data,
        i_wr_fifo	=> '0',
        i_wr_data	=> in_fifo_data, -- not used
        o_data_0	=> in_fifo_data,
        o_data_1	=> in_fifo_data,
        o_fifo_empty    => in_fifo_empty,
        o_fifo_full	=> in_fifo_full
    );

-- OUT FIFO

    OUT_FIFO: fifo
    generic map(
        g_depth	        => 20,
        g_data_width    => 16,
	g_init_mem	=> '0',
        g_addr_width    => 16
    )
    port map(
        i_clk	        => clk,
        i_reset	        => reset,
        i_re_fifo	=> '0',
        i_wr_fifo	=> wr_fifo_data,
        i_wr_data	=> out_fifo_data,
        --o_data_0	=> out_fifo_data, -- not used
        --o_data_1	=> out_fifo_data, -- not used
        o_fifo_empty    => out_fifo_empty,
        o_fifo_full	=> out_fifo_full
    );
clk <= not clk after 10 ns;


process
begin

    reset <= '1';
    wait for 60 ns;
    reset <= '0';
    wait for 20 ns;
    init_button <= '1';
    wait for 20 ns;
    init_button <= '0';

    wait;
end process;

end arch_ranger_tb;
