library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.float_pkg.all;
use work.dt_ctl_pkg.all;

entity dt_ctl is
    generic(
        node_width : integer;
        link_width : integer;
        data_width : integer;
        span : integer
    );
    port(
	i_clk		        : in std_logic;
	i_reset		        : in std_logic;
	i_node_out	        : in std_logic_vector(node_width - 1 downto 0);
	i_link_addr_out	: in std_logic_vector(link_width - 1 downto 0);
	i_data_out	        : in std_logic_vector(data_width - 1 downto 0);
	-----------------------------------------------------
	o_RE_node		    : out std_logic;
	o_RE_data    	    : out std_logic;
	o_RE_link    	    : out std_logic;
	o_node_addr         : out unsigned(link_width - 1 downto 0);
	o_link_addr	        : out unsigned(link_width - 1 downto 0);
    o_data_addr	        : out unsigned(link_width - 1 downto 0);
	o_class		        : out std_logic_vector(15 downto 0)
    );
end dt_ctl;

architecture arch_dt_ctl of dt_ctl is

-- State machine
type state is (E0, E1, E2, E3, E4, E5, E6,E7, E8, E9, E10);
signal current_s, next_s: state;

-- C node mem
signal LD_c_node_mem, INC_c_node_mem, CL_c_node_mem : std_logic;
signal c_node_mem_out : std_logic_vector(link_width - 1 downto 0);

-- C link mem
signal LD_c_link_mem, INC_c_link_mem : std_logic;
signal c_link_mem_out : std_logic_vector(link_width - 1 downto 0);
signal o_link_addr_base : std_logic_vector(link_width - 1 downto 0);

-- C data mem
signal CL_c_data_mem, INC_c_data_mem : std_logic;
signal c_data_mem_out : std_logic_vector(link_width - 1 downto 0);

-- R feature
signal LD_feature : std_logic;
signal r_feature_out : std_logic_vector(link_width - 2 downto 0);

-- R value
signal LD_value : std_logic;
signal r_value_out : std_logic_vector(node_width - 1 downto 0);

-- R class
signal LD_class : std_logic;
signal r_class_out : std_logic_vector(link_width - 2 downto 0);

-- CMP
signal eq, gr, ls, gr_eq, ls_eq: std_logic;
signal cmd : std_logic_vector(2 downto 0);
signal value : float(8 downto -23);
signal data_out : float(8 downto -23);

--JK
signal CL_jk, PR_jk : std_logic;

signal leaf, node_sel, read_node_info : std_logic;

begin

-- State machine

process(current_s, next_s, leaf, node_sel)
begin
	case current_s is
	    when E0 => next_s <= E1;
	    when E1 => if read_node_info = '1' then next_s <= E2;
					else next_s <= E3;
					end if;
	    when E2 => if leaf = '1' then next_s <= E10;
            else next_s <= E3;
            end if;
        when E3 => next_s <= E4;
	    when E4 => next_s <= E5;
	    when E5 => if node_sel = '1' then next_s <= E6;
			else next_s <= E8;
			end if;
	    when E6 => next_s <= E7;
		when E7 => next_s <= E1;
	    when E8 => next_s <= E9;
		when E9 => next_s <= E3;
	    when E10 => next_s <= E1;
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

leaf <= i_node_out(0);
PR_jk <= '1' when current_s = E0 or current_s = E7 else '0';
CL_jk <= '1' when current_s = E9 else '0';

-- RE mem signals

o_RE_node <= '1' when current_s = E1 or current_s = E2 or current_s = E9 else '0';
o_RE_link <= '1' when current_s = E6 else '0';
o_RE_data <= '1' when current_s = E4 else '0';

-- C node mem

LD_c_node_mem <= '1' when current_s = E7 else '0';
INC_c_node_mem <= '1' when current_s = E1 or current_s = E8 else '0';
CL_c_node_mem <= '1' when current_s = E0 or current_s = E10 else '0';

process(i_clk, CL_c_node_mem)
    begin
	if CL_c_node_mem = '1' then c_node_mem_out <= x"0000";
	elsif rising_edge(i_clk) then
	    if LD_c_node_mem = '1' then
			c_node_mem_out <= i_link_addr_out;
	    elsif INC_c_node_mem = '1' then
			c_node_mem_out <= std_logic_vector(unsigned(c_node_mem_out) + 1);
	    end if;
	end if;
end process;

o_node_addr <= unsigned(c_node_mem_out);

-- C link mem

LD_c_link_mem <= '1' when current_s = E2 else '0';
INC_c_link_mem <= '1' when current_s = E8 else '0';

process(i_clk)
    begin
	if rising_edge(i_clk) then
	    if LD_c_link_mem = '1' then
			c_link_mem_out <= i_node_out(node_width - 1 downto 16);
	    elsif INC_c_link_mem = '1' then
			c_link_mem_out <= std_logic_vector(unsigned(c_link_mem_out) + 1);
	    end if;
	end if;
end process;

o_link_addr <= unsigned(c_link_mem_out);

-- C data mem

INC_c_data_mem <= '1' when current_s = E10 else '0';
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

o_data_addr <= unsigned(c_data_mem_out) + (unsigned(r_feature_out));

-- R_feature

LD_feature <= '1' when current_s = E2 else '0';

process(i_clk)
begin
	if rising_edge(i_clk) then
	    if LD_feature = '1' then
			r_feature_out <= i_node_out(node_width - 17 downto 1);
	    end if;
	end if;
end process;

-- R_value

LD_value <= '1' when current_s = E3 else '0';

process(i_clk)
begin
	if rising_edge(i_clk) then
	    if LD_value = '1' then
			r_value_out <= i_node_out(node_width - 1 downto 0);
	    end if;
	end if;
end process;

cmd <= r_value_out(2 downto 0);
value <= to_float(r_value_out(node_width - 1 downto 3) & "000");
--value <= to_float(r_value_out);
data_out <= to_float(i_data_out);

-- R class

LD_class <= '1' when current_s = E10 else '0';
process(i_clk)
begin
    if rising_edge(i_clk) then
        if LD_class = '1' then
            r_class_out <= r_feature_out;
        end if;
    end if;
end process;

--o_class <= r_class_out;

-- CMP

process(value, data_out)
begin
    if data_out > value then
        gr <= '1'; eq <= '0'; ls <= '0';
    elsif data_out = value then
        gr <= '0'; eq <= '1'; ls <= '0';
    elsif data_out < value then
        gr <= '0'; eq <= '0'; ls <= '1';
    else
        gr <= '0'; eq <= '0'; ls <= '0';
    end if;
end process;

process(cmd, gr, eq, ls)
begin
    case cmd is
        when "001" => node_sel <= eq;
        when "010" => node_sel <= gr;
        when "100" => node_sel <= ls;
        when "011" => node_sel <= gr OR eq;
        when "101" => node_sel <= ls OR eq;
        when others => node_sel <= 'Z';
    end case;
end process;

-- JK

process(CL_jk, PR_jk)
begin
    if CL_jk = '1' then read_node_info <= '0';
    elsif PR_jk = '1' then read_node_info <= '1';
    end if;
end process;


p_ASSERT : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      if ld_class = '1' and next_s = E1 then
        report "Class: " & integer'image(to_integer(unsigned(r_feature_out))) severity note;
      end if;
    end if;
  end process p_ASSERT;

end arch_dt_ctl;
