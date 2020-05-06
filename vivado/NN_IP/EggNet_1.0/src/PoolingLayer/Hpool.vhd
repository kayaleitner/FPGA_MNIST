library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.EggNetCommon.all;

-- HPool Entity
--
entity Hpool is
    generic
    (
        ACTIVATION_WIDTH_BITS : natural;      -- bit width of the input
        N_CHANNELS            : natural := 1; -- number of input channels

        -- #TODO More generic implementation with more than one channel
        -- POOL_H_WIDTH : natural := 2  -- width of the pooling layer
    );
    port
    (
        clk_i : in std_logic;
        rst_i : in std_logic;

        valid_i : in std_logic;
        valid_o : out std_logic;

        x_i : in U_CHANNEL_ARRAY(0 to N_CHANNELS - 1)(ACTIVATION_WIDTH_BITS - 1 downto 0);
        y_o : out U_CHANNEL_ARRAY(0 to N_CHANNELS - 1)(ACTIVATION_WIDTH_BITS - 1 downto 0)
    );
end entity Hpool;

architecture rtl of Hpool is

    -- Types
    type buffer_state_t is (EMPTY, FULL);
    type buffer_values_t is array (0 to N_CHANNELS - 1) of unsigned(ACTIVATION_WIDTH_BITS - 1 downto 0);

    -- Constants
    constant ZERO_BUFFER      : buffer_values_t := (others => '0');
    constant UNDEFINED_OUTPUT : buffer_values_t := (others => 'X');

    -- Signals
    signal buffer_values : buffer_values_t := (others => '0');
    signal buffer_state  : buffer_state_t  := EMPTY;

begin

    process (clk_i, rst_i)
    begin
        if rst_i = '1' then
            -- Reset to all zeros
            buffer_state  <= EMPTY;
            buffer_values <= ZERO_BUFFER;
            valid_o       <= '0';
            y_o           <= UNDEFINED_OUTPUT;
        elsif rising_edge(clk_i) then

            -- If valid_i is '1' then add it
            if valid_i = '0' then
                valid_o <= '0';
                y_o     <= UNDEFINED_OUTPUT;

                -- Reset the state, because the 
                buffer_state <= EMPTY;
            else
                if buffer_state = EMPTY then
                    -- Current state is empty, so store the input in the buffer
                    buffer_values <= x_i;
                    buffer_state  <= FULL;
                    valid_o       <= '0';
                else
                    -- If there are already values, then output the maximum value
                    loop_pool : for c in 0 to N_CHANNELS - 1 loop
                        if buffer_values(c) > x_i(c) then
                            y_o(c) <= buffer_values(c);
                        else
                            y_o(c) <= x_i(c);
                        end if;

                        valid_o      <= '1';
                        buffer_state <= EMPTY;
                    end loop; -- loop_pool
                end if;
            end if;
        end if;
    end process;
end architecture;