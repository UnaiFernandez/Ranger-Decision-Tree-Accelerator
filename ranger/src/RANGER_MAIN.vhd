library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

use work.RANGER_MAIN_pkg.all;
use work.ranger_pkg.all;
use work.axis_fifo_pkg.all;

entity RANGER_MAIN is
    generic(
	g_data_width: integer := 32;
	g_addr_width: integer := 16
    );
    port(
	clk : in std_logic;
	reset : in std_logic;
	init : in std_logic;
    	i_ps_ready : in std_logic;
	-----------------------------
    	o_re_data : out std_logic;
    	o_wr_data : out std_logic;
    	o_last_class : out std_logic;
    	o_in_fifo_data	  : out std_logic_vector(g_data_width - 1 downto 0);
    	o_out_fifo_data	  : out std_logic_vector(g_addr_width - 1 downto 0)
	--class_0 : out std_logic;
	--class_1 : out std_logic
    );
end RANGER_MAIN;

architecture arch_RANGER_MAIN of RANGER_MAIN is

signal in_fifo_data : std_logic_vector(g_data_width - 1 downto 0);
signal out_fifo_data : std_logic_vector(g_addr_width - 1 downto 0);
signal rd_fifo_data, wr_fifo_data : std_logic;
signal in_fifo_empty, in_fifo_full : std_logic;
signal out_fifo_empty, out_fifo_full : std_logic;
signal in_fifo_valid : std_logic;
signal pl_last : std_logic;
signal ps_wr_fifo, ps_last : std_logic := '0';
signal ps_data : std_logic_vector(g_data_width - 1 downto 0) := X"00000000";
signal out_data : std_logic_vector(g_addr_width - 1 downto 0);
signal o_cl_0 : std_logic_vector(g_addr_width - 1 downto 0);
signal o_cl_1 : std_logic_vector(g_addr_width - 1 downto 0);
signal o_cl_2 : std_logic_vector(g_addr_width - 1 downto 0);
signal o_cl_3 : std_logic_vector(g_addr_width - 1 downto 0);
signal o_cl_4 : std_logic_vector(g_addr_width - 1 downto 0);
signal o_cl_5 : std_logic_vector(g_addr_width - 1 downto 0);
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
        init	        => init,
		i_data_valid	=> in_fifo_valid,
        i_fifo_data	=> in_fifo_data,
        o_rd_fifo_data	=> rd_fifo_data,
	o_wr_fifo_data	=> wr_fifo_data,
	o_last		=> pl_last,
		o_class_mat_0 => o_cl_0,
		o_class_mat_1 => o_cl_1,
		o_class_mat_2 => o_cl_2,
		o_class_mat_3 => o_cl_3,
		o_class_mat_4 => o_cl_4,
		o_class_mat_5 => o_cl_5,
        o_fifo_data    	=> out_fifo_data
    );

-- IN FIFO
    IN_AXIS_FIFO: axis_fifo
    generic map(
        g_DATA_WIDTH => 32,
        g_ADDR_WIDTH => 16,
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
		m00_TVALID => in_fifo_valid,
	m00_TDATA => in_fifo_data
    );

-- OUT FIFO
    OUT_AXIS_FIFO: axis_fifo
    generic map(
        g_DATA_WIDTH => 16,
        g_ADDR_WIDTH => 16,
        g_INIT_MEM => '0',
        g_DEPTH => 20
    )
    port map(
        i_CLK => clk,
        i_reset => reset,
        s00_TVALID => wr_fifo_data,
        s00_TLAST => pl_last,
        s00_TDATA => out_fifo_data,
        m00_TREADY => i_ps_ready,
	m00_TDATA => out_data
    );

    o_re_data <= rd_fifo_data;
    o_wr_data <= wr_fifo_data;
	o_last_class <= pl_last;
    o_in_fifo_data <= in_fifo_data;
    o_out_fifo_data <= out_data;
end arch_RANGER_MAIN;
