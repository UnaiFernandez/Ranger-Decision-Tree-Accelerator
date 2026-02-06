library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package ram_pkg is

    -- Component Declaration 
    -------------------------------------------------------
    component ram is
        generic (
            -- G_INIT_FILE:  string    := "RAM/contents/random.txt";
            -- G_INIT:       std_logic := '0';
            G_ADDR_WIDTH: integer   := 16;
            G_DATA_WIDTH: integer   := 32
        );
        port (
            i_clk:      in  std_logic;
            -- i_word_a:   in  std_logic_vector(G_DATA_WIDTH-1 downto 0);
            i_addr_a:   in  unsigned(G_ADDR_WIDTH-1 downto 0);
            -- i_wr_en_a:  in  std_logic;
            i_word_b:   in  std_logic_vector(G_DATA_WIDTH-1 downto 0);
            i_addr_b:   in  unsigned(G_ADDR_WIDTH-1 downto 0);
            i_wr_en_b:  in  std_logic;
            o_word_a:   out std_logic_vector(G_DATA_WIDTH-1 downto 0)
            -- o_word_b:   out std_logic_vector(G_DATA_WIDTH-1 downto 0)
        );
    end component;

end ram_pkg;
