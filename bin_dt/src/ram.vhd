library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.ram_pkg.all;

entity ram is
    generic (
	g_addr_width : integer;
	g_data_width : integer;
	g_depth	     : integer;
	g_init_file  : string;
	g_init	     : std_logic
    );
    port(
	i_clk	    : in std_logic;
	i_read_en_0 : in std_logic;
	i_read_en_1 : in std_logic;
	i_addr_0    : in unsigned(g_addr_width - 1 downto 0);
	i_addr_1    : in unsigned(g_addr_width - 1 downto 0);
	--------------------------------------------------------------
	o_data_0    : out std_logic_vector(g_data_width - 1 downto 0);
	o_data_1    : out std_logic_vector(g_data_width - 1 downto 0)
    );
end ram;

architecture arch_ram of ram is

    type memory_t is array (natural range <>) of std_logic_vector(g_data_width - 1 downto 0);

    attribute ram_style: string;

    impure function init_mem(mem_depth : in integer) return memory_t is
	file mem_content : text open read_mode is g_init_file;
	variable fline : line;
	variable temp : memory_t(mem_depth - 1 downto 0);
	variable data : bit_vector(temp(0)'range);
    begin
	--while not endfile(mem_content) loop
	for i in 0 to mem_depth - 1 loop
	    if not endfile(mem_content) then
		readline(mem_content, fline);
		read(fline, data);
		temp(i) := to_stdlogicvector(data);
	    else
		temp(i) := (others => '0');
	    end if;
	end loop;
	return temp;
    end;

    --signal ram_mem: memory_t(2**g_addr_width-1 downto 0) := init_mem(2**g_addr_width);
    signal ram_mem: memory_t(g_depth - 1 downto 0) := init_mem(g_depth);

    attribute ram_style of ram_mem: signal is "block";

begin

    process(i_clk)
    begin
	if rising_edge(i_clk) then
	    if i_read_en_0 = '1' then
			o_data_0 <= ram_mem(to_integer(i_addr_0));
        end if;
		if i_read_en_1 = '1' then
            o_data_1 <= ram_mem(to_integer(i_addr_1));
	    end if;
	end if;
    end process;

end arch_ram;
