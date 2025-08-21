library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fifo_pkg.all;
use work.ram_pkg.all;

entity fifo is
    generic(
	g_DATA_WIDTH: integer;
	g_ADDR_WIDTH: integer;
	g_SPAN: integer;
	g_DEPTH: integer
    );
    port(
	i_CLK		: in std_logic;
    	i_RESET		: in std_logic;
	i_RE_FIFO	: in std_logic;
	i_RE_0		: in std_logic;
    	i_RE_1		: in std_logic;
	i_WR_FIFO	: in std_logic;
	i_WR_DATA	: in std_logic_vector(g_DATA_WIDTH - 1 downto 0);
	i_MODE		: in std_logic;
	i_ADDR_0	: in unsigned(g_ADDR_WIDTH - 1 downto 0);
	i_ADDR_1	: in unsigned(g_ADDR_WIDTH - 1 downto 0);
    --------------------------------------------------------
	o_DATA_0	: out std_logic_vector(g_DATA_WIDTH - 1 downto 0);
	o_DATA_1	: out std_logic_vector(g_DATA_WIDTH - 1 downto 0);
	o_FIFO_EMPTY	: out std_logic;
	o_FIFO_FULL	: out std_logic
    );
end fifo;

architecture arch_fifo of fifo is

-- Control logic
signal full, empty: std_logic;
signal re_en_0, re_en_1, wr_en : std_logic := '0';
signal c_inc, c_dec : std_logic := '0';
signal span : integer := 0;
-- Number of elements
signal mem_elements : integer range 0 to g_DEPTH := 0;
signal elem_dec : integer range 0 to g_DEPTH := 0;
signal elem_inc : integer range 0 to g_DEPTH := 0;

-- DATA
signal data_0, data_1 : std_logic_vector(g_DATA_WIDTH - 1 downto 0);

-- ADDR
subtype addr_t is integer range 0 to g_DEPTH - 1;
signal rd_addr, wr_addr : addr_t := 0;
signal addr_0, addr_1 : unsigned(g_ADDR_WIDTH - 1 downto 0);

procedure inc_addr(signal addr : inout addr_t; mem_span : in  integer) is
begin
    addr <= (addr + mem_span) mod addr_t'high;
end procedure;

begin

FIFO_MEM: ram
generic map(
    g_addr_width    => g_ADDR_WIDTH,
    g_data_width    => g_DATA_WIDTH,
    g_depth	    => g_DEPTH,
    g_init_file	    => "./memory_content/bin_node_mem_content.txt",
    g_init	    => '0'
)
port map(
    i_CLK	    => i_clk,
    i_RE_0	    => re_en_0,
    i_RE_1	    => re_en_1, --not used
    i_WE_1	    => wr_en,
    i_ADDR_0	    => addr_0, -- to_unsigned(rd_addr, g_ADDR_WIDTH),
    i_ADDR_1	    => addr_1,
    i_WR_ADDR	    => to_unsigned(wr_addr, g_ADDR_WIDTH),
    o_DATA_0	    => data_0,
    o_DATA_1	    => data_1,
    i_DATA_1	    => i_WR_DATA
);

re_en_0 <= i_RE_FIFO and not empty when i_mode = '0' else i_RE_0;
re_en_1 <= i_RE_1;
wr_en <= i_WR_FIFO and not full;

span <= g_SPAN when i_mode = '1' else 1;

addr_0 <= to_unsigned(rd_addr, g_ADDR_WIDTH) when i_mode = '0' else i_addr_0 + to_unsigned(rd_addr, g_ADDR_WIDTH);
addr_1 <= to_unsigned(wr_addr, g_ADDR_WIDTH) when i_mode = '0' else i_addr_1 + to_unsigned(rd_addr, g_ADDR_WIDTH);

o_DATA_0 <= data_0;
o_DATA_1 <= data_1;

-- READ ADDR update
process(i_clk, i_RESET)
begin
    if i_RESET = '1' then
	rd_addr <= 0;
	wr_addr <= 0;
    elsif rising_edge(i_clk) then
	-- Read
	if i_re_fifo = '1' and empty = '0' then
	    inc_addr(rd_addr, span);
	end if;
	-- Write
	if i_wr_fifo = '1' and full = '0' then
	    inc_addr(wr_addr, span);
	end if;
	mem_elements <= mem_elements + (elem_inc - elem_dec);
    end if;
end process;

elem_dec <= span when i_re_fifo = '1' and empty = '0' else 0;
elem_inc <= span when i_wr_fifo = '1' and full = '0' else 0;

-- Control signals
empty <= '1' when mem_elements = 0 else '0';
full <= '1' when mem_elements >= g_DEPTH else '0'; -- No puede ser //Cuando llega al valor maximo ya se queda bloqueado.

o_FIFO_EMPTY <= empty;
o_FIFO_FULL <= full;

end arch_fifo;
