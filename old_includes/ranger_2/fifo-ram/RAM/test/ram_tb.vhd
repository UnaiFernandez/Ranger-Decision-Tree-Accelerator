library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ram_pkg.all;

entity ram_tb is
end ram_tb;

architecture tb of ram_tb is
    signal clk: std_logic:= '0';

    constant C_AWIDTH: integer:= 12;
    constant C_DWIDTH: integer:= 32;

    signal word_in:   std_logic_vector(C_DWIDTH-1 downto 0);
    signal word_out:  std_logic_vector(C_DWIDTH-1 downto 0);

    signal addr_a: unsigned(C_AWIDTH-1 downto 0);
    signal addr_b: unsigned(C_AWIDTH-1 downto 0);

    signal wr_en: std_logic;
begin
    -- Component Instantiaton
    -------------------------------------------------------
    MEM: RAM
    generic map (
        G_ADDR_WIDTH => C_AWIDTH,
        G_DATA_WIDTH => C_DWIDTH,
        G_INIT_FILE  => "RAM/contents/syn_mem.txt",
        G_INIT       => '1'

    )
    port map (
               i_clk     => clk,
               i_addr_a  => addr_a,
               i_addr_b  => addr_b,
               i_word_b  => word_in,
               i_wr_en_b => wr_en,
               o_word_a  => word_out
             );

    -- Simulation
    -------------------------------------------------------
    clk <= not clk after 10 ns;

    process
    begin
        wait for 50 ns;
        addr_a <= to_unsigned(0, C_AWIDTH);
        addr_b <= to_unsigned(5, C_AWIDTH);

        wait for 20 ns;
        wr_en <= '1';
        word_in <= std_logic_vector(to_unsigned(148,C_DWIDTH));

        wait for 20 ns;
        wr_en <= '0';
        wait for 30 ns;
        addr_a <= to_unsigned(5, C_AWIDTH);

        wait;
    end process;
end tb;
