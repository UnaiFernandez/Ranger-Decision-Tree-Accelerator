library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--use work.define_forest.all;

package general_package is

    function ceil_log2(n : positive) return natural;
    
    -----------------------------------------------------
    --                  Configuration                  --
    -----------------------------------------------------
    constant  n_estimators : integer := 128;
    constant  n_classes : integer := 4;  
    constant  chunk_size : integer := 64;
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

  type max_idx_t is record    
        val : sum_t;    
        idx : integer;
    end record; 

	  procedure add_set_bits(signal class_mat : in mat_t; col : in natural; signal sum: out unsigned(n_estimators - 1 downto 0));	
	  procedure find_max(signal sum_mat : in cols_t; signal class : out integer);
    procedure find_max_tree(    signal sum_mat : in  cols_t;    signal class   : out integer);   
    function max_tree(    a   : cols_t;    low : integer;    high: integer) return max_idx_t; 
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
		    variable tmp_class : integer;
		    variable max : sum_t; --unsigned(n_estimators - 1 downto 0);
	  begin
        max := sum_mat(0);
        tmp_class := 0;
		    for i in sum_mat'low + 1 to sum_mat'high loop
		        if sum_mat(i) > max then
					      max := sum_mat(i);
					      tmp_class := i;
				    end if;
		    end loop;
		    class <= tmp_class;
    end find_max;

    procedure find_max_tree(    signal sum_mat : in  cols_t;    signal class   : out integer) is    
        constant N : integer := sum_mat'length;
        type level_t is array (natural range <>) of max_idx_t;    
        variable curr : level_t(0 to N-1);    
        variable nxt : level_t(0 to N-1);    
        variable count : integer;begin    
        -- Cargar hojas    
            for i in 0 to N-1 loop        
                curr(i).val := sum_mat(sum_mat'low + i);        
                curr(i).idx := sum_mat'low + i;    
            end loop;
            count := N;
        -- Reducción por árbol    
            while count > 1 loop        
                for i in 0 to (count/2)-1 loop            
                    if curr(2*i).val >= curr(2*i+1).val then                
                        nxt(i) := curr(2*i);            
                    else                
                        nxt(i) := curr(2*i+1);            
                    end if;        
                end loop;
            if (count mod 2) = 1 then            
                nxt(count/2) := curr(count-1);            
                count := count/2 + 1;        
            else            
                count := count/2;        
            end if;
            for i in 0 to count-1 loop            
                curr(i) := nxt(i);        
            end loop;    
        end loop;
        class <= curr(0).idx;
    end procedure;


function max_tree(    a   : cols_t;    low : integer;    high: integer) return max_idx_t is    variable res : max_idx_t;    variable m1  : max_idx_t;    variable m2  : max_idx_t;    variable mid : integer;begin    if low = high then        res.val := a(low);        res.idx := low;        return res;    else        mid := (low + high) / 2;        m1 := max_tree(a, low, mid);        m2 := max_tree(a, mid + 1, high);
        if m1.val >= m2.val then            return m1;        else            return m2;        end if;    end if;end function;

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
