library ieee;

use ieee.std_logic_1164.all;
use work.test_comb_pkg.all;

entity test_comb is
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
end test_comb;

architecture test_comb_arch of test_comb is

begin

	m00_TVALID <= s00_TVALID;
   	m00_TDATA <= s00_TDATA(30 downto 0) & s00_TDATA(31);
	m00_TLAST <= s00_TLAST;
	s00_TREADY <= m00_TREADY;
		
end test_comb_arch;
