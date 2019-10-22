----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:18:04 10/18/2019 
-- Design Name: 
-- Module Name:    data_loader - Behavioral 
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

entity data_loader is
    Port ( 
           clk_i : in  STD_LOGIC;
			  write_i : in  STD_LOGIC;
           data_i : in  STD_LOGIC_VECTOR (7 downto 0);
           address_i : in  STD_LOGIC_VECTOR (8 downto 0);
           data_o : out  STD_LOGIC_VECTOR (511 downto 0));
end data_loader;

architecture Behavioral of data_loader is

begin


loading : process(clk_i)
begin
	if(rising_edge(clk_i)) then
		if (write_i = '1') then
			data_o((to_integer(unsigned(address_i)))*8+7 downto (to_integer(unsigned(address_i)))*8)<=data_i;
		end if;
	end if;
end process;



end Behavioral;

