library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

use work.ranger_pkg.all;
use work.fifo_pkg.all;

entity ranger_tb is
end ranger_tb;

architecture arch_ranger_tb of ranger_tb is

constant n_width: integer := 32;
constant l_width: integer := 16;
constant depth: integer := 64;
constant g_data_width: integer := 32;
constant g_init_file: string := "./memory_content/mixed.txt";

signal clk : std_logic := '1';
signal reset : std_logic := '0';
signal data : std_logic_vector(n_width - 1 downto 0);
---------------------------------------------------------------------
signal RE_data : std_logic;
signal data_addr: unsigned(l_width - 1 downto 0);
signal class: std_logic_vector(15 downto 0);

signal re_en		: std_logic := '0';
signal wr_en		: std_logic := '0';
signal fifo_empty	: std_logic;
signal fifo_full	: std_logic;
signal class_wr: std_logic_vector(31 downto 0);
signal class_re: std_logic_vector(31 downto 0);

signal init_button	: std_logic := '0';

-------------------------------------------------------------------------
signal re_fifo, re_0, re_1 : std_logic;
signal wr_fifo : std_logic;
signal mode : std_logic;
signal wr_fifo_data : std_logic_vector(n_width - 1 downto 0);
signal fifo_data_0, fifo_data_1 : std_logic_vector(n_width - 1 downto 0);
signal addr_0, addr_1 : UNSIGNED(l_width - 1 downto 0) := (others => '0');
-------------------------------------------------------------------------
type memory_t is array (natural range <>) of std_logic_vector(g_data_width - 1 downto 0);

impure function init_mem(mem_depth : in integer) return memory_t is
    file mem_content : text open read_mode is g_INIT_FILE;
    variable fline : line;
    variable temp : memory_t(mem_depth - 1 downto 0);
    variable init_mem_data : bit_vector(temp(0)'range);
    begin
    --while not endfile(mem_content) loop
    for i in 0 to mem_depth - 1 loop
			if not endfile(mem_content) then
	    	    readline(mem_content, fline);
	    	    read(fline, init_mem_data);
	    	    temp(i) := to_stdlogicvector(init_mem_data);
	    	else
	    	    temp(i) := (others => '0');
	    	end if;
    end loop;
    return temp;
end;

signal pc_data: memory_t(depth - 1 downto 0) := init_mem(depth);
signal pc_data_addr : UNSIGNED(l_width - 1 downto 0) := (others => '0');
signal inc_pc_data_addr : STD_LOGIC := '0';


signal axi_data : std_logic_vector(g_data_width - 1 downto 0);
signal wr_axi_data : std_logic;
begin

DT_RANGER: ranger
generic map(
    g_dt_instances  => 2,
    g_mem_depth    => 64,
    g_data_width    => 32,
    g_addr_width    => 16
)
port map(
    i_clk	        => clk,
    i_reset	        => reset,
    init	        => init_button,
    i_data_mem	    => axi_data,
    i_wr_data	    => wr_axi_data,
    o_class_fifo    => class
);



process(clk, inc_pc_data_addr)
begin
    if rising_edge(clk) then
        if inc_pc_data_addr = '1' then
            pc_data_addr <= pc_data_addr + 1;
        end if;
    end if;
end process;


clk <= not clk after 10 ns;


process
begin

 -- while not full

    --for index in 0 to depth - 6 loop -- Tener en cuenta
    --    axi_data <= pc_data(index);
    --    wait for 10 ns;
    --    wr_axi_data <= '1';
    --    wait for 10 ns;
    --    wr_axi_data <= '0';
    --end loop;

    wait for 20 ns;
    init_button <= '1';
    wait for 20 ns;
    init_button <= '0';
    wr_axi_data <= '0';

    wait;
end process;

end arch_ranger_tb;
