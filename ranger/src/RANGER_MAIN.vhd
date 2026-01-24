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

		stop_ranger : out std_logic;
		idle_ranger : out std_logic;
		empty_fifo	: out std_logic;
    	s00_ps_tvalid : in std_logic;	
    	s00_ps_tlast : in std_logic;	
    	s00_ps_tdata : in std_logic_vector(g_data_width - 1 downto 0);	
    	s00_ps_tready : out std_logic;
			
    	m00_ps_tvalid : out std_logic;	
    	m00_ps_tlast : out std_logic;	
    	m00_ps_tdata : out std_logic_vector(g_data_width - 1 downto 0);	
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
signal ps_tvalid, ps_tlast, ps_tready : std_logic;
signal ps_data : std_logic_vector(g_addr_width - 1 downto 0);
signal out_data : std_logic_vector(g_addr_width - 1 downto 0);

signal last_inf : std_logic;

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
		i_fifo_empty => in_fifo_empty,
        o_rd_fifo_data	=> rd_fifo_data,
		o_wr_fifo_data	=> wr_fifo_data,
		o_last		=> pl_last,
		o_stop => stop_ranger,
		o_idle => idle_ranger,
        o_fifo_data    	=> out_fifo_data
    );

-- IN FIFO
    IN_AXIS_FIFO: axis_fifo
    generic map(
        g_DATA_WIDTH => 32,
        g_ADDR_WIDTH => 16,
		g_EMPTY_THRESHOLD => 0,
        g_INIT_MEM => '0',
        g_DEPTH => 254
    )
    port map(
        i_CLK => clk,
        i_reset => reset,
        s00_TVALID => s00_ps_tvalid,
        s00_TLAST => s00_ps_tlast,
        s00_TDATA => s00_ps_tdata,
        m00_TREADY => rd_fifo_data,
		m00_TDATA => in_fifo_data,
		fifo_empty => in_fifo_empty
    );

-- OUT FIFO
    OUT_AXIS_FIFO: axis_fifo
    generic map(
        g_DATA_WIDTH => 16,
        g_ADDR_WIDTH => 16,
		g_EMPTY_THRESHOLD => 8,
        g_INIT_MEM => '0',
        g_DEPTH => 20
    )
    port map(
        i_CLK => clk,
        i_reset => reset,
        s00_TVALID => wr_fifo_data,
        s00_TLAST => pl_last,
        s00_TDATA => out_fifo_data,
        s00_TREADY => ps_tready,
		m00_TVALID => ps_tvalid,
		m00_TLAST => ps_tlast,
		m00_TDATA => ps_data,
        m00_TREADY => m00_ps_tready
    );

	--last_inf <= '1' when wr_fifo_data = '1' and pl_last = '1' else '0';
	process(clk, pl_last, wr_fifo_data)
	begin
		if rising_edge(clk) then
			if pl_last = '1' and wr_fifo_data = '1' then
				last_inf <= '1';
			elsif ps_tvalid = '1' then
				last_inf <= '0';
			else
				last_inf <= last_inf;
			end if;
		end if;
	end process;

    m00_ps_tdata <= X"0000" & ps_data;
    m00_ps_tvalid <= ps_tvalid;
	m00_ps_tlast <= '1' when ps_tlast = '1' and last_inf = '1' else '0';
    s00_ps_tready <= ps_tready;
	empty_fifo <= in_fifo_empty;
end arch_RANGER_MAIN;
