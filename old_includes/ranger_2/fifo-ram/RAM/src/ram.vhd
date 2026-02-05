library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.ram_pkg.all;

entity ram is
        generic (
            -- G_INIT_FILE:  string    := "";
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
end ram;

architecture arch_ram of ram is
    attribute ram_style: string; -- auto | block | distributed | pipe_distributed | block_power1 | block_power2 | ultra
    type memory_t is array (natural range <>) of std_logic_vector(G_DATA_WIDTH-1 downto 0);

    impure function init_mem(mem_depth: in integer) return memory_t is
        -- FILE contents : text is G_INIT_FILE;
        variable fline : line;
        -- variable data: integer;
        variable temp : memory_t(mem_depth-1 downto 0);
        variable data: bit_vector(temp(0)'range);
    begin
        for i in 0 to mem_depth-1 loop
            -- if G_INIT = '1' and not endfile(contents) then
            --     readline(contents, fline);
            --     read(fline, data);
            --     -- temp(i):= std_logic_vector(to_unsigned(data, G_DATA_WIDTH));
            --     temp(i):= to_stdlogicvector(data);
            -- else
                temp(i):= (others => '0');
            -- end if;
        end loop;
        return temp;
    end;

    -- signal ram_mem: memory_t(2**G_ADDR_WIDTH-1 downto 0):= init_mem(2**G_ADDR_WIDTH);
    signal ram_mem: memory_t(2**G_ADDR_WIDTH-1 downto 0):= (others => (others => '0'));

    attribute ram_style of ram_mem: signal is "auto";
begin
    -- DUAL PORT (1 read, 1 write)
    --------------------------------

    process(i_clk, i_wr_en_b)
    begin
        if rising_edge(i_clk) then
            o_word_a <= ram_mem(to_integer(i_addr_a));
            if i_wr_en_b = '1' then
                ram_mem(to_integer(i_addr_b)) <= i_word_b;
            end if;
        end if;
    end process;


    -- REAL DUAL PORT
    --------------------------------

    -- process(i_clk)
    -- begin
    --     if rising_edge(i_clk) then
    --         o_word_a <= ram_mem(to_integer(i_addr_a));
    --         if i_wr_en_a = '1' then
    --             ram_mem(to_integer(i_addr_a)) <= i_word_a;
    --         end if;
    --     end if;
    -- end process;
    --
    -- process(i_clk)
    -- begin
    --     if rising_edge(i_clk) then
    --         o_word_b <= ram_mem(to_integer(i_addr_b));
    --         if i_wr_en_b = '1' then
    --             ram_mem(to_integer(i_addr_b)) <= i_word_b;
    --         end if;
    --     end if;
    -- end process;

end arch_ram;
