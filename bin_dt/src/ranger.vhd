library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dt_accel_pkg.all;
use work.ram_pkg.all;
use work.fifo_pkg.all;
use work.ranger_pkg.all;
use work.configurator_pkg.all;

entity ranger is
    generic(
	g_dt_instances : integer;
	g_fifo_depth : integer;
	g_data_width : integer;
	g_addr_width : integer
    );
    port(
	i_clk : in std_logic;
	i_reset : in std_logic;
	i_data_mem : in std_logic_vector(g_data_width - 1 downto 0);
	init : in std_logic;
	o_RE_data : out std_logic;
	o_addr_data_mem : out unsigned(g_addr_width - 1 downto 0);
	o_class_fifo : out std_logic_vector(g_addr_width - 1 downto 0)
    );
end ranger;

architecture arch_ranger of ranger is

-- State machine
type state is (E0, E1, E2);
signal current_s, next_s: state;

signal re_en		: std_logic;
signal wr_en		: std_logic;
signal fifo_empty	: std_logic;
signal fifo_full	: std_logic;
signal class		: std_logic_vector(g_addr_width - 1 downto 0);

signal sel		    : std_logic_vector(g_dt_instances - 1 downto 0);


signal config_done, en_config, inc_data_addr: std_logic;
signal re_data : std_logic;
signal dt_id : std_logic_vector(7 downto 0);

signal inf_done :std_logic;

signal data_addr : UNSIGNED(g_ADDR_WIDTH - 1 downto 0);

begin
-- State machine

process(current_s, next_s, init, config_done, inf_done)
begin
	case current_s is
	    when E0 => if init = '1' then next_s <= E1;
		       else next_s <= E0;
		       end if;
	    when E1 => if config_done = '1' then next_s <= E2;
		       else next_s <= E1;
		       end if;
	    when E2 => if config_done = '1' then next_s <= E0;
		       else next_s <= E2;
		       end if;
	end case;
end process;

-- CLK

process(i_clk, i_reset)
begin
	if i_reset = '1' then current_s <= E0;
	elsif rising_edge(i_clk) then current_s <= next_s;
	end if;
end process;

en_config <= '1' when current_s = E1 else '0';

-- DECODER

process(dt_id)
begin
    sel <= (others => '0');
    if dt_id /= "UUUUUUUU" then
        sel(to_integer(unsigned(dt_id))) <= '1';
    end if;
end process;

-- Generate multiple instances of DT_ACCEL
DT_ACCELERATOR:
for I in 0 to g_dt_instances - 1 generate
    DT_ACCEL_X : dt_accel
    generic map(
        g_DATA_WIDTH => g_DATA_WIDTH,
        g_ADDR_WIDTH => g_ADDR_WIDTH,
	g_DEPTH => 256
    )
    port map(
        i_clk => i_clk,
        i_reset => i_reset,
        i_data => i_data_mem,
        i_RE_CLASS => re_en,
        i_CONFIG_DONE => config_done,
        i_SEL => sel(I),
        i_DATA_ADDR => data_addr,
        o_RE_data => re_data,
        o_data_addr => o_addr_data_mem,
        o_class => class
    );
end generate DT_ACCELERATOR;

-- CONFIGURATOR

CONFIG: configurator
generic map(
    g_dt_number => g_dt_instances,
    g_addr_width => g_addr_width
)
port map(
    i_clk => i_clk,
    i_reset => i_reset,
    i_en_config => en_config,
    i_data => i_data_mem,
    o_dt_id => dt_id,
    o_data_addr => data_addr,
    o_config_done => config_done,
    o_re_data => o_RE_data
);

p_ASSERT : process (i_CLK) is
begin
    if rising_edge(i_CLK) then
        if config_done = '1' then
	    report "Configuration done" severity note;
        end if;
    end if;
end process p_ASSERT;

-- Counter



-- Elements:
--     - Counter
--     - Decoder
-- sel iual tiene que ser una señal independiente a ka de wr en la RAM, para poder controlar tambien los registros de ID y el del sesgo, de cara al scheduler y el AVG


end arch_ranger;
