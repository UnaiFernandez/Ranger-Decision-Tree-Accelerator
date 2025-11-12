library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package data_sender_pkg is
	component data_sender is
		port(
			i_CLK		: in std_logic;
			i_RESET		: in std_logic;
			init	: in std_logic;
	--------------------------------------------------------
			o_TLAST		: out std_logic;
			o_TVALID	: out std_logic;
			o_TDATA		: out std_logic_vector(31 downto 0)
			);
	end component;
end data_sender_pkg;
