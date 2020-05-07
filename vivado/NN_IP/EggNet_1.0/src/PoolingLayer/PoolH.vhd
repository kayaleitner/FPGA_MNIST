library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.EggNetCommon.all;
-- HPool Entity
--
entity HPool is
    generic (
        ACTIVATION_WIDTH_BITS : natural -- bit width of the input
        -- #TODO More generic implementation with more than one channel
        -- POOL_KERNEL_SIZE : natural := 2  -- width of the pooling layer
    );
    port (
        clk_i   : in std_logic;
        rst_i   : in std_logic;
        valid_i : in std_logic;
        valid_o : out std_logic;
        x_i     : in std_logic_vector(ACTIVATION_WIDTH_BITS - 1 downto 0);
        y_o     : out std_logic_vector(ACTIVATION_WIDTH_BITS - 1 downto 0)
    );
end entity HPool;
architecture rtl of HPool is

    -- Types
    type buffer_data_type is array (integer range <>) of signed (ACTIVATION_WIDTH_BITS - 1 downto 0);
    type buffer_state_t is (EMPTY, FULL);
    -- Constants
    constant ZERO_BUFFER      : std_logic_vector(ACTIVATION_WIDTH_BITS - 1 downto 0) := (others => '0');
    constant UNDEFINED_OUTPUT : std_logic_vector(ACTIVATION_WIDTH_BITS - 1 downto 0) := (others => 'X');
    -- Signals
    signal buffer_state : buffer_state_t                                       := EMPTY;
    signal buffer_value : std_logic_vector(ACTIVATION_WIDTH_BITS - 1 downto 0) := (others => '0');

    -- For larger kernel sizes than 2
    -- signal max_value_signal : signed(ACTIVATION_WIDTH_BITS-1 downto 0);
    -- signal buffer_data      : buffer_data_type (POOL_KERNEL_SIZE - 1 downto 0);

begin

    process (clk_i, rst_i)
    begin
        if rst_i = '1' then
            -- Reset to all zeros
            buffer_state <= EMPTY;
            buffer_value <= ZERO_BUFFER;
            valid_o      <= '0';
            y_o          <= UNDEFINED_OUTPUT;
        elsif rising_edge(clk_i) then

            -- If valid_i is '1' then add it
            if valid_i = '0' then
                valid_o <= '0';
                y_o     <= UNDEFINED_OUTPUT;
                -- Reset the state, because the 
                -- buffer_state <= EMPTY;
            else
                if buffer_state = EMPTY then
                    -- Current state is empty, so store the input in the buffer
                    buffer_value <= x_i;
                    buffer_state <= FULL;
                    valid_o      <= '0';
                else
                    -- If there are already values, then output the maximum value
                    if unsigned(buffer_value) > unsigned(x_i) then
                        y_o <= buffer_value;
                    else
                        y_o <= x_i;
                    end if;

                    valid_o      <= '1';
                    buffer_state <= EMPTY;
                end if;
            end if;
        end if;
    end process;
end architecture;