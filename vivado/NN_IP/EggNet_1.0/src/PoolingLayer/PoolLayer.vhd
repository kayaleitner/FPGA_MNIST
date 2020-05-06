library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.EggNetCommon.all;
entity PoolLayer is

    generic (
        IMAGE_WIDTH           : natural; -- Width of the image
        ACTIVATION_WIDTH_BITS : natural; -- bit width of the input
        ACTIVATION_N_CHANNELS : natural

        -- #TODO More generic implementation with more than one channel
        -- POOL_KERNEL_SIZE : natural := 2  -- width of the pooling layer
    );
    port (
        clk_i   : in std_logic;
        rst_i   : in std_logic;
        valid_i : in std_logic;
        valid_o : out std_logic;
        x_i     : in channel_vector_t(0 to ACTIVATION_N_CHANNELS)(ACTIVATION_WIDTH_BITS - 1 downto 0);
        y_o     : out channel_vector_t(0 to ACTIVATION_N_CHANNELS)(ACTIVATION_WIDTH_BITS - 1 downto 0)
    );
end entity PoolLayer;

architecture rtl of PoolLayer is

begin

    PoolFilters : for i in 0 to ACTIVATION_N_CHANNELS generate

        PoolFilter_i : entity work.PoolFilter
            generic map(
                IMAGE_WIDTH           => IMAGE_WIDTH,          -- Width of the image
                ACTIVATION_WIDTH_BITS => ACTIVATION_WIDTH_BITS -- bit width of the input
            )
            port map(
                clk_i   => clk_i,
                rst_i   => rst_i,
                valid_i => valid_i,
                valid_o => valid_o,
                x_i     => x_i(i),
                y_o     => y_o(i)
            );

    end generate; -- PoolFilters
end architecture;