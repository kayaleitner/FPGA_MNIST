----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:57:58 11/01/2019 
-- Design Name: 
-- Module Name:    accumulator - Behavioral 
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity accumulator is
	Generic(	BIAS_WIDTH : integer := 8;
	            INPUT_WIDTH : integer := 16;
				OUTPUT_WIDTH : integer := 27);
   Port ( 	Clk_i : in  STD_LOGIC;
			Reset_i : in  STD_LOGIC;
			Enable_i : in  STD_LOGIC;
			Reset_value_i : in STD_LOGIC_VECTOR(BIAS_WIDTH-1 downto 0);
			Data_i : in  STD_LOGIC_VECTOR (INPUT_WIDTH-1 downto 0);
			Data_o : out  STD_LOGIC_VECTOR (OUTPUT_WIDTH-1 downto 0));
end accumulator;

architecture Behavioral of accumulator is

    signal s_accumulated : std_logic_vector(OUTPUT_WIDTH-1 downto 0) := (others => '0');

begin

    process(Clk_i,Reset_i,Enable_i,Data_i)
    begin
        if(rising_edge(Clk_i))then
            if(Reset_i='1')then
                s_accumulated <= std_logic_vector(resize(signed(Reset_value_i),OUTPUT_WIDTH));
            elsif(Enable_i='1')then
                s_accumulated <= std_logic_vector(signed(s_accumulated) + resize(signed(Data_i),OUTPUT_WIDTH));
            end if;
        end if; 
    end process;
    
    Data_o <= s_accumulated;
    
end Behavioral;

