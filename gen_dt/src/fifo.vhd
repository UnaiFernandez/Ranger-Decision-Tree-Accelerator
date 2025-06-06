library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fifo_pkg.all;

entity fifo is
    generic(
	g_depth : integer;
	g_width : integer
    );
    port(
	i_clk		: in std_logic;
	i_re_en		: in std_logic;
	i_wr_en		: in std_logic;
	i_wr_data	: in std_logic_vector(g_width - 1 downto 0);
    --------------------------------------------------------
	o_rd_data	: out std_logic_vector(g_width - 1 downto 0);
	o_fifo_empty	: out std_logic;
	o_fifo_full	: out std_logic
    );
end fifo;

architecture arch_fifo of fifo is

type t_fifo is array (0 to g_depth-1) of std_logic_vector(g_width-1 downto 0);
signal fifo_data : t_fifo := (others => (others => '0'));

signal rd_addr, wr_addr : integer range 0 to g_depth - 1;
signal counter : integer range 0 to g_depth - 1 := 0;


-- Counter
signal INC, DEC, CL, FF, FE : std_logic;
signal Q : integer range -1 to g_depth + 1 := 0;

begin

-- FIFO clk
process(i_clk)
begin
    if rising_edge(i_clk) then

	-- READ addr
	if i_re_en = '1' and FE = '0' then 
	    o_rd_data <= fifo_data(rd_addr); 
	    DEC <= '1';
	    if rd_addr = g_depth - 1 then
		rd_addr <= 0;
	    else
		rd_addr <= rd_addr + 1;
	    end if;
	else
	    DEC <= '0';
	end if;

	-- WRITE addr
	if i_wr_en = '1' and FF = '0' then
	    fifo_data(wr_addr) <= i_wr_data;
	    INC <= '1';
	    if wr_addr = g_depth - 1 then
		wr_addr <= 0;
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

o_fifo_empty <= FE;
o_fifo_full <= FF;
end arch_fifo;

