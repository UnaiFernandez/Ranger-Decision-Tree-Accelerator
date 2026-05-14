library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--use work.define_forest.all;

package general_package is


    -----------------------------------------------------
    --                  Configuration                  --
    -----------------------------------------------------
    constant  n_estimators : integer := 100;
    constant  node_mem_size : integer := 512;
    constant  in_fifo_size : integer := 1024;
    constant  out_fifo_size : integer := 64;
    constant  mem_config_file : string := "/home/unai/Projects/dt_vhdl/ranger/memory_content/random_forest_bin.txt";
    constant  debug : std_logic := '0';

    constant  data_width : integer := 32;
    constant  addr_width : integer := 16;

	  -- Data types

	  --type mat_t is array (natural range <>) of std_logic_vector(15 downto 0);
	  type mat_t is array (natural range <>) of std_logic_vector(3 downto 0);
	  type cols_t is array (natural range <>) of unsigned(n_estimators - 1 downto 0);

	  procedure add_set_bits(signal class_mat : in mat_t; col : in natural; signal sum: out unsigned(n_estimators - 1 downto 0));	
	  procedure find_max(signal sum_mat : in cols_t; signal class : out integer);	
	
end package;

package body general_package is

    procedure add_set_bits(signal class_mat : in mat_t; col : in natural; signal sum: out unsigned(n_estimators - 1 downto 0)) is
		    variable tmp_sum : unsigned(n_estimators - 1 downto 0);
	  begin
		    tmp_sum := (others => '0');
				for i in 0 to n_estimators - 1 loop
					  if class_mat(i)(col) = '1' then
						    tmp_sum := tmp_sum + 1;
					  end if;
				end loop;
				sum <= tmp_sum;
	  end add_set_bits;

	  procedure find_max(signal sum_mat : in cols_t; signal class : out integer) is	
		    variable tmp_class : integer:= 0;
		    variable max : unsigned(n_estimators - 1 downto 0);
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
