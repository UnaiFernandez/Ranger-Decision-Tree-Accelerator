library ieee;
library ieee_proposed;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.dt_ctl_pkg.all;

entity dt_ctl is
    generic(
	    g_DATA_WIDTH 		: integer;
	    g_ADDR_WIDTH 		: integer
	);
    port(
	      i_CLK		        : in std_logic;
	      i_RESET		        : in std_logic;
	      i_ENABLE			: in std_logic;
	      i_NODE_INFO			: in std_logic_vector(g_DATA_WIDTH - 1 downto 0);
	      i_CALC_RESULT		: in std_logic;
        i_num_features  : in integer;  
		    -----------------------------------------------------
	      o_RE_NODE			: out std_logic;
	      o_NODE_ADDR			: out unsigned(g_ADDR_WIDTH - 1 downto 0);
	      o_DONE			: out std_logic;
	      o_CLASS		        : out std_logic_vector(15 downto 0)
	);
end dt_ctl;

architecture arch_dt_ctl of dt_ctl is

-- State machine
    type state is (E0, E1, E2, E3, E4, E5, E6);
    signal current_s, next_s, r_state: state;

-- C node mem
    signal LD_c_node_mem, INC_c_node_mem, CL_c_node_mem : std_logic;
    signal c_node_mem_out : std_logic_vector(g_ADDR_WIDTH - 1 downto 0);
    signal next_node : unsigned(g_ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal node_info : std_logic_vector(g_DATA_WIDTH - 1 downto 0);
    signal threshold : signed(g_DATA_WIDTH - 1 downto 0);

-- R class
    signal LD_class : std_logic;
    signal R_class : std_logic_vector(g_ADDR_WIDTH - 1 downto 0);

--
    signal leaf, go_right, read_node_info : std_logic;
    signal data_out : signed(g_DATA_WIDTH - 1 downto 0);


    signal ld_node_info: std_logic := '0';
    signal cl_node_info: std_logic := '0';
    signal ld_threshold: std_logic := '0';
    signal base_data_addr: unsigned(g_ADDR_WIDTH - 1 downto 0) := to_unsigned(511, g_ADDR_WIDTH);

    signal sel_addr : std_logic_vector(1 downto 0) := "00";
    signal mux_addr : unsigned(g_ADDR_WIDTH - 1 downto 0);
    signal node_addr : unsigned(g_ADDR_WIDTH - 1 downto 0);
    signal data_addr : unsigned(g_ADDR_WIDTH - 1 downto 0);
    signal ld_node_addr : std_logic := '0';
    signal cl_node_addr : std_logic := '0';

    signal ld_addr, ld_next : std_logic := '0';

    signal sel_base : std_logic := '0';
    signal base_feature_addr : unsigned(g_ADDR_WIDTH - 1 downto 0);


begin

-- State machine

    process(current_s, leaf, go_right, i_enable, i_calc_result)
    begin
	  case current_s is
	      when E0 => if i_enable = '1' then next_s <= E1;
	  				  else next_s <= E0;
	  				  end if;
	      when E1 => next_s <= E2;
	      when E2 => next_s <= E3;
	      when E3 => next_s <= E4;
        when E4 => if leaf = '1' then next_s <= E6;
              else next_s <= E5;
              end if;
        when E5 => next_s <= E2;
	      when E6 => if i_enable = '1' then next_s <= E2;
	  	       else next_s <= E6;
	  	       end if;
	  end case;
    end process;

-- CLK, RESET and HALT

    process(i_CLK, i_RESET)
    begin
        if rising_edge(i_CLK) then 
        	  if i_RESET = '1' then 
	    		      current_s <= E0;
			      else
				        current_s <= next_s;
        	  end if;
        end if;
    end process;

   
    -- Registers

    ld_node_info <= '1' when current_s = E2 else '0';

    process(i_clk, ld_node_info)
    begin
        if rising_edge(i_clk) then
            if ld_node_info = '1' then
                node_info <= i_NODE_INFO;
            end if;
        end if;
    end process;
    
    ld_threshold <= '1' when current_s = E3 else '0';
    
    process(i_clk, ld_threshold)
    begin
        if rising_edge(i_clk) then
            if ld_threshold = '1' then
                threshold <= signed(i_NODE_INFO);
            end if;
        end if;
    end process;

    ld_node_addr <= '1' when current_s = E1
                    or current_s = E2
                    or (current_s = E4 and leaf = '0')
                    or (current_s = E6 and i_enable = '1')
                    or current_s = E5 else '0';

    cl_node_addr <= '1' when (current_s = E0 and i_enable = '1') or (current_s = E4 and leaf = '1') else '0';

    process(i_clk, cl_node_addr, ld_node_addr, current_s)
    begin
        if rising_edge(i_clk) then
            if cl_node_addr = '1' then
                node_addr <= (others => '0');
            elsif ld_node_addr = '1' then
                if current_s = E2 then
                    node_addr <= data_addr;
                elsif current_s = E4 and leaf = '0' then
                    node_addr <= '0' & next_node(g_ADDR_WIDTH - 1 downto 1);
                elsif current_s = E1 or current_s = E5 or (current_s = E6 and i_enable = '1') then
                    node_addr <= node_addr + 1;
                end if;
            end if;
        end if;
    end process;

    o_NODE_ADDR <= node_addr;





    leaf <= next_node(0); -- when current_s = E4 else '0'; 

-- RE mem signals

    o_RE_NODE <= '1' when (current_s = E1) 
                    or (current_s = E2)
                    or (current_s = E3)
                    or (current_s = E5) 
                    or (current_s = E6 and i_ENABLE = '1') else '0';


    data_addr <= base_data_addr - base_feature_addr - unsigned("000000" & i_node_info(9 downto 0));

    process(i_clk, go_right, node_info)
    begin
        if go_right = '1' then
            next_node <= unsigned("00000" & node_info(20 downto 10));
        else 
            next_node <= unsigned("00000" & node_info(31 downto 21));
        end if;
    end process;




    o_DONE <= '1' when current_s = E6 and i_enable = '0' else '0';

-- CMP

    process(i_clk, threshold, i_NODE_INFO, data_out)
    begin
        if signed(i_NODE_INFO) <= threshold then
            go_right <= '0';
        else
            go_right <= '1';
        end if;
    end process;

-- R class
    ld_class <= '1' when current_s = E4 and leaf = '1' else '0';

    process(i_clk, ld_class)
    begin
        if rising_edge(i_clk) then
    	      if ld_class = '1' then
    	          o_class <= '0' & std_logic_vector(next_node(15 downto 1));
    	      end if;
        end if;
    end process;

    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if current_s = E4 and leaf = '1' then
                sel_base <= not sel_base;
            end if;
        end if;
    end process;



    --process(sel_base, i_num_features)
    process(sel_base)
    begin
        if sel_base = '1' then
            base_feature_addr <= to_unsigned(i_num_features + 1, g_ADDR_WIDTH);
        else
            base_feature_addr <= to_unsigned(0, g_ADDR_WIDTH);
        end if;
    end process;

end arch_dt_ctl;
