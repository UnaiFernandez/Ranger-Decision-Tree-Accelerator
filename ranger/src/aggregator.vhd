library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.general_package.all;

entity aggregator is
    port (
        i_clk : in std_logic;
        i_reset : in std_logic;
        i_mat : in  mat_t;
        i_ready : in std_logic;
        o_done : out std_logic;
        o_max : out integer
        --o_resul : out cols_t
    );
end entity;   

architecture arch_aggregator of aggregator is
-- State machine
    type state is (E0, E1, E2, E3);
    signal current_s, next_s, r_state: state;

    signal en_find_max : std_logic := '0';
    signal ld_total_sum : std_logic := '0';
            
    signal sum_mat : cols_t(0 to 3);
    signal sum_mat_r : cols_t(0 to 3);
    signal max_class : integer := 0;
    signal res : unsigned(COUNT_WIDTH-1 downto 0) := (others => '0'); 

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
	      when E3 => next_s <= E0;
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


    gen_classes : for j in 0 to N_CLASSES-1 generate
        signal chunk_counts : cols_t(0 to N_CHUNKS-1);
        signal chunk_counts_r : cols_t(0 to N_CHUNKS-1);    
    begin
        -- Count votes in chunks of CHUNK_SIZE
        gen_chunks : for c in 0 to N_CHUNKS-1 generate
        begin
            u_counter : entity work.count_votes
                generic map (
                    N_INPUTS    => CHUNK_SIZE,
                    COUNT_WIDTH => COUNT_WIDTH
                )
                port map (
                    i_votes => get_chunk_votes(i_mat, j, c),
                    o_count => chunk_counts(c).val
                );
        end generate;

        process(i_clk)
        begin
            if rising_edge(i_clk) then
                chunk_counts_r <= chunk_counts;
            end if;
        end process;
                
        sum_mat(j).val <= total_sum(chunk_counts_r);
        sum_mat(j).idx <= j;
        
    end generate;
    
    --ld_total_sum <= '1' when current_s = E1 else '0';

    process(i_CLK)
    begin
        if rising_edge(i_clk) then
      --      if ld_total_sum = '1' then
                sum_mat_r <= sum_mat;
        --    end if;
        end if;
    end process;

    en_find_max <= '1' when current_s = E2 else '0';
    process(i_CLK, sum_mat_r, max_class)
    begin
        if rising_edge(i_CLK) then
            --if en_find_max = '1' then
                --find_max(sum_mat_r, max_class);
                find_max_tree(sum_mat_r, max_class);
                --max_class <= max_tree(sum_mat_r, sum_mat_r'low, sum_mat_r'high).idx;
            --end if;
        end if;
    end process;

    o_done <= '1' when current_s = E3 else '0';
    --o_resul <= sum_mat;
    o_max <= max_class;


end architecture;
