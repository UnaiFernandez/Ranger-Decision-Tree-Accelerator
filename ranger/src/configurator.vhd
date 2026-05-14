library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.configurator_pkg.all;

entity configurator is
    generic(
               g_dt_number	: integer;
               g_ADDR_WIDTH	: integer
           );
    port(
            i_clk		: in std_logic;
            i_reset		: in std_logic;
            i_en_config	: in std_logic;
            i_data		: in std_logic_vector(31 downto 0);
            i_up_int_data	: in std_logic;
            i_empty_fifo	: in std_logic; 
            -----------------------------------------------
            o_dt_id		: out std_logic_vector(7 downto 0);
            o_infer : out std_logic_vector(31 downto 0);
            o_DATA_ADDR	: out unsigned(g_ADDR_WIDTH - 1 downto 0);
            o_config_done	: out std_logic;
            o_re_data	: out std_logic;
            o_transfer_done : out std_logic;
            o_get_data	: out std_logic
        );
end configurator;

architecture arch_configurator of configurator is

    -- State machine
    type state is (E0, E1, E2, E3, E4, E5);
    signal current_s, next_s: state;

    signal ld_num_labels : std_logic := '0';
    signal num_labels : unsigned(31 downto 0);
    -- dt_id
    signal ld_dt_id : std_logic := '0';
    signal dt_id : std_logic_vector(7 downto 0);
    -- delayed i_en_config
    signal d_en_config : std_logic;
    -- delayed i_up_int_data
    signal d_up_int_data : std_logic;
    -- delayed i_empty_fifo
    signal d_empty_fifo : std_logic;
    -- node counter
    signal cl_node_counter : std_logic := '0';
    signal dec_node_counter : std_logic := '0';
    signal dec_2 : std_logic := '0';
    signal last_node : std_logic := '0';
    signal copy_dt_id : std_logic := '0';
    signal node_counter : integer;
    signal node_addr : unsigned(g_ADDR_WIDTH -1 downto 0);
    signal dt_id_addr : unsigned(g_ADDR_WIDTH -1 downto 0);
    --dt counter
    signal cl_dt_counter : std_logic := '0';
    signal dec_dt_counter : std_logic := '0';
    signal last_dt : std_logic := '0';
    signal dt_counter : integer := g_dt_number - 1;
    --reg config done
    signal ld_config_done : std_logic := '0';
    signal cl_config_done : std_logic := '0';
    signal config_done: std_logic := '0';
    --update internal data
    signal loaded : std_logic := '0';
    signal ld_num_features : std_logic := '0';
    signal cl_num_features : std_logic := '0';
    signal dec_num_features : std_logic := '0';
    signal last_feature : std_logic := '0';
    signal num_features : integer := 0;
    signal r_num_features : integer := 0;
    signal data_addr : unsigned(g_ADDR_WIDTH -1 downto 0);
    signal base_data_addr : unsigned(g_ADDR_WIDTH -1 downto 0) := to_unsigned(511, g_ADDR_WIDTH);
    -- re_en counter
    signal cl_re_en_counter : std_logic := '0';
    signal dec_re_en_counter : std_logic := '0';
    signal re_en_counter : integer;
    signal re_data : std_logic := '0';


