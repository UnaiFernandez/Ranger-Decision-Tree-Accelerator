library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.ram_pkg.all;

entity ram is
    generic (
        g_ADDR_WIDTH : integer;
        g_DATA_WIDTH : integer;
        g_DEPTH	     : integer;
        g_INIT_FILE  : string;
        g_INIT	     : std_logic
    );
    port(
        i_CLK	    : in std_logic;
        i_RE_0 	    : in std_logic;
        i_RE_1 	    : in std_logic;
        i_WE_1 	    : in std_logic;
        i_ADDR_0    : in unsigned(g_ADDR_WIDTH - 1 downto 0);
        i_ADDR_1    : in unsigned(g_ADDR_WIDTH - 1 downto 0);
        i_WR_ADDR   : in unsigned(g_ADDR_WIDTH - 1 downto 0);
        i_DATA_1    : in std_logic_vector(g_DATA_WIDTH - 1 downto 0);
        --------------------------------------------------------------
        o_DATA_0    : out std_logic_vector(g_DATA_WIDTH - 1 downto 0);
        o_DATA_1    : out std_logic_vector(g_DATA_WIDTH - 1 downto 0)
    );
end ram;

architecture arch_ram of ram is

    type memory_t is array (natural range <>) of std_logic_vector(g_data_width - 1 downto 0);

    attribute ram_style: string;

    -- TODO Borrar la funcion??
    impure function init_mem(mem_depth : in integer) return memory_t is
        file mem_content : text open read_mode is g_INIT_FILE;
        variable fline : line;
        variable temp : memory_t(mem_depth - 1 downto 0);
        variable data : bit_vector(temp(0)'range);
        begin
        --while not endfile(mem_content) loop
        for i in 0 to mem_depth - 1 loop
	    if g_INIT = '1' then
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

    attribute ram_style of ram_mem: signal is "auto";

begin

    process(i_clk)
    begin
        if rising_edge(i_clk) then
	        if i_RE_0 = '1' then
		    o_DATA_0 <= ram_mem(to_integer(i_ADDR_0));
		--else
		--    o_DATA_0 <= (others => '0');
	        end if;
	        if i_RE_1 = '1' then
		    o_DATA_1 <= ram_mem(to_integer(i_ADDR_1));
		--else
		--    o_DATA_1 <= (others => '0');
	        end if;
	        if i_WE_1 = '1' then
		      	ram_mem(to_integer(i_WR_ADDR)) <= i_DATA_1;
	        end if;
        end if;
    end process;

end arch_ram;
