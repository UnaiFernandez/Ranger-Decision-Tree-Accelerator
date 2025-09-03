library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dt_accel_pkg.all;
use work.ram_pkg.all;
use work.fifo_pkg.all;
use work.ranger_pkg.all;
use work.configurator_pkg.all;
use work.bus_master_pkg.all;

entity ranger is
    generic(
	g_dt_instances : integer;
	g_mem_depth : integer;
	g_data_width : integer;
	g_addr_width : integer
    );
    port(
	i_clk : in std_logic;
	i_reset : in std_logic;
	i_data_mem : in std_logic_vector(g_data_width - 1 downto 0);
	i_wr_data : in std_logic;
	init : in std_logic;
	o_mode : out std_logic;
	o_class_fifo : out std_logic_vector(g_addr_width - 1 downto 0)
    );
end ranger;

architecture arch_ranger of ranger is

    -- State machine
    type state is (E0, E1, E2, E3);
    signal current_s, next_s: state;

    signal re_en		: std_logic;
    signal wr_en		: std_logic;
    signal fifo_empty	: std_logic;
    signal fifo_full	: std_logic;
    signal class		: std_logic_vector(g_addr_width - 1 downto 0);

    signal sel		    : std_logic_vector(g_dt_instances - 1 downto 0);
    signal result_ready : std_logic_vector(g_dt_instances - 1 downto 0) := (others => '0');
    signal ready : std_logic_vector(g_dt_instances - 1 downto 0) := (others => '1');
    signal calc_result : std_logic;
    signal stop : std_logic := '0';


    signal config_done, enable, enable_next, en_config, inc_data_addr: std_logic;
    signal re_data : std_logic;
    signal dt_id : std_logic_vector(7 downto 0);

    signal sel_re_data: std_logic:= '0';
    signal re_data_config, re_data_ctl : STD_LOGIC;
    signal re_data_fifo : std_logic;

    signal inf_done :std_logic;

    signal data_addr : UNSIGNED(g_ADDR_WIDTH - 1 downto 0);

    signal mode : std_logic := '0';

    signal req, grant : std_logic_vector(g_dt_instances - 1 downto 0);

    -- DATA MEMORY

    signal re_0, re_1: std_logic;
    signal wr_mem: std_logic;
    signal rd_mem: std_logic;
    signal wr_mem_data: std_logic_vector(g_data_width - 1 downto 0);
    signal mem_data_0: std_logic_vector(g_data_width - 1 downto 0);
    signal mem_data_1: std_logic_vector(g_data_width - 1 downto 0);
    signal addr_0: unsigned(g_addr_width - 1 downto 0);
    signal addr_1: unsigned(g_addr_width - 1 downto 0);

begin
-- State machine

    process(current_s, next_s, init, config_done, calc_result, stop)
    begin
    	case current_s is
    	    when E0 => if init = '1' then next_s <= E1;
    		       else next_s <= E0;
    		       end if;
    	    when E1 => if config_done = '1' then next_s <= E2;
    		       else next_s <= E1;
    		       end if;
    	    when E2 => if calc_result = '1' then next_s <= E3;
    		       else next_s <= E2;
    		       end if;
            when E3 => if stop = '1' then next_s <= E0;
                    else next_s <= E2;
                    end if;
    	end case;
    end process;

-- CLK

    process(i_clk, i_reset)
    begin
    	if i_reset = '1' then current_s <= E0;
    	elsif rising_edge(i_clk) then current_s <= next_s;
    	end if;
    end process;

    en_config <= '1' when current_s = E1 else '0';

-- DECODER

    process(dt_id)
    begin
        sel <= (others => '0');
        if dt_id /= "00000000" then
            sel(to_integer(unsigned(dt_id) - 1)) <= '1';
        end if;
    end process;

-- DT_ACCELERATOR instances

    DT_ACCELERATOR:
    for I in 0 to g_dt_instances - 1 generate
        DT_ACCEL_X : dt_accel
        generic map(
            g_DATA_WIDTH => g_DATA_WIDTH,
            g_ADDR_WIDTH => g_ADDR_WIDTH,
            g_DEPTH	 => 256
        )
        port map(
            i_clk	        => i_clk,
            i_reset	        => i_reset,
            i_data	        => mem_data_0, -- TODO: revisar tambien
            i_ENABLE	    => enable,
            i_SEL	        => sel(I),
            i_DATA_ADDR	    => data_addr, -- TODO: Remane to avoid confusion
            i_GRANT	        => grant(I),
            o_RE_data	    => req(I),
            o_DONE	        => result_ready(I),
            o_data_addr	    => addr_0, --- TODO: Revisar esta señal
            o_class	        => class
        );
    end generate DT_ACCELERATOR;

    calc_result <= '1' when result_ready = ready else '0';
    enable <= '1' when (current_s = E1 and config_done = '1') or (current_s = E3 and stop = '0') else '0';


-- CONFIGURATOR

    CONFIG: configurator
    generic map(
        g_dt_number	=> g_dt_instances,
        g_addr_width    => g_addr_width
    )
    port map(
        i_clk		=> i_clk,
        i_reset		=> i_reset,
        i_en_config	=> en_config,
        i_data		=> mem_data_0, -- REVISAR
        o_dt_id		=> dt_id,
        o_data_addr	=> data_addr,
        o_CONFIG_DONE   => config_done,
        o_re_data	=> re_data_config
    );

    -- Select who controls RE_DATA signal.
    --sel_re_data <= '1' when current_s = E2 else '0';

    mode <= '1' when current_s = E2 else '0';
    o_mode <= mode;

    --rd_mem <= '1' when (current_s = E1) or (current_s = E2 and calc_result = '1') else '0';
    re_data_fifo <= '1' when current_s = E2 and calc_result = '1' else '0';
    rd_mem <= re_data_config when current_s = E1 else re_data_fifo;

    --rd_mem <= re_data_config when sel_re_data = '0' else re_0;


-- BUS MASTER

    BUSMASTER : bus_master
    generic map(
        g_DATA_WIDTH	=> g_data_width,
        g_ADDR_WIDTH	=> g_addr_width,
        g_INSTANCES	=> g_dt_instances
    )
    port map(
        i_CLK		=> i_clk,
        i_RESET		=> i_reset,
        i_REQ		=> req,
        o_RE_EN	    => re_0,
        o_GRANT		=> grant
    );

-- DATA MEMORY

    DATA_MEM: fifo
    generic map(
        g_depth	        => g_mem_depth,
        g_data_width    => g_data_width,
        g_span	        => 4,  -- TODO: Automatizarlo
	g_init_mem	=> '0',
        g_addr_width    => g_addr_width
    )
    port map(
        i_clk	        => i_clk,
        i_reset	        => i_reset,
        i_re_fifo	    => rd_mem,
        i_re_0	        => re_0,
        i_re_1	        => re_1,
        i_wr_fifo	    => i_wr_data,
        i_wr_data	    => i_data_mem,
        i_mode	        => mode,
        i_addr_0	    => addr_0,
        i_addr_1	    => addr_1,
        o_data_0	    => mem_data_0,
        o_data_1	    => mem_data_1,
        o_fifo_empty    => fifo_empty,
        o_fifo_full	    => fifo_full
    );

    p_ASSERT : process (i_CLK) is
    begin
        if rising_edge(i_CLK) then
            if current_s = E1 and enable = '1' then
    	    report "Configuration done" severity note;
            end if;
        end if;
    end process p_ASSERT;

end arch_ranger;
