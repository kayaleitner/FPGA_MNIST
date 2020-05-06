library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.EggNetCommon.all;

-- VPool will store incomming pixels in the line buffer. If the line buffer is full (so the count exceeds the line length) pooling starts. So the 

entity VPool is
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
end entity VPool;

architecture rtl of VPool is

    constant HALF_IMAGE_WIDTH : natural := IMAGE_WIDTH/2;
    subtype buffer_count_t is natural range 0 to HALF_IMAGE_WIDTH;
    type pool_state_t is (BUFFERING, POOLING);
    type buffer_data_type is array (integer range <>) of std_logic_vector (ACTIVATION_WIDTH_BITS - 1 downto 0);
    constant ZERO_BUFFER_LINE : buffer_data_type(HALF_IMAGE_WIDTH - 1 downto 0)      := (others => (others => '0'));
    constant UNDEFINED_OUTPUT : std_logic_vector(ACTIVATION_WIDTH_BITS - 1 downto 0) := (others => 'X');

    -- Buffer Line to store incoming pixels.
    signal pool_state  : pool_state_t := BUFFERING;
    signal buffer_line : buffer_data_type (0 to HALF_IMAGE_WIDTH - 1);
    signal cnt         : buffer_count_t := 0;

begin

    -- Setup Debug Signals
    dbg_cnt <= cnt;
    dbg_is_buffering <= '1' when pool_state=BUFFERING else '0';
    

    main : process (clk_i)
    begin
        if rst_i = '1' then
            -- Reset to all zeros
            pool_state  <= BUFFERING;
            buffer_line <= ZERO_BUFFER_LINE;
            cnt         <= 0;

            valid_o <= '0';
            y_o     <= UNDEFINED_OUTPUT;
        
        elsif rising_edge(clk_i) then
            if valid_i = '0' then
                -- In case we encounter an invalid input, just halt the operation
                valid_o <= '0';
                y_o     <= UNDEFINED_OUTPUT;
            else

                -- Output the data
                if pool_state = BUFFERING then
                    -- Append value
                    buffer_line(cnt) <= x_i;
                    valid_o          <= '0';
                else

                    valid_o <= '1';

                    -- Pool operation
                    if unsigned(buffer_line(cnt)) < unsigned(x_i) then
                        y_o <= buffer_line(cnt);
                    else
                        y_o <= x_i;
                    end if;

                end if;

                -- Update the state
                if cnt < HALF_IMAGE_WIDTH-1  then
                    -- Range 0 ... Half_image_width-1
                    cnt <= cnt + 1;
                else
                    -- Toggle state
                    cnt        <= 0;
                    pool_state <= BUFFERING when pool_state = POOLING else
                        POOLING;
                end if;

            end if;
        end if;
    end process; -- main
end architecture;