library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dt_ctl_pkg.all;
use work.ram_pkg.all;
use work.fifo_pkg.all;
use work.dt_accel_pkg.all;

entity dt_accel is
    generic(
	g_DATA_WIDTH: integer;
	g_ADDR_WIDTH: integer;
	g_DEPTH: integer
    );    
    port(
	i_CLK : in std_logic;
	i_RESET : in std_logic;
	i_DATA : in std_logic_vector;
	i_RE_CLASS : in std_logic;
	----------------------------------------------------
	o_RE_DATA : out std_logic;
	o_DATA_ADDR : out unsigned(g_ADDR_WIDTH - 1 downto 0);
	o_CLASS : out std_logic_vector(15 downto 0);
	o_CLASS_FIFO_EMPTY : out std_logic
    );
end dt_accel;

architecture arch_dt_accel of dt_accel is

constant n_width: integer := g_DATA_WIDTH;
constant l_width: integer := g_ADDR_WIDTH;

signal node_info : std_logic_vector(n_width - 1 downto 0);
signal threshold : std_logic_vector(n_width - 1 downto 0);
---------------------------------------------------------------------
signal RE_node : std_logic := '0';
signal RE_thr : std_logic := '0';
signal node_addr: unsigned(l_width - 1 downto 0);
signal thr_addr: unsigned(l_width - 1 downto 0);
signal class: std_logic_vector(15 downto 0);

signal re_en		: std_logic;
signal wr_en		: std_logic;
signal rd_data		: std_logic_vector(l_width - 1 downto 0);
signal fifo_empty	: std_logic;
signal fifo_full	: std_logic;



begin

NODE_MEM: ram
generic map(
    g_ADDR_WIDTH => g_ADDR_WIDTH,
    g_DATA_WIDTH => g_DATA_WIDTH,
    g_DEPTH => g_DEPTH,
    g_INIT_FILE => "./memory_content/bin_node_mem_content.txt",
    g_INIT => '1'
)
port map(
    i_CLK => i_clk,
    i_RE_0 => RE_node,
    i_RE_1 => RE_thr,
    i_WE_1 => '0',
    i_ADDR_0 => node_addr,
    i_ADDR_1 => node_addr + 1,
    i_DATA_1 => (others => '0'),
    o_DATA_0 => node_info,
    o_DATA_1 => threshold
);

	
DT: dt_ctl
generic map(
    g_NODE_WIDTH => n_width,
    g_LINK_WIDTH => l_width,
    g_DATA_WIDTH => n_width,
    g_SPAN => 4
)
port map(
    i_clk => i_clk,
    i_reset => i_reset,
    i_FIFO_FULL => fifo_full,
    i_node_info => node_info,
    i_threshold	=> threshold,
    i_data_out => i_data,
    o_RE_node => RE_node,
    o_RE_data => o_RE_data,
    o_RE_thr => RE_thr,
    o_node_addr => node_addr,
    o_thr_addr => thr_addr,
    o_data_addr	=> o_data_addr,
    o_wr_fifo => wr_en,
    o_class => class
);

CLASS_FIFO: fifo
generic map(
    g_DEPTH => 8,
    g_DATA_WIDTH => g_ADDR_WIDTH,
    g_ADDR_WIDTH => g_ADDR_WIDTH
)
port map(
    i_clk => i_clk,
    i_re_en => i_RE_CLASS,
    i_wr_en => wr_en,
    i_wr_data => class,
    o_rd_data => o_class, 
    o_FIFO_EMPTY => fifo_empty,
    o_fifo_full	=> fifo_full
);

o_CLASS_FIFO_EMPTY <= fifo_empty;

end arch_dt_accel;
