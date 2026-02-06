library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

use work.ranger_pkg.all;
use work.axis_fifo_pkg.all;

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
signal pl_last : std_logic;
signal ps_wr_fifo, ps_last, ps_ready : std_logic := '0';
signal ps_data : std_logic_vector(g_data_width - 1 downto 0);
begin

-- RANGER

    DT_RANGER: ranger
    generic map(
        g_dt_instances  => 6,
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
	o_last		=> pl_last,
        o_fifo_data    	=> out_fifo_data
    );

-- IN FIFO
    IN_AXIS_FIFO: axis_fifo
    generic map(
        g_DATA_WIDTH => 32,
        g_ADDR_WIDTH => 16,
	g_EMPTY_THRESHOLD => 1,
        g_INIT_MEM => '1',
        g_DEPTH => 1024
    )
    port map(
        i_CLK => clk,
        i_reset => reset,
        s00_TVALID => ps_wr_fifo,
        s00_TLAST => ps_last,
        s00_TDATA => ps_data,
        m00_TREADY => rd_fifo_data,
	m00_TDATA => in_fifo_data
    );

-- OUT FIFO
    OUT_AXIS_FIFO: axis_fifo
    generic map(
        g_DATA_WIDTH => 16,
        g_ADDR_WIDTH => 16,
	g_EMPTY_THRESHOLD => 1,
        g_INIT_MEM => '0',
        g_DEPTH => 20
    )
    port map(
        i_CLK => clk,
        i_reset => reset,
        s00_TVALID => wr_fifo_data,
        s00_TLAST => pl_last,
        s00_TDATA => out_fifo_data,
        m00_TREADY => ps_ready
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
