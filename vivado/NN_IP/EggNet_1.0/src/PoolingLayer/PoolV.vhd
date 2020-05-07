library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.EggNetCommon.all;

-- VPool will store incomming pixels in the line buffer. If the line buffer is full (so the count exceeds the line length) pooling starts. So the 

entity VPool is
    generic (
        IMAGE_WIDTH           : natural; -- Width of the image
        ACTIVATION_WIDTH_BITS : natural; -- bit width of the input
        MEMORY_ARCH           : memory_type_t := DISTRIBUTED
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
        dbg_cnt          : out natural;
        dbg_fifo_empty   : out std_logic;
        dbg_fifo_full    : out std_logic;
        dbg_fifo_read_en : out std_logic;
        dbg_fifo_write_en : out std_logic
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

    -- FIFO Signals
    signal s_fifo_out      : std_logic_vector(ACTIVATION_WIDTH_BITS - 1 downto 0);
    signal s_fifo_full     : std_logic;
    signal s_fifo_empty    : std_logic;
    signal s_fifo_read_en  : std_logic := '0';
    signal s_fifo_write_en : std_logic := '0';
    signal is_buffering    : std_logic;

begin

    
    -- is_buffering <= not rst_i and (is_buffering xor (s_fifo_empty or s_fifo_full)) after 1 ns;

    -- Check if the code is buffering or not
    dbg_is_buffering <= is_buffering;
    dbg_fifo_empty   <= s_fifo_empty;
    dbg_fifo_full    <= s_fifo_full;
    dbg_fifo_read_en <= s_fifo_read_en;
    dbg_fifo_write_en <= s_fifo_write_en;

    -- Setup Debug Signals
    dbg_cnt <= cnt;

    -- Initialize the FIFO Memory
    channelbuffer : entity work.STD_FIFO
        generic map(
            DATA_WIDTH => ACTIVATION_WIDTH_BITS,
            FIFO_DEPTH => HALF_IMAGE_WIDTH)
        port map(
            Clk_i     => clk_i,
            Rst_i     => rst_i,
            Data_i    => x_i,
            WriteEn_i => s_fifo_write_en,
            ReadEn_i  => s_fifo_read_en,
            Data_o    => s_fifo_out,
            Full_o    => s_fifo_full,
            Empty_o   => s_fifo_empty
        );
    process (clk_i, rst_i)

        variable v_is_buffering : std_logic := '1';
    begin
        if rst_i = '1' then
            is_buffering <= '1';
            v_is_buffering := '1';
            s_fifo_read_en <= '0';
            s_fifo_write_en <= '0';
            pool_state <= BUFFERING;
            valid_o    <= '0';
            y_o        <= UNDEFINED_OUTPUT;
        elsif rising_edge(clk_i) then

            -- When ever a full or empty signal occurs toggle state
            -- v_is_buffering := v_is_buffering xor (s_fifo_full or s_fifo_empty);
            -- More safe implementation
            if s_fifo_full = '1' then
                v_is_buffering := '0';
            elsif s_fifo_empty = '1' then
                v_is_buffering := '1';
            end if;

            -- Update Signals for debugging
            is_buffering <= v_is_buffering;

            -- Update Read & Write Enables
            s_fifo_write_en <= valid_i and is_buffering;
            s_fifo_read_en  <= valid_i and not is_buffering;

            
            -- Pool
            if v_is_buffering = '0' and valid_i = '1' then
                -- Check if input is larger than FIFO
                if unsigned(x_i) > unsigned(s_fifo_out) then
                    y_o <= x_i;
                else
                    y_o <= s_fifo_out;
                end if;

                valid_o <= '1';
            else
                valid_o <= '0';    
                y_o <= UNDEFINED_OUTPUT;
            end if;
        end if;
    end process;

end architecture;