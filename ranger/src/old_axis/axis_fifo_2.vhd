library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fifo_pkg.all;
use work.axis_fifo_pkg.all;

entity axis_fifo is
    generic(
	g_DATA_WIDTH: integer;
	g_ADDR_WIDTH: integer;
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
    	m00_TVALID		: out std_logic;
    	m00_TLAST		: out std_logic;
    	m00_TDATA		: out std_logic_vector(g_DATA_WIDTH - 1 downto 0);
    	s00_TREADY		: out std_logic
    );
end axis_fifo;

architecture arch_axis_fifo of axis_fifo is
-- State machine
    type state is (E0, E1, E2);
    signal current_s, next_s: state;

    signal fifo_full, fifo_empty, fifo_last : std_logic;
    signal re_fifo, wr_fifo : std_logic;

	signal ld_buf, buf_busy : std_logic := '0';
	signal buf_data, data : std_logic_vector(g_DATA_WIDTH - 1 downto 0);
begin
-- State machine

    process(current_s, next_s, m00_TREADY, fifo_empty)
    begin
	case current_s is
		when E0 => if fifo_empty = '1' then next_s <= E0;
					else next_s <= E1;
					end if;
	    when E1 => next_s <= E2;
	    when E2 => if m00_TREADY = '0' then next_s <= E2;
				  elsif m00_TREADY = '1' and fifo_empty = '1' then next_s <= E0;
		       else next_s <= E1;
		       end if;
	end case;
    end process;

-- CLK, RESET and HALT

    process(i_CLK, i_RESET)
    begin
        if i_RESET = '1' then 
	    current_s <= E0;
	    --c_node_mem_out <= (others => '0');
	    --feature <= (others => '0');
        elsif rising_edge(i_CLK) then current_s <= next_s;
        end if;
    end process;


    FIFO_MEM: fifo
    generic map(
        g_depth	        => g_DEPTH,
        g_data_width    => g_DATA_WIDTH,
	g_init_mem	=> g_INIT_MEM,
        g_addr_width    => g_ADDR_WIDTH
    )
    port map(
        i_clk	        => i_clk,
        i_reset	        => i_reset,
        i_re_fifo	=> re_fifo,
        i_wr_fifo	=> wr_fifo,
        i_wr_data	=> s00_TDATA, -- not used
        o_data_0	=> m00_TDATA,
        o_data_1	=> m00_TDATA,
        o_fifo_empty    => fifo_empty,
		o_fifo_last	=> fifo_last,
        o_fifo_full	=> fifo_full
    );

	--ld_buf <= '1' when buf_busy = '0' and m00_TREADY = '1' else '0';
	--process(i_CLK, ld_buf)
	--begin
	--	if rising_edge(i_CLK) then
	--		if ld_buf = '1' then
	--			buf_data <= m00_TDATA; --copy data from fifo to buffer
	--			buf_busy <= '1';
	--		else
	--			buf_busy <= '0';
	--		end if;
	--	end if;
	--end process;
    
	--process(i_CLK, m00_TREADY)
	--begin
	--	if rising_edge(i_CLK) then
	--		if m00_TREADY = '1' then
	--			re_fifo <= '1';
	--		else
	--			re_fifo <= '0';
	--		end if;
	--	end if;
	--end process;
	re_fifo <= '1' when current_s = E1 else '0';
    wr_fifo <= s00_TVALID and not fifo_full;

    --m00_TVALID <= '1' when buf_busy = '1' else '0';
    m00_TVALID <= '1' when current_s = E2 else '0';
	m00_TLAST <= '1' when fifo_last = '1' and m00_TVALID = '1' else '0';
    s00_TREADY <= '1' when fifo_full = '0' else '0';

end arch_axis_fifo;
