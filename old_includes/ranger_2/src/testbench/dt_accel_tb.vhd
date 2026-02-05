library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dt_accel_pkg.all;
use work.ram_pkg.all;
use work.fifo_pkg.all;

entity dt_accel_tb is
end dt_accel_tb;

architecture arch_dt_accel_tb of dt_accel_tb is

    constant g_data_width: integer := 32;
    constant g_addr_width: integer := 16;

    signal clk : std_logic := '1';
    signal reset : std_logic := '0';
    signal data : std_logic_vector(g_data_width - 1 downto 0);
    ---------------------------------------------------------------------
    signal RE_data : std_logic := '0';
    signal data_addr: unsigned(g_addr_width - 1 downto 0);
    signal class: std_logic_vector(15 downto 0);

    signal re_en		: std_logic:= '0';
    signal wr_en		: std_logic;
    signal rd_data		: std_logic_vector(g_addr_width - 1 downto 0);
    signal fifo_empty	: std_logic;
    signal fifo_full	: std_logic;

    signal rd_mem : std_logic := '0';

    signal enable, sel, get_data : std_logic := '0';
    signal o_addr_data_mem : unsigned(16 - 1 downto 0);

    signal grant : std_logic;
    signal done : std_logic;

    signal config_done, data_copied : std_logic := '0';

-- State machine
    type state is (E0, E1, E2);
    signal current_s, next_s: state;

    signal CL_c_data_addr, INC_c_data_addr : std_logic := '0';
    signal c_data_addr_out : unsigned(g_ADDR_WIDTH - 1 downto 0);

begin

-- State machine

    process(current_s, next_s, config_done, data_copied, done)
    begin
	    case current_s is
	        when E0 => if config_done = '1' then next_s <= E1;
		        else next_s <= E0;
		        end if;
	        when E1 => if data_copied = '1' then next_s <= E2;
		        else next_s <= E1;
		        end if;
		when E2 => if done = '1' then next_s <= E1;
		        else next_s <= E2;
		        end if;

	        --when E2 => next_s <= E0;
	    end case;
    end process;

-- CLK

    process(clk, reset)
    begin
	    if reset = '1' then current_s <= E0;
	    elsif rising_edge(clk) then current_s <= next_s;
	    end if;
    end process;

-- DATA ADDR COUNTER


    CL_c_data_addr <= '1' when (current_s = E0 and config_done = '1') or (current_s = E2 and done = '1') else '0';
    INC_c_data_addr <= '1' when current_s = E1 and data_copied = '0' else '0';

    process(clk, CL_c_data_addr)
    begin
	if CL_c_data_addr = '1' then data_addr <= (others => '0');
	elsif rising_edge(clk) then
	    if INC_c_data_addr = '1' then
		data_addr <= data_addr + 1;
	    end if;
	end if;
    end process;

    data_copied <= '1' when data_addr >= 3 else '0';
-- DATA_MEM

     DATA_MEM: fifo
    generic map(
        g_depth	        => 256,
        g_data_width    => g_data_width,
	g_init_mem	=> '1',
        g_addr_width    => g_addr_width
    )
    port map(
        i_clk	        => clk,
        i_reset	        => reset,
        i_re_fifo	    => re_en,
        i_wr_fifo	    => '0',
        i_wr_data	    => X"00000000",
        o_data_0	    => data,
        o_data_1	    => data,
        o_fifo_empty    => fifo_empty,
        o_fifo_full	    => fifo_full
    );



-- DT_ACCELERATOR

    DT_ACCELERATOR: dt_accel
    generic map(
        g_DATA_WIDTH => 32,
        g_ADDR_WIDTH => 16,
	g_K => 16,
        g_DEPTH => 256
    )
    port map(
        i_clk => clk,
        i_reset => reset,
        i_data_mem => data,
        i_ENABLE => enable,
        i_SEL => sel,
        i_GET_DATA => get_data,
        i_DATA_ADDR => data_addr,
        i_calc_result => '0',
        --o_class => class,
	o_done => done
    );


-- Simulation

    clk <= not clk after 10 ns;

    enable <= '1' when current_s = E1 and data_copied = '1' else '0';
    re_en <= '1' when (current_s = E0 and config_done = '1') or current_s = E1 else '0';
    get_data <= '1' when current_s = E1 else '0';

    process
    begin
	wait for 40 ns;
	config_done <= '1';
	wait for 20 ns;
	config_done <= '0';
        --enable <= '1';
        --wait for 20 ns;
        --enable <= '0';
        --wait for 400 ns;
	--re_en <= '1';
	--wait for 20 ns;
	--get_data <= '1';
	--wait for 100 ns;
	--re_en <= '0';
	--wait for 20 ns;
	--get_data <= '0';
        --enable <= '1';
        --wait for 20 ns;
        --enable <= '0';
        wait;
    end process;


end arch_dt_accel_tb;
