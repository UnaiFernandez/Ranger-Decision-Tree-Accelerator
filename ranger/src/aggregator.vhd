library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use work.utils_tree.all;
use work.general_package.all;

entity aggregator is
    port (
        i_clk : in std_logic;
        i_mat : in  mat_t;
        o_resul : out cols_t_2
    );
end entity;   

architecture arch_aggregator of aggregator is
            
signal res : unsigned(COUNT_WIDTH-1 downto 0); 

begin
    gen_classes : for j in 0 to N_CLASSES-1 generate
        signal votes_j      : std_logic_vector(N_ESTIMATORS-1 downto 0);
        signal chunk_counts : cols_t_2(0 to N_CHUNKS-1);
        signal chunk_counts_r : cols_t_2(0 to N_CHUNKS-1);    
    begin
        -- Count votes in chunks of CHUNK_SIZE
        -- ToDo: Se puede pasar a una funcion en general_package
        -- function get_chunk_votes(mat: mat_t; j: integer; c: integer) return std_logic_vector is
        gen_chunks : for c in 0 to N_CHUNKS-1 generate
            signal votes_chunk : std_logic_vector(CHUNK_SIZE-1 downto 0);
        begin
            process(all)
            begin
                votes_chunk <= (others => '0');
                for k in 0 to CHUNK_SIZE-1 loop
                    if (c * CHUNK_SIZE + k) < N_ESTIMATORS then
                        votes_chunk(k) <= i_mat(c * CHUNK_SIZE + k)(j);
                    end if;
                end loop;
            end process;

            u_counter : entity work.count_votes
                generic map (
                    N_INPUTS    => CHUNK_SIZE,
                    COUNT_WIDTH => COUNT_WIDTH
                )
                port map (
                    i_votes => votes_chunk,
                    o_count => chunk_counts(c)
                );
        end generate;

        process(i_clk)
        begin
            if rising_edge(i_clk) then
                chunk_counts_r <= chunk_counts;
            end if;
        end process;


        -- Sum all partial counts 
        process(i_clk)
            variable total : unsigned(COUNT_WIDTH-1 downto 0); 
        begin 
            total := (others => '0'); 
            for c in 0 to N_CHUNKS-1 loop 
                 total := total + chunk_counts_r(c); 
            end loop;
            if rising_edge(i_clk) then
                res <= total;
            end if;
            --o_resul(j) <= total;
        end process;
        
        o_resul(j) <= res;

        --process(i_clk)
        --begin
         --   if rising_edge(i_clk) then
           --     o_resul(j) <= res;
           --- end if;
        --end process;
    end generate;
end architecture;
