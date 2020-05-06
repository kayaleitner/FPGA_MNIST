library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.EggNetCommon.all;

entity PoolFilter is
    generic (
        IMAGE_WIDTH           : natural; -- Width of the image
        ACTIVATION_WIDTH_BITS : natural  -- bit width of the input
        -- #TODO More generic implementation with more than one channel
        -- POOL_KERNEL_SIZE : natural := 2  -- width of the pooling layer
    );
    port (

        -- Public Interface
        clk_i   : in std_logic;
        rst_i   : in std_logic;
        valid_i : in std_logic;
        valid_o : out std_logic;
        x_i     : in std_logic_vector(ACTIVATION_WIDTH_BITS - 1 downto 0);
        y_o     : out std_logic_vector(ACTIVATION_WIDTH_BITS - 1 downto 0);

        -- Test Interface
        dbg_is_buffering : out std_logic;
        dbg_cnt          : out natural
    );
end entity PoolFilter;

architecture rtl of PoolFilter is
    signal s_valid_i, s_valid_o : std_logic;
    signal s_x_i                : std_logic_vector(ACTIVATION_WIDTH_BITS - 1 downto 0);
begin

    hpool_0 : entity work.HPool
        generic map(
            ACTIVATION_WIDTH_BITS => ACTIVATION_WIDTH_BITS
        )
        port map(
            clk_i   => clk_i,
            rst_i   => rst_i,
            valid_i => valid_i,
            valid_o => s_valid_o,
            x_i     => x_i,
            y_o     => s_x_i
        );

    vpool_0 : entity work.VPool
        generic map(
            IMAGE_WIDTH           => IMAGE_WIDTH,
            ACTIVATION_WIDTH_BITS => ACTIVATION_WIDTH_BITS
        )
        port map(
            clk_i            => clk_i,
            rst_i            => rst_i,
            valid_i          => s_valid_o,
            valid_o          => valid_o,
            x_i              => s_x_i,
            y_o              => y_o,
            dbg_is_buffering => dbg_is_buffering,
            dbg_cnt          => dbg_cnt
        );
end architecture;