begin


    -- State machine
    process(current_s, i_en_config, last_node, last_dt, i_up_int_data, loaded, last_feature, d_en_config, d_up_int_data)
    begin
        case current_s is
            when E0 => if i_en_config = '1' then next_s <= E1;
                    elsif i_en_config = '0' and i_up_int_data = '1' and loaded = '0' then next_s <= E4;
                    elsif i_en_config = '0' and i_up_int_data = '1' and loaded = '1' then next_s <= E5;
                    else next_s <= E0;
                    end if;
            when E1 => if i_en_config = '1' then next_s <= E2;
                    else next_s <= E1;
                    end if;
            when E2 => if i_en_config = '1' then next_s <= E3;
                    else next_s <= E2;
                    end if;
            when E3 => if d_en_config = '1' and last_node = '1' and last_dt = '0' then next_s <= E1;
                    elsif d_en_config = '1' and last_node = '1' and last_dt = '1' then next_s <= E0;
                    else next_s <= E3;
                    end if;
            when E4 => if i_up_int_data = '1' then next_s <= E5;
                    else next_s <= E4;
                    end if;
            when E5 => if d_up_int_data = '1' and last_feature = '1' then next_s <= E0;
                    else next_s <= E5;
                    end if;
        end case;
    end process;


    -- CLK

    process(i_clk, i_reset)
    begin
        if rising_edge(i_clk) then 
            if i_reset = '1' then 
                current_s <= E0;
                cl_config_done <= '1';
            else
                current_s <= next_s;
                cl_config_done <= '0';
            end if;
        end if;
    end process;

    re_data <= '1' when (current_s = E0 and i_en_config = '1') --leer cabecera
                or (current_s = E0 and i_up_int_data = '1') 
                or (current_s = E1 and i_en_config = '1') 
                or (current_s = E2 and i_en_config = '1') 
                or (current_s = E3 and last_node = '0' and i_en_config = '1') 
                or (current_s = E3 and re_en_counter = 1 and i_en_config = '1')
                or (current_s = E4 and i_up_int_data = '1') 
                or (current_s = E5 and last_feature = '0' and i_up_int_data = '1') 
                or (current_s = E5 and re_en_counter = 1 and i_up_int_data = '1') else '0';

    o_re_data <= re_data;
    --o_get_data <= '1' when current_s = E5 and i_empty_fifo = '0' else '0';
    o_get_data <= '1' when current_s = E5 and d_empty_fifo = '0' else '0';

    -- num labels register
    ld_num_labels <= '1' when current_s = E0 and i_en_config = '1' else '0';

    process(i_CLK)
    begin
        if rising_edge(i_clk) then
            if ld_num_labels = '1' then
                num_labels <= unsigned(i_data);
            end if;
        end if;
    end process;

    o_infer <= std_logic_vector(num_labels);
    -- DT ID Register

    ld_dt_id <= '1' when current_s = E2 and d_en_config = '1' else '0';
    process (i_clk, ld_dt_id)
    begin
        if rising_edge(i_clk) then
            if ld_dt_id = '1' then
                dt_id <= i_data(7 downto 0);
            end if;
        end if;
    end process;

    --o_dt_id <= dt_id;
    o_dt_id <= dt_id when current_s = E3 else (others => '0');

    --delayed en_config
    process(i_clk, i_en_config)
    begin
        if rising_edge(i_clk) then
            d_en_config <= i_en_config;
        end if;
    end process;    

    --delayed i_up_int_data
    process(i_clk, i_up_int_data)
    begin
        if rising_edge(i_clk) then
            d_up_int_data <= i_up_int_data;
        end if;
    end process; 

    --delayed empty_fifo
    process(i_clk, i_empty_fifo)
    begin
        if rising_edge(i_clk) then
            d_empty_fifo <= i_empty_fifo;
        end if;
    end process;

    -- re_en counter

    cl_re_en_counter <= '1' when (current_s = E2 and d_en_config = '1') 
                        or current_s = E4 
                        or (current_s = E0 and i_up_int_data = '1' and loaded = '1') else '0';

    dec_re_en_counter <= '1' when (current_s = E3 and re_data = '1') or (current_s = E5 and re_data = '1') else '0';

    process(i_clk, cl_re_en_counter, dec_re_en_counter)
    begin
        if rising_edge(i_clk) then
            if cl_re_en_counter = '1' then
                if config_done = '1' then
                    re_en_counter <= r_num_features;
                else
                    re_en_counter <= to_integer(unsigned(i_data(20 downto 8))-1);
                end if;
            elsif dec_re_en_counter = '1' then
                re_en_counter <= re_en_counter - 1;
            end if;
        end if;
    end process;

    -- Node counter

    cl_node_counter <= '1' when current_s = E2 and d_en_config = '1' else '0';
    dec_node_counter <= '1' when current_s = E3 and last_node = '0' and d_en_config = '1' else '0';
    copy_dt_id <= '1' when current_s = E3 and last_node = '1' else '0';

    process(i_clk, cl_node_counter, dec_node_counter, copy_dt_id)
    begin
        if rising_edge(i_clk) then
            if cl_node_counter = '1' then
                node_counter <= to_integer(unsigned(i_data(20 downto 8)) -1);
                node_addr <= (others => '0');
            elsif copy_dt_id = '1' then
                node_addr <= dt_id_addr + 1;
            elsif dec_node_counter = '1' then
                node_counter <= node_counter - 1;
                node_addr <= node_addr + 1;
                dt_id_addr <= node_addr + 1;
            end if;
        end if;
    end process;

    last_node <= '1' when current_s = E3 and node_counter = 0 else '0';
    o_DATA_ADDR <= (base_data_addr - data_addr) when current_s = E5 else node_addr;

    -- DT counter

    cl_dt_counter <= '1' when current_s = E0 and d_en_config = '1' else '0';
    dec_dt_counter <= '1' when current_s = E3 and last_node = '1' and last_dt = '0' and d_en_config = '1' else '0';

    process(i_clk, cl_node_counter, dec_node_counter)
    begin
        if rising_edge(i_clk) then
            if cl_dt_counter = '1' then
                dt_counter <= g_dt_number - 1;
            elsif dec_dt_counter = '1' then
                dt_counter <= dt_counter - 1;
            end if;
        end if;
    end process;

    last_dt <= '1' when current_s = E3 and dt_counter = 0 else '0';

    ld_config_done <= '1' when current_s = E3 and last_node = '1' and last_dt = '1' and re_en_counter = 0 else '0';
    process(i_clk, ld_config_done, cl_config_done)
    begin
        if rising_edge(i_clk) then
            if cl_config_done = '1' then
                config_done <= '0';
            elsif ld_config_done = '1' then
                config_done <= '1';
            end if;
        end if;
    end process;

    o_config_done <= config_done;

    o_transfer_done <= '1' when current_s = E5 and last_feature = '1' and re_en_counter = 0 else '0';

    
    -- Num features counter

    cl_num_features <= '1' when (current_s = E0 and i_en_config = '0' and i_up_int_data = '1' and loaded = '1') else '0';
    ld_num_features <= '1' when current_s = E0 and i_up_int_data = '1' and loaded = '0' else '0';
    dec_num_features <= '1' when current_s = E5 and last_feature = '0' and d_up_int_data = '1' else '0';

    process(i_clk, cl_num_features, ld_num_features, dec_num_features)
    begin
        if rising_edge(i_clk) then
            if cl_num_features = '1' then
                data_addr <= (others => '0');
                num_features <= r_num_features;
            elsif ld_num_features = '1' then
                data_addr <= (others => '0');
                r_num_features <= to_integer(unsigned(i_data(7 downto 0)) - 1);
                num_features <= to_integer(unsigned(i_data(7 downto 0)) - 1);
            elsif dec_num_features = '1' then
                num_features <= num_features - 1;
                data_addr <= data_addr + 1;
            end if;
        end if;
    end process;

    last_feature <= '1' when num_features <= 0 else '0';
    -- Loaded

    process(i_clk, i_reset, ld_num_features)
    begin
        if rising_edge(i_clk) then
            if i_reset = '1' then
                loaded <= '0';
            elsif ld_num_features = '1' then
                loaded <= '1';
            end if;
        end if;
    end process;

end arch_configurator;
