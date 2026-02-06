library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dt_ctl_pkg.all;
use work.ram_pkg.all;
use work.fifo_pkg.all;
use work.dt_accel_pkg.all;

entity dt_accel is
    generic(
        g_DATA_WIDTH: integer := 32;
        g_ADDR_WIDTH: integer := 16;
	g_K	    : integer := 4;
        g_DEPTH	    : integer := 512
    );
    port(
        i_CLK	    : in std_logic;
        i_RESET	    : in std_logic;
        i_ENABLE    : in std_logic;
        i_SEL	    : in std_logic;
        i_GET_DATA  : in std_logic;
        i_DATA_ADDR : in UNSIGNED(g_ADDR_WIDTH - 1 downto 0);
        i_DATA_MEM  : in std_logic_vector(g_DATA_WIDTH - 1 downto 0);
	    i_CALC_RESULT : in std_logic;
        ----------------------------------------------------
        --o_CLASS	    : out std_logic_vector(g_K - 1 downto 0);
	o_CLASS	: out std_logic_vector(g_K - 1 downto 0);
        o_DONE	    : out std_logic
    );
end dt_accel;

architecture arch_dt_accel of dt_accel is

-- NODE MEM
    signal node_info : std_logic_vector(g_DATA_WIDTH - 1 downto 0);
    signal threshold : std_logic_vector(g_DATA_WIDTH - 1 downto 0);
    signal RE_node : std_logic := '0';
    signal RE_thr : std_logic := '0';
    signal node_addr_0: unsigned(g_ADDR_WIDTH - 1 downto 0);
    signal thr_addr: unsigned(g_ADDR_WIDTH - 1 downto 0);

-- DATA MEM
    signal RE_int_data : std_logic := '0';
    signal int_data_addr: unsigned(g_ADDR_WIDTH - 1 downto 0);
    signal int_data : std_logic_vector(g_DATA_WIDTH - 1 downto 0);

-- DT_CTL
    --signal class: std_logic_vector(g_K - 1 downto 0);
    signal class: std_logic_vector(15 downto 0);

-- DT ACCEL control signals
    signal task_terminated : STD_LOGIC;

-- ONE HOT REPRESENTATION
    --signal one_hot : std_logic_vector(g_K - 1 downto 0) := (0 => '1', others => '0');
    --signal o_h : std_logic_vector(g_K - 1 downto 0) := (0 => '1', others => '0');

begin

-- NODE MEMORY
    NODE_MEM: ram
    generic map(
        g_ADDR_WIDTH	=> g_ADDR_WIDTH,
        g_DATA_WIDTH	=> g_DATA_WIDTH,
        --g_DEPTH		=> g_DEPTH,
        g_DEPTH		=> 254,
        g_INIT_FILE	=> "/home/makinote/Project/vivado/dt_vhdl/ranger/memory_content/bin_node_mem_content.txt",
        --g_INIT_FILE	=> "./memory_content/bin_node_mem_content.txt",
        g_INIT		=> '0'
    )
    port map(
        i_CLK		=> i_clk,
        i_RE_0		=> RE_node,
        i_RE_1		=> RE_thr,
        i_WE_1		=> i_SEL,
        i_ADDR_0	=> node_addr_0,
        i_ADDR_1	=> thr_addr,
        i_WR_ADDR	=> i_DATA_ADDR,
        i_DATA_1	=> i_DATA_MEM,
        o_DATA_0	=> node_info,
        o_DATA_1	=> threshold
    );

-- INTERNAL DATA MEMORY
    INT_DATA_MEM: ram
    generic map(
        g_ADDR_WIDTH	=> g_ADDR_WIDTH,
        g_DATA_WIDTH	=> g_DATA_WIDTH,
        --g_DEPTH		=> g_DEPTH,
        g_DEPTH		=> 64,
        g_INIT_FILE	=> "/home/makinote/Project/vivado/dt_vhdl/ranger/memory_content/data_mem_content.txt",
        --g_INIT_FILE	=> "./memory_content/data_mem_content.txt",
        g_INIT		=> '0'
    )
    port map(
        i_CLK		=> i_clk,
        i_RE_0		=> RE_int_data,
        i_RE_1		=> RE_int_data,
        i_WE_1		=> i_GET_DATA,
        i_ADDR_0	=> int_data_addr,
        i_ADDR_1	=> int_data_addr,
        i_WR_ADDR	=> i_data_addr,
        i_DATA_1	=> i_DATA_MEM,
        o_DATA_0	=> int_data,
        o_DATA_1	=> int_data
    );

-- DT CONTROL
    DT: dt_ctl
    generic map(
        g_NODE_WIDTH	=> g_DATA_WIDTH,
        g_LINK_WIDTH	=> g_ADDR_WIDTH,
        g_DATA_WIDTH	=> g_DATA_WIDTH,
        g_SPAN		=> 4
    )
    port map(
        i_clk		=> i_clk,
        i_reset		=> i_reset,
        i_ENABLE	=> i_enable,
        i_node_info	=> node_info,
        i_threshold	=> threshold,
        i_data_out	=> int_data,
        i_calc_result	=> i_calc_result,
        o_RE_node	=> RE_node,
        o_RE_thr	=> RE_thr,
        o_RE_data	=> RE_int_data,
        o_node_addr	=> node_addr_0,
        o_thr_addr	=> thr_addr,
        o_data_addr	=> int_data_addr,
        o_DONE		=> task_terminated,
        o_class		=> class
    );

    o_DONE <= '1' when task_terminated = '1' else '0';


	process(i_CLK, task_terminated, class)
		variable o_h_v : std_logic_vector(g_K - 1 downto 0) := (others => '0');
		variable idx : integer;
	begin
		if rising_edge(i_CLK) then
			o_h_v := (others => '0');
			if task_terminated = '1' then
				idx := to_integer(unsigned(class));
				o_h_v(idx) := '1';
			end if;
			o_CLASS <= o_h_v;
		end if;
	end process;

end arch_dt_accel;
