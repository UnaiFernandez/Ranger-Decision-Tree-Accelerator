library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.general_package.all;

entity find_max is
    generic (
        COUNT_WIDTH : positive := 5
    );
    port (
        i_sum_mat : in cols_t;
        o_max_class : out unsigned(addr_width - 1 downto 0)
    );
end entity;

architecture rtl of find_max is
begin

    --procedure find_max(signal sum_mat : in cols_t; signal class : out integer) is	
    process(i_sum_mat)
		    variable tmp_class : integer:= 0;
		    variable max : sum_t; --unsigned(n_estimators - 1 downto 0);
	  begin
        max := (others => '0');
        tmp_class := 0;
		    for i in i_sum_mat'range loop
		        if i_sum_mat(i) > max then
					      max := i_sum_mat(i);
					      tmp_class := i;
				    end if;
		    end loop;
		    o_max_class <= to_unsigned(tmp_class, addr_width);
    end process;


    --process(i_sum_mat)
    --    variable max : unsigned(COUNT_WIDTH -1 downto 0) := (others => '0');
    --begin
    --    for i in i_sum_mat'range loop
    --        if i_sum_mat(i) > max then
    --            max := to_unsigned(i, COUNT_WIDTH);
    --        end if;
    --    end loop;
    --    o_max_class <= to_integer(max);
    --end process;

end architecture;
