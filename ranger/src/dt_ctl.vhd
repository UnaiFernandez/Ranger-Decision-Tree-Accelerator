library ieee;
library ieee_proposed;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.fixed_pkg.all;
--use ieee.float_pkg.all;
use ieee_proposed.fixed_pkg.all;
use ieee_proposed.float_pkg.all;
use work.dt_ctl_pkg.all;

entity dt_ctl is
    generic(
	    g_NODE_WIDTH 		: integer;
	    g_LINK_WIDTH 		: integer;
	    g_DATA_WIDTH 		: integer;
	    g_SPAN 			: integer
	);
    port(
	    i_CLK		        : in std_logic;
	    i_RESET		        : in std_logic;
	    i_ENABLE			: in std_logic;
	    i_NODE_INFO			: in std_logic_vector(g_NODE_WIDTH - 1 downto 0);
	    i_THRESHOLD			: in std_logic_vector(g_NODE_WIDTH - 1 downto 0);
	    i_DATA_OUT			: in std_logic_vector(g_DATA_WIDTH - 1 downto 0);
	    i_CALC_RESULT		: in std_logic;
		-----------------------------------------------------
	    o_RE_NODE			: out std_logic;
	    o_RE_DATA			: out std_logic;
	    o_RE_THR			: out std_logic;
	    o_NODE_ADDR			: out unsigned(g_LINK_WIDTH - 1 downto 0);
	    o_THR_ADDR			: out unsigned(g_LINK_WIDTH - 1 downto 0);
	    o_DATA_ADDR			: out unsigned(g_LINK_WIDTH - 1 downto 0);
	    o_DONE			: out std_logic;
	    o_CLASS		        : out std_logic_vector(15 downto 0)
	);
end dt_ctl;

architecture arch_dt_ctl of dt_ctl is

-- State machine
    type state is (E0, E1, E2, E3, E4, E6, E7);
    signal current_s, next_s, r_state: state;

-- C node mem
    signal LD_c_node_mem, INC_c_node_mem, CL_c_node_mem : std_logic;
    signal c_node_mem_out : std_logic_vector(g_LINK_WIDTH - 1 downto 0);
    signal feature, right_node : std_logic_vector(g_LINK_WIDTH - 1 downto 0);
    signal threshold : float(8 downto -23);

-- R class
    signal LD_class : std_logic;
    signal R_class : std_logic_vector(g_LINK_WIDTH - 1 downto 0);

-- JK
	signal done_j, done_k : std_logic := '0';
	signal done_i: std_logic;

--
    signal leaf, go_right, read_node_info : std_logic;
    signal data_out : float(8 downto -23);

begin

-- State machine

    process(current_s, leaf, go_right, i_enable, i_calc_result)
    begin
	case current_s is
	    when E0 => if i_enable = '1' then next_s <= E1;
					else next_s <= E0;
					end if;
	    when E1 => next_s <= E2;
	    when E2 => next_s <= E3;
	    when E3 => if leaf = '0' then next_s <= E4;
		       else next_s <= E6;
		       end if;
	    when E4 => next_s <= E2;
	    --when E5 => if i_calc_result = '1' then next_s <= E6;
		--       else next_s <= E5;
		--       end if;
	    when E6 => if i_enable = '1' then next_s <= E7;
		       else next_s <= E6;
		       end if;
	    when E7 => next_s <= E2;
	end case;
    end process;

-- CLK, RESET and HALT

    process(i_CLK, i_RESET)
    begin
        if rising_edge(i_CLK) then 
        	if i_RESET = '1' then 
	    		current_s <= E0;
	    		--c_node_mem_out <= (others => '0');
				--feature <= (others => '0');
			else
				current_s <= next_s;
        	end if;
        end if;
    end process;

-- LEAF and NODE_ACT

    leaf <= i_NODE_INFO(0);

-- RE mem signals

    o_RE_NODE <= '1' when current_s = E2 else '0';
    o_RE_THR  <= '1' when current_s = E2 else '0';
    o_RE_DATA <= '1' when current_s = E3 else '0';

-- C node mem

    LD_c_node_mem <= '1' when current_s = E4 and go_right = '1' else '0';
    INC_c_node_mem <= '1' when current_s = E4 and go_right = '0' else '0';
    CL_c_node_mem <= '1' when current_s = E1 or current_s = E6 or i_reset = '1'else '0';

    process(i_CLK, CL_c_node_mem)
    begin
	if rising_edge(i_CLK) then
		if CL_c_node_mem = '1' then 
			c_node_mem_out <= (others => '0');
	    elsif LD_c_node_mem = '1' then
			c_node_mem_out <= right_node;
	    elsif INC_c_node_mem = '1' then
			c_node_mem_out <= std_logic_vector(unsigned(c_node_mem_out) + 2);
	    end if;
	end if;
    end process;

    o_NODE_ADDR <= unsigned(c_node_mem_out);
    o_THR_ADDR <= unsigned(c_node_mem_out) + 1;
    threshold <= to_float(i_THRESHOLD);

    feature <= '0' & i_NODE_INFO(15 downto 1);
    right_node<= i_NODE_INFO(31 downto 16);
    o_DATA_ADDR <= unsigned(feature);
    data_out <= to_float(i_DATA_OUT);


-- R class

    --o_DONE <= '1' when current_s = E5 else '0';
    o_DONE <= done_i;

	done_j <= '1' when current_s = E3 and leaf = '1' else '0';
	process(current_s, i_CALC_RESULT)
	begin
		if current_s = E1 or current_s = E0 or i_CALC_RESULT = '1' then
			done_k <= '1';
		else 
			done_k <= '0';
		end if;
	end process;

	process(i_CLK, done_j, done_k)
	begin
		if rising_edge(i_CLK) then
			if done_j = '0' and done_k = '0' then done_i <= done_i;
			elsif done_j = '0' and done_k = '1' then done_i <= '0';
			elsif done_j = '1' and done_k = '0' then done_i <= '1';
			elsif done_j = '1' and done_k = '1' then done_i <= not done_i;
			else done_i <= done_i;
			end if;
		end if;
	end process;	

-- CMP

    process(threshold, data_out)
    begin
	if data_out = threshold then
	    go_right <= '0';
	elsif data_out < threshold then
	    go_right <= '0';
	else
	    go_right <= '1';
	end if;
    end process;

    ld_class <= '1' when current_s = E3 and leaf = '1' else '0';

    process(i_clk, ld_class)
    begin
        if rising_edge(i_clk) then
    	if ld_class = '1' then
    	    o_class <= feature;
    	end if;
        end if;
    end process;

end arch_dt_ctl;
