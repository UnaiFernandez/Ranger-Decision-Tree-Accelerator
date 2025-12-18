library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package test_comb_pkg is

    component test_comb is
		port(
		s00_ACLK			: in std_logic;
    	s00_ARESETN			: in std_logic;
		m00_ACLK			: in std_logic;
    	m00_ARESETN			: in std_logic;
    	s00_TVALID		: in std_logic; 
    	s00_TLAST		: in std_logic; 
    	s00_TDATA		: in std_logic_vector(31 downto 0); 
    	m00_TREADY		: in std_logic; 
    	----------------------------------------------------
    	m00_TVALID		: out std_logic;
    	m00_TLAST		: out std_logic;
    	m00_TDATA		: out std_logic_vector(31 downto 0);
    	s00_TREADY		: out std_logic
		
		);
    end component;

end test_comb_pkg;
