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
	i_RE_EN		: in std_logic;
	i_WR_EN		: in std_logic;
	i_WR_DATA	: in std_logic_vector(g_DATA_WIDTH - 1 downto 0);
    --------------------------------------------------------
	o_RD_DATA	: out std_logic_vector(g_DATA_WIDTH - 1 downto 0);
	o_FIFO_EMPTY	: out std_logic;
	o_FIFO_FULL	: out std_logic
    );
end fifo;

architecture arch_fifo of fifo is


signal rd_addr, wr_addr : unsigned(g_ADDR_WIDTH - 1 downto 0) := (others => '0');
signal counter : integer range 0 to g_DEPTH - 1 := 0;


-- Counter
signal INC, DEC, CL, FF, FE : std_logic;
signal Q : integer range -1 to g_depth + 1 := 0;

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
    i_RE_0 => i_re_en,
    i_RE_1 => '0', --not used
    i_WE_1 => i_wr_en,
    i_ADDR_0 => rd_addr,
    i_ADDR_1 => wr_addr,
    o_DATA_0 => o_rd_data,
    i_DATA_1 => i_wr_data
);

-- FIFO clk
process(i_clk)
begin
    if rising_edge(i_clk) then

	-- READ addr
	if i_re_en = '1' and FE = '0' then 
	    --o_rd_data <= fifo_data(rd_addr); 
	    DEC <= '1';
	    if rd_addr = g_depth - 1 then
		rd_addr <= (others => '0');
	    else
		rd_addr <= rd_addr + 1;
	    end if;
	else
	    DEC <= '0';
	end if;

	-- WRITE addr
	if i_wr_en = '1' and FF = '0' then
	    --fifo_data(wr_addr) <= i_wr_data;
	    INC <= '1';
	    if wr_addr = g_depth - 1 then
		wr_addr <= (others => '0');
	    else
		wr_addr <= wr_addr + 1;
	    end if;
	else
	    INC <= '0';
	end if;

    end if;
end process;



-- Counter
process(i_clk, CL)
begin
    if CL = '1' then Q <= 0;
    elsif rising_edge(i_clk) then
	if INC = '1' and DEC = '0' then
	    Q <= Q + 1;
	end if;
	if DEC = '1' and INC = '0' then
	    Q <= Q - 1;
	end if;
    end if;
end process;

FF <= '1' when Q >= g_depth else '0';
FE <= '1' when Q <= 0 else '0';

o_FIFO_EMPTY <= FE;
o_FIFO_FULL <= FF;
end arch_fifo;

