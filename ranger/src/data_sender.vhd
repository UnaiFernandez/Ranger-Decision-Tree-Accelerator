library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.data_sender_pkg.all;
use work.fifo_pkg.all;

entity data_sender is
		port(
			i_CLK		: in std_logic;
			i_RESET		: in std_logic;
			init	: in std_logic;
	--------------------------------------------------------
			o_TLAST		: out std_logic;
			o_TVALID	: out std_logic;
			o_TDATA		: out std_logic_vector(31 downto 0)
			);
	end data_sender;

architecture arch_data_sender of data_sender is

-- State machine
    type state is (E0, E1, E2);
    signal current_s, next_s: state;
	


	signal re_fifo, fifo_empty, fifo_last, fifo_full : std_logic;
	signal valid : std_logic;

begin

-- State machine

    process(current_s, next_s, init, fifo_empty)
    begin
    	case current_s is
    	    when E0 => if init = '1' then next_s <= E1;
    		       else next_s <= E0;
    		       end if;
		    when E1 => next_s <= E2;
    	    when E2 => if fifo_empty = '1' then next_s <= E0;
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


		re_fifo <= '1' when current_s = E1 or current_s = E2 else '0';
		valid <= '1' when current_s = E2 else '0';

		FIFO_MEM: fifo
    generic map(
        g_depth	        => 3096,
        g_data_width    => 32,
	g_init_mem	=> '1',
        g_addr_width    => 16
    )
    port map(
        i_clk	        => i_clk,
        i_reset	        => i_reset,
        i_re_fifo	=> re_fifo,
        i_wr_fifo	=> '0',
        i_wr_data	=> X"00000000", -- not used
        o_data_0	=> o_TDATA,
        o_data_1	=> o_TDATA,
        o_fifo_empty    => fifo_empty,
	o_fifo_last	=> fifo_last,
        o_fifo_full	=> fifo_full
    );

	o_TLAST <= fifo_last;
	o_TVALID <= valid; 



end arch_data_sender;
