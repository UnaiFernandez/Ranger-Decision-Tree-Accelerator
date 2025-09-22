library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dt_accel_pkg.all;
use work.fifo_pkg.all;
use work.ranger_pkg.all;
use work.configurator_pkg.all;

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
	o_class_fifo : out std_logic_vector(g_addr_width - 1 downto 0)
    );
end ranger;

architecture arch_ranger of ranger is

-- State machine
    type state is (E0, E1, E2, E3, E4);
    signal current_s, next_s: state;

-- DT_ACCEL
    signal sel		    : std_logic_vector(g_dt_instances - 1 downto 0);
    signal enable : std_logic;
    signal re_data : std_logic;
    signal data_addr : UNSIGNED(g_ADDR_WIDTH - 1 downto 0);

-- Configurator
    signal re_data_config : STD_LOGIC;
    signal get_data : std_logic;
    signal data_loaded : std_logic;
    signal config_done : std_logic;
    signal up_int_data : std_logic := '0';
    signal en_config : std_logic;
    signal dt_id : std_logic_vector(7 downto 0);

-- Data memory
    signal fifo_empty	: std_logic;
    signal fifo_full	: std_logic;
    signal class	: std_logic_vector(g_addr_width - 1 downto 0);

-- Ranger
    signal result_ready : std_logic_vector(g_dt_instances - 1 downto 0) := (others => '0');
    signal ready : std_logic_vector(g_dt_instances - 1 downto 0) := (others => '1');
    signal calc_result : std_logic;
    signal stop : std_logic := '0';

-- DATA MEMORY
    signal mem_data_0: std_logic_vector(g_data_width - 1 downto 0);
    signal mem_data_1: std_logic_vector(g_data_width - 1 downto 0);
    signal addr_0: unsigned(g_addr_width - 1 downto 0);
    signal addr_1: unsigned(g_addr_width - 1 downto 0);

-- AGGREGATOR
    type mat_t is array (natural range <>) of std_logic_vector;
    signal class_mat : mat_t(0 to g_dt_instances - 1)(15 downto 0);
    signal t_class_mat : mat_t(0 to 15)(g_dt_instances - 1 downto 0);
    signal count_arr : mat_t(0 to 15)(g_dt_instances - 1 downto 0);


-- Count number of set bits
    function bit_count(bits : std_logic_vector) return std_logic_vector is
        variable t: integer := 0;
    begin
        for i in bits'range loop
            if bits(i) = '1' then
    	   t := t + 1;
            end if;
        end loop;
        return std_logic_vector(to_unsigned(t, bits'length));
    end bit_count;

begin
-- State machine

    process(current_s, next_s, init, config_done, data_loaded, calc_result, stop)
    begin
    	case current_s is
    	    when E0 => if init = '1' then next_s <= E1;
    		       else next_s <= E0;
    		       end if;
    	    when E1 => if config_done = '1' then next_s <= E2;
    		       else next_s <= E1;
    		       end if;
    	    when E2 => if data_loaded = '1' then next_s <= E3;
    		       else next_s <= E2;
    		       end if;
	    when E3 => if calc_result = '1' then next_s <= E4;
    		       else next_s <= E3;
    		       end if;
            when E4 => if stop = '1' then next_s <= E0;
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
	    g_K => 16,
            g_DEPTH	 => 256
        )
        port map(
            i_clk	        => i_clk,
            i_reset	        => i_reset,
            i_data_mem	        => mem_data_0, -- TODO: revisar tambien
            i_ENABLE		=> enable,
            i_SEL	        => sel(I),
            i_GET_DATA	        => get_data,
            i_DATA_ADDR		=> data_addr, -- TODO: Remane to avoid confusion
	    i_CALC_RESULT	=> calc_result,
	    o_class	        => class_mat(I),
            o_DONE	        => result_ready(I)
        );
    end generate DT_ACCELERATOR;

    -- create traspose matrix of predicted classes
    process(class_mat)
    begin
	for j in t_class_mat'range loop
	    for i in class_mat'range loop
		t_class_mat(j)(i) <= class_mat(i)(j);
	    end loop;
	end loop;
    end process;

    -- TODO:
    -- Activate a signal when calc done
    -- Count the number of 1's
    process(t_class_mat)
    begin
	for i in t_class_mat'range loop
	    count_arr(i) <= bit_count(t_class_mat(i)); 
	end loop;
    end process;

    -- Find the max
    process(count_arr)
	variable max : integer := 0;
    begin
	for i in count_arr'range loop
	    --if to_integer(unsigned(count_arr(i))) >= max then
	    if count_arr(i) >= count_arr(max) then
		max := i; --to_integer(unsigned(count_arr(i)));
	    end if;
	end loop;
	class <= std_logic_vector(to_unsigned(max, g_addr_width));
    end process;


    calc_result <= '1' when current_s = E3 and result_ready = ready else '0';
    enable <= '1' when current_s = E3 and calc_result = '0' else '0';

-- CONFIGURATOR

    en_config <= '1' when current_s = E1 else '0';
    up_int_data <= '1' when current_s = E2 else '0';

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
        i_up_int_data	=> up_int_data,
        o_dt_id		=> dt_id,
        o_data_addr	=> data_addr,
        o_CONFIG_DONE   => config_done,
        o_get_data	=> get_data,
        o_transfer_done => data_loaded,
        o_re_data	=> re_data_config
    );

-- DATA MEMORY

    DATA_MEM: fifo
    generic map(
        g_depth	        => g_mem_depth,
        g_data_width    => g_data_width,
	g_init_mem	=> '1',
        g_addr_width    => g_addr_width
    )
    port map(
        i_clk	        => i_clk,
        i_reset	        => i_reset,
        i_re_fifo	=> re_data_config,
        i_wr_fifo	=> i_wr_data,
        i_wr_data	=> i_data_mem,
        i_addr_0	=> addr_0,
        i_addr_1	=> addr_1,
        o_data_0	=> mem_data_0,
        o_data_1	=> mem_data_1,
        o_fifo_empty    => fifo_empty,
        o_fifo_full	=> fifo_full
    );

    p_ASSERT : process (i_CLK) is
    begin
        if rising_edge(i_CLK) then
            if current_s = E1 and config_done = '1' then
		report "Configuration done" severity note;
            end if;
	    if current_s = E2 and data_loaded = '1' then
		report "Features loaded" severity note;
            end if;
	    if current_s = E4 then
		report "Final Class:" & integer'image(to_integer(unsigned(class))) severity note;
	    end if;
        end if;
    end process p_ASSERT;

end arch_ranger;
