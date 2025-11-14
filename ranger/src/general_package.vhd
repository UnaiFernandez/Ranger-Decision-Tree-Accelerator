library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--use work.define_forest.all;

package general_package is

	-- Data types
 	subtype onehot_class is std_logic_vector(15 downto 0);
    type matr is array (natural range <>) of onehot_class;

	
	procedure class_aggregation(signal class_mat : in matr; signal class_ag : inout onehot_class; signal t_sum : out integer);	

	--TODO definir los tamaños de todo en este archivo
end package;

package body general_package is

	procedure class_aggregation(signal class_mat : in matr; signal class_ag : inout onehot_class; signal t_sum : out integer) is
		variable max : integer := 0;
		variable max_idx : integer := 0;
		variable tmp_sum : integer := 0;
		variable total_sum : integer := 0;
	begin
		for class_idx in 0 to 15 loop
			tmp_sum := 0;
			-- Add columns 
			for i in class_mat'range loop
				if class_mat(i)(class_idx) = '1' then
					tmp_sum := tmp_sum + 1;
					total_sum := total_sum + 1;
				end if;
			end loop;
			-- Find max value
			if tmp_sum >= max then
				max := tmp_sum;
				max_idx := class_idx;
			--else
			--	class_ag <= class_ag; -- TODO: No se si esto esta muy bien
			end if;
		end loop;
		class_ag <= std_logic_vector(to_unsigned(max_idx, class_ag'length));
		t_sum <= total_sum;
	end class_aggregation;

end package body;
