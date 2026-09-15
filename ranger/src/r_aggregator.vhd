library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.general_package.all;

entity r_aggregator is
    port (
        i_clk : in std_logic;
        i_reset : in std_logic;
        i_mat : in  mat_t;
        i_ready : in std_logic;
        o_done : out std_logic;
        o_max : out unsigned(addr_width - 1 downto 0)
        --o_resul : out cols_t
    );
end entity;   

architecture arch_r_aggregator of r_aggregator is
-- State machine
    type state is (E0, E1, E2, E3, E4);
    signal current_s, next_s, r_state: state;

    signal en_find_max : std_logic := '0';
    signal ld_total_sum : std_logic := '0';
            
    signal sum_mat : cols_t(0 to n_classes - 1);
    signal sum_mat_r : cols_t(0 to n_classes - 1);
    signal max_class : integer := 0;
    signal res : unsigned(COUNT_WIDTH-1 downto 0) := (others => '0'); 
--------------------------------
    signal c_sum: cols_r_t(0 to N_CHUNKS-1);
    signal c_sum_r: cols_r_t(0 to N_CHUNKS-1);
    signal t_sum : unsigned(data_width - 1 downto 0);
    signal final_value : unsigned(data_width - 1 downto 0) := (others => '0');
    signal ld_final_value : std_logic := '0';
    signal calc_done: std_logic := '0';
    signal ld_c_sum : std_logic := '0';
begin
-- State machine

    process(current_s, i_ready)
    begin
	  case current_s is
	      when E0 => if i_ready = '1' then next_s <= E1;
	  				  else next_s <= E0;
	  				  end if;
	      when E1 => next_s <= E2;
	      when E2 => next_s <= E3;
	      when E3 => next_s <= E4;
	      when E4 => next_s <= E0;
	  end case;
    end process;

-- CLK, RESET and HALT

    process(i_CLK, i_RESET)
    begin
        if rising_edge(i_CLK) then 
        	  if i_RESET = '1' then 
	    		      current_s <= E0;
			      else
				        current_s <= next_s;
        	  end if;
        end if;
    end process;


    ld_c_sum <= '1' when current_s = E1 else '0';
    gen_chunks : for c in 0 to N_CHUNKS-1 generate
    begin
        process(i_clk)
        begin
            if rising_edge(i_clk) then
                if ld_c_sum = '1' then
                    c_sum(c) <= get_chunk_sum(i_mat, c);
                end if;
            end if;
        end process;
    end generate;


    ld_total_sum <= '1' when current_s = E2 else '0';
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if ld_total_sum = '1' then
                t_sum <= total_sum_r(c_sum);
            end if;
        end if;
    end process;


    ld_final_value <= '1' when current_s = E3 else '0';
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if ld_final_value = '1' then 
                final_value <= t_sum / n_estimators;
                calc_done <= '1';
            else
                calc_done <= '0';
            end if;
        end if;
    end process;

    o_done <= '1' when current_s = E4 else '0';
    o_max <= final_value(addr_width - 1 downto 0);

end architecture;
