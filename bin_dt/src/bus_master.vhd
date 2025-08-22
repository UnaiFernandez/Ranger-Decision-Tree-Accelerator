library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fifo_pkg.all;
use work.bus_master_pkg.all;
use work.sched_pkg.all;

entity bus_master is
    generic(
        g_DATA_WIDTH: integer;
        g_ADDR_WIDTH: integer;
        g_INSTANCES: integer
	);
    port(
	i_CLK		: in std_logic;
	i_RESET		: in std_logic;
	i_REQ		: in std_logic_vector(g_INSTANCES - 1 downto 0);
	--------------------------------------------------------
	io_RE_EN	: inout std_logic;
	o_GRANT		: out std_logic_vector(g_INSTANCES - 1 downto 0)
    );
end bus_master;

architecture arch_bus_master of bus_master is

type state is (E0, E1, E2);
signal current_s, next_s: state;

signal re_fifo : std_logic;
signal wr_fifo : std_logic;
signal fifo_empty : std_logic;
signal fifo_full : std_logic;

signal wr_data, req_id : std_logic_vector(g_DATA_WIDTH - 1 downto 0);
signal addr_0 : unsigned(g_ADDR_WIDTH - 1 downto 0);

signal ld_c_req, dec_c_req, done_req : std_logic;
signal c_req : integer := 0; 

signal new_req : std_logic;

signal cl_flt, update_flt : std_logic;
signal min_id : integer;
signal flt : std_logic_vector(g_INSTANCES - 1 downto 0) := (others => '1');
signal req : std_logic_vector(g_INSTANCES - 1 downto 0);
signal grant : std_logic_vector(g_INSTANCES - 1 downto 0);

signal prueba_int : integer;
signal prueba_std : std_logic_vector(12 downto 0);

-- Estas funciones en la simulacion son instantaneas, pero en HW real puede cambiar el rendimiento (dependiendo de la frecuancia de reloj)

function get_num_req(r : std_logic_vector) return integer is
    variable t: integer := 0;
begin
    for i in r'range loop
        if r(i) = '1' then
	   t := t + 1;
        end if;
    end loop;
    return t;
end get_num_req;


function get_id(r : std_logic_vector) return integer is
    variable t: integer := 0;
begin
    for i in r'range loop
        if r(i) = '1' then
	   t := i;
        end if;
    end loop;
    return t;
end get_id;

begin

-- Filter
req <= flt and i_REQ;
-- un registro para cargar el nuevo valor del filtro
-- En E2 se actualiza el filtro, en principio no hay q hacer prefetching pero ay q probar.
cl_flt <= '1' when current_s = E1 else '0';
update_flt <= wr_fifo; 
min_id <= get_id(req);
process(i_clk, cl_flt)
begin
    if cl_flt = '1' then flt <= (others => '1');
    elsif rising_edge(i_clk) then
	if update_flt = '1' then
	    flt(min_id) <= '0' ;
	end if;
    end if;
end process;


-- State machine

process(current_s, next_s, new_req, done_req)
begin
	case current_s is
	    when E0 => if new_req = '1' then next_s <= E1;
			else next_s <= E0;
			end if;
	    when E1 => next_s <= E2;
	    when E2 => if done_req = '1' then next_s <= E0;
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

new_req <= '1' when req /= std_logic_vector(to_unsigned(0, i_REQ'length)) else '0';

-- QUEUE COUNTER
ld_c_req <= '1' when current_s = E1 or current_s = E2 else '0';
dec_c_req <= '1' when current_s = E2 and done_req = '0' else '0';

process(i_clk)
begin
    if rising_edge(i_clk) then
	if ld_c_req = '1' then
	    c_req <= get_num_req(i_REQ);
	elsif dec_c_req = '1'then
	    c_req <= c_req - 1;
	end if;
    end if;
end process;


-- Queue
done_req <= '1' when current_s = E2 and c_req = 0 else '0';
wr_fifo <= '1' when current_s = E2 and new_req = '1' else '0';
wr_data <= std_logic_vector(to_signed(min_id, wr_data'length));


QUEUE: fifo
generic map(
    g_depth	    => g_INSTANCES,
    g_data_width    => 32,
    g_addr_width    => 16,
    g_span	    => 1
)
port map(
    i_clk	    => i_clk,
    i_reset	    => i_reset,
    i_re_fifo	    => re_fifo, --dequeue
    i_re_0	    => '0',
    i_re_1	    => '0',
    i_wr_fifo	    => wr_fifo, --enqueue
    i_wr_data	    => wr_data, --identifier and update filter
    i_mode	    => '0',
    i_addr_0	    => addr_0,  -- Not Used
    i_addr_1	    => X"0000", -- Not Used
    o_data_0	    => req_id, -- update filter
    --o_data_1	    => fifo_data_1,
    o_fifo_empty    => fifo_empty,
    o_fifo_full	    => fifo_full
);

-- Sched ctl

SCHEDULER: sched
generic map(
    g_INSTANCES => g_INSTANCES
)
port map(
    i_clk => i_CLk,
    i_reset => i_RESET,
    i_EMPTY => fifo_empty,
    i_REQ_ID => req_id,
    o_RE_EN => io_RE_EN,
    o_DEQUEUE => re_fifo,
    o_GRANT => grant
);


end arch_bus_master;
