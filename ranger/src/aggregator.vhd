library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.general_package.all;

entity aggregator is
    port (
        i_clk : in std_logic;
        i_mat : in  mat_t;
        o_resul : out cols_t
    );
end entity;   

architecture arch_aggregator of aggregator is
            
signal res : unsigned(COUNT_WIDTH-1 downto 0) := (others => '0'); 

begin
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
                    o_count => chunk_counts(c)
                );
        end generate;

        process(i_clk)
        begin
            if rising_edge(i_clk) then
                chunk_counts_r <= chunk_counts;
            end if;
        end process;

        o_resul(j) <= total_sum(chunk_counts_r);

    end generate;
end architecture;
