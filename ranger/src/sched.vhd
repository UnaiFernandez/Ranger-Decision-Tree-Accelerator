library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sched_pkg.all;



entity sched is
    generic(
        g_INSTANCES: integer
	);
    port(
	i_CLK		: in std_logic;
	i_RESET		: in std_logic;
	i_INIT		: in std_logic;
	i_EMPTY		: in std_logic;
    	i_REQ_ID	: in std_logic_vector(g_INSTANCES - 1 downto 0);
	--------------------------------------------------------
	o_GRANT_ID	: out integer;
    	o_DEQUEUE	: out std_logic;
    	o_FLT_EN	: out std_logic;
    	o_RE_EN		: out std_logic;
    	o_BUSY		: out std_logic;
	o_GRANT		: out std_logic_vector(g_INSTANCES - 1 downto 0)
    );
end sched;

architecture arch_sched of sched is

type state is (E0, E1, E2);
signal current_s, next_s: state;

signal cl_timer, en_timer : std_logic;
signal timer : integer;

signal timer_end : std_logic;

signal ld_id : std_logic;
signal grant : std_logic_vector(g_INSTANCES - 1 downto 0) := (others => '0');
signal r_id : integer := 0;
begin

-- State machine

process(current_s, next_s, i_init, timer_end)
begin
	case current_s is
	    when E0 => if i_init = '0' then next_s <= E0;
			else next_s <= E2;
			end if;
	    when E1 => next_s <= E2;
	    when E2 => if timer_end = '1' and i_EMPTY = '0' then next_s <= E1;
					elsif timer_end = '1' and i_EMPTY = '1' then next_s <= E0;
		       else next_s <= E2;
		       end if;
	end case;
end process;

process(i_clk, i_reset)
begin
	if i_reset = '1' then current_s <= E0;
	elsif rising_edge(i_clk) then current_s <= next_s;
	end if;
end process;


-- Grant

--ld_id <= '1' when (current_s = E0 and i_INIT = '1') or (current_s = E1 and i_EMPTY = '0') else '0';
ld_id <= '1' when (current_s = E0 and i_INIT = '1') or (current_s = E1) else '0';
process(i_clk, ld_id)
begin
    if rising_edge(i_clk) then
	if ld_id = '1' then
	    r_id <= to_integer(unsigned(i_REQ_ID));
	    grant <= (others => '0');
	    grant(to_integer(unsigned(i_REQ_ID))) <= '1';
	end if;
    end if;
end process;

o_GRANT_ID <= r_id;

--grant <= (others => '0') when current_s = E1 else grant;
o_GRANT <= grant when current_s = E2 else (others => '0');

-- Timer
cl_timer <= '1' when current_s = E0 or current_s = E1 else '0';
en_timer <= '1' when current_s = E2 else '0';
--o_DEQUEUE <= '1' when (current_s = E0 and i_INIT = '1') or (current_s = E1 and i_EMPTY = '0') else '0';
o_DEQUEUE <= '1' when current_s = E2 and timer_end = '1' and i_EMPTY = '0' else '0';
o_FLT_EN <= '1' when current_s = E2 and timer_end = '1' else '0';

--o_DEQUEUE <= '1' when (current_s = E0 and i_init = '1') or (current_s = E2 and timer_end = '1' and i_EMPTY = '0') else '0';

process(i_clk, cl_timer)
begin
    if cl_timer = '1' then timer <= 4; -- numero de ciclos
    elsif rising_edge(i_clk) then
	if en_timer = '1' then
	    timer <= timer - 1;
	end if;
    end if;
end process;

o_RE_EN <= '1' when en_timer = '1' else '0';
o_BUSY <= '1' when en_timer = '1' or current_s = E1 else '0';

timer_end <= '1' when timer <= 0 else '0';

end arch_sched;
