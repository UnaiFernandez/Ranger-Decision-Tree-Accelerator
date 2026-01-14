library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.fifo_pkg.all;
use work.ram_pkg.all;

entity axis_fifo is
    generic(
	g_DATA_WIDTH: integer;
	g_ADDR_WIDTH: integer;
	g_EMPTY_THRESHOLD: integer;
	g_INIT_MEM: std_logic;
    g_init_file:string;
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
    	m00_TVALID		: out std_logic;
    	m00_TLAST		: out std_logic;
    	m00_TDATA		: out std_logic_vector(g_DATA_WIDTH - 1 downto 0);
    	s00_TREADY		: out std_logic;
    	FIFO_LAST		: out std_logic;
    	FIFO_EMPTY		: out std_logic
    );
end axis_fifo;

architecture arch_axis_fifo of axis_fifo is

-- Control logic
signal full, empty, last: std_logic;
signal init : std_logic := g_INIT_MEM;
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

signal rd_wr_fifo, valid_i, ready_i : std_logic;

signal m00_tready_i: std_logic;

type memory_t is array (natural range <>) of std_logic_vector(g_data_width - 1 downto 0);
attribute ram_style: string;


impure function init_mem(mem_depth : in integer) return memory_t is
    file mem_content : text open read_mode is g_INIT_FILE;
    variable fline : line;
    variable temp : memory_t(mem_depth - 1 downto 0);
    variable data : bit_vector(temp(0)'range);
begin
    --while not endfile(mem_content) loop
    for i in 0 to mem_depth - 1 loop
    	if g_INIT_MEM = '1' then
    		if not endfile(mem_content) then
            	readline(mem_content, fline);
            	read(fline, data);
            	temp(i) := to_stdlogicvector(data);
        	else
            	temp(i) := (others => '0');
        end if;
    else
    		temp(i) := (others => '0');
    end if;
    end loop;
    return temp;
end;

signal ram_mem: memory_t(g_DEPTH - 1 downto 0) := init_mem(g_DEPTH);
attribute ram_style of ram_mem: signal is "block";

function next_addr(addr : addr_t; ready : std_logic; valid : std_logic) return addr_t is
begin
  if ready = '1' and valid = '1' then
    if addr = addr_t'high then
      return addr_t'low;
    else
      return addr + 1;
    end if;
  end if;
  
  return addr;
end function;

begin

process(i_CLK)
begin
	if rising_edge(i_CLK) then
		if init = '0' then
			ram_mem(wr_addr) <= s00_TDATA;
		end if;
		m00_TDATA <= ram_mem(next_addr(rd_addr, m00_tready_i, valid_i));
	end if;
end process;

wr_en <= s00_TVALID and not full;
re_en <= m00_tready_i and valid_i;

m00_tready_i <= m00_TREADY;

-- READ & WRITE address update
process(i_clk, i_RESET, init, re_en, empty, wr_en, full)
begin

    if rising_edge(i_clk) then
        if i_RESET = '1' then
	       	rd_addr <= 0;
	       	wr_addr <= 0;
	   		if init = '1' then
				wr_addr <= addr_t'high;
			end if;
	    else
			wr_addr <= next_addr(wr_addr, ready_i, s00_TVALID);
			rd_addr <= next_addr(rd_addr, m00_tready_i, valid_i);
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
	if mem_elements = 0 or mem_elements_old = 0 then
	--if mem_elements	<= 1 then
	   	valid_i <= '0';
	elsif mem_elements = 1 and rd_wr_fifo = '1' then
		valid_i <= '0';
	else
		valid_i <= '1';
	end if;	
end process;

process(mem_elements)
begin
	if mem_elements < g_DEPTH - 1 then
		ready_i <= '1';
	else
		ready_i <= '0';
	end if;
end process;

-- Control signals
empty <= '1' when mem_elements = 0 else '0';
full <= '1' when mem_elements >= g_DEPTH else '0'; -- No puede ser //Cuando llega al valor maximo ya se queda bloqueado.
last <= '1' when mem_elements = 1 else '0';


	m00_TVALID <= valid_i;
	m00_TLAST <= '1' when last = '1' and valid_i = '1' else '0';
    s00_TREADY <= '1' when full = '0' else '0';
	FIFO_EMPTY <= empty;
	FIFO_LAST <= last;

end arch_axis_fifo;
