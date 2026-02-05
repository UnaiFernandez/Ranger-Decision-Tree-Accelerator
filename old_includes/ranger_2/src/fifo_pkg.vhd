library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package fifo_pkg is

    -- Component Declaration 
    -------------------------------------------------------
    component fifo is
        generic (
            -- G_INIT_FILE:  string    := "";
            -- G_INIT:       std_logic := '0';
            G_MAX_ADDR:   integer   := 32;
            G_DATA_WIDTH: integer   := 32
        );
        port (
            i_clk:      in std_logic;
            i_rst:      in std_logic;
            o_is_full:  out std_logic;
            o_is_empty: out std_logic;

            -- SLAVE AXI
            s00_axis_aclk:      in std_logic;
            s00_axis_aresetn:   in std_logic;
            s00_axis_tready:    out std_logic;
            s00_axis_tdata:     in std_logic_vector(G_DATA_WIDTH-1 downto 0);
            s00_axis_tlast:     in std_logic;
            s00_axis_tvalid:    in std_logic;

            -- MASTER AXI
            m00_axis_aclk:      in std_logic;
            m00_axis_aresetn:   in std_logic;
            m00_axis_tvalid:    out std_logic;
            m00_axis_tdata:     out std_logic_vector(G_DATA_WIDTH-1 downto 0);
            m00_axis_tlast:     out std_logic;
            m00_axis_tready:    in std_logic

            -- i_rd:       in std_logic;
            -- i_wr:       in std_logic;
            -- i_data:     in std_logic_vector(G_DATA_WIDTH-1 downto 0);
            -- o_t_valid:  out std_logic;
            -- o_data:     out std_logic_vector(G_DATA_WIDTH-1 downto 0)
        );
    end component;

end fifo_pkg;
