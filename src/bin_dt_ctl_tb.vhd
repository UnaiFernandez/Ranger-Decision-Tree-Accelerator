library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.bin_dt_ctl_pkg.all;
use work.ram_pkg.all;
use work.fifo_pkg.all;

entity bin_dt_ctl_tb is
end bin_dt_ctl_tb;

architecture arch_bin_dt_ctl_tb of bin_dt_ctl_tb is

constant n_width: integer := 32;
constant l_width: integer := 16;

signal clk : std_logic := '1';
signal reset : std_logic := '0';
signal node_info : std_logic_vector(n_width - 1 downto 0);
signal threshold : std_logic_vector(n_width - 1 downto 0);
signal data_out : std_logic_vector(n_width - 1 downto 0);
---------------------------------------------------------------------
signal RE_node : std_logic := '0';
signal RE_thr : std_logic := '0';
signal RE_data : std_logic := '0';
signal node_addr: unsigned(l_width - 1 downto 0);
signal thr_addr: unsigned(l_width - 1 downto 0);
signal data_addr: unsigned(l_width - 1 downto 0);
signal class: std_logic_vector(15 downto 0);

signal re_en		: std_logic;
signal wr_en		: std_logic;
signal rd_data		: std_logic_vector(l_width - 1 downto 0);
signal fifo_empty	: std_logic;
signal fifo_full	: std_logic;



begin

NODE_MEM: ram
generic map(
    g_addr_width => l_width,
    g_data_width => n_width,
    g_depth => 256,
    g_init_file => "./memory_content/bin_node_mem_content.txt",
    g_init => '1'
)
port map(
    i_clk => clk,
    i_read_en_0 => RE_node,
    i_read_en_1 => RE_thr,
    i_addr_0 => node_addr,
    i_addr_1 => node_addr + 1,
    o_data_0 => node_info,
    o_data_1 => threshold
);

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
    i_read_en_0 => RE_data,
    i_read_en_1 => RE_data,
    i_addr_0 => data_addr,
    i_addr_1 => data_addr,
    o_data_0 => data_out,
    o_data_1 => data_out
);

DT: bin_dt_ctl
generic map(
    node_width => n_width,
    link_width => l_width,
    data_width => n_width,
    span => 4
)
port map(
    i_clk => clk,
    i_reset => reset,
    i_node_info => node_info,
    i_threshold	=> threshold,
    i_data_out => data_out,
    -----------------------------------------------------
    o_RE_node => RE_node,
    o_RE_data => RE_data,
    o_RE_thr => RE_thr,
    o_node_addr => node_addr,
    o_thr_addr => thr_addr,
    o_data_addr	=> data_addr,
    o_wr_fifo => wr_en,
    o_class => class
);

CLASS_FIFO: fifo
generic map(
    g_depth => 8,
    g_width => l_width
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
    wait;
end process;


end arch_bin_dt_ctl_tb;
