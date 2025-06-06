library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use wor.ram_pkg.all;

entity dt_ctl is

end dt_ctl;

architecture arch_dt_ctl of dt_ctl is

-- address width
constant node_mem_a_width: integer := 16;
constant node_link_a_width: integer := 16;
constant data_mem_a_width: integer := 16;

-- data width
constant node_mem_d_width: integer := 16;
constant node_link_d_width: integer := 16;
constant data_mem_d_width: integer := 16;



begin

NODE_MEM: ram
generic map(
    g_addr_width => node_mem_a_width,
    g_data_width => node_mem_d_width,
    g_init_file => "memory_content/node_content.txt",
    g_init => '1'
);
port map();


NODE_LINK: ram
generic map(
    g_addr_width => node_link_a_width,
    g_data_width => node_link_d_width,
    g_init_file => "memory_content/node_content.txt",
    g_init => '1'
);
port map();


DATA_MEM: ram
generic map(
    g_addr_width => data_mem_a_width,
    g_data_width => data_mem_d_width,
    g_init_file => "memory_content/node_content.txt",
    g_init => '1'
);
port map();
end arch_dt_ctl;
