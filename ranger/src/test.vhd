library ieee;

use ieee.std_logic_1164.all;
use work.test_pkg.all;

entity test is
	port(
		s00_ACLK			: in std_logic;
    	s00_ARESETN			: in std_logic;
		m00_ACLK			: in std_logic;
    	m00_ARESETN			: in std_logic;
    	s00_TVALID		: in std_logic; 
    	s00_TLAST		: in std_logic; 
    	s00_TDATA		: in std_logic_vector(31 downto 0); 
    	m00_TREADY		: in std_logic; 
    	----------------------------------------------------
    	m00_TVALID		: out std_logic;
    	m00_TLAST		: out std_logic;
    	m00_TDATA		: out std_logic_vector(31 downto 0);
    	s00_TREADY		: out std_logic
		
		);
end test;

architecture test_arch of test is

type state is (E0, E1, E2, E3, E4);
signal current_s, next_s, r_state: state;

signal ld_data, en_data, en_ready, en_valid, en_last: std_logic := '0';
signal r_out : std_logic_vector(31 downto 0);

begin

-- State machine

    process(current_s, next_s, s00_TVALID, m00_TREADY)
    begin
	case current_s is
	    when E0 => if s00_TVALID = '1' then next_s <= E1;
					else next_s <= E0;
					end if;
	    when E1 => next_s <= E2;
	    when E2 => next_s <= E3;
		when E3 => if m00_TREADY = '1' then next_s <= E4;
					else next_s <= E3;
					end if;
		when E4 => next_s <= E0;
	end case;
    end process;

-- CLK, RESET and HALT

    process(s00_ACLK, s00_ARESETN)
    begin

        if rising_edge(s00_ACLK) then 
		    if s00_ARESETN = '1' then 
				current_s <= E0;
		    else
				current_s <= next_s;
		    end if;
        end if;
    end process;

	ld_data <= '1' when current_s = E2 else '0';

	process(s00_ACLK, ld_data, s00_TDATA)
	begin
		if rising_edge(s00_ACLK) then
			if ld_data = '1' then
				r_out <= s00_TDATA(30 downto 0) & s00_TDATA(31);
			end if;
		end if;
	end process;


	en_ready <= '1' when current_s = E1 else '0';
	en_valid <= '1' when current_s = E4 else '0';
	en_last <= '1' when current_s = E4 else '0';
	en_data <= '1' when current_s = E4 else '0';

	m00_TVALID <= '1' when en_valid = '1' else '0';
	m00_TDATA <= r_out;
	m00_TLAST <= s00_TLAST when en_last = '1' else '0';
	s00_TREADY <= m00_TREADY when en_ready = '1' else '0';
		
end test_arch;
