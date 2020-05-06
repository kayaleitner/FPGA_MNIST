library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.EggNetCommon.all;

entity Hpool is
    generic
    (
        N_CHANNELS : NATURAL := 1;      -- number of input channels
        DATA_WIDTH : NATURAL := 8;      -- data with of each output channel 
        POOL_H_WIDTH : NATURAL := 2     -- width of the pooling layer
    );
    port
    (
        clk_i : in std_logic;
        reset_i : in std_logic;

        valid_i : in std_logic;
        valid_o : out std_logic;

        x_i : in U_CHANNEL_ARRAY(0 to N_CHANNELS-1)(DATA_WIDTH-1 downto 0);
        y_i : in U_CHANNEL_ARRAY(0 to N_CHANNELS-1)(DATA_WIDTH-1 downto 0)
    );
end entity Hpool;

architecture rtl of Hpool is

    type STATE is (WAITING, FULL);
        

    type input_buffer_t is array (0 to N_CHANNELS-1, 0 to POOL_H_WIDTH-1) of unsigned(DATA_WIDTH-1 downto 0);
    signal input_buffer : input_buffer_t := (others => '0');
    signal input_buffer_count : NATURAL := 0;
    constant ZERO_BUFFER : input_buffer_t := (others => '0');

begin

    process (clk_i, reset_i)
    begin
        if rst_i = '1' then
            input_buffer <= ZERO_BUFFER;
        elsif rising_edge(clk_i) then
            for c in 0 to N_CHANNELS-1 loop
                for i in 0 to POOL_H_WIDTH-2 loop
                    input_buffer(c,i+1) <= input_buffer(c,i);
                end loop;
            end loop;

        end if;
    end process;
end architecture;