library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--use work.define_forest.all;

package general_package is

	-- Data types
		constant instances : integer := 32;

	--type mat_t is array (natural range <>) of std_logic_vector(15 downto 0);
	type mat_t is array (natural range <>) of std_logic_vector(3 downto 0);
	type cols_t is array (natural range <>) of unsigned(instances - 1 downto 0);

	procedure add_set_bits(signal class_mat : in mat_t; col : in natural; signal sum: out unsigned(instances - 1 downto 0));	
	procedure find_max(signal sum_mat : in cols_t; signal class : out integer);	
	
end package;

package body general_package is
procedure add_set_bits(signal class_mat : in mat_t; col : in natural; signal sum: out unsigned(instances - 1 downto 0)) is
		variable tmp_sum : unsigned(instances - 1 downto 0);
	begin
				tmp_sum := (others => '0');
				for i in 0 to instances - 1 loop
					if class_mat(i)(col) = '1' then
						tmp_sum := tmp_sum + 1;
					end if;
				end loop;
				sum <= tmp_sum;
	end add_set_bits;

	procedure find_max(signal sum_mat : in cols_t; signal class : out integer) is	
		variable tmp_class : integer:= 0;
		variable max : unsigned(instances - 1 downto 0);
	begin
			max := (others => '0');
			for i in sum_mat'range loop
				if sum_mat(i) > max then
					max := sum_mat(i);
					tmp_class := i;
				end if;
			end loop;
			class <= tmp_class;
	end find_max;

end package body;
