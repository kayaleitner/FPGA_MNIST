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
    Port ( a_in : in  STD_LOGIC_VECTOR (7 downto 0);
           b_in : in  STD_LOGIC_VECTOR (7 downto 0);
           c_out : out  STD_LOGIC_VECTOR (7 downto 0));
end multiplier;

architecture Behavioral of multiplier is

signal s_result : std_logic_vector(15 downto 0);

begin

-- just a quick test multiplier
s_result<=a_in*b_in;
c_out<=s_result(15 downto 8);




end Behavioral;

