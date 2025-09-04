library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dt_accel_pkg.all;
use work.ram_pkg.all;
use work.fifo_pkg.all;

entity dt_accel_tb is
end dt_accel_tb;

architecture arch_dt_accel_tb of dt_accel_tb is

    constant g_data_width: integer := 32;
    constant g_addr_width: integer := 16;

    signal clk : std_logic := '1';
    signal reset : std_logic := '0';
    signal data : std_logic_vector(g_data_width - 1 downto 0);
    ---------------------------------------------------------------------
    signal RE_data : std_logic := '0';
    signal data_addr: unsigned(g_addr_width - 1 downto 0);
    signal class: std_logic_vector(15 downto 0);

    signal re_en		: std_logic;
    signal wr_en		: std_logic;
    signal rd_data		: std_logic_vector(g_addr_width - 1 downto 0);
    signal fifo_empty	: std_logic;
    signal fifo_full	: std_logic;

    signal rd_mem : std_logic := '0';
    
    signal enable, sel, get_data : std_logic := '0';
    signal o_addr_data_mem : unsigned(16 - 1 downto 0);

    signal grant : std_logic;
    signal done : std_logic;

begin

-- DATA_MEM

     DATA_MEM: fifo
    generic map(
        g_depth	        => 256,
        g_data_width    => g_data_width,
	g_init_mem	=> '1',
        g_addr_width    => g_addr_width
    )
    port map(
        i_clk	        => clk,
        i_reset	        => reset,
        i_re_fifo	    => get_data,
        i_wr_fifo	    => '0',
        i_wr_data	    => X"00000000",
        i_addr_0	    => data_addr,
        i_addr_1	    => data_addr,
        o_data_0	    => data,
        o_data_1	    => data,
        o_fifo_empty    => fifo_empty,
        o_fifo_full	    => fifo_full
    );



-- DT_ACCELERATOR

    DT_ACCELERATOR: dt_accel
    generic map(
        g_DATA_WIDTH => 32,
        g_ADDR_WIDTH => 16,
        g_DEPTH => 256
    )
    port map(
        i_clk => clk,
        i_reset => reset,
        i_data_mem => data,
    --    i_RE_CLASS => re_en,
        i_ENABLE => enable,
        i_SEL => sel,
        i_GET_DATA => get_data,
        i_DATA_ADDR => data_addr,
	o_done => done,
        o_class => class
    );


-- Simulation

    clk <= not clk after 10 ns;

    process
    begin
        enable <= '1';
        wait for 20 ns;
        enable <= '0';
        wait for 400 ns;
	get_data <= '1';
	wait for 100 ns;
	get_data <= '0';
        enable <= '1';
        wait for 20 ns;
        enable <= '0';
        wait;
    end process;


end arch_dt_accel_tb;
