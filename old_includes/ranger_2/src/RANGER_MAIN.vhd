library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

use work.RANGER_MAIN_pkg.all;
use work.ranger_pkg.all;
use work.fifo_pkg.all;

entity RANGER_MAIN is
    generic(
		g_data_width: integer := 32;
		g_addr_width: integer := 16
    );
    port(
		clk : in std_logic;
		reset : in std_logic;
		init : in std_logic;
    	s00_ps_tvalid : in std_logic;	
    	s00_ps_tlast : in std_logic;	
    	s00_ps_tdata : in std_logic_vector(g_data_width - 1 downto 0);	
    	s00_ps_tready : out std_logic;
			
    	m00_ps_tvalid : out std_logic;	
    	m00_ps_tlast : out std_logic;	
    	m00_ps_tdata : out std_logic_vector(g_addr_width - 1 downto 0);	
    	m00_ps_tready : in std_logic	
		--i_ps_ready : in std_logic;
		-------------------------------
    	--o_re_data : out std_logic;
    	--o_wr_data : out std_logic;
    	--o_in_fifo_data	  : out std_logic_vector(g_data_width - 1 downto 0);
    	--o_out_fifo_data	  : out std_logic_vector(g_addr_width - 1 downto 0)
		----class_0 : out std_logic;
		----class_1 : out std_logic
    );
end RANGER_MAIN;

architecture arch_RANGER_MAIN of RANGER_MAIN is

signal in_fifo_data : std_logic_vector(g_data_width - 1 downto 0);
signal out_fifo_data : std_logic_vector(g_addr_width - 1 downto 0);
signal rd_fifo_data, wr_fifo_data : std_logic;
signal in_fifo_empty, in_fifo_full : std_logic;
signal out_fifo_empty, out_fifo_full : std_logic;
signal pl_last : std_logic;
signal ps_wr_fifo, ps_last : std_logic := '0';
signal ps_data : std_logic_vector(g_data_width - 1 downto 0) := X"00000000";
signal out_data : std_logic_vector(g_addr_width - 1 downto 0);
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
        i_fifo_data	=> in_fifo_data,
        o_rd_fifo_data	=> rd_fifo_data,
	o_wr_fifo_data	=> wr_fifo_data,
	o_last		=> pl_last,
        o_fifo_data    	=> out_fifo_data
    );

-- IN FIFO
    IN_AXIS_FIFO: fifo
    generic map(
        G_DATA_WIDTH => 32,
        G_MAX_ADDR => 1024
    )
    port map(
        i_CLK => clk,
        i_rst => reset,

		s00_axis_aclk => clk,
		s00_axis_aresetn => reset,
        s00_axis_tvalid => s00_ps_tvalid,
        s00_axis_tlast => s00_ps_tlast,
        s00_axis_tdata => s00_ps_tdata,
		
		m00_axis_aclk => clk,
		m00_axis_aresetn => reset,
        m00_axis_tready => rd_fifo_data,
		m00_axis_tdata => in_fifo_data
    );

-- OUT FIFO
    OUT_AXIS_FIFO: fifo
    generic map(
        G_DATA_WIDTH => 16,
        G_MAX_ADDR => 20
    )
    port map(
        i_CLK => clk,
        i_rst => reset,

		s00_axis_aclk => clk,
		s00_axis_aresetn => reset,
        s00_axis_tvalid => wr_fifo_data,
        s00_axis_tlast => pl_last,
        s00_axis_tdata => out_fifo_data,
        s00_axis_tready => s00_ps_tready,
		
		m00_axis_aclk => clk,
		m00_axis_aresetn => reset,
		m00_axis_tvalid => m00_ps_tvalid,
		m00_axis_tlast => m00_ps_tlast,
		m00_axis_tdata => m00_ps_tdata,
        m00_axis_tready => m00_ps_tready
    );

    --o_re_data <= rd_fifo_data;
    --o_wr_data <= wr_fifo_data;
    --o_in_fifo_data <= in_fifo_data;
    --o_out_fifo_data <= out_data;
end arch_RANGER_MAIN;
