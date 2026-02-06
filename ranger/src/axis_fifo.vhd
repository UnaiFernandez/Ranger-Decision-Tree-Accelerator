library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fifo_pkg.all;
use work.ram_pkg.all;

entity axis_fifo is
    generic(
	g_DATA_WIDTH: integer;
	g_ADDR_WIDTH: integer;
	g_EMPTY_THRESHOLD: integer;
	g_INIT_MEM: std_logic;
	g_DEPTH: integer
    );
    port(
	i_CLK			: in std_logic;
    	i_RESET			: in std_logic;
    	s00_TVALID		: in std_logic; 
    	s00_TLAST		: in std_logic; 
    	s00_TDATA		: in std_logic_vector(g_data_width - 1 downto 0); 
    	m00_TREADY		: in std_logic; 
    	----------------------------------------------------
		fifo_empty		:out std_logic;
    	m00_TVALID		: out std_logic;
    	m00_TLAST		: out std_logic;
    	m00_TDATA		: out std_logic_vector(g_DATA_WIDTH - 1 downto 0);
    	s00_TREADY		: out std_logic
    );
end axis_fifo;

architecture arch_axis_fifo of axis_fifo is

-- Control logic
signal full, empty, last: std_logic;
signal init_mem: std_logic := g_init_mem;
signal init_done: std_logic_vector(1 downto 0) := "00";
signal re_en, wr_en : std_logic := '0';

-- Number of elements
signal mem_elements : integer range 0 to g_DEPTH := 0;
signal mem_elements_old : integer range 0 to g_DEPTH := 0;
signal elem_dec : integer range 0 to g_DEPTH := 0;
signal elem_inc : integer range 0 to g_DEPTH := 0;

-- DATA
signal data_0, data_1 : std_logic_vector(g_DATA_WIDTH - 1 downto 0);

-- ADDR
subtype addr_t is integer range 0 to g_DEPTH - 1;
signal rd_addr, wr_addr : addr_t := 0;
signal addr_0, addr_1, addr_2 : unsigned(g_ADDR_WIDTH - 1 downto 0);
signal prueba : integer;

signal rd_wr_fifo, valid_i : std_logic;

signal m00_tready_i: std_logic;

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
    g_init_file	    => "/home/makinote/Project/vivado/dt_vhdl/ranger/memory_content/random_forest.txt",
    --g_init_file	    => "./memory_content/random_forest.txt",
    g_init	    => g_init_mem
)
port map(
    i_CLK	    => i_clk,
    i_RE_0	    => '1',
    i_RE_1	    => '1', -- not used
    i_WE_1	    => wr_en,
    i_ADDR_0	    => addr_0,
    i_ADDR_1	    => addr_1, -- not used
    i_WR_ADDR	    => addr_2,
    o_DATA_0	    => m00_TDATA,
    o_DATA_1	    => m00_TDATA,
    i_DATA_1	    => s00_TDATA
);

addr_0 <= to_unsigned(rd_addr, g_ADDR_WIDTH);
addr_1 <= to_unsigned(rd_addr, g_ADDR_WIDTH);
addr_2 <= to_unsigned(wr_addr, g_ADDR_WIDTH);


wr_en <= s00_TVALID and not full;
re_en <= m00_tready_i and valid_i;

m00_tready_i <= m00_TREADY;

-- READ & WRITE address update
process(i_clk, i_RESET, init_mem, re_en, empty, wr_en, full)
begin

    if rising_edge(i_clk) then
        if i_RESET = '1' then
	       	rd_addr <= 0;
	       	wr_addr <= 0;
	   		if init_mem = '1' then
				wr_addr <= addr_t'high;
			end if;
	    else
	        -- Read
	        if re_en = '1' and empty = '0' then
	            inc_addr(rd_addr, 1);
	        end if;
	        -- Write
	        if wr_en = '1' and full = '0' then
	            inc_addr(wr_addr, 1);
	        end if;
        end if;
    end if;
end process;

process(rd_addr, wr_addr)
begin
	if wr_addr < rd_addr then
		mem_elements <= wr_addr - rd_addr + g_DEPTH;
	else
		mem_elements <= wr_addr - rd_addr;
	end if;
end process;

process(i_CLK, i_RESET, mem_elements)
begin
	if rising_edge(i_CLK) then
		if i_RESET = '1' then
			mem_elements_old <= 0;
		else
			mem_elements_old <= mem_elements;
		end if;
	end if;
end process;

process(i_CLK, i_RESET, s00_TVALID, full, valid_i, m00_tready_i)
begin
	if rising_edge(i_CLK) then
		if i_RESET = '1' then
			rd_wr_fifo <= '0';
		else
			if s00_TVALID = '1' and full = '0' and valid_i = '1' and m00_tready_i = '1' then
				rd_wr_fifo <= '1';
			else
				rd_wr_fifo <= '0';
			end if;
		end if;
	end if;
end process;


process(rd_wr_fifo, mem_elements_old, mem_elements)
begin
	if mem_elements = 0  or mem_elements_old = 0 then
	--if mem_elements	<= 1 then
	   	valid_i <= '0';
	elsif mem_elements = 1 and rd_wr_fifo = '1' then
		valid_i <= '0';
	else
		valid_i <= '1';
	end if;	
end process;

-- Control signals
empty <= '1' when mem_elements = 0 else '0';
full <= '1' when mem_elements >= g_DEPTH else '0'; -- No puede ser //Cuando llega al valor maximo ya se queda bloqueado.
last <= '1' when mem_elements = 1 else '0';

fifo_empty <= '1' when mem_elements <= 4 else '0';
	m00_TVALID <= valid_i;
	m00_TLAST <= '1' when last = '1' and valid_i = '1' else '0';
    s00_TREADY <= '1' when full = '0' else '0';

end arch_axis_fifo;
