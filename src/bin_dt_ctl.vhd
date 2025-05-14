library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.float_pkg.all;
use work.bin_dt_ctl_pkg.all;

entity bin_dt_ctl is
    generic(
        node_width : integer;
        link_width : integer;
        data_width : integer;
        span : integer
    );
    port(
	i_clk		        : in std_logic;
	i_reset		        : in std_logic;
	i_node_info	        : in std_logic_vector(node_width - 1 downto 0);
	i_threshold		    : in std_logic_vector(node_width - 1 downto 0);
	i_data_out	        : in std_logic_vector(data_width - 1 downto 0);
	-----------------------------------------------------
	o_RE_node		    : out std_logic;
	o_RE_data    	    : out std_logic;
	o_RE_thr    	    : out std_logic;
	o_node_addr         : out unsigned(link_width - 1 downto 0);
	o_thr_addr	        : out unsigned(link_width - 1 downto 0);
	o_data_addr	        : out unsigned(link_width - 1 downto 0);
	o_class		        : out std_logic_vector(15 downto 0)
    );
end bin_dt_ctl;

architecture arch_bin_dt_ctl of bin_dt_ctl is

-- State machine
type state is (E0, E1, E2, E3, E4, E5, E6, E7);
signal current_s, next_s: state;

-- C node mem
signal LD_c_node_mem, INC_c_node_mem, CL_c_node_mem : std_logic;
signal c_node_mem_out : std_logic_vector(link_width - 1 downto 0);
signal feature, right_node : std_logic_vector(link_width - 1 downto 0);

-- C data mem
signal CL_c_data_mem, INC_c_data_mem : std_logic;
signal c_data_mem_out : std_logic_vector(link_width - 1 downto 0);

-- R class
signal LD_class : std_logic;
signal R_class : std_logic_vector(link_width - 1 downto 0);

signal leaf, go_right, read_node_info : std_logic;

begin

-- State machine

process(current_s, next_s, leaf, go_right)
begin
	case current_s is
	    when E0 => next_s <= E1;
	    when E1 => next_s <= E2;
	    when E2 => if leaf = '0' then next_s <= E3;
					else next_s <= E7;
					end if;
	    when E3 => next_s <= E4;
	    when E4 => if go_right = '1' then next_s <= E5;
					    else next_s <= E6;
					    end if;
	    when E5 => next_s <= E1;
	    when E6 => next_s <= E1;
		when E7 => next_s <= E1;
	end case;
end process;

-- CLK

process(i_clk, i_reset)
begin
	if i_reset = '1' then current_s <= E0;
	elsif rising_edge(i_clk) then current_s <= next_s;
	end if;
end process;

-- LEAF and NODE_ACT

leaf <= i_node_info(0);

-- RE mem signals

o_RE_node <= '1' when current_s = E1 else '0';
o_RE_thr  <= '1' when current_s = E1 else '0';
o_RE_data <= '1' when current_s = E3 else '0';

-- C node mem

LD_c_node_mem <= '1' when current_s = E5 else '0';
INC_c_node_mem <= '1' when current_s = E6 else '0';
CL_c_node_mem <= '1' when current_s = E0 or current_s = E7 else '0';

process(i_clk, CL_c_node_mem)
    begin
	if CL_c_node_mem = '1' then c_node_mem_out <= x"0000";
	elsif rising_edge(i_clk) then
	    if LD_c_node_mem = '1' then
			c_node_mem_out <= right_node;
	    elsif INC_c_node_mem = '1' then
			c_node_mem_out <= std_logic_vector(unsigned(c_node_mem_out) + 2);
	    end if;
	end if;
end process;

o_node_addr <= unsigned(c_node_mem_out);

-- C data mem

INC_c_data_mem <= '1' when current_s = E7 else '0';
CL_c_data_mem <= '1' when current_s = E0 else '0';

process(i_clk, CL_c_data_mem)
    begin
	if CL_c_data_mem = '1' then c_data_mem_out <= x"0000";
	elsif rising_edge(i_clk) then
	    if INC_c_data_mem = '1' then
			c_data_mem_out <= std_logic_vector(unsigned(c_data_mem_out) + span);
	    end if;
	end if;
end process;

feature <= '0' & i_node_info(15 downto 1);
right_node<= i_node_info(31 downto 16);
o_data_addr <= unsigned(c_data_mem_out) + (unsigned(feature));


-- R class

LD_class <= '1' when current_s = E7 else '0';

process(i_clk)
begin
    if rising_edge(i_clk) then
	if LD_class = '1' then
	    R_class <= feature;
	end if;
    end if;
end process;


-- CMP

process(i_threshold, i_data_out)
begin
    if i_data_out = i_threshold then
	go_right <= '0';
    elsif i_data_out < i_threshold then
	go_right <= '0';
    else
	go_right <= '1';
    end if;
end process;


p_ASSERT : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      if ld_class = '1' and next_s = E1 then
        report "Class: " & integer'image(to_integer(unsigned(feature))) severity note;
      end if;
    end if;
  end process p_ASSERT;



end arch_bin_dt_ctl;
