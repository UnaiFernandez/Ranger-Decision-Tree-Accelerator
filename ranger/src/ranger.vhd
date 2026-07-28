library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dt_accel_pkg.all;
use work.ranger_pkg.all;
use work.configurator_pkg.all;
use work.general_package.all;

entity ranger is
    generic(
    	      g_n_estimators : integer;
    	      g_data_width : integer := 32;
    	      g_addr_width : integer := 16
    );
    port(
            i_clk : in std_logic;
            i_reset : in std_logic;
            init : in std_logic;
            start : in std_logic;
            i_fifo_data : in std_logic_vector(g_data_width - 1 downto 0);
            i_fifo_empty : in std_logic;
            o_rd_fifo_data : out std_logic;
            o_wr_fifo_data : out std_logic;
            o_last : out std_logic;
            o_stop: out std_logic;
            o_idle : out std_logic;
            o_config_done : out std_logic;
            o_fifo_data : out std_logic_vector(g_addr_width - 1 downto 0)
        );
end ranger;

architecture arch_ranger of ranger is

    -- State machine
    type state is (E0, E01, E1, E2, E3, E4, E5);
    --type state is (E0, E01, E1, E2, E3, E4, E5, E8, E6, E7);
    signal current_s, next_s: state;

    -- DT_ACCEL
    signal sel		    : std_logic_vector(g_n_estimators - 1 downto 0);
    signal enable : std_logic;
    signal re_data : std_logic;
    signal data_addr : UNSIGNED(g_addr_width - 1 downto 0);

    -- Configurator
    signal get_data : std_logic;
    signal data_loaded : std_logic;
    signal loaded : std_logic := '0';
    signal config_done : std_logic;
    signal up_int_data : std_logic := '0';
    signal en_config : std_logic;
    signal dt_id : std_logic_vector(7 downto 0);

    -- Data memory
    signal class	: std_logic_vector(g_addr_width - 1 downto 0);
    signal max_class : integer;
    signal class_temp	: std_logic_vector(g_addr_width - 1 downto 0);
    --signal class_old	: std_logic_vector(g_addr_width - 1 downto 0);

    -- Ranger
    signal result_ready : std_logic_vector(g_n_estimators - 1 downto 0) := (others => '0');
    constant const_ready : std_logic_vector(g_n_estimators - 1 downto 0) := (others => '1');
    signal ready :std_logic := '0';
    signal calc_done : std_logic := '0';
    signal stop : std_logic := '0';
    signal en_find_max : std_logic := '0';
    signal inference_number : integer := 1;
    signal dec_inf_counter : std_logic;

-- AGGREGATOR
    signal class_mat : mat_t(0 to g_n_estimators - 1);
--signal sum_mat : cols_t(0 to 15);
    signal sum_mat : cols_t(0 to 3);
    signal sum_mat_r : cols_t(0 to 3);

    signal inc_c, ld_cycles : std_logic;
    signal cycle_count : integer := 0;
    signal sel_cycles : std_logic := '0';
    signal ld_last : std_logic := '0';
    signal last : std_logic := '0';

    signal infer : std_logic_vector(31 downto 0);
    signal idle : std_logic;
    signal dec_sample : std_logic;
    signal num_features : integer;

    signal enable2 : std_logic := '0';

