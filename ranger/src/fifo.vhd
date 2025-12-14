library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fifo_pkg.all;
use work.ram_pkg.all;

entity fifo is
    generic(
	g_DATA_WIDTH: integer;
	g_ADDR_WIDTH: integer;
	g_INIT_MEM: std_logic;
	g_DEPTH: integer
    );
    port(
	i_CLK		: in std_logic;
	i_RESET		: in std_logic;
	i_RE_FIFO	: in std_logic;
	i_WR_FIFO	: in std_logic;
	i_WR_DATA	: in std_logic_vector(g_DATA_WIDTH - 1 downto 0);
    --------------------------------------------------------
	o_DATA_0	: out std_logic_vector(g_DATA_WIDTH - 1 downto 0);
	o_DATA_1	: out std_logic_vector(g_DATA_WIDTH - 1 downto 0);
	o_FIFO_EMPTY	: out std_logic;
	o_FIFO_LAST	: out std_logic;
	o_FIFO_FULL	: out std_logic
    );
end fifo;

architecture arch_fifo of fifo is

-- Control logic
signal full, empty, last: std_logic;
signal init: std_logic := g_init_mem;
signal re_en, wr_en : std_logic := '0';

-- Number of elements
signal mem_elements : integer range 0 to g_DEPTH := 0;
signal elem_dec : integer range 0 to g_DEPTH := 0;
signal elem_inc : integer range 0 to g_DEPTH := 0;

-- DATA
signal data_0, data_1 : std_logic_vector(g_DATA_WIDTH - 1 downto 0);

-- ADDR
subtype addr_t is integer range 0 to g_DEPTH - 1;
signal rd_addr, wr_addr : addr_t := 0;
signal addr_0, addr_1, addr_2 : unsigned(g_ADDR_WIDTH - 1 downto 0);
signal prueba : integer;

signal rd_wr_fifo, pruebote : std_logic;

procedure inc_addr(signal addr : inout addr_t; mem_span : in  integer) is
begin
    addr <= (addr + mem_span) mod (addr_t'high + 1);
end procedure;

begin

prueba <= addr_t'high;
FIFO_MEM: ram
generic map(
    g_addr_width    => g_ADDR_WIDTH,
    g_data_width    => g_DATA_WIDTH,
    g_depth	    => g_DEPTH,
    g_init_file	    => "./memory_content/random_forest.txt",
    g_init	    => g_init_mem
)
port map(
    i_CLK	    => i_clk,
    i_RE_0	    => re_en,
    i_RE_1	    => re_en, -- not used
    i_WE_1	    => wr_en,
    i_ADDR_0	    => addr_0,
    i_ADDR_1	    => addr_1, -- not used
    i_WR_ADDR	    => addr_2,
    o_DATA_0	    => data_0,
    o_DATA_1	    => data_1,
    i_DATA_1	    => i_WR_DATA
);

addr_0 <= to_unsigned(rd_addr, g_ADDR_WIDTH);
addr_1 <= to_unsigned(rd_addr, g_ADDR_WIDTH);
addr_2 <= to_unsigned(wr_addr, g_ADDR_WIDTH);


wr_en <= i_WR_FIFO and not full;
re_en <= i_RE_FIFO and not empty;

o_DATA_0 <= data_0;
o_DATA_1 <= data_1;

-- READ ADDR update
process(i_clk, i_RESET)
begin
    if i_RESET = '1' then
	rd_addr <= 0;
	wr_addr <= 0;
    elsif rising_edge(i_clk) then
	-- init
	if init = '1' then
	    mem_elements <= g_DEPTH - 1;
	    init <= '0';
	else
	    -- Read
	    if i_re_fifo = '1' and empty = '0' then
	        inc_addr(rd_addr, 1);
	    end if;
	    -- Write
	    if i_wr_fifo = '1' and full = '0' then
	        inc_addr(wr_addr, 1);
	    end if;
	    mem_elements <= mem_elements + (elem_inc - elem_dec);
	end if;
    end if;
end process;

elem_dec <= 1 when i_re_fifo = '1' and empty = '0' else 0;
elem_inc <= 1 when i_wr_fifo = '1' and full = '0' else 0;

rd_wr_fifo <= '1' when elem_dec = 1 and elem_inc = 1 else '0';

process(rd_wr_fifo, last, empty)
begin
	pruebote <= '1';

	if empty = '1' or last = '1' then
	   	pruebote <= '0';
   	end if;
	if rd_wr_fifo = '1' then
		pruebote <= '0';
	end if;	
end process;

-- Control signals
empty <= '1' when mem_elements = 0 else '0';
full <= '1' when mem_elements >= g_DEPTH else '0'; -- No puede ser //Cuando llega al valor maximo ya se queda bloqueado.
last <= '1' when mem_elements = 1 else '0';

o_FIFO_EMPTY <= empty;
o_FIFO_FULL <= full;
o_FIFO_LAST <= last;

end arch_fifo;

