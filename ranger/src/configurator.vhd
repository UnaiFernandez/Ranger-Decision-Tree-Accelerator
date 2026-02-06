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
	o_DATA_ADDR	: out unsigned(g_ADDR_WIDTH - 1 downto 0);
	o_config_done	: out std_logic;
	o_re_data	: out std_logic;
    	o_transfer_done : out std_logic;
    	o_get_data	: out std_logic
    );
end configurator;

architecture arch_configurator of configurator is

-- State machine
    type state is (E0, E1, E2, E3, E3b, E3c, E4, E5);
    signal current_s, next_s: state;

    signal config, last_dt, last_node : std_logic := '0';

-- DT counter
    signal cl_c_dt, ld_c_dt, dec_c_dt : std_logic;
    signal c_dt_out : integer := 0; --range??

-- Node Counter
    signal cl_c_nodes, ld_c_nodes, dec_c_nodes : std_logic;
    signal c_nodes_out : integer := 0; --range??
    signal data_addr : UNSIGNED(g_ADDR_WIDTH - 1 downto 0);
    signal node_addr : UNSIGNED(g_ADDR_WIDTH - 1 downto 0);

-- Register
    signal r_dt_id_out : std_logic_vector(7 downto 0) := (others => '0');
    signal ld_dt_id : std_logic;

-- Load data
    signal last_feature : std_logic;
    signal ld_num_features, dec_num_features : std_logic;
    signal num_features : integer := 0;
    signal r_num_features : integer := 0;
    signal loaded : std_logic := '0';
    signal rst_c_features : std_logic;

signal ld_config_done, config_done : std_logic := '0';

begin


-- State machine

    process(current_s, i_en_config, last_dt, last_node, last_feature, i_up_int_data, loaded)
    begin
    	case current_s is
    	    when E0 => if i_en_config = '1' then next_s <= E1;
		           elsif i_en_config = '0' and i_up_int_data = '1' and loaded = '1' then next_s <= E5;
    		       elsif i_en_config = '0' and i_up_int_data = '1' and loaded = '0' then next_s <= E4;
    		       else next_s <= E0;
    		       end if;
		    when E1 => if i_en_config = '1' then next_s <= E2;
						else next_s <= E0;
						end if;
				when E2 =>  next_s <= E3;
				when E3 => if i_en_config = '0' then next_s <= E3b;
				   elsif last_node = '1' and last_dt = '1' then next_s <= E0;
    		       elsif last_node = '1' and last_dt = '0' then next_s <= E1;
    		       else next_s <= E3;
    		       end if;
		when E3c => next_s <= E3;
		when E3b => if i_en_config = '0' then next_s <= E3b;
				else next_s <= E3c;
				end if;
    	    when E4 => next_s <= E5;
		when E5 => if last_feature = '1' then next_s <= E0;
    			else next_s <= E5;
    			end if;
    	    --when E1 => next_s <= E2;
    	    --when E2 => next_s <= E3;
    	    --when E3 => if last_node = '1' and last_dt = '1' then next_s <= E0;
    		--       elsif last_node = '1' and last_dt = '0' then next_s <= E1;
    		--       else next_s <= E3;
    		--       end if;
    	    --when E4 => next_s <= E5;
    	    --when E5 => if last_feature = '1' then next_s <= E0;
    		--	else next_s <= E5;
    		--	end if;
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


    ld_config_done <= '1' when current_s = E3 and last_node = '1' and last_dt = '1' else '0';

	process(i_CLK, ld_config_done)
	begin
			if rising_edge(i_CLK) then
				    if ld_config_done = '1' then
						config_done <= '1';
				    end if;
		    end if;
	end process;

    --o_config_done <= '1' when current_s = E3 and last_node = '1' and last_dt = '1' else '0';
    o_config_done <= config_done;

    o_transfer_done <= '1' when current_s = E5 and last_feature = '1' else '0';
    
    o_re_data <= '1' when current_s = E1 
		or  current_s = E2
		or (current_s = E3 and last_node = '0' and i_en_config = '1') 
		or current_s = E3c
		or (current_s = E0 and i_up_int_data = '1')
		or current_s = E4
		or (current_s = E5 and last_feature = '0' and i_empty_fifo = '0') else '0'; 



    o_get_data <= '1' when current_s = E5 else '0';

-- DT Counter

    cl_c_dt <= '1' when current_s = E0 else '0';
    dec_c_dt <= '1' when current_s = E3 and last_node = '1' and last_dt = '0' and i_en_config = '1' else '0';
    
    process (i_clk, cl_c_dt)
    begin
        if rising_edge(i_clk) then
        	if cl_c_dt = '1' then 
				c_dt_out <= g_dt_number - 1;
    		elsif dec_c_dt = '1' then
    	    	c_dt_out <= c_dt_out - 1;
    		end if;
        end if;
    end process;
    
    last_dt <= '1' when c_dt_out <= 0 else '0';

-- Node Counter

    cl_c_nodes <= '1' when current_s = E1 else '0';
    ld_c_nodes <= '1' when current_s = E2 else '0';
    dec_c_nodes <= '1' when (current_s = E3 and last_node = '0' and i_en_config = '1') or current_s = E3c else '0';
    
    process (i_clk, cl_c_nodes)
    begin
		if rising_edge(i_clk) then
		 	if cl_c_nodes = '1' then
            	c_nodes_out <= 0;
            	node_addr <= (others => '0');
			elsif ld_c_nodes = '1' then
    	    	c_nodes_out <= to_integer(unsigned(i_data(31 downto 8)) - 1);
    		elsif dec_c_nodes = '1' then
    	    	c_nodes_out <= c_nodes_out - 1;
    			node_addr <= node_addr + 1;
    		end if;
        end if;
    end process;
    
    o_DATA_ADDR <= data_addr when current_s = E5 else node_addr;
    last_node <= '1' when current_s = E3 and c_nodes_out = 0 else '0';

-- DT ID Register

    ld_dt_id <= '1' when current_s = E2 else '0';
    process (i_clk, ld_dt_id)
    begin
        if rising_edge(i_clk) then
    	if ld_dt_id = '1' then
    	    r_dt_id_out <= i_data(7 downto 0);
    	end if;
        end if;
    end process;
    
    o_dt_id <= r_dt_id_out when current_s = E3 else (others => '0');


-- Feature Counter

    rst_c_features <= '1' when (current_s = E0 and i_en_config = '0' and i_up_int_data = '1' and loaded = '1') else '0';
    ld_num_features <= '1' when current_s = E4 else '0';
    dec_num_features <= '1' when current_s = E5 and last_feature = '0' and i_empty_fifo = '0' else '0';

    process(i_clk, rst_c_features, ld_num_features, dec_num_features)
    begin
        if rising_edge(i_clk) then
    		if rst_c_features = '1' then
    	    	data_addr <= (others => '0');
    	    	num_features <= r_num_features;
			elsif ld_num_features = '1' then
	    		data_addr <= (others => '0');
	    		r_num_features <= to_integer(unsigned(i_data) - 1);
	    		num_features <= to_integer(unsigned(i_data) - 1);
    		elsif dec_num_features = '1' then
    	    	num_features <= num_features - 1;
    	    	data_addr <= data_addr + 1;
    		end if;
        end if;
    end process;
    
    last_feature <= '1' when num_features <= 0 else '0';

-- Loaded

    process(i_clk, ld_num_features)
    begin
	if rising_edge(i_clk) then
	    if ld_num_features = '1' then 
		loaded <= '1';
	    end if;
	end if;
    end process;
end arch_configurator;
