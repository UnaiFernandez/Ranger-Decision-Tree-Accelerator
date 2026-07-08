library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity count_votes is
    generic (
        N_INPUTS    : positive := 16;
        COUNT_WIDTH : positive := 5
    );
    port (
        i_votes : in  std_logic_vector(N_INPUTS-1 downto 0);
        o_count : out unsigned(COUNT_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of count_votes is
begin

    process(i_votes)
        variable cnt : unsigned(COUNT_WIDTH-1 downto 0);
    begin
        cnt := (others => '0');
        for i in i_votes'range loop
            if i_votes(i) = '1' then
                cnt := cnt + 1;
            end if;
        end loop;
        o_count <= cnt;
    end process;

end architecture;
