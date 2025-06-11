library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dt_accel_pkg.all;
use work.ram_pkg.all;
use work.fifo_pkg.all;

entity dt_accel_tb is
end dt_accel_tb;

architecture arch_dt_accel_tb of dt_accel_tb is

constant n_width: integer := 32;
constant l_width: integer := 16;

signal clk : std_logic := '1';
signal reset : std_logic := '0';
signal data : std_logic_vector(n_width - 1 downto 0);
---------------------------------------------------------------------
signal RE_data : std_logic := '0';
signal data_addr: unsigned(l_width - 1 downto 0);
signal class: std_logic_vector(15 downto 0);

signal re_en		: std_logic;
signal wr_en		: std_logic;
signal rd_data		: std_logic_vector(l_width - 1 downto 0);
signal fifo_empty	: std_logic;
signal fifo_full	: std_logic;



begin

DATA_MEM: ram
generic map(
    g_addr_width => l_width,
    g_data_width => n_width,
    g_depth => 256,
    g_init_file => "./memory_content/data_mem_content.txt",
    g_init => '1'
)
port map(
    i_clk => clk,
    i_RE_0 => RE_data,
    i_RE_1 => RE_data,
    i_WE_1 => '0',
    i_addr_0 => data_addr,
    i_addr_1 => data_addr,
    i_data_1 => (others => '0'),
    o_data_0 => data,
    o_data_1 => data
);

DT_ACCELERATOR: dt_accel
generic map(
    g_depth => 256,
    g_data_width => 32,
    g_addr_width => 16
)
port map(
    i_clk => clk,
    i_reset => reset,
    i_data => data,
    o_RE_data => RE_data,
    o_data_addr => data_addr,
    o_class => class,
    o_class_fifo_empty => fifo_empty,
    i_RE_class => re_en
);

CLASS_FIFO: fifo
generic map(
    g_depth => 8,
    g_DATA_WIDTH => l_width,
    g_ADDR_WIDTH => l_width
)
port map(
    i_clk => clk,
    i_re_en => re_en,
    i_wr_en => wr_en,
    i_wr_data => class,
    o_rd_data => rd_data, 
    o_fifo_empty => fifo_empty,
    o_fifo_full	=> fifo_full
);




clk <= not clk after 10 ns;

process
begin
    re_en <= '0';
    wait for 420 ns;
    re_en <= '1';
    wait for 20 ns;
    re_en <= '0';
    wait for 420 ns;
    re_en <= '1';
    wait for 20 ns;
    re_en <= '0';
    wait;
end process;


end arch_dt_accel_tb;