begin
    -- State machine

    process(current_s, next_s, init, i_fifo_empty, config_done, data_loaded, calc_done, stop, ready, calc_done)
    begin
        case current_s is
            when E0 => if init = '1' then next_s <= E01;
                else next_s <= E0;
                end if;
            when E01 => if i_fifo_empty = '0' and config_done = '0' and stop = '0' then next_s <= E1;
                elsif i_fifo_empty = '0' and config_done = '1' and stop = '0' then next_s <= E2;
                else next_s <= E01;
                end if;
            when E1 => if i_fifo_empty = '1' then next_s <= E01;
                elsif config_done = '1' then next_s <= E2;
                else next_s <= E1;
                end if;
            when E2 => if i_fifo_empty = '1' and data_loaded = '0' then next_s <= E01; 
                elsif data_loaded = '1' then next_s <= E3;
                else next_s <= E2;
                end if;
            when E3 => if calc_done = '1' then next_s <= E4;
                else next_s <= E3;
                end if;
            --when E4 => next_s <= E5;
            when E4 => if stop = '1' then next_s <= E5;
                elsif i_fifo_empty = '1' and data_loaded = '0' then next_s <= E01;
                elsif data_loaded = '1' then next_s <= E3;
                else next_s <= E4;
                end if;
            when E5 => next_s <= E01;
        end case;
    end process;

    -- CLK

    process(i_clk, i_reset)
    begin
        if rising_edge(i_clk) then 
            if i_reset = '1' then 
                current_s <= E0;
            else
                current_s <= next_s;
            end if;
        end if;
    end process;


    -- DECODER

    process(dt_id, get_data)
        variable sel_v :std_logic_vector(sel'range);
        variable idx : integer;	
    begin
        sel_v := (others => '0');
        if get_data = '1' then
            sel_v := (others => '1');
        elsif dt_id /= "00000000" then
            idx := to_integer(unsigned(dt_id)) - 1;
            if idx >= sel_v'low and idx <= sel_v'high then
                sel_v(idx) := '1';
            end if;
        end if;
        sel <= sel_v;
    end process;

    -- DT_ACCELERATOR g_n_estimators

    DT_ACCELERATOR:
    for I in 0 to g_n_estimators - 1 generate
        DT_ACCEL_X : dt_accel
        generic map(
            g_data_width => g_data_width,
            g_addr_width => g_addr_width,
            g_K => 4,
            g_DEPTH	 => 1024
        )
        port map(
            i_clk	        => i_clk,
            i_reset	        => i_reset,
            i_data_mem	        => i_fifo_data, -- TODO: revisar tambien
            i_ENABLE		=> enable,
            i_SEL	        => sel(I),
            i_GET_DATA	        => get_data,
            i_DATA_ADDR		=> data_addr, -- TODO: Remane to avoid confusion
            i_CALC_RESULT	=> calc_done,
            i_num_features => num_features,
            o_class	        => class_mat(I),
            o_DONE	        => result_ready(I)
        );
    end generate DT_ACCELERATOR;

    u_aggregator: entity work.aggregator
        port map(
            i_clk => i_CLK,
            i_reset => i_reset,
            i_mat => class_mat,
            i_ready => ready,
            o_done => calc_done,
            o_max => max_class
        );

    o_fifo_data <= std_logic_vector(to_unsigned(cycle_count, class'length)) when sel_cycles = '1' else std_logic_vector(to_unsigned(max_class, class'length));
    o_wr_fifo_data <= '1' when calc_done = '1' or current_s = E5 else '0';

    ready <= '1' when result_ready = const_ready and current_s = E3 else '0';

    --process(i_CLK, result_ready, ready)
    --begin
    --    if rising_edge(i_CLK) then
    --        if result_ready = const_ready and current_s = E3 then
    --            ready <= '1';
    --        else 
    --            ready <= '0';
    --        end if;
    --    end if;
    --end process;
    enable <= '1' when (current_s = E2 or current_s = E4) and data_loaded = '1' else '0';

    process(i_clk)
    begin
        if rising_edge(i_clk) then
                enable2 <= enable;
        end if;
    end process;

    -- CONFIGURATOR

    en_config <= '1' when (current_s = E1 and config_done = '0') else '0';
    up_int_data <= '1' when (current_s = E2 or current_s = E3) and i_fifo_empty = '0' else '0';

    dec_sample <= '1' when current_s = E4 or current_s = E5 else '0';

    CONFIG: configurator
    generic map(
                   g_dt_number	=> g_n_estimators,
                   g_addr_width    => g_addr_width
               )
    port map(
                i_clk		=> i_clk,
                i_reset		=> i_reset,
                i_en_config	=> en_config,
                i_data		=> i_fifo_data, -- REVISAR
                i_up_int_data	=> up_int_data,
                i_empty_fifo => i_fifo_empty,
                i_dec_sample => dec_sample,
                o_infer => infer,
                o_get_data	=> get_data,
                o_dt_id		=> dt_id,
                o_data_addr	=> data_addr,
                o_CONFIG_DONE   => config_done,
                o_transfer_done => data_loaded,
                o_num_features => num_features,
                o_re_data	=> o_rd_fifo_data
            );


    -- INFERENCE COUNTER

    dec_inf_counter <= '1' when calc_done = '1' and current_s = E3 else '0';

    process(i_clk, dec_inf_counter, inference_number, start, i_reset)
    begin
        if rising_edge(i_clk) then
            --if i_reset = '1' or start = '1' or init = '1' then
            if start = '1' or (config_done = '1' and current_s = E1) then
                inference_number <= to_integer(unsigned(infer));
                --inference_number <= 19;
            elsif dec_inf_counter = '1' and inference_number /= 0 then 
                inference_number <= inference_number - 1;
            end if;
        end if;
    end process;


    ld_last <= '1' when inference_number = 0 and current_s = E5 else '0';
    
    process(i_clk, ld_last, start)
    begin
        if rising_edge(i_clk) then
            if start = '1' then
                last <= '0';
            elsif ld_last = '1' then
                last <= '1';
            end if;
        end if;
    end process;
    

    --o_last <= '1' when last = '1' and current_s = E7 else '0';
    o_last <= last;
    stop <= '1' when inference_number = 0 else '0';

    o_stop <= stop;
    idle <= '1' when current_s = E0 or current_s = E01 or (current_s = E4 and i_fifo_empty = '1') else '0';
    o_idle <= idle;
    o_config_done <= config_done;

    -- CLYCLE COUNTER
    inc_c <= '1' when config_done = '1' and stop = '0' and idle = '0' else '0';
    ld_cycles <= '1' when config_done = '1' and stop = '1' else '0';

    sel_cycles <= '1' when stop = '1' else '0';
    process(i_clk, inc_c, start, i_reset)
    begin
        if rising_edge(i_clk) then
            if i_reset = '1' or start = '1' then
                cycle_count <= 0;
            elsif inc_c = '1' then 
                cycle_count <= cycle_count + 1;
            end if;
        end if;
    end process;

    p_ASSERT : process (i_CLK, current_s, config_done, data_loaded) is
    begin
        if rising_edge(i_CLK) then
            if current_s = E1 and config_done = '1' then
                report "Configuration done" severity note;
            end if;
            if current_s = E2 and data_loaded = '1' then
                report "Features loaded" severity note;
            end if;
            if calc_done = '1' then
                report "Final Class:" & integer'image(max_class) severity note;
            end if;
        end if;
    end process p_ASSERT;

end arch_ranger;
