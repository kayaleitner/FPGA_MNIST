----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:58:14 10/18/2019 
-- Design Name: 
-- Module Name:    matrix_multiplier - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;


LIBRARY work;
USE work.denseLayerPkg.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity vectorMultiplier is
	Generic(   VECTOR_WIDTH : integer := 8;
	           INPUT_COUNT : integer := 4;
			   OUTPUT_COUNT : integer := 4);
    Port ( 
			  Clk_i : in std_logic;
			  Rd_en_o : out std_logic;
			  Data_i : in std_logic_vector(VECTOR_WIDTH-1 downto 0);
			  Weights_address_o : out std_logic_vector(integer(ceil(log2(real(INPUT_COUNT))))-1 downto 0);
			  Weights_i : in array_type(OUTPUT_COUNT-1 downto 0)(VECTOR_WIDTH-1 downto 0);
              Output_o : out  array_type(OUTPUT_COUNT-1 downto 0)((2*VECTOR_WIDTH + integer(ceil(log2(real(INPUT_COUNT)))))-1 downto 0);
			  Start_calculation_i : in std_logic;
			  Write_data_o : out std_logic);
			  
end vectorMultiplier;

architecture Behavioral of vectorMultiplier is

    signal s_multiplied : array_type(OUTPUT_COUNT-1 downto 0)(2*VECTOR_WIDTH-1 downto 0);
    
    type state_type is (idle, calculating, wait_calculation, write_data);
    signal state : state_type := idle;
    
    signal s_counter : std_logic_vector(integer(ceil(log2(real(INPUT_COUNT))))-1 downto 0) := (others=>'0');
    
    signal s_enable_accumulation : std_logic := '0';
    
    signal s_reset_accumulators : std_logic := '0';

begin
    
    -- Generate as many multiplier-accumulator pairs as there are output neurons.
    generateMultipliers: for i in 0 to OUTPUT_COUNT-1 generate
        -- Multiplies the input pixel with appropriate weight.
        multiplierBlock : entity work.multiplier
        generic map
        (
           VECTOR_WIDTH => VECTOR_WIDTH
        )
        port map
        (
            A_in => Data_i,
            B_in => Weights_i(i),
            C_out => s_multiplied(i)
        );
        -- Accumulates multiplied values.
        accumulatorBlock : entity work.accumulator
        generic map
        (
            INPUT_WIDTH => 2*VECTOR_WIDTH,
            OUTPUT_WIDTH => 2*VECTOR_WIDTH + integer(ceil(log2(real(INPUT_COUNT))))
        )
        port map
        (
            Clk_i => Clk_i,
            Reset_i => s_reset_accumulators,
            Enable_i => s_enable_accumulation,
            Data_i => s_multiplied(i),
            Data_o => Output_o(i)
        );
    end generate generateMultipliers;
    
    Weights_address_o <= s_counter;
    
    -- Finite state machine, that controls the calculation of all pixels.
    FSM : process(Clk_i)
    begin
        if(rising_edge(Clk_i))then
            case state is
                
                -- FSM is in idle state until it receives a signal to start calculations.
                when idle =>
                    s_enable_accumulation <= '0';
                    s_reset_accumulators <= '1';
                    Rd_en_o <= '0';
                    Write_data_o <= '0';
                    
                    s_counter <= (others=>'0');
                    
                    if(Start_calculation_i='1')then
                        state <= calculating;
                    end if;
                
                -- FSM is in this state until all of the pixels have been calculated.
                when calculating =>
                    s_enable_accumulation <= '1';
                    s_reset_accumulators <= '0';
                    Rd_en_o <= '1';
                    Write_data_o <= '0';
                    
                    if(s_counter = INPUT_COUNT-1)then
                        state <= wait_calculation;
                    else
                        s_counter <= s_counter + '1';
                    end if;
                
                -- This state is to wait the calculation of the last pixel.
                when wait_calculation =>
                    s_enable_accumulation <= '0';
                    s_reset_accumulators <= '0';
                    Rd_en_o <= '0';
                    Write_data_o <= '0';
                    
                    state <= write_data;
                
                -- Write_data_o is pulsed, to notify that calculation is finished
                when write_data =>
                    s_enable_accumulation <= '0';
                    s_reset_accumulators <= '0';
                    Rd_en_o <= '0';
                    Write_data_o <= '1';
                    
                    state <= idle;	
                    
            end case;
        end if;	
    end process;

end Behavioral;

