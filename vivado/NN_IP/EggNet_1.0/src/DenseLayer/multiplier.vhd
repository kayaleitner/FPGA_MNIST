----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:51:55 10/18/2019 
-- Design Name: 
-- Module Name:    multiplier - Behavioral 
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

entity multiplier is
    Generic ( VECTOR_WIDTH : integer := 8);
    Port ( A_in : in  STD_LOGIC_VECTOR (VECTOR_WIDTH-1 downto 0);
           B_in : in  STD_LOGIC_VECTOR (VECTOR_WIDTH-1 downto 0);
           C_out : out  STD_LOGIC_VECTOR (VECTOR_WIDTH*2-1 downto 0));
end multiplier;

architecture Behavioral of multiplier is
begin
    calc : process(A_in, B_in)
		variable temp : signed(VECTOR_WIDTH downto 0);
		variable temp_out : signed(VECTOR_WIDTH*2 downto 0);
	begin
		temp(VECTOR_WIDTH) := '0';
		temp(VECTOR_WIDTH - 1 downto 0) := signed(A_in);
		temp_out := signed(B_in)*temp;
		C_out <= std_logic_vector(temp_out(VECTOR_WIDTH*2-1 downto 0));
	end process;

end Behavioral;

