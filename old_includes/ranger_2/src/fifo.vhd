library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ram_pkg.all;
-- use work.fifo_pkg.all;
use work.utils_pkg.all;

entity fifo is
    generic (
        -- G_INIT_FILE:  string    := "";
        -- G_INIT:       std_logic := '0';
        G_MAX_ADDR:   integer   := 1024;
        G_DATA_WIDTH: integer   := 32
    );
    port (
        i_clk:      in std_logic;
        i_rst:      in std_logic;
        o_is_full:  out std_logic;
        o_is_empty: out std_logic;

        -- SLAVE AXI
        s00_axis_aclk:      in std_logic;
        s00_axis_aresetn:   in std_logic;
        s00_axis_tready:    out std_logic;
        s00_axis_tdata:     in std_logic_vector(G_DATA_WIDTH-1 downto 0);
        s00_axis_tlast:     in std_logic;
        s00_axis_tvalid:    in std_logic;

        -- MASTER AXI
        m00_axis_aclk:      in std_logic;
        m00_axis_aresetn:   in std_logic;
        m00_axis_tvalid:    out std_logic;
        m00_axis_tdata:     out std_logic_vector(G_DATA_WIDTH-1 downto 0);
        m00_axis_tlast:     out std_logic;
        m00_axis_tready:    in std_logic

        -- i_rd:       in std_logic;
        -- i_wr:       in std_logic;
        -- i_data:     in std_logic_vector(G_DATA_WIDTH-1 downto 0);
        -- o_t_valid:  out std_logic;
        -- o_is_full:  out std_logic;
        -- o_is_empty: out std_logic;
        -- o_data:     out std_logic_vector(G_DATA_WIDTH-1 downto 0)
    );
end fifo;

architecture arch_fifo of fifo is
    constant C_AWIDTH: integer := 16;

    -- Data Counter
    signal is_empty: std_logic;
    signal is_space: std_logic;
    signal dc:       unsigned(C_AWIDTH-1 downto 0);

    -- AXI control
    signal axi_rd: std_logic;
    signal axi_wr: std_logic;
    signal t_last: std_logic;

    -- Data buffer
    signal dbuffer:     std_logic_vector(G_DATA_WIDTH-1 downto 0);
    signal is_buffered: std_logic;
    signal to_buffer:   std_logic;

    -- Muxes
    signal wr_data:  std_logic;
    signal rd_data:  std_logic;

    -- Address counters
    signal rd_addr: unsigned(C_AWIDTH-1 downto 0);
    signal wr_addr: unsigned(C_AWIDTH-1 downto 0);

    signal end_rd: std_logic;
    signal end_wr: std_logic;

    -- Register
    signal rd_data_reg: std_logic;

    -- Memory
    signal word_a: std_logic_vector(G_DATA_WIDTH-1 downto 0);

	signal init : std_logic := '1';

begin
    -- OUTPUT
    m00_axis_tdata  <= dbuffer;
    m00_axis_tlast  <= t_last;
    m00_axis_tvalid <= is_buffered;

    s00_axis_tready <= is_space;

    o_is_full  <= not is_space;
    o_is_empty <= is_empty and (to_buffer);

    -- Data counter
    process(i_clk, i_rst, wr_data, rd_data, init)
    begin
        if rising_edge(i_clk) then
            if i_rst = '1' then
                dc <= (others => '0');
            else
				if init = '1' then
					dc <= to_unsigned(G_MAX_ADDR - 1, dc'length);
					init <= '0';
				end if;
                if wr_data = '1' and rd_data = '0' then
                    dc <= dc + 1;
                elsif rd_data = '1' and wr_data = '0' then
                    dc <= dc - 1;
                end if;
            end if;
        end if;
    end process;
    is_empty <= '1' when dc = to_unsigned(0, C_AWIDTH) else '0';
    is_space <= '1' when dc < G_MAX_ADDR-1             else '0';
    t_last   <= '1' when dc = to_unsigned(0, C_AWIDTH) and is_buffered = '1' else '0';

    -- AXI control
    axi_wr <= wr_data;
    axi_rd <= is_buffered and m00_axis_tready;

    -- Data buffer and rd_data reg
    -- process (i_clk, i_rst, rd_data_reg, axi_rd)
    -- begin
    --     if i_rst = '1' then
    --         is_buffered <= '0';
    --         dbuffer <= (others => '0');
    --         rd_data_reg <= '0';
    --     elsif rising_edge(i_clk) then
    --         if rd_data_reg = '1' then
    --             dbuffer <= word_a;
    --             is_buffered <= '1';
    --         elsif axi_rd = '1' then
    --             is_buffered <= '0';
    --         end if;
    --         rd_data_reg <= rd_data;
    --     end if;
    -- end process;
    process (i_clk, i_rst, rd_data_reg, axi_rd)
    begin
        if rising_edge(i_clk) then
            if i_rst = '1' then
                is_buffered <= '0';
                dbuffer <= (others => '0');
                rd_data_reg <= '0';
            else
                if rd_data_reg = '1' then
                    dbuffer <= word_a;
                    is_buffered <= '1';
                elsif axi_rd = '1' then
                    is_buffered <= '0';
                end if;
                rd_data_reg <= rd_data;
            end if;
        end if;
    end process;

    to_buffer <= (not is_buffered and not rd_data_reg);

    -- Muxes
    rd_data <= (axi_rd or to_buffer) and (not is_empty);
    wr_data <= s00_axis_tvalid and is_space;

    -- Address counters  TODO: creo que estas condiciones pueden ir mas elegantes
    process(i_clk, i_rst, end_rd, rd_data)
    begin
        if rising_edge(i_clk) then
            if i_rst = '1' then
                rd_addr <= (others => '0');
                wr_addr <= (others => '0');
            else
                if rd_data = '1' then
                    if end_rd = '1' then
                        rd_addr <= (others => '0');
                    else
                        rd_addr <= rd_addr + 1;
                    end if;
                end if;

                if end_wr = '1' then
                    wr_addr <= (others => '0');
                elsif wr_data = '1' then
                    wr_addr <= wr_addr + 1;
                end if;
            end if;
        end if;
    end process;
    end_rd <= '1' when rd_addr = G_MAX_ADDR-1 else '0';
    end_wr <= '1' when wr_addr = G_MAX_ADDR-1 else '0';

    -- Memory
    BUFF: ram
     generic map(
        -- G_INIT_FILE  => G_INIT_FILE,
        -- G_INIT       => G_INIT,
        g_ADDR_WIDTH => C_AWIDTH,
		g_DEPTH => G_MAX_ADDR,
		g_INIT_FILE	=> "./memory_content/random_forest.txt",
        g_INIT		=> init,
        g_DATA_WIDTH => G_DATA_WIDTH
    )
     port map(
        i_clk     => i_clk,
		i_RE_0    => rd_data,
		i_RE_1	  => rd_data,
		i_WE_1	  => wr_data,
		i_ADDR_0  => rd_addr,
		i_ADDR_1  => rd_addr,
		i_WR_ADDR => wr_addr,
		o_DATA_0  => word_a,
		i_DATA_1  => s00_axis_tdata
    );

end arch_fifo;

