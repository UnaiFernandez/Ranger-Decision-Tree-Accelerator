library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--use work.define_forest.all;

package general_package is

    function ceil_log2(n : positive) return natural;
    
    -----------------------------------------------------
    --                  Configuration                  --
    -----------------------------------------------------
    constant  n_estimators : integer := 32;
    constant  n_classes : integer := 4;  
    constant  chunk_size : integer := 16;
    constant  n_chunks : positive := (n_estimators + chunk_size - 1) / chunk_size; -- ToDo: Revisar
    constant  count_width : integer := ceil_log2(n_estimators + 1);
    constant  node_mem_size : integer := 512;
    constant  in_fifo_size : integer := 1024;
    constant  out_fifo_size : integer := 64;
    constant  mem_config_file : string := "/home/unai/Projects/dt_vhdl/ranger/memory_content/random_forest_bin.txt";
    constant  debug : std_logic := '1';
    constant  data_width : integer := 32;
    constant  addr_width : integer := 16;

    -- Data types

	  --type mat_t is array (natural range <>) of std_logic_vector(15 downto 0);
	  type mat_t is array (natural range <>) of std_logic_vector(n_classes - 1 downto 0);
	  type cols_t is array (natural range <>) of unsigned(count_width - 1 downto 0);
    subtype sum_t is unsigned(count_width - 1 downto 0);

	  procedure add_set_bits(signal class_mat : in mat_t; col : in natural; signal sum: out unsigned(n_estimators - 1 downto 0));	
	  procedure find_max(signal sum_mat : in cols_t; signal class : out integer);
    function get_chunk_votes(mat: mat_t; j: integer; c:integer) return std_logic_vector; 
    function total_sum(chunk: cols_t) return unsigned;
	
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
		    variable max : sum_t; --unsigned(n_estimators - 1 downto 0);
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

    function ceil_log2(n : positive) return natural is
        variable v : natural := n - 1;
        variable r : natural := 0;
    begin
        while v > 0 loop
            v := v / 2;
            r := r + 1;
        end loop;
        return r;
    end function;

    function get_chunk_votes(mat: mat_t; j: integer; c:integer) return std_logic_vector is 
        variable votes_chunk : std_logic_vector(chunk_size-1 downto 0) := (others => '0');
    begin
        for i in 0 to chunk_size-1 loop
            if (c * chunk_size + i) < n_estimators then
                votes_chunk(i) := mat(c * chunk_size + i)(j);
            end if;
        end loop;
        return votes_chunk;
    end function;
    

    function total_sum(chunk: cols_t) return unsigned is
        variable total : unsigned(COUNT_WIDTH-1 downto 0) := (others => '0');
    begin
        for c in 0 to N_CHUNKS-1 loop 
             total := total + chunk(c); 
        end loop;
        return total;
    end function;

end package body;
