library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--use work.define_forest.all;

package general_package is

	-- Data types
 	subtype onehot_class is std_logic_vector(15 downto 0);
    type matr is array (natural range <>) of onehot_class;
    type s_matr is array (natural range <>) of integer;

	constant c_max : onehot_class := (15 => '0', others => '1');
	constant c_min : onehot_class := (15 => '1', others => '0');
	
	procedure class_aggregation(signal class_mat : in matr; signal class_ag : out onehot_class);	
	procedure add_set_bits(signal clk : in std_logic; signal class_mat : in matr; signal sum_mat : out s_matr);	
	procedure find_max(signal clk : in std_logic; signal sum_mat : in s_matr; signal class : out std_logic_vector);	

	--procedure class_aggregation_tree(constant n_inputs : in natural; signal class_mat : in matr; signal class_ag : out onehot_class);	

	--TODO definir los tamaños de todo en este archivo
end package;

package body general_package is

	procedure add_set_bits(signal clk : in std_logic; signal class_mat : in matr; signal sum_mat : out s_matr) is
		variable tmp_sum : integer := 0;
	begin
		if rising_edge(clk) then
			for class_idx in 0 to 15 loop
				tmp_sum := 0;
				for i in class_mat'range loop
					if class_mat(i)(class_idx) = '1' then
						tmp_sum := tmp_sum + 1;
					end if;
				end loop;
				sum_mat(class_idx) <= tmp_sum;
			end loop;
		end if;
	end add_set_bits;

	procedure find_max(signal clk : in std_logic; signal sum_mat : in s_matr; signal class : out std_logic_vector) is	
		variable tmp_class : integer;
		variable max : integer;
	begin
		if rising_edge(clk) then
			for i in sum_mat'range loop
				if sum_mat(i) >= max then
					max := sum_mat(i);
					tmp_class := i;
				end if;
			end loop;
			class <= std_logic_vector(to_unsigned(tmp_class, class'length));
		end if;
	end find_max;

	procedure class_aggregation(signal class_mat : in matr; signal class_ag : out onehot_class) is
		variable max : integer := 0;
		variable tmp_sum : integer := 0;
		variable temp_class_ag: onehot_class := (others => '0');
	begin
		for class_idx in 0 to 15 loop
			tmp_sum := 0;
			-- Add columns 
			for i in class_mat'range loop
				if class_mat(i)(class_idx) = '1' then
					tmp_sum := tmp_sum + 1;
				end if;
			end loop;
			-- Find max value
			if tmp_sum >= max then
				max := tmp_sum;
				temp_class_ag := std_logic_vector(to_unsigned(class_idx, temp_class_ag'length));
				--class_ag <= std_logic_vector(to_unsigned(class_idx, class_ag'length));
			end if;
			class_ag <= temp_class_ag;
		end loop;
	end class_aggregation;



	--procedure class_aggregation_tree(constant n_inputs : in natural; signal class_mat_col : in std_logic_vector; signal class_ag : out onehot_class) is
    --
    --    variable stage_a : std_logic_vector(n_inputs - 1 downto 0); 
    --    variable stage_b : std_logic_vector(n_inputs - 1 downto 0); -- Used to alternate between stages
    --    variable current_num : integer := n_inputs;
    --    variable toggle : boolean := true;
    --    variable next_num : integer := (current_num / 2) + (current_num mod 2);
    --    variable final_sum : onehot_class;
    --begin
    --    -- Initialization: copy and resize input weights to stage_a
    --    for i in 0 to n_inputs - 1 loop
    --        stage_a(i) := class_mat_col(i);
    --    end loop;
    --
    --    -- Adder tree loop
    --    while current_num > 1 loop
    --        next_num  := (current_num / 2) + (current_num mod 2);
    --        for i in 0 to (current_num / 2) - 1 loop
    --            if toggle then
    --                stage_b(i) := stage_a(2*i) + stage_a(2*i + 1);
    --            else
    --                stage_a(i) := stage_b(2*i) + stage_b(2*i + 1);
    --            end if;
    --        end loop;
    --
    --        -- If odd number of elements, propagate the last one
    --        if (current_num mod 2) = 1 then
    --            if toggle then
    --                stage_b(next_num - 1) := stage_a(current_num - 1);
    --            else
    --                stage_a(next_num - 1) := stage_b(current_num - 1);
    --            end if;
    --        end if;
    --
    --        current_num := next_num;
    --        toggle := not toggle; -- Switch stages
    --    end loop;
    --
    --    -- Final result is in the last active stage
    --    if toggle then
    --        final_sum := stage_a(0);
    --    else
    --        final_sum := stage_b(0);
    --    end if;
    --
    --    -- Apply saturation limits
    --    if final_sum > c_max then
    --        class_ag <= c_max;
    --    elsif final_sum < c_min then
    --        class_ag <= c_min;
    --    else
    --        class_ag <= final_sum;
    --    end if;
    --end procedure;

end package body;
