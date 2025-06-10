library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.float_pkg.all;
use work.dt_ctl_pkg.all;

entity dt_ctl is
    generic(
    	g_NODE_WIDTH 		: integer;
		g_LINK_WIDTH 		: integer;
		g_DATA_WIDTH 		: integer;
		g_SPAN 				: integer
	);
    port(
	    i_CLK		        : in std_logic;
	    i_RESET		        : in std_logic;
	    i_FIFO_FULL		        : in std_logic;
	    i_NODE_INFO	        : in std_logic_vector(g_NODE_WIDTH - 1 downto 0);
	    i_THRESHOLD		    : in std_logic_vector(g_NODE_WIDTH - 1 downto 0);
	    i_DATA_OUT	        : in std_logic_vector(g_DATA_WIDTH - 1 downto 0);
	-----------------------------------------------------
	    o_RE_NODE		    : out std_logic;
	    o_RE_DATA    	    : out std_logic;
	    o_RE_THR    	    : out std_logic;
	    o_NODE_ADDR         : out unsigned(g_LINK_WIDTH - 1 downto 0);
	    o_THR_ADDR	        : out unsigned(g_LINK_WIDTH - 1 downto 0);
	    o_DATA_ADDR	        : out unsigned(g_LINK_WIDTH - 1 downto 0);
	    o_WR_FIFO		    : out std_logic;
	    o_CLASS		        : out std_logic_vector(15 downto 0)
	);
end dt_ctl;

architecture arch_dt_ctl of dt_ctl is

-- State machine
    type state is (E0, E1, E2, E3, E4, E5);
    signal current_s, next_s: state;

-- C node mem
    signal LD_c_node_mem, INC_c_node_mem, CL_c_node_mem : std_logic;
    signal c_node_mem_out : std_logic_vector(g_LINK_WIDTH - 1 downto 0);
    signal feature, right_node : std_logic_vector(g_LINK_WIDTH - 1 downto 0);
    signal threshold : float(8 downto -23);

-- C data mem
    signal CL_c_data_mem, INC_c_data_mem : std_logic;
    signal c_data_mem_out : std_logic_vector(g_LINK_WIDTH - 1 downto 0);
    signal data_out : float(8 downto -23);

-- R class
    signal LD_class : std_logic;
    signal R_class : std_logic_vector(g_LINK_WIDTH - 1 downto 0);

    signal leaf, go_right, read_node_info : std_logic;

begin

-- State machine

    process(current_s, next_s, leaf, go_right)
    begin
	case current_s is
	    when E0 => next_s <= E1;
	    when E1 => next_s <= E2;
	    when E2 => if leaf = '0' then next_s <= E3;
		       else next_s <= E4;
		       end if;
	    when E3 => next_s <= E1;
	    when E4 => if i_FIFO_FULL = '0' then next_s <= E5;
		       else next_s <= E4;
		       end if;
	    when E5 => next_s <= E1;
	end case;
    end process;

-- CLK

    process(i_CLK, i_RESET)
    begin
	if i_RESET = '1' then current_s <= E0;
	elsif rising_edge(i_CLK) then current_s <= next_s;
	end if;
    end process;

-- LEAF and NODE_ACT

    leaf <= i_NODE_INFO(0);

-- RE mem signals

    o_RE_NODE <= '1' when current_s = E1 else '0';
    o_RE_THR  <= '1' when current_s = E1 else '0';
    o_RE_DATA <= '1' when current_s = E2 else '0';

-- C node mem

    LD_c_node_mem <= '1' when current_s = E3 and go_right = '1' else '0';
    INC_c_node_mem <= '1' when current_s = E3 and go_right = '0' else '0';
    CL_c_node_mem <= '1' when current_s = E0 or current_s = E5 else '0';

    process(i_CLK, CL_c_node_mem)
    begin
	if CL_c_node_mem = '1' then c_node_mem_out <= x"0000";
	elsif rising_edge(i_CLK) then
	    if LD_c_node_mem = '1' then
		c_node_mem_out <= right_node;
	    elsif INC_c_node_mem = '1' then
		c_node_mem_out <= std_logic_vector(unsigned(c_node_mem_out) + 2);
	    end if;
	end if;
    end process;

    o_NODE_ADDR <= unsigned(c_node_mem_out);
    threshold <= to_float(i_THRESHOLD);

-- C data mem

    INC_c_data_mem <= '1' when current_s = E5 else '0';
    CL_c_data_mem <= '1' when current_s = E0 else '0';

    process(i_CLK, CL_c_data_mem)
    begin
	if CL_c_data_mem = '1' then c_data_mem_out <= x"0000";
	elsif rising_edge(i_CLK) then
	    if INC_c_data_mem = '1' then
		c_data_mem_out <= std_logic_vector(unsigned(c_data_mem_out) + g_SPAN);
	    end if;
	end if;
    end process;

    feature <= '0' & i_NODE_INFO(15 downto 1);
    right_node<= i_NODE_INFO(31 downto 16);
    o_DATA_ADDR <= unsigned(c_data_mem_out) + (unsigned(feature));
    data_out <= to_float(i_DATA_OUT);


-- R class

    o_CLASS <= feature;
    o_WR_FIFO <= '1' when current_s = E5 else '0';

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


    p_ASSERT : process (i_CLK) is
    begin
	if rising_edge(i_CLK) then
	    if o_WR_FIFO = '1' and next_s = E1 then
		report "Class: " & integer'image(to_integer(unsigned(feature))) severity note;
	    end if;
	end if;
    end process p_ASSERT;



end arch_dt_ctl;
