library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fifo_pkg.all;
use work.axis_fifo_pkg.all;

entity axis_fifo is
    generic(
	g_DATA_WIDTH: integer;
	g_ADDR_WIDTH: integer;
	g_INIT_MEM: std_logic;
	g_DEPTH: integer
    );
    port(
	i_CLK			: in std_logic;
    	i_RESET			: in std_logic;
    	s00_TVALID		: in std_logic; 
    	s00_TLAST		: in std_logic; 
    	s00_TDATA		: in std_logic_vector(g_data_width - 1 downto 0); 
    	m00_TREADY		: in std_logic; 
    	----------------------------------------------------
    	m00_TVALID		: out std_logic;
    	m00_TLAST		: out std_logic;
    	m00_TDATA		: out std_logic_vector(g_DATA_WIDTH - 1 downto 0);
    	s00_TREADY		: out std_logic
    );
end axis_fifo;

architecture arch_axis_fifo of axis_fifo is

    signal fifo_full, fifo_empty, fifo_last : std_logic;
begin

    FIFO_MEM: fifo
    generic map(
        g_depth	        => g_DEPTH,
        g_data_width    => g_DATA_WIDTH,
	g_init_mem	=> g_INIT_MEM,
        g_addr_width    => g_ADDR_WIDTH
    )
    port map(
        i_clk	        => i_clk,
        i_reset	        => i_reset,
        i_re_fifo	=> m00_TREADY and not fifo_empty,
        i_wr_fifo	=> s00_TVALID and not fifo_full,
        i_wr_data	=> s00_TDATA, -- not used
        o_data_0	=> m00_TDATA,
        o_data_1	=> m00_TDATA,
        o_fifo_empty    => fifo_empty,
	o_fifo_last	=> fifo_last,
        o_fifo_full	=> fifo_full
    );

    m00_TVALID <= '1' when fifo_empty = '0' else '0';
    m00_TLAST <= fifo_last;
    s00_TREADY <= '1' when fifo_full = '0' else '0';

end arch_axis_fifo;
