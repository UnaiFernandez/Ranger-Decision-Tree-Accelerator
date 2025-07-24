library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fifo_pkg.all;
use work.ram_pkg.all;

entity fifo is
    generic(
	g_DATA_WIDTH: integer;
	g_ADDR_WIDTH: integer;
	g_DEPTH: integer
    );
    port(
	i_CLK		: in std_logic;
    	i_RESET		: in std_logic;
	i_RE_FIFO	: in std_logic;
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

signal mem_elements : integer range 0 to g_DEPTH := 0;
-- Flag logic
signal full, empty: std_logic;
signal re_en, wr_en : std_logic := '0';
signal c_inc, c_dec : std_logic := '0';

-- DATA
signal data_0, data_1 : std_logic_vector(g_DATA_WIDTH - 1 downto 0);

-- ADDR
subtype addr_t is integer range 0 to g_DEPTH - 1;
signal rd_addr, wr_addr : addr_t := 0;
signal addr_0, addr_1 : unsigned(g_ADDR_WIDTH - 1 downto 0);

procedure inc_addr(signal addr : inout addr_t) is
begin
    if addr = addr_t'high then
	addr <= addr_t'low;
    else
	--report "ADDR2: " & integer'image(addr) severity note;
	addr <= addr + 1;
    end if;
end procedure;


begin

FIFO_MEM: ram
generic map(
    g_addr_width => g_ADDR_WIDTH,
    g_data_width => g_DATA_WIDTH,
    g_depth => g_DEPTH,
    g_init_file => "./memory_content/bin_node_mem_content.txt",
    g_init => '0'
)
port map(
    i_CLK => i_clk,
    i_RE_0 => re_en,
    i_RE_1 => '0', --not used
    i_WE_1 => wr_en,
    i_ADDR_0 => to_unsigned(rd_addr, g_ADDR_WIDTH), --addr_0,
    i_ADDR_1 => addr_1,
    i_WR_ADDR => to_unsigned(wr_addr, g_ADDR_WIDTH),
    o_DATA_0 => data_0,
    o_DATA_1 => data_1,
    i_DATA_1 => i_WR_DATA
);

-- TODO
-- Los addr del fifo wr_addr y rd_addr, se inicializan a 0.
-- El contador tiene q funcionar bien y activar las señales de FF y FE a tiempo.
-- Cuando este en el modo 1 hay q saber cuantos features hay en una linea, para poder saltarlos todos de golpe, añadir un paramentro.
-- El codigo funciona, pero se podria hacer de una forma mas sencilla y limpia.

re_en <= i_RE_FIFO and not empty;
wr_en <= i_WR_FIFO and not full;

-- READ ADDR update
process(i_clk, i_RESET)
begin
    if i_RESET = '1' then
	rd_addr <= 0;
	wr_addr <= 0;
    elsif rising_edge(i_clk) then
	c_dec <= '0';
	if i_re_fifo = '1' and empty = '0' then
	    inc_addr(rd_addr);
	    mem_elements <= mem_elements - 1;
	    c_dec <= '1';
	    report "RD_ADDR: " & integer'image(rd_addr) severity note;
	end if;
	c_inc <= '0';
	if i_wr_fifo = '1' and full = '0' then
	    inc_addr(wr_addr);
	    c_inc <= '1';
	    mem_elements <= mem_elements + 1;
	end if;
    end if;
end process;

-- WRITE ADDR update
--process(i_clk)
--begin
--    if i_RESET = '1' then
--	wr_addr <= 0;
--    elsif rising_edge(i_clk) then
--	c_inc <= '0';
--	if i_wr_fifo = '1' and full = '0' then
--	    inc_addr(wr_addr);
--	    c_inc <= '1';
--	end if;
--    end if;
--end process;


--process (i_clk, c_inc, c_dec)
--begin
--    if rising_edge(i_clk) then
--	if c_inc = '1' and c_dec = '0'then
--    	    mem_elements <= mem_elements + 1;
--    	end if;
--    	if c_dec = '1' and c_inc = '0' then
--    	    mem_elements <= mem_elements - 1;
--    	end if;
--    end if;
--end process;

--process(wr_addr, rd_addr)
--begin
--    if wr_addr >= rd_addr then
--	mem_elements <= wr_addr - rd_addr;
--	report "WR >= RD: " & integer'image(mem_elements) severity note;
--    else
--	mem_elements <= (g_DEPTH - wr_addr + rd_addr);
--	report "WR < RD: " & integer'image(mem_elements) severity note;
--    end if;
--end process;

--mem_elements <= (wr_addr - rd_addr + g_DEPTH) when wr_addr < rd_addr else (wr_addr - rd_addr);

-- Prueba
empty <= '1' when mem_elements = 0 else '0';
full <= '1' when mem_elements >= g_DEPTH else '0'; -- No puede ser //Cuando llega al valor maximo ya se queda bloqueado.

end arch_fifo;
