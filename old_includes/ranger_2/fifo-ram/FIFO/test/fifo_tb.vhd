library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fifo_pkg.all;

entity fifo_tb is
end fifo_tb;

architecture tb of fifo_tb is 
    signal i_clk: std_logic:= '0';
    signal i_rst: std_logic:= '0';
    signal i_rstn: std_logic:= '0';

    signal o_is_full:  std_logic;
    signal o_is_empty: std_logic;

    signal s00_axis_tready: std_logic;
    signal s00_axis_tdata:  std_logic_vector(31 downto 0):= (others => '0');
    signal s00_axis_tlast:  std_logic:= '0';
    signal s00_axis_tvalid: std_logic:= '0';

    signal m00_axis_tvalid: std_logic;
    signal m00_axis_tdata:  std_logic_vector(31 downto 0);
    signal m00_axis_tlast:  std_logic;
    signal m00_axis_tready: std_logic:= '0';


begin

    DUT: entity work.fifo
     generic map(
        G_MAX_ADDR => 5,
        G_DATA_WIDTH => 32
    )
     port map(
        i_clk => i_clk,
        i_rst => i_rst,
        
        o_is_full  => o_is_full,
        o_is_empty => o_is_empty,

        s00_axis_aclk    => i_clk,
        s00_axis_aresetn => i_rstn,
        s00_axis_tready  => s00_axis_tready,
        s00_axis_tdata   => s00_axis_tdata,
        s00_axis_tlast   => s00_axis_tlast,
        s00_axis_tvalid  => s00_axis_tvalid,

        m00_axis_aclk    => i_clk,
        m00_axis_aresetn => i_rstn,
        m00_axis_tvalid  => m00_axis_tvalid,
        m00_axis_tdata   => m00_axis_tdata,
        m00_axis_tlast   => m00_axis_tlast,
        m00_axis_tready  => m00_axis_tready
    );

    i_clk <= not i_clk after 10 ns;
    i_rstn <= not i_rst;
    process
    begin
        i_rst <= '1';
        wait for 30 ns;
        i_rst <= '0';

        --wait for 5 ns;
        s00_axis_tvalid <= '1';
        s00_axis_tdata <= std_logic_vector(to_unsigned(1, 32));
        wait for 20 ns;
        s00_axis_tdata <= std_logic_vector(to_unsigned(2, 32));
        wait for 20 ns;
        s00_axis_tdata <= std_logic_vector(to_unsigned(3, 32));
        wait for 20 ns;
        s00_axis_tdata <= std_logic_vector(to_unsigned(4, 32));
        wait for 20 ns;
        s00_axis_tdata <= std_logic_vector(to_unsigned(5, 32));
        wait for 20 ns;
        s00_axis_tdata <= std_logic_vector(to_unsigned(6, 32));
        wait for 20 ns;
        s00_axis_tdata <= std_logic_vector(to_unsigned(7, 32));
        wait for 20 ns;
        s00_axis_tdata <= std_logic_vector(to_unsigned(8, 32));
        wait for 20 ns;
        s00_axis_tvalid <= '0';

        wait for 5 ns;
        m00_axis_tready <= '1';
        wait for 165 ns;

        -- s00_axis_tvalid <= '1';
        -- s00_axis_tdata <= std_logic_vector(to_unsigned(10, 32));
        -- wait for 20 ns;
        -- s00_axis_tdata <= std_logic_vector(to_unsigned(20, 32));
        -- wait for 20 ns;
        -- s00_axis_tdata <= std_logic_vector(to_unsigned(30, 32));
        -- wait for 20 ns;
        -- s00_axis_tdata <= std_logic_vector(to_unsigned(40, 32));
        -- wait for 20 ns;
        -- s00_axis_tdata <= std_logic_vector(to_unsigned(50, 32));
        -- wait for 20 ns;
        -- s00_axis_tdata <= std_logic_vector(to_unsigned(60, 32));
        -- wait for 20 ns;
        -- s00_axis_tdata <= std_logic_vector(to_unsigned(70, 32));
        -- wait for 20 ns;
        -- s00_axis_tdata <= std_logic_vector(to_unsigned(80, 32));
        -- wait for 20 ns;
        -- s00_axis_tvalid <= '0';



        wait;
    end process;
end tb;